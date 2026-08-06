function [res, cambios] = gibbs3_upgrade_result_schema(res)
% GIBBS3_UPGRADE_RESULT_SCHEMA Actualiza resultados GF3 anteriores.
%
% Reconstruye, cuando es posible, la configuracion instalable de la sarta,
% barras de peso y espaciamiento. Esto permite usar GF3_ULTIMO_RESULTADO
% creado antes del parche sin repetir obligatoriamente la simulacion.

  if nargin < 1 || ~isstruct(res)
    error('El resultado GF3 a actualizar no es una estructura valida.');
  end
  if ~isfield(res, 'param') || ~isstruct(res.param)
    error('El resultado GF3 no contiene param.');
  end

  cambios = {};
  try
    res.param = gibbs3_defaults(res.param);
  catch
  end

  signo_modificado = false;
  try
    [res, cambios_signo, signo_modificado] = ...
      gibbs3_repair_tubing_sign_result(res, false);
    cambios = [cambios, cambios_signo];
  catch err_signo
    res.gf3_tubing_sign_upgrade_warning = ...
      ['No se pudo actualizar el signo de tubing: ' err_signo.message];
  end_try_catch

  % El spacing consume la carrera relativa almacenada en metricas. Si la
  % cinematica piston-barril cambio, las metricas deben actualizarse antes
  % de recalcular el espaciamiento, no despues.
  if signo_modificado && isfield(res, 'bomba') && isstruct(res.bomba) && ...
      isfield(res, 'promedio') && isstruct(res.promedio)
    try
      res.metricas = gibbs3_metrics(res);
      cambios{end+1} = 'metricas_recalculadas_por_signo_tubing';
    catch err_metricas
      res.gf3_tubing_sign_metrics_warning = err_metricas.message;
    end_try_catch
  endif

  if isfield(res, 'diseno_sarta_espaciamiento') && ...
      isstruct(res.diseno_sarta_espaciamiento)
    d_anterior = res.diseno_sarta_espaciamiento;
  else
    d_anterior = struct();
  end
  d = d_anterior;

  necesita_recalculo = signo_modificado || ...
    ~isfield(d, 'plan_instalacion_sarta') || ...
    isempty(d.plan_instalacion_sarta) || ...
    ~isfield(d, 'barras_peso') || ~isstruct(d.barras_peso) || ...
    ~isfield(d, 'espaciamiento') || ~isstruct(d.espaciamiento);

  if necesita_recalculo && puede_recalcular_local(res)
    try
      d_nuevo = gibbs3_rod_spacing_design(res);
      d = combinar_faltantes_local(d_nuevo, d_anterior);
      cambios{end+1} = 'diseno_sarta_espaciamiento_recalculado';
    catch err_recalculo
      res.gf3_schema_upgrade_warning = ['No se pudo recalcular toda la ' ...
        'seccion de sarta/spacing: ' err_recalculo.message];
    end
  end

  if ~isfield(d, 'plan_instalacion_sarta') || ...
      isempty(d.plan_instalacion_sarta)
    plan = gibbs3_build_installation_plan(res.param);
    if ~isempty(plan)
      d.plan_instalacion_sarta = plan;
      d.masa_total_varillas_kg = sumar_masa_local(plan);
      cambios{end+1} = 'plan_instalacion_sarta_reconstruido';
    end
  end

  d = completar_barras_local(d, res.param);
  d = completar_espaciamiento_local(d, res.param);

  res.diseno_sarta_espaciamiento = d;
  if (~isfield(res, 'metricas') || ~isstruct(res.metricas)) && ...
      isfield(res, 'bomba') && isstruct(res.bomba) && ...
      isfield(res, 'promedio') && isstruct(res.promedio)
    try
      res.metricas = gibbs3_metrics(res);
    catch
    end_try_catch
  endif
  res.gf3_schema_version = 'GF3_RESULTADO_1_8_SIGNO_TUBERIA_LIBRE';
  res.gf3_tubing_sign_schema = 'GF3_TUBING_SIGN_1_8';
  res.gf3_schema_upgrade_changes = unique(cambios);
end

function ok = puede_recalcular_local(res)
  campos = {'param','malla','promedio','equilibrio','tuberia','metricas'};
  ok = true;
  for i = 1:numel(campos)
    if ~isfield(res, campos{i}) || ~isstruct(res.(campos{i}))
      ok = false;
      return;
    end
  end
  if ~isfield(res.promedio, 'U_m') || isempty(res.promedio.U_m)
    ok = false;
  end
end

