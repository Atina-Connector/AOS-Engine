function resumen = aos_sincronizar_geologia_activa()
% Sincroniza CONFIG_ACTIVA, geologia global y punzados sin inventar geologia.
  global CONFIG_ACTIVA geologia;
  resumen = struct('geologia_cargada', false, 'n_punzados', 0, ...
                   'n_punzados_activos',0,'avisos', {{}});

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    return;
  endif

  geol_local = struct();
  if isfield(CONFIG_ACTIVA,'geologia') && isstruct(CONFIG_ACTIVA.geologia)
    geol_local=CONFIG_ACTIVA.geologia;
  endif

  fuente=struct('tramos',struct([]));
  if isfield(CONFIG_ACTIVA,'punzados')
    fuente=CONFIG_ACTIVA.punzados;
  elseif isfield(geol_local,'intervalos')
    fuente=geol_local.intervalos;
  endif
  [intervalos, avisos_pz]=aos_punzados_normalizar(fuente, ...
    struct('origen','SINCRONIZACION_CONFIG'));
  resumen.avisos=[resumen.avisos,avisos_pz];
  resumen.n_punzados=numel(intervalos.tramos);
  resumen.n_punzados_activos=intervalos.n_activos;

  % Punzados independientes siempre quedan disponibles en CONFIG_ACTIVA.
  CONFIG_ACTIVA.punzados=intervalos;

  if ~isempty(fieldnames(geol_local))
    geol_local.intervalos=intervalos;
    [geol_local,avisos_geo]=aos_normalizar_geologia(geol_local,CONFIG_ACTIVA);
    resumen.avisos=[resumen.avisos,avisos_geo];
    geologia=geol_local;
    CONFIG_ACTIVA.geologia=geol_local;
    CONFIG_ACTIVA.punzados=geol_local.intervalos;
    resumen.geologia_cargada=true;
  else
    % No se crea una geologia ficticia por el solo hecho de tener punzados.
    geologia=[];
    if isfield(CONFIG_ACTIVA,'geologia')
      CONFIG_ACTIVA=rmfield(CONFIG_ACTIVA,'geologia');
    endif
  endif
endfunction
