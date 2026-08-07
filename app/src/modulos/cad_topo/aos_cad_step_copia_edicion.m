function [copia, info] = aos_cad_step_copia_edicion(origen, opciones)
% AOS_CAD_STEP_COPIA_EDICION Copia de trabajo STEP bajo intercambio/cad/edicion.
% FreeCAD no pisa el .step al guardar; la edicion AOS trabaja sobre esta copia
% para poder detectar mtime al exportar STEP sobre la misma ruta.
%
% [copia, info] = aos_cad_step_copia_edicion(origen)
% [copia, info] = aos_cad_step_copia_edicion(origen, opciones)
%   opciones.forzar_recopia (default false): si ya hay copia, no la regenera
%     salvo que se pida forzar desde origen.
%
% No modifica el archivo origen. Crea el directorio edicion si falta.
  if nargin < 1 || isempty(origen)
    error('AOS CAD_TOPO: origen STEP requerido para copia de edicion.');
  endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  forzar = false;
  if isfield(opciones, 'forzar_recopia')
    forzar = logical(opciones.forzar_recopia);
  endif

  origen = char(origen);
  if exist(origen, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), origen);
    if exist(cand, 'file') == 2
      origen = cand;
    else
      error('AOS CAD_TOPO: no existe STEP origen: %s', origen);
    endif
  endif

  info = struct();
  info.dir_edicion = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'edicion');
  info.origen = origen;
  info.ya_era_edicion = false;
  info.copiado = false;
  info.reutilizado = false;

  if exist(info.dir_edicion, 'dir') ~= 7
    [ok_mk, msg_mk] = mkdir(info.dir_edicion);
    if ~ok_mk
      error('AOS CAD_TOPO: no se pudo crear %s (%s)', info.dir_edicion, msg_mk);
    endif
  endif

  [~, nombre, ext] = fileparts(origen);
  if isempty(ext), ext = '.step'; endif
  copia = fullfile(info.dir_edicion, [nombre, ext]);

  if esta_bajo_edicion_local(origen, info.dir_edicion)
    info.ya_era_edicion = true;
    copia = origen;
    info.reutilizado = true;
    return;
  endif

  if ~forzar && exist(copia, 'file') == 2
    % Reutilizar copia existente (puede contener export previo de FreeCAD).
    info.reutilizado = true;
    return;
  endif

  copiar_binario_local(origen, copia);
  info.copiado = true;
endfunction

function copiar_binario_local(origen, destino)
% Copia binaria (evita copyfile interactivo de Octave/Windows).
  fid_in = fopen(origen, 'rb');
  if fid_in < 0
    error('AOS CAD_TOPO: no se pudo abrir origen: %s', origen);
  endif
  data = fread(fid_in, Inf, 'uint8=>uint8');
  fclose(fid_in);
  fid_out = fopen(destino, 'wb');
  if fid_out < 0
    error('AOS CAD_TOPO: no se pudo crear copia: %s', destino);
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
