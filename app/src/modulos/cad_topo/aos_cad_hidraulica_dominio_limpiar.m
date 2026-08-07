function ok = aos_cad_hidraulica_dominio_limpiar(silencioso)
% Desactiva la seleccion y vuelve a usar la red completa.
  global CONFIG_ACTIVA;
  if nargin < 1
    silencioso = false;
  endif
  ok = false;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD DOMINIO: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  [dominio, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    if ~silencioso
      fprintf('No habia dominio activo.\n');
    endif
    ok = true;
    return;
  endif

  dominios = modelo.tablas_entrada.dominios_hidraulicos;
  if isstruct(dominios)
    dominios = num2cell(dominios);
  endif
  for i = 1:numel(dominios)
    dominios{i}.activo = false;
  endfor
  modelo.tablas_entrada.dominios_hidraulicos = dominios;
  modelo.simulacion.dominio_hidraulico_activo_id = '';
  modelo = aos_cad_hidraulica_invalidar_por_dominio( ...
    modelo, 'DESACTIVAR_DOMINIO_HIDRAULICO', dominio.id);
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  ok = true;
  if ~silencioso
    fprintf(['Dominio %s desactivado. La siguiente corrida usara ' ...
             'la red completa.\n'], dominio.id);
  endif
endfunction
