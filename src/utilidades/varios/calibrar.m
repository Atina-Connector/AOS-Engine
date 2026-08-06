% calibrar.m - Comparacion de IPR/VLP contra datos de campo.
% GNU Octave objetivo. Usa una configuracion canonica, un Qiny explicito y
% los solvers activos de AOS 0.0.12. No usa caudales hardcodeados ni JGL
% heredado.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(fileparts(script_dir)));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

[base, origen_config] = aos_config_base('CALIBRACION');
base = aos_sincronizar_config(base, 'CALIBRACION');
fprintf('Calibracion usando %s.\n', origen_config);

% El factor se aplica al canonico una sola vez para esta corrida.
factor_ip = 1.0;
if isfield(base, 'factor_IP_residual') && isnumeric(base.factor_IP_residual) && ...
   isscalar(base.factor_IP_residual) && isfinite(base.factor_IP_residual)
  factor_ip = base.factor_IP_residual;
end
base.IP = base.IP * factor_ip;
base = aos_sincronizar_config(base, 'CALIBRACION');
base.survey = obtener_survey(base);

cal = struct();
if isfield(base, 'calibracion') && isstruct(base.calibracion) && ...
   isfield(base.calibracion, 'tipo') && isfield(base.calibracion, 'valor')
  cal = base.calibracion;
  fprintf('Datos de campo tomados de [CALIBRACION] del .aosdat.\n');
elseif exist(fullfile('config', 'calibracion.txt'), 'file')
  archivo_cal = fullfile('config', 'calibracion.txt');
  fid = fopen(archivo_cal, 'r');
  if fid == -1, error('No se pudo abrir %s.', archivo_cal); end
  while ~feof(fid)
    linea = fgetl(fid);
    if ~ischar(linea), continue; end
    limpia = strtrim(linea);
    if isempty(limpia) || limpia(1) == '#', continue; end
    partes = strsplit(limpia, '=');
    if numel(partes) == 2
      campo = strtrim(partes{1});
      cal.(campo) = aos_parse_valor(strtrim(partes{2}));
    end
  end
  fclose(fid);
else
  fprintf('\nNo hay [CALIBRACION] en el .aosdat ni config/calibracion.txt.\n');
  fprintf('El archivo config/GL/Calibracion_Coeficientes_JGL.txt es documentacion, no datos de campo.\n');
  return;
end

if ~isfield(cal, 'tipo')
  if isfield(cal, 'Ql_m3_d')
    cal.tipo = 'Ql'; cal.valor = cal.Ql_m3_d / 86400;
  elseif isfield(cal, 'Pwf_bar')
    cal.tipo = 'Pwf'; cal.valor = cal.Pwf_bar * 1e5;
  end
end
if isfield(cal, 'tipo') && strcmpi(cal.tipo, 'Ql') && isfield(cal, 'valor_m3_d')
  cal.valor = cal.valor_m3_d / 86400;
elseif isfield(cal, 'tipo') && strcmpi(cal.tipo, 'Pwf') && isfield(cal, 'valor_bar')
  cal.valor = cal.valor_bar * 1e5;
end
if ~isfield(cal, 'tipo') || ~isfield(cal, 'valor') || ...
   ~isnumeric(cal.valor) || ~isscalar(cal.valor) || ~isfinite(cal.valor)
  error('Los datos de calibracion requieren tipo y valor validos.');
end

fprintf('\n--- Sistemas a calibrar ---\n');
fprintf('1 - Solo JGL\n2 - Solo GL\n3 - Ambos\n');
opcion = input('Seleccione [3]: ');
if isempty(opcion), opcion = 3; end
if opcion == 1
  sistemas = {'JGL'};
elseif opcion == 2
  sistemas = {'GL'};
else
  sistemas = {'JGL','GL'};
end

% Una politica de gas comun evita comparar solvers con entradas diferentes.
[Qcfg, fuente_q] = aos_qiny_referencia(base);
fprintf('\n--- QINY PARA CALIBRACION ---\n');
if isempty(Qcfg)
  fprintf('Valor configurado: no disponible.\n');
else
  fprintf('Valor configurado: %s [%s]\n', aos_formato_caudal_gas(Qcfg), fuente_q);
end
fprintf('1 - Mantener valor configurado para todos los modelos (Enter)\n');
fprintf('2 - Forzar un valor manual (se admite 0 o cualquier valor >= 0)\n');
fprintf('3 - Calcular por presion/orificio\n');
op_q = input('Seleccione opcion [1]: '); if isempty(op_q), op_q = 1; end
if op_q == 3
  [Qiny_cal, det_qiny] = aos_calcular_qiny_auto_gl(base, base.D_iny); %#ok<NASGU>
  politica_qiny = 'PRESION_ORIFICIO';
elseif op_q == 2
  if isempty(Qcfg), qdef=0; else, qdef=Qcfg*86400; end
  while true
    qsm=input(sprintf('Qiny manual (Sm3/d) [%.0f]: ',qdef)); if isempty(qsm),qsm=qdef;end
    if isnumeric(qsm)&&isscalar(qsm)&&isfinite(qsm)&&qsm>=0,break;end
    fprintf('Valor invalido. Ingrese un numero mayor o igual que cero.\n');
  end
  Qiny_cal=qsm/86400; politica_qiny='FIJO_MANUAL';