function d = completar_barras_local(d, p)
  if ~isfield(d, 'barras_peso') || ~isstruct(d.barras_peso)
    d.barras_peso = struct();
  end
  b = d.barras_peso;
  b = set_default_local(b, 'habilitadas', logico_param_local(p, 'barras_peso_habilitadas', true));
  b = set_default_local(b, 'cantidad_recomendada', 0);
  b = set_default_local(b, 'cantidad_instalada', ...
    round(numero_param_local(p, 'barras_peso_aplicadas_cantidad', 0)));
  b = set_default_local(b, 'longitud_unitaria_m', ...
    numero_param_local(p, 'barras_peso_longitud_unitaria_m', 7.62));
  b = set_default_local(b, 'diametro_mm', ...
    numero_param_local(p, 'barras_peso_diametro_mm', 38.1));
  b = set_default_local(b, 'longitud_instalada_m', ...
    b.cantidad_instalada*b.longitud_unitaria_m);
  b = set_default_local(b, 'instalar', ...
    logical(max(b.cantidad_recomendada, b.cantidad_instalada) > 0));
  if ~isfield(b, 'resultado_operativo') || ~ischar(b.resultado_operativo) || ...
      isempty(strtrim(b.resultado_operativo))
    n = max(round(b.cantidad_recomendada), round(b.cantidad_instalada));
    if n > 0
      b.resultado_operativo = sprintf('INSTALAR %d BARRAS DE PESO', n);
    elseif b.habilitadas
      b.resultado_operativo = 'NO SE REQUIEREN BARRAS DE PESO';
    else
      b.resultado_operativo = 'CALCULO DE BARRAS DE PESO DESHABILITADO';
    end
  end
  d.barras_peso = b;
end

function d = completar_espaciamiento_local(d, p)
  if ~isfield(d, 'espaciamiento') || ~isstruct(d.espaciamiento)
    d.espaciamiento = struct();
  end
  e = d.espaciamiento;
  e = set_default_local(e, 'modo', texto_param_local(p, 'spacing_mode', 'NO_CONFIGURADO'));
  e = set_default_local(e, 'tolerancia_ejecucion_mm', ...
    1000*numero_param_local(p, 'spacing_tolerancia_ejecucion_m', 0.01));
  if isfield(e, 'recomendado_superficie_m') && ...
      isnumeric(e.recomendado_superficie_m) && ...
      ~isempty(e.recomendado_superficie_m) && ...
      isfinite(e.recomendado_superficie_m(1)) && ...
      (~isfield(e, 'levantamiento_despues_sensar_mm') || ...
       ~isfinite_numero_local(e.levantamiento_despues_sensar_mm))
    e.levantamiento_despues_sensar_mm = ...
      1000*e.recomendado_superficie_m(1);
  end

  % Migra resultados anteriores al contrato publico vigente sin alterar el
  % valor fisico calculado. valido indica que el calculo es finito; la
  % aprobacion geometrica se conserva por separado en geometria_aprobada.
  if ~isfield(e, 'valido_calculo') || isempty(e.valido_calculo)
    if isfield(e, 'valido') && ~isempty(e.valido)
      e.valido_calculo = logical(e.valido(1));
    else
      e.valido_calculo = isfield(e, 'levantamiento_despues_sensar_mm') && ...
        isfinite_numero_local(e.levantamiento_despues_sensar_mm) && ...
        e.levantamiento_despues_sensar_mm(1) > 0;
    end
  end
  if ~isfield(e, 'valido') || isempty(e.valido)
    e.valido = logical(e.valido_calculo);
  end
  if ~isfield(e, 'mensaje_validacion') || ...
      ~ischar(e.mensaje_validacion) || isempty(strtrim(e.mensaje_validacion))
    if isfield(e, 'validacion') && ischar(e.validacion) && ...
        ~isempty(strtrim(e.validacion))
      e.mensaje_validacion = e.validacion;
    else
      e.mensaje_validacion = 'SIN_DIAGNOSTICO';
    end
  end
  if ~isfield(e, 'validacion') || ~ischar(e.validacion) || ...
      isempty(strtrim(e.validacion))
    e.validacion = e.mensaje_validacion;
  end
  if ~isfield(e, 'schema') || ~ischar(e.schema) || isempty(e.schema)
    e.schema = 'GF3_SPACING_RESULT_1_1';
  end
  d.espaciamiento = e;
end

function s = combinar_faltantes_local(s, anterior)
  if ~isstruct(anterior), return; end
  nombres = fieldnames(anterior);
  for i = 1:numel(nombres)
    f = nombres{i};
    if ~isfield(s, f)
      s.(f) = anterior.(f);
    elseif isstruct(s.(f)) && isstruct(anterior.(f)) && ...
        isscalar(s.(f)) && isscalar(anterior.(f))
      s.(f) = combinar_faltantes_local(s.(f), anterior.(f));
    end
  end
end

function suma = sumar_masa_local(plan)
  suma = 0;
  for i = 1:numel(plan)
    if isfield(plan(i), 'masa_kg') && isfinite_numero_local(plan(i).masa_kg)
      suma = suma + plan(i).masa_kg;
    end
  end
end

function s = set_default_local(s, campo, valor)
  if ~isfield(s, campo) || isempty(s.(campo))
    s.(campo) = valor;
  end
end

function tf = isfinite_numero_local(x)
  tf = isnumeric(x) && ~isempty(x) && isfinite(x(1));
end

function v = numero_param_local(p, campo, defecto)
  v = defecto;
  if isstruct(p) && isfield(p, campo)
    x = p.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end

function v = logico_param_local(p, campo, defecto)
  v = defecto;
  if isstruct(p) && isfield(p, campo) && ~isempty(p.(campo))
    x = p.(campo);
    v = logical(x(1));
  end
end

function v = texto_param_local(p, campo, defecto)
  v = defecto;
  if isstruct(p) && isfield(p, campo) && ischar(p.(campo)) && ...
      ~isempty(strtrim(p.(campo)))
    v = strtrim(p.(campo));
  end
end
