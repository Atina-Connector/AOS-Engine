function [copia, info] = aos_cad_dxf_copia_edicion(origen, opciones)
% AOS_CAD_DXF_COPIA_EDICION Copia de trabajo DXF bajo intercambio/cad/edicion.
% LibreCAD edita/guarda in-place; AOS nunca usa el fixture como destino editable.
%
% [copia, info] = aos_cad_dxf_copia_edicion(origen)
% [copia, info] = aos_cad_dxf_copia_edicion(origen, opciones)
%   opciones.forzar_recopia (default false)
%   opciones.registrar_contexto (default false): origen/copia/mtime en CONFIG
%   opciones.validar_copia (default false): detecta ausente/truncada/ilegible
%   opciones.no_reparar (default false): no regenera desde origen si invalida
%   opciones.ruta_copia_forzada: ruta alternativa a validar/usar (tests)
%
% Nunca modifica el archivo origen. Nunca devuelve un fixture de
% datos/ejemplos/cad como destino editable.
  if nargin < 1 || isempty(origen)
    error('AOS CAD_TOPO: origen DXF requerido para copia de edicion.');
  endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif

  forzar = false;
  if isfield(opciones, 'forzar_recopia')
    forzar = logical(opciones.forzar_recopia);
  endif
  registrar = false;
  if isfield(opciones, 'registrar_contexto')
    registrar = logical(opciones.registrar_contexto);
  endif
  validar = false;
  if isfield(opciones, 'validar_copia')
    validar = logical(opciones.validar_copia);
  endif
  no_reparar = false;
  if isfield(opciones, 'no_reparar')
    no_reparar = logical(opciones.no_reparar);
  endif

  origen = char(origen);
  if exist(origen, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), origen);
    if exist(cand, 'file') == 2
      origen = cand;
    else
      error('AOS CAD_TOPO: no existe DXF origen: %s', origen);
    endif
  endif

  info = struct();
  info.dir_edicion = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'edicion');
  info.origen = origen;
  info.ya_era_edicion = false;
  info.copiado = false;
  info.reutilizado = false;
  info.copia_invalida = false;
  info.motivo = '';
  info.item = [];

  if exist(info.dir_edicion, 'dir') ~= 7
    [ok_mk, msg_mk] = mkdir(info.dir_edicion);
    if ~ok_mk
      error('AOS CAD_TOPO: no se pudo crear %s (%s)', info.dir_edicion, msg_mk);
    endif
  endif

  [~, nombre, ext] = fileparts(origen);
  if isempty(ext), ext = '.dxf'; endif
  copia = fullfile(info.dir_edicion, [nombre, ext]);
  if isfield(opciones, 'ruta_copia_forzada') && ~isempty(opciones.ruta_copia_forzada)
    copia = char(opciones.ruta_copia_forzada);
  endif

  % Si el origen YA esta bajo edicion, reutilizarlo (nunca un fixture).
  if esta_bajo_edicion_local(origen, info.dir_edicion) ...
      && ~isfield(opciones, 'ruta_copia_forzada')
    info.ya_era_edicion = true;
    copia = origen;
    info.reutilizado = true;
    if validar
      [ok_v, motivo_v] = validar_dxf_copia_local(copia);
      if ~ok_v
        info.copia_invalida = true;
        info.motivo = motivo_v;
        info.item = item_copia_local(motivo_v, copia);
        registrar_item_sesion_local(info.item);
      endif
    endif
    if registrar
      registrar_contexto_local(origen, copia);
    endif
    return;
  endif

  % Nunca devolver fixture de ejemplos como destino editable.
  if es_fixture_ejemplos_local(origen) && strcmpi(copia, origen)
    copia = fullfile(info.dir_edicion, [nombre, ext]);
  endif

  existe_copia = (exist(copia, 'file') == 2);

  if validar || (existe_copia && ~forzar)
    if ~existe_copia
      if validar
        info.copia_invalida = true;
        info.motivo = sprintf('Copia de edicion DXF ausente: %s', copia);
        info.item = item_copia_local(info.motivo, copia);
        registrar_item_sesion_local(info.item);
      endif
      if no_reparar && validar
        if registrar
          registrar_contexto_local(origen, copia);
        endif
        return;
      endif
      % Regenerar desde origen (protege sesion; no toca fixture).
      copiar_binario_local(origen, copia);
      info.copiado = true;
      if registrar
        registrar_contexto_local(origen, copia);
      endif
      return;
    endif

    if validar
      [ok_v, motivo_v] = validar_dxf_copia_local(copia);
      if ~ok_v
        info.copia_invalida = true;
        info.motivo = motivo_v;
        info.item = item_copia_local(motivo_v, copia);
        registrar_item_sesion_local(info.item);
        if no_reparar
          info.reutilizado = true;
          if registrar
            registrar_contexto_local(origen, copia);
          endif
          return;
        endif
        % Reparar desde origen legible
        copiar_binario_local(origen, copia);
        info.copiado = true;
        info.reutilizado = false;
        if registrar
          registrar_contexto_local(origen, copia);
        endif
        return;
      endif
    endif
  endif

  if ~forzar && exist(copia, 'file') == 2
    info.reutilizado = true;
    if registrar
      registrar_contexto_local(origen, copia);
    endif
    return;
  endif

  copiar_binario_local(origen, copia);
  info.copiado = true;
  if registrar
    registrar_contexto_local(origen, copia);
  endif
