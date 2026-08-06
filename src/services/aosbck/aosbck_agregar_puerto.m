function puerto = aosbck_agregar_puerto(datos, silencioso)
% AOSBCK_AGREGAR_PUERTO Declara un puerto local para futura conexion.
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || ~isstruct(datos), datos = struct(); endif

  e = aosbck_estado('GET');
  if isempty(e.paquete), error('AOSBCK: no hay paquete activo.'); endif

  pid = campo_texto_local(datos, 'port_id', sprintf('P%d', numel(e.manifest.ports)+1));
  puerto = struct( ...
    'port_id', pid, ...
    'type', campo_texto_local(datos, 'type', 'FLUID'), ...
    'nominal_size', campo_texto_local(datos, 'nominal_size', ''), ...
    'connection_standard', campo_texto_local(datos, 'connection_standard', ''), ...
    'local_position', vector3_local(datos, 'local_position', [0 0 0]), ...
    'local_direction', vector3_local(datos, 'local_direction', [1 0 0]), ...
    'status', 'DEFINED_NOT_ASSEMBLED');

  if isempty(e.manifest.ports)
    e.manifest.ports = {puerto};
  elseif iscell(e.manifest.ports)
    e.manifest.ports{end+1} = puerto;
  else
    e.manifest.ports(end+1) = puerto;
  endif
  aosbck_estado('SET', e);
  aosbck_guardar_activo(true);
  if ~silencioso, fprintf('Puerto agregado: %s\n', pid); endif
endfunction

function v = campo_texto_local(s, nombre, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, nombre) && ~isempty(s.(nombre))
    [candidato, ok] = aos_texto_seguro(s.(nombre), defecto);
    if ok, v = candidato; endif
  endif
endfunction

function v = vector3_local(s, nombre, defecto)
  v = defecto;
  if ~isstruct(s) || ~isfield(s, nombre), return; endif
  [candidato, ok] = aos_vector_seguro(s.(nombre), defecto);
  if ok && numel(candidato) == 3 && all(isfinite(candidato))
    v = double(candidato(:))';
  endif
endfunction
