function contexto = gibbs3_report_context(res)
% GIBBS3_REPORT_CONTEXT Adapta un resultado GF3 al contrato transversal AOS.

  if nargin < 1 || ~isstruct(res) || ~isfield(res, 'param') || ...
      ~isfield(res, 'promedio') || ~isfield(res, 'metricas')
    error('Resultado GF3 incompleto para generar informe.');
  end

  res = gibbs3_upgrade_result_schema(res);
  if exist('gibbs3_repair_spacing_result', 'file') == 2
    [res, ~] = gibbs3_repair_spacing_result(res);
  end

  p = res.param;
  m = res.metricas;
  prom = res.promedio;

  Ql = numero_local(m, 'caudal_estimado_m3_d', 0) / 86400;
  wc = numero_local(p, 'WC', 0);
  wc = min(max(wc, 0), 1);
  Qo = Ql * (1 - wc);
  Qiny = 0;

  bm = struct();
  bm.Q_teorico = numero_local(m, 'caudal_teorico_bomba_m3_d', 0) / 86400;
  bm.Q_teorico_fondo = bm.Q_teorico;
  bm.S_superficie_m = numero_local(m, 'carrera_superficie_m', NaN);
  bm.S_fondo_m = numero_local(m, 'carrera_piston_relativa_m', NaN);
  bm.llenado_bomba = numero_local(res.bomba, 'llenado', numero_local(p, 'eta_vol', NaN));
  bm.Q_bomba = Ql;
  if isfield(p, 'P_intake') && isnumeric(p.P_intake) && isfinite(p.P_intake)
    bm.P_intake = p.P_intake;
  elseif isfield(p, 'P_intake_min')
    bm.P_intake = p.P_intake_min;
  end
  if isfield(res, 'diseno_sarta_espaciamiento') && ...
      isfield(res.diseno_sarta_espaciamiento, 'espaciamiento')
    e = res.diseno_sarta_espaciamiento.espaciamiento;
    bm.espaciamiento = struct();
    bm.espaciamiento.recomendacion_m = ...
      numero_local(e, 'recomendado_superficie_m', NaN);
    bm.espaciamiento.valido_calculo = ...
      logico_local(e, 'valido_calculo', logico_local(e, 'valido', false));
    bm.espaciamiento.estado = texto_local(e, 'estado', 'NO_EVALUADO');
    bm.espaciamiento.mensaje = texto_local(e, 'mensaje_validacion', ...
      texto_local(e, 'validacion', 'SIN_DIAGNOSTICO'));
  end

  p.BM_resultado = bm;
  p.GF3_resultado = res;
  p.tipo_unidad = texto_local(p, 'pumping_unit_type', 'NO_ESPECIFICADO');
  p.modelo_unidad_BM = texto_local(p, 'pumping_unit_model', 'NO_ESPECIFICADO');
  p.material_varillas = texto_local(p, 'rod_grade_name', 'NO_ESPECIFICADO');

  p.cartas_sup = [prom.u_superficie_plot_m(:), prom.F_superficie_N(:)];
  p.cartas_fondo = [prom.u_piston_relativo_plot_m(:), prom.F_bomba_N(:)];
  p.diagnostico_gibbs = struct();
  p.diagnostico_gibbs.carta_sup = p.cartas_sup;
  p.diagnostico_gibbs.carta_fondo = p.cartas_fondo;
  p.diagnostico_gibbs.modelo = 'Gibbs Foundation 3 integral';

  if ~isfield(p, 'nombre_pozo') || ~ischar(p.nombre_pozo) || ...
      isempty(strtrim(p.nombre_pozo))
    p.nombre_pozo = nombre_caso_local(p);
  end

  contexto = struct();
  contexto.tipo = 'BM';
  contexto.tipo_calculo = 'simulacion_operativa';
  contexto.solver = 'Gibbs Foundation 3 integral';
  contexto.nombre_caso = nombre_caso_local(p);
  contexto.param = p;
  contexto.resultado = res;
  contexto.report_tables = gibbs3_report_build_tables(res);
  contexto.Ql = Ql;
  contexto.Qo = Qo;
  contexto.Qiny = Qiny;
  contexto.exportador_simple = 'gibbs3_export_aosrpt_simple';
  contexto.exportador_enriquecido = 'gibbs3_export_aosrpt_enriched';
  contexto.carpeta_defecto = fullfile('intercambio', 'reportes', 'enviados');
end

function nombre = nombre_caso_local(p)
  nombre = '';
  campos = {'nombre_pozo', 'well_name', 'nombre_caso'};
  for i = 1:numel(campos)
    if isfield(p, campos{i}) && ischar(p.(campos{i})) && ...
        ~isempty(strtrim(p.(campos{i})))
      nombre = strtrim(p.(campos{i}));
      break;
    end
  end
  if isempty(nombre)
    global AOSDAT_ACTIVO
    if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
      [~, nombre, ~] = fileparts(AOSDAT_ACTIVO);
    end
  end
  if isempty(nombre), nombre = 'BM_GF3'; end
end

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end

function v = texto_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ischar(s.(campo)) && ...
      ~isempty(strtrim(s.(campo)))
    v = strtrim(s.(campo));
  end
end


function v = logico_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ~isempty(s.(campo))
    x = s.(campo);
    if islogical(x) || (isnumeric(x) && isfinite(x(1)))
      v = logical(x(1));
    end
  end
end