endfunction

function copiar_binario_local(origen, destino)
  fid_in = fopen(origen, 'rb');
  if fid_in < 0
    error('AOS CAD_TOPO: no se pudo abrir origen DXF: %s', origen);
  endif
  data = fread(fid_in, Inf, 'uint8=>uint8');
  fclose(fid_in);
  fid_out = fopen(destino, 'wb');
  if fid_out < 0
    error('AOS CAD_TOPO: no se pudo crear copia DXF: %s', destino);
  endif
  fwrite(fid_out, data, 'uint8');
  fclose(fid_out);
endfunction

function tf = esta_bajo_edicion_local(archivo, dir_ed)
  tf = false;
  archivo = char(archivo);
  dir_ed = char(dir_ed);
  try
    [pd, ~, ~] = fileparts(archivo);
    tf = strcmpi(strrep(pd, '/', filesep), strrep(dir_ed, '/', filesep));
  catch
    tf = false;
  end_try_catch
endfunction

function tf = es_fixture_ejemplos_local(ruta)
  tf = false;
  ruta = strrep(lower(char(ruta)), '/', filesep);
  marca = lower(fullfile('datos', 'ejemplos', 'cad'));
  tf = ~isempty(strfind(ruta, marca)); %#ok<STREMP>
endfunction

function [ok, motivo] = validar_dxf_copia_local(archivo)
  ok = false;
  motivo = '';
  archivo = char(archivo);
  if exist(archivo, 'file') ~= 2
    motivo = sprintf('Copia de edicion DXF ausente: %s', archivo);
    return;
  endif
  fid = fopen(archivo, 'rb');
  if fid < 0
    motivo = sprintf('Copia de edicion DXF no legible (fopen): %s', archivo);
    return;
  endif
  data = fread(fid, Inf, 'uint8=>uint8');
  fclose(fid);
  if isempty(data) || numel(data) < 16
    motivo = sprintf('Copia de edicion DXF truncada (tam=%d): %s', ...
      numel(data), archivo);
    return;
  endif
  % DXF ASCII tipico: debe contener tokens de seccion / EOF
  txt = lower(char(data(:)'));
  if isempty(strfind(txt, 'section')) && isempty(strfind(txt, 'eof')) %#ok<STREMP>
    motivo = sprintf('Copia de edicion DXF no legible (sin SECTION/EOF): %s', archivo);
    return;
  endif
  if isempty(strfind(txt, 'eof')) && numel(data) < 64 %#ok<STREMP>
    motivo = sprintf('Copia de edicion DXF truncada (sin EOF): %s', archivo);
    return;
  endif
  ok = true;
endfunction

function item = item_copia_local(motivo, ruta)
  item = struct( ...
    'codigo', 'DXF_COPIA_EDICION_INVALIDA', ...
    'mensaje', char(motivo), ...
    'severidad', 'ADVERTENCIA', ...
    'origen', char(ruta));
endfunction

function registrar_item_sesion_local(item)
  if isempty(item) || ~isstruct(item), return; endif
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    return;
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    return;
  endif
  ct = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(ct, 'dxf_items') || isempty(ct.dxf_items)
    ct.dxf_items = {};
  elseif ~iscell(ct.dxf_items)
    ct.dxf_items = {ct.dxf_items};
  endif
  codigo = '';
  if isfield(item, 'codigo'), codigo = char(item.codigo); endif
  ya = false;
  for i = 1:numel(ct.dxf_items)
    it = ct.dxf_items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), codigo) ...
        && isfield(it, 'mensaje') && isfield(item, 'mensaje') ...
        && strcmp(char(it.mensaje), char(item.mensaje))
      ya = true;
      break;
    endif
  endfor
  if ~ya
    ct.dxf_items{end+1} = item;
  endif
  CONFIG_ACTIVA.cad_topologia = ct;
endfunction

function registrar_contexto_local(origen, copia)
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  ct = CONFIG_ACTIVA.cad_topologia;
  origen = char(origen);
  copia = char(copia);
  ct.dxf_archivo_edicion = copia;
  if ~strcmpi(origen, copia)
    ct.dxf_archivo_origen = origen;
  elseif ~isfield(ct, 'dxf_archivo_origen') || isempty(ct.dxf_archivo_origen)
    ct.dxf_archivo_origen = origen;
  endif
  CONFIG_ACTIVA.cad_topologia = ct;
  if exist(copia, 'file') == 2
    aos_cad_registrar_mtime(copia);
  else
    % Copia ausente: registrar rutas sin pisar mtime previo ni sesion.
    ct = CONFIG_ACTIVA.cad_topologia;
    ct.dxf_archivo = copia;
    CONFIG_ACTIVA.cad_topologia = ct;
  endif
endfunction
