function info = aos_punzados_commit(candidatos, origen)
% AOS_PUNZADOS_COMMIT Confirma punzados sin exigir geologia activa.
% Mantiene sincronizados CONFIG_ACTIVA.punzados y, cuando existe una
% geologia real, geologia.intervalos. Invalida resultados anteriores.

  if nargin < 2 || isempty(origen), origen='MANUAL'; endif
  [origen,okori]=aos_texto_seguro(origen,'MANUAL');
  if ~okori,origen='MANUAL';endif
  [nuevos,avisos_norm]=aos_punzados_normalizar(candidatos,struct('origen',origen));

  global CONFIG_ACTIVA geologia;
  previo_cfg=CONFIG_ACTIVA; previo_geo=geologia;

  anteriores=struct('tramos',struct([]));
  if isstruct(CONFIG_ACTIVA)&&isfield(CONFIG_ACTIVA,'punzados')
    [anteriores,~]=aos_punzados_normalizar(CONFIG_ACTIVA.punzados);
  elseif isstruct(geologia)&&isfield(geologia,'intervalos')
    [anteriores,~]=aos_punzados_normalizar(geologia.intervalos);
  endif
  cambio=~isequal(limpiar_auditoria_local(anteriores), ...
                  limpiar_auditoria_local(nuevos));

  try
    if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA),CONFIG_ACTIVA=struct();endif
    nuevos.aos_origen_punzados=origen;
    nuevos.aos_fecha_modificacion=datestr(now,'yyyy-mm-dd HH:MM:SS');
    CONFIG_ACTIVA.punzados=nuevos;
    CONFIG_ACTIVA.aos_origen_punzados=origen;

    if isfield(CONFIG_ACTIVA,'geologia')&&isstruct(CONFIG_ACTIVA.geologia)&& ...
       ~isempty(fieldnames(CONFIG_ACTIVA.geologia))
      CONFIG_ACTIVA.geologia.intervalos=nuevos;
      try
        [CONFIG_ACTIVA.geologia,~]=aos_normalizar_geologia( ...
          CONFIG_ACTIVA.geologia,CONFIG_ACTIVA);
      catch
      end_try_catch
    endif
    if isstruct(geologia)&&~isempty(fieldnames(geologia))
      geologia.intervalos=nuevos;
      try,[geologia,~]=aos_normalizar_geologia(geologia,CONFIG_ACTIVA);catch,end_try_catch
      CONFIG_ACTIVA.geologia=geologia;
    endif

    if cambio,aos_invalidar_resultados('Cambio de intervalos de punzados');endif
  catch err
    CONFIG_ACTIVA=previo_cfg; geologia=previo_geo;
    rethrow(err);
  end_try_catch

  info=struct('ok',true,'cambio',cambio,'origen',origen, ...
    'n_tramos',numel(nuevos.tramos),'n_activos',nuevos.n_activos, ...
    'avisos',{avisos_norm});
  if cambio
    fprintf('Punzados actualizados. Resultados anteriores invalidados.\n');
  else
    fprintf('Los punzados confirmados no cambian el caso vigente.\n');
  endif
endfunction

function s=limpiar_auditoria_local(s)
  if ~isstruct(s),s=struct();return;endif
  campos={'aos_origen_punzados','aos_fecha_modificacion','schema', ...
    'n_tramos','n_activos','longitud_total_m','tiros_totales_estimados'};
  for i=1:numel(campos)
    if isfield(s,campos{i}),s=rmfield(s,campos{i});endif
  endfor
endfunction
