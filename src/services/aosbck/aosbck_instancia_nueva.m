function inst = aosbck_instancia_nueva(manifest, instance_id, placement, datos)
% AOSBCK_INSTANCIA_NUEVA Crea identidad fisica liviana sin duplicar STEP.
  if nargin < 4 || ~isstruct(datos), datos = struct(); endif
  if nargin < 3 || ~isstruct(placement)
    error('AOSBCK: placement debe ser una estructura valida.');
  endif
  if nargin < 2 || isempty(instance_id)
    instance_id = aosbck_id_seguro([datestr(now,'yyyymmddHHMMSS') ...
      sprintf('_%06d', randi(999999))], 'INST');
  endif
  if ~isstruct(manifest) || ~isfield(manifest, 'component') || ...
     ~isstruct(manifest.component)
    error('AOSBCK: manifiesto de componente invalido.');
  endif

  iid = texto_requerido_local(instance_id, 'instance_id');
  cid = campo_requerido_local(manifest.component, 'component_id');
  part = campo_requerido_local(manifest.component, 'part_number');
  supplier_default = campo_texto_local(manifest.component, 'supplier_id', 'UNSPECIFIED');

  inst = struct( ...
    'instance_id', iid, ...
    'component_id', cid, ...
    'part_number', part, ...
    'placement', placement, ...
    'serial_number', campo_texto_local(datos, 'serial_number', ''), ...
    'lot_number', campo_texto_local(datos, 'lot_number', ''), ...
    'installation_date', campo_texto_local(datos, 'installation_date', ''), ...
    'supplier_id', campo_texto_local(datos, 'supplier_id', supplier_default), ...
    'status', campo_texto_local(datos, 'status', 'INSTALLED'), ...
    'notes', campo_texto_local(datos, 'notes', ''), ...
    'created_at', datestr(now,'yyyy-mm-dd HH:MM:SS'));
endfunction

function v = campo_texto_local(s, nombre, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, nombre) && ~isempty(s.(nombre))
    [candidato, ok] = aos_texto_seguro(s.(nombre), defecto);
    if ok, v = candidato; endif
  endif
endfunction

function v = campo_requerido_local(s, nombre)
  if ~isfield(s, nombre), error('AOSBCK: falta campo requerido %s.', nombre); endif
  v = texto_requerido_local(s.(nombre), nombre);
endfunction

function v = texto_requerido_local(valor, etiqueta)
  [v, ok] = aos_texto_seguro(valor, '');
  if ~ok || isempty(v)
    error('AOSBCK: %s debe ser texto escalar no vacio.', etiqueta);
  endif
endfunction