else
  if isempty(Qcfg), error('No existe Qiny configurado. Use opcion 2 o 3.'); end
  Qiny_cal=Qcfg; politica_qiny='CONFIGURADO';
end
fprintf('Qiny efectivo de calibracion: %s\n', aos_formato_caudal_gas(Qiny_cal));

modo_jgl = 'iterativo';
max_iter = 10;
if any(strcmp(sistemas, 'JGL'))
  fprintf('\nEl solver iterativo es la referencia para calibracion JGL.\n');
  usar_otro = aos_preguntar_sn('Cambiar modo JGL? (s/n) [n]: ', false);
  if usar_otro
    [modo_jgl, max_iter] = jgl_menu_aproximacion('iterativo', 10);
  else
    v = input('Maximo de iteraciones JGL [10]: ');
    if ~isempty(v), max_iter = max(3, min(100, round(v))); end
  end
end

modelos_IPR = {'linear','Vogel','Fetkovich'};
modelos_VLP = {'simplified','HB','DR'};
resultados = struct();

for s = 1:length(sistemas)
  sistema = sistemas{s};
  fprintf('\n========== CALIBRACION %s ==========\n', sistema);
  if strcmpi(cal.tipo, 'Ql')
    fprintf('Dato medido: Ql = %.3f m3/d\n', cal.valor * 86400);
  else
    fprintf('Dato medido: Pwf = %.3f bar\n', cal.valor / 1e5);
  end
  fprintf('Qiny: %.0f Sm3/d | politica: %s\n', Qiny_cal * 86400, politica_qiny);
  fprintf('IPR        VLP          Ql(m3/d)  Error(%%)  Pwf(bar)  Estado\n');
  fprintf('----------------------------------------------------------------\n');

  mejor = struct('error', Inf, 'IPR', '', 'VLP', '', 'estado', 'SIN_RESULTADO');
  tabla = cell(length(modelos_IPR), length(modelos_VLP));

  for i = 1:length(modelos_IPR)
    for j = 1:length(modelos_VLP)
      p = base;
      p.modelo_IPR = modelos_IPR{i};
      p.modelo_VLP = modelos_VLP{j};
      p = aos_set_qiny(p, Qiny_cal * 86400, 'fijo');
      p.jgl_max_iter = max_iter;
      p = aos_sincronizar_config(p, sistema);
      estado = 'OK';
      Ql_sim = NaN;
      Pwf_sim = NaN;
      sol = [];
      try
        if strcmp(sistema, 'JGL')
          sol = jgl_ejecutar(p, Qiny_cal, modo_jgl);
          Ql_sim = sol.Ql;
          estado = sol.estado;
        else
          [Ql_sim, ~, ~, qef] = GL_sim(p, Qiny_cal);
          if abs(qef - Qiny_cal) > max(1e-12, 1e-9 * max(Qiny_cal, 1))
            error('GL devolvio Qiny %.6g, solicitado %.6g m3/s.', qef, Qiny_cal);
          end
        end
        [~, Pwf_func] = ipr(p, p.modelo_IPR);
        Pwf_sim = Pwf_func(Ql_sim);
      catch err
        estado = ['ERROR: ', err.message];
      end

      if ~isfinite(Ql_sim) || ~isfinite(Pwf_sim)
        error_total = Inf;
        fprintf('%-10s %-12s %-9s %-9s %-9s %s\n', ...
          modelos_IPR{i}, modelos_VLP{j}, '--', '--', '--', estado);
      else
        if strcmpi(cal.tipo, 'Ql')
          error_total = abs(Ql_sim - cal.valor) / max(abs(cal.valor), eps) * 100;
        else
          error_total = abs(Pwf_sim - cal.valor) / max(abs(cal.valor), eps) * 100;
        end
        fprintf('%-10s %-12s %9.2f %9.2f %9.2f %s\n', ...
          modelos_IPR{i}, modelos_VLP{j}, Ql_sim * 86400, error_total, Pwf_sim / 1e5, estado);
      end

      tabla{i,j} = struct('IPR', modelos_IPR{i}, 'VLP', modelos_VLP{j}, ...
        'Ql', Ql_sim, 'Pwf', Pwf_sim, 'error_porcentaje', error_total, ...
        'estado', estado, 'Qiny', Qiny_cal, 'sol_jgl', sol);
      if isfinite(error_total) && error_total < mejor.error
        mejor.error = error_total;
        mejor.IPR = modelos_IPR{i};
        mejor.VLP = modelos_VLP{j};
        mejor.estado = estado;
      end
    end
  end

  if isfinite(mejor.error)
    fprintf('Mejor %s: %s + %s, error %.2f %%\n', sistema, mejor.IPR, mejor.VLP, mejor.error);
  else
    fprintf('Ninguna combinacion %s produjo un resultado valido.\n', sistema);
  end
  resultados.(sistema) = struct('mejor', mejor, 'tabla', {tabla});
end

CALIBRACION_AUDIT = struct('origen', origen_config, 'base', base, 'dato', cal, ...
  'Qiny', Qiny_cal, 'politica_Qiny', politica_qiny, 'modo_JGL', modo_jgl, ...
  'max_iter_JGL', max_iter, 'resultados', resultados);
assignin('base', 'CALIBRACION_AUDIT', CALIBRACION_AUDIT);

fprintf('\nLa calibracion no modifica automaticamente config/GL/config_jgl.txt.\n');
fprintf('El resultado completo queda en CALIBRACION_AUDIT para revision ingenieril.\n');
