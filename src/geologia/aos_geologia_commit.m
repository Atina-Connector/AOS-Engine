function info = aos_geologia_commit(candidata, origen)
% AOS_GEOLOGIA_COMMIT Confirma en forma atomica una geologia candidata.
% Si la normalizacion o la sincronizacion falla, restaura el caso anterior.

  if nargin < 1 || ~isstruct(candidata) || isempty(fieldnames(candidata))
    error('AOS Geologia: no hay una geologia candidata valida.');
  endif
  if nargin < 2 || isempty(origen), origen = 'MANUAL'; endif
  [origen, ok_origen] = aos_texto_seguro(origen, 'MANUAL');
  if ~ok_origen, origen = 'MANUAL'; endif

  global geologia CONFIG_ACTIVA;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;

  geologia_previa = geologia;
  config_previa = CONFIG_ACTIVA;
  resultados_previos = {ULTIMO_QL, ULTIMO_QO, ULTIMO_QINY, ULTIMO_TIPO, ULTIMO_PARAM};

  anterior = geologia_previa;
  if (isempty(anterior) || ~isstruct(anterior)) && ...
     isstruct(config_previa) && isfield(config_previa, 'geologia') && ...
     isstruct(config_previa.geologia)
    anterior = config_previa.geologia;
  endif
  if ~isstruct(anterior), anterior = struct(); endif

  contexto = struct();
  if isstruct(config_previa), contexto = config_previa; endif
  [normalizada, avisos] = aos_normalizar_geologia(candidata, contexto);
  if isfield(normalizada,'intervalos')
    [normalizada.intervalos,avisos_pz]=aos_punzados_normalizar( ...
      normalizada.intervalos,struct('origen','GEOLOGIA'));
    avisos=[avisos,avisos_pz];
  endif

  % La geologia y los punzados contienen campos opcionales NaN. En GNU
  % Octave isequal(NaN,NaN) es falso, por lo que una reconfirmacion sin
  % cambios quedaba marcada como modificacion. isequaln trata NaN en la
  % misma posicion como equivalente y permite un commit idempotente.
  cambio = ~isequaln(limpiar_auditoria_local(anterior), ...
    limpiar_auditoria_local(normalizada));
  normalizada.aos_origen_geologia = origen;
  normalizada.aos_fecha_modificacion = datestr(now, 'yyyy-mm-dd HH:MM:SS');

  try
    geologia = normalizada;
    if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
      CONFIG_ACTIVA = struct();
    endif
    CONFIG_ACTIVA.geologia = normalizada;
    if isfield(normalizada,'intervalos')
      CONFIG_ACTIVA.punzados=normalizada.intervalos;
    elseif ~isfield(CONFIG_ACTIVA,'punzados')
      CONFIG_ACTIVA.punzados=aos_punzados_normalizar(struct('tramos',struct([])));
    endif

    if cambio
      aos_invalidar_resultados('Cambio de geologia o punzados');
    endif
  catch err
    geologia = geologia_previa;
    CONFIG_ACTIVA = config_previa;
    ULTIMO_QL = resultados_previos{1};
    ULTIMO_QO = resultados_previos{2};
    ULTIMO_QINY = resultados_previos{3};
    ULTIMO_TIPO = resultados_previos{4};
    ULTIMO_PARAM = resultados_previos{5};
    rethrow(err);
  end_try_catch

  info = struct('ok', true, 'cambio', cambio, 'origen', origen, ...
    'avisos', {avisos}, 'n_punzados', n_punzados_local(normalizada));
  if cambio
    fprintf('Resultados anteriores invalidados por cambio de geologia/punzados.\n');
  else
    fprintf('La geologia confirmada no cambia los datos fisicos vigentes.\n');
  endif
endfunction

function s = limpiar_auditoria_local(s)
  if ~isstruct(s), s = struct(); return; endif
  campos = {'aos_origen_geologia','aos_fecha_modificacion'};
  for i = 1:numel(campos)
    if isfield(s, campos{i}), s = rmfield(s, campos{i}); endif
  endfor
endfunction

function n = n_punzados_local(g)
  n = 0;
  if isstruct(g) && isfield(g, 'intervalos') && ...
     isstruct(g.intervalos) && isfield(g.intervalos, 'tramos')
    n = numel(g.intervalos.tramos);
  endif
endfunction
