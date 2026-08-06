function items = aos_cad_invalidar_escena_3d(motivo, prefijo, opciones)
% AOS_CAD_INVALIDAR_ESCENA_3D Marca escena/vinculo 3D no vigentes + item.
% Delega la invalidacion de simulacion/derivados a aos_cad_invalidar_simulacion
% cuando opciones.invalidar_simulacion es true (default), para no dejar
% resultados EJECUTADA vigentes tras invalidar la escena.
%
% items = aos_cad_invalidar_escena_3d(motivo, prefijo)
% items = aos_cad_invalidar_escena_3d(motivo, prefijo, opciones)
%   opciones.invalidar_simulacion = true
  global CONFIG_ACTIVA;
  items = {};
  if nargin < 1 || isempty(motivo)
    motivo = 'Escena/vinculo 3D no vigentes; reconstruir.';
  endif
  if nargin < 2 || isempty(prefijo), prefijo = 'step'; endif
  if nargin < 3 || isempty(opciones) || ~isstruct(opciones)
    opciones = struct();
  endif
  invalidar_sim = true;
  if isfield(opciones, 'invalidar_simulacion')
    invalidar_sim = logical(opciones.invalidar_simulacion);
  endif

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) ...
      || ~isfield(CONFIG_ACTIVA, 'cad_topologia') ...
      || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    return;
  endif
  ct = CONFIG_ACTIVA.cad_topologia;
  motivo = char(motivo);
  item = struct( ...
    'codigo', 'ESCENA_3D_INVALIDADA_POR_EDICION', ...
    'mensaje', motivo, ...
    'severidad', 'ADVERTENCIA');
  items = {item};

  if isfield(ct, 'escena_3d') && isstruct(ct.escena_3d)
    ct.escena_3d.vigente = false;
  endif
  if isfield(ct, 'vinculo_3d') && isstruct(ct.vinculo_3d)
    ct.vinculo_3d.vigente = false;
  endif
  if isfield(ct, 'escena_federada') && isstruct(ct.escena_federada)
    ct.escena_federada.vigente = false;
  endif
  if isfield(ct, 'overlay') && isstruct(ct.overlay)
    ct.overlay.vigente = false;
  endif

  campo_items = 'step_items';
  if strcmpi(char(prefijo), 'dxf'), campo_items = 'dxf_items'; endif
  if isfield(ct, campo_items) && ~isempty(ct.(campo_items))
    its = ct.(campo_items);
    if ~iscell(its), its = {its}; endif
    its{end+1} = item;
    ct.(campo_items) = its;
  else
    ct.(campo_items) = {item};
  endif

  if isfield(ct, 'modelo_aoscad') && isstruct(ct.modelo_aoscad)
    m = ct.modelo_aoscad;
    if invalidar_sim
      opts = struct( ...
        'codigo', 'INVALIDADA_POR_EDICION', ...
        'invalidar_escena', true, ...
        'limpiar_resultados', true, ...
        'invalidar_recursos', true, ...
        'accion', 'INVALIDAR_ESCENA_3D', ...
        'origen', upper(char(prefijo)));
      [m, items_sim] = aos_cad_invalidar_simulacion(m, motivo, opts);
      for i = 1:numel(items_sim)
        items{end+1} = items_sim{i}; %#ok<AGROW>
      endfor
    else
      if isfield(m, 'escena_3d') && isstruct(m.escena_3d)
        m.escena_3d.vigente = false;
      endif
      if isfield(m, 'vinculo_3d') && isstruct(m.vinculo_3d)
        m.vinculo_3d.vigente = false;
      endif
      if ~isfield(m, 'validaciones') || ~isstruct(m.validaciones)
        m.validaciones = struct('estado', 'ADVERTENCIA', 'items', {{}});
      endif
      if ~isfield(m.validaciones, 'items') || isempty(m.validaciones.items)
        m.validaciones.items = {};
      elseif ~iscell(m.validaciones.items)
        m.validaciones.items = {m.validaciones.items};
      endif
      m.validaciones.items{end+1} = item;
      if ~isfield(m.validaciones, 'estado') ...
          || strcmp(m.validaciones.estado, 'PENDIENTE') ...
          || strcmp(m.validaciones.estado, 'OK')
        m.validaciones.estado = 'ADVERTENCIA';
      endif
    endif
    ct.modelo_aoscad = m;
  endif

  CONFIG_ACTIVA.cad_topologia = ct;
endfunction
