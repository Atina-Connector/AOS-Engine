function [recursos, items] = aos_aoscad_generar_recursos_visuales(modelo, opciones)
% AOS_AOSCAD_GENERAR_RECURSOS_VISUALES PNG regenerables para perfil ENRIQUECIDO.
% [recursos, items] = aos_aoscad_generar_recursos_visuales(modelo, opciones)
%   opciones.incluir_2d = true
%   opciones.incluir_3d = true
%   opciones.incluir_overlay = true
%   opciones.visible = false
%   opciones.directorio = ''   % default: intercambio/cad/recursos
%
% SIMPLE: recursos={} sin PNG. ENRIQUECIDO: rutas relativas regenerables (no base64).
% Orden/ids deterministas: PLANO_2D_RED, VISTA_3D_ESCENA, VISTA_3D_OVERLAY.
  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    error('AOS CAD_TOPO: aos_aoscad_generar_recursos_visuales requiere modelo.');
  endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif

  items = {};
  recursos = {};

  perfil = 'SIMPLE';
  if isfield(modelo, 'info') && isstruct(modelo.info) ...
      && isfield(modelo.info, 'aoscad_perfil') ...
      && ~isempty(modelo.info.aoscad_perfil)
    perfil = upper(char(modelo.info.aoscad_perfil));
  endif
  if ~strcmp(perfil, 'ENRIQUECIDO')
    return;
  endif

  incluir_2d = true;
  incluir_3d = true;
  incluir_overlay = true;
  visible = false;
  if isfield(opciones, 'incluir_2d'), incluir_2d = logical(opciones.incluir_2d); endif
  if isfield(opciones, 'incluir_3d'), incluir_3d = logical(opciones.incluir_3d); endif
  if isfield(opciones, 'incluir_overlay')
    incluir_overlay = logical(opciones.incluir_overlay);
  endif
  if isfield(opciones, 'visible'), visible = logical(opciones.visible); endif

  root = aos_cad_raiz();
  directorio = '';
  if isfield(opciones, 'directorio') && ~isempty(opciones.directorio)
    directorio = char(opciones.directorio);
  endif
  if isempty(directorio)
    directorio = fullfile(root, 'intercambio', 'cad', 'recursos');
  endif
  if exist(directorio, 'dir') ~= 7
    [mk_ok, mk_msg] = mkdir(directorio);
    if ~mk_ok
      error('AOS CAD_TOPO: no se pudo crear directorio de recursos (%s)', mk_msg);
    endif
  endif

  planos = {};
  graficos = {};

  global CONFIG_ACTIVA;
  prev_cfg = CONFIG_ACTIVA;
  figs_antes = findobj('type', 'figure');

  unwind_protect
    % --- 2D ---
    if incluir_2d
      [rec2d, it2d] = generar_2d_local(modelo, directorio, visible);
      if ~isempty(rec2d)
        planos{end+1} = rec2d; %#ok<AGROW>
      endif
      items = [items, it2d];
    endif

    % --- 3D escena ---
    escena = escena_modelo_local(modelo);
    tiene_escena = escena_util_local(escena);
    if incluir_3d
      if ~tiene_escena
        items{end+1} = item_local( ...
          'RECURSO_3D_SIN_ESCENA', ...
          'INFO', ...
          'Sin escena 3D vigente: se omite VISTA_3D_ESCENA; plano 2D disponible.');
      else
        [rec3d, it3d] = generar_3d_local(escena, directorio, visible, ...
          'VISTA_3D_ESCENA', 'VISTA_3D_ESCENA', 'Vista 3D escena', false, modelo);
        if ~isempty(rec3d)
          graficos{end+1} = rec3d; %#ok<AGROW>
        endif
        items = [items, it3d];
      endif
    endif

    % --- Overlay solo con resultados vigentes + escena ---
    if incluir_overlay
      if ~resultados_vigentes_local(modelo)
        % no genera overlay; silencio (no es error)
      elseif ~tiene_escena
        items{end+1} = item_local( ...
          'RECURSO_OVERLAY_SIN_ESCENA', ...
          'INFO', ...
          'Overlay omitido: no hay escena 3D para aplicar resultados.');
      else
        [rec_ov, it_ov] = generar_3d_local(escena, directorio, visible, ...
          'VISTA_3D_OVERLAY', 'VISTA_3D_OVERLAY', 'Vista 3D con overlay', true, modelo);
        if ~isempty(rec_ov)
          graficos{end+1} = rec_ov; %#ok<AGROW>
        endif
        items = [items, it_ov];
      endif
    endif

    recursos = struct( ...
      'tipo', 'RECURSOS_VIEWER', ...
      'planos', {planos}, ...
      'graficos', {graficos}, ...
      'vigente', true, ...
      'obsoletos', false, ...
      'nota', 'Recursos regenerables (PNG). No sustituyen tablas ni resultados.');

  unwind_protect_cleanup
    CONFIG_ACTIVA = prev_cfg;
    try
      figs = findobj('type', 'figure');
      if ~isempty(figs)
        % cerrar solo figuras creadas en esta corrida
        extras = setdiff(figs, figs_antes);
        if ~isempty(extras), close(extras); endif
      endif
    catch
    end_try_catch
  end_unwind_protect
