function [modelo, cfg] = aos_cad_hidraulica_preparar_modelo(silencioso)
% Prepara tablas, metadatos, topologia y configuracion sin ejecutar el solver.
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
  if ~isfield(modelo.tablas_entrada, 'dominios_hidraulicos')
    modelo.tablas_entrada.dominios_hidraulicos = {};
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  if ~isfield(modelo, 'topologia') || ~isfield(modelo.topologia, 'aristas') || ...
      isempty(modelo.topologia.aristas)
    aos_cad_construir_topologia(0.05, true);
  endif
  aos_cad_validar_topologia(true);
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  cfg = aos_cad_hidraulica_defaults(modelo);
  if ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion)
    modelo.simulacion = struct();
  endif
  modelo.simulacion.configuracion_hidraulica = cfg;
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  if ~silencioso
    nN = contar_local(modelo, 'nodos'); nE = contar_local(modelo, 'tramos');
    [d, ~] = aos_cad_hidraulica_dominio_activo(modelo);
    fprintf('\nMODELO HIDRAULICO PREPARADO\n');
    fprintf('Nodos totales   : %d\n', nN);
    fprintf('Tramos totales  : %d\n', nE);
    if isempty(d), fprintf('Dominio efectivo: RED COMPLETA\n');
    else, fprintf('Dominio efectivo: %s (%s -> %s)\n', d.id, d.nodo_inicio, d.nodo_fin); endif
    fprintf('Modelo efectivo : %s\n', cfg.modelo);
    fprintf('Multifasico     : %s\n', cfg.modelo_multifasico);
    fprintf('Estado          : listo para seleccionar/validar/ejecutar\n');
  endif
endfunction
function n = contar_local(modelo, campo)
  n=0; if isfield(modelo,'tablas_entrada')&&isfield(modelo.tablas_entrada,campo),n=numel(modelo.tablas_entrada.(campo));endif
endfunction
