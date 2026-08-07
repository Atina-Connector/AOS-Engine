function resultados = aos_cad_hidraulica_ejecutar(silencioso)
% AOS_CAD_HIDRAULICA_EJECUTAR Ejecuta el solver oficial DEV1 sobre el DXF activo.
  global CONFIG_ACTIVA;
  if nargin < 1, silencioso = false; endif
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    error('AOSCAD HID: no hay DXF activo. Importe un DXF primero.');
  endif
  if ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    aos_cad_mapear_objetos([], true);
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  modelo = aos_cad_hidraulica_aplicar_metadatos(modelo);
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  if ~isfield(modelo, 'topologia') || ~isfield(modelo.topologia, 'aristas') || ...
      isempty(modelo.topologia.aristas)
    aos_cad_construir_topologia(0.05, true);
    modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  endif
  aos_cad_validar_topologia(true);
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  cfg = aos_cad_hidraulica_defaults(modelo);
  [dominio_act, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  modo_pp = false;
  es_lazo = false;
  if ~isempty(dominio_act)
    if isfield(dominio_act, 'tipo')
      es_lazo = strcmpi(char(dominio_act.tipo), 'LOOP_SUBNETWORK');
    endif
    if isfield(dominio_act, 'condicion_extremos') && ...
        strcmpi(char(dominio_act.condicion_extremos), 'P_INICIO_P_FIN')
      modo_pp = true;
    endif
  endif
  if modo_pp && ~es_lazo
    [modelo, resultados] = aos_cad_hidraulica_dominio_resolver_pp( ...
      modelo, cfg, silencioso);
  else
    [modelo, resultados] = aos_cad_hidraulica_resolver(modelo, cfg, silencioso);
  endif
  if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion)
    if isfield(modelo.simulacion, 'solver_usado')
      solver_txt = char(modelo.simulacion.solver_usado);
    elseif isfield(modelo.simulacion, 'parametros_efectivos') && ...
        isfield(modelo.simulacion.parametros_efectivos, 'topologia_soportada') && ...
        strcmp(char(modelo.simulacion.parametros_efectivos.topologia_soportada), ...
               'LAZOS_KIRCHHOFF_MONOFASICO')
      solver_txt = 'HYD_LOOP';
      modelo.simulacion.solver_usado = 'HYD_LOOP';
    else
      solver_txt = 'HYD_TREE';
      modelo.simulacion.solver_usado = 'HYD_TREE';
    endif
    if ~silencioso
      fprintf('Solver usado: %s\n', solver_txt);
    endif
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.resultados_hidraulicos = resultados;
endfunction