endfunction

function [rec, items] = generar_2d_local(modelo, directorio, visible)
  rec = [];
  items = {};
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;

  nom = 'plano_2d_red.png';
  png = fullfile(directorio, nom);
  if exist(png, 'file') == 2, delete(png); endif

  opts = struct('visible', visible, 'png', png, 'silencioso', true, ...
    'usar_resultados', true, 'cerrar', true);
  try
    [info, h] = aos_cad_visor_2d(true, opts);
    if ~isempty(h)
      try
        if ishandle(h), close(h); endif
      catch
      end_try_catch
    endif
    if exist(png, 'file') ~= 2 && isstruct(info) && isfield(info, 'png') ...
        && ~isempty(info.png) && exist(info.png, 'file') == 2
      png = char(info.png);
    endif
  catch err
    items{end+1} = item_local('RECURSO_2D_FALLO', 'ADVERTENCIA', ...
      sprintf('No se pudo generar PLANO_2D_RED (%s).', err.message));
    return;
  end_try_catch

  if exist(png, 'file') ~= 2
    items{end+1} = item_local('RECURSO_2D_AUSENTE', 'ADVERTENCIA', ...
      'PLANO_2D_RED no genero archivo PNG.');
    return;
  endif

  rec = recurso_local('PLANO_2D_RED', 'PLANO_2D_RED', 'Red AOS CAD', ...
    ruta_relativa_local(directorio, nom));
endfunction

function [rec, items] = generar_3d_local(escena, directorio, visible, id, tipo, titulo, con_overlay, modelo)
  rec = [];
  items = {};
  esc = escena;
  if con_overlay
    try
      tr = struct();
      if isfield(modelo, 'tablas_resultados')
        tr = modelo.tablas_resultados;
      endif
      [esc, items_ov] = aos_cad_overlay_resultados(esc, tr);
      items = [items, items_ov];
    catch err
      items{end+1} = item_local('RECURSO_OVERLAY_FALLO', 'ADVERTENCIA', ...
        sprintf('Overlay no aplicado (%s).', err.message));
      return;
    end_try_catch
  endif

  nom = sprintf('%s.png', lower(id));
  png = fullfile(directorio, nom);
  if exist(png, 'file') == 2, delete(png); endif

  try
    [info, h] = aos_cad_visor_3d(esc, struct('visible', visible, 'png', png, ...
      'cerrar', true));
    if ~isempty(h)
      try
        if ishandle(h), close(h); endif
      catch
      end_try_catch
    endif
    if exist(png, 'file') ~= 2 && isstruct(info) && isfield(info, 'png') ...
        && ~isempty(info.png) && exist(info.png, 'file') == 2
      png = char(info.png);
    endif
  catch err
    items{end+1} = item_local('RECURSO_3D_FALLO', 'ADVERTENCIA', ...
      sprintf('No se pudo generar %s (%s).', id, err.message));
    return;
  end_try_catch

  if exist(png, 'file') ~= 2
    items{end+1} = item_local('RECURSO_3D_AUSENTE', 'ADVERTENCIA', ...
      sprintf('%s no genero archivo PNG.', id));
    return;
  endif

  rec = recurso_local(id, tipo, titulo, ruta_relativa_local(directorio, nom));
endfunction

function r = recurso_local(id, tipo, titulo, ruta_rel)
  r = struct( ...
    'id', char(id), ...
    'tipo', char(tipo), ...
    'titulo', char(titulo), ...
    'formato', 'PNG', ...
    'unidades', 'm', ...
    'origen', 'REGENERABLE_AOSCAD', ...
    'ruta_relativa', char(ruta_rel), ...
    'vigente', true, ...
    'asset_scope', {{}});
endfunction

function rr = ruta_relativa_local(directorio, nom)
  % Preferir ruta relativa bajo intercambio/cad cuando sea posible.
  root = aos_cad_raiz();
  base = fullfile(root, 'intercambio', 'cad');
  dir_n = strrep(char(directorio), '/', filesep);
  base_n = strrep(char(base), '/', filesep);
  if length(dir_n) >= length(base_n) ...
      && strcmpi(dir_n(1:length(base_n)), base_n)
    rest = dir_n((length(base_n) + 1):end);
    while ~isempty(rest) && (rest(1) == '/' || rest(1) == '\')
      rest = rest(2:end);
    endwhile
    if isempty(rest)
      rr = strrep(fullfile('recursos', nom), '\', '/');
    else
      rr = strrep(fullfile(rest, nom), '\', '/');
    endif
  else
    % directorio de prueba u otro: nombre determinista relativo corto
    rr = strrep(fullfile('recursos', nom), '\', '/');
    % si el archivo esta directamente en directorio, usar solo el nombre
    if exist(fullfile(directorio, nom), 'file') == 2
      rr = nom;
    endif
  endif
endfunction

function esc = escena_modelo_local(modelo)
  esc = struct();
  if isfield(modelo, 'escena_3d') && isstruct(modelo.escena_3d)
    esc = modelo.escena_3d;
  endif
endfunction

function tf = escena_util_local(escena)
  tf = false;
  if ~isstruct(escena), return; endif
  if isfield(escena, 'objetos') && iscell(escena.objetos) && numel(escena.objetos) >= 1
    tf = true;
  endif
endfunction

function tf = resultados_vigentes_local(modelo)
  tf = false;
  if ~isstruct(modelo) || ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion)
    return;
  endif
  estado = '';
  if isfield(modelo.simulacion, 'estado')
    estado = upper(char(modelo.simulacion.estado));
  endif
  if ~any(strcmp(estado, {'EJECUTADA', 'EJECUTADA_CON_ADVERTENCIAS'}))
    return;
  endif
  if ~isfield(modelo, 'tablas_resultados') || ~isstruct(modelo.tablas_resultados)
    return;
  endif
  tr = modelo.tablas_resultados;
  n_ok = 0;
  if isfield(tr, 'nodos') && ~isempty(tr.nodos), n_ok = n_ok + numel(tr.nodos); endif
  if isfield(tr, 'tramos') && ~isempty(tr.tramos), n_ok = n_ok + numel(tr.tramos); endif
  tf = n_ok > 0;
endfunction

function it = item_local(codigo, severidad, mensaje)
  it = struct( ...
    'codigo', char(codigo), ...
    'severidad', char(severidad), ...
    'mensaje', char(mensaje), ...
    'origen', 'aos_aoscad_generar_recursos_visuales');
endfunction
