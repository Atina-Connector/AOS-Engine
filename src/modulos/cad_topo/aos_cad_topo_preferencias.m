function salida = aos_cad_topo_preferencias(accion, valor)
% Preferencias abiertas del modulo CAD_TOPO en JSON UTF-8.
%   p = aos_cad_topo_preferencias('cargar')
%   aos_cad_topo_preferencias('guardar', p)
  if nargin < 1 || isempty(accion), accion = 'cargar'; endif
  if nargin < 2, valor = []; endif
  ruta = fullfile(aos_cad_raiz(), 'datos_usuario', 'configuracion', ...
                  'preferencias_cad_topo.json');
  switch lower(strtrim(accion))
    case 'defaults'
      salida = defaults_local();
    case 'ruta'
      salida = ruta;
    case 'cargar'
      salida = cargar_local(ruta);
    case 'guardar'
      if ~isstruct(valor), error('AOS CAD_TOPO: preferencias invalidas.'); endif
      if ~json_disponible_local('jsonencode') || ~json_disponible_local('jsondecode')
        error('AOS CAD_TOPO: GNU Octave requiere jsonencode/jsondecode para preferencias.');
      endif
      prefs = fusionar_local(defaults_local(), valor);
      prefs.version = 'AOS_CAD_TOPO_PREFS_0.0.1';
      prefs.formato = 'JSON_UTF8';
      prefs.fecha_modificacion = datestr(now, 'yyyy-mm-dd HH:MM:SS');
      carpeta = fileparts(ruta);
      if exist(carpeta, 'dir') ~= 7, mkdir(carpeta); endif
      texto = jsonencode(prefs);
      tmp = [ruta '.tmp'];
      fid = fopen(tmp, 'wt');
      if fid < 0, error('AOS CAD_TOPO: no se pudo escribir %s', tmp); endif
      fprintf(fid, '%s\n', texto);
      fclose(fid);
      % Validar antes de reemplazar.
      p2 = leer_json_local(tmp);
      if ~isstruct(p2) || ~isfield(p2, 'version')
        delete(tmp);
        error('AOS CAD_TOPO: preferencias JSON no validas.');
      endif
      if exist(ruta, 'file') == 2, delete(ruta); endif
      [ok, msg] = movefile(tmp, ruta);
      if ~ok, error('AOS CAD_TOPO: no se pudo guardar preferencias (%s)', msg); endif
      salida = prefs;
    otherwise
      error('AOS CAD_TOPO: accion no reconocida: %s', accion);
  endswitch
endfunction

function p = defaults_local()
  p = struct();
  p.version = 'AOS_CAD_TOPO_PREFS_0.0.1';
  p.formato = 'JSON_UTF8';
  p.librecad_exe = '';
  p.freecad_exe = '';
  p.meta_tol_m = 2.0;
endfunction

function prefs = cargar_local(ruta)
  base = defaults_local();
  if exist(ruta, 'file') ~= 2
    prefs = base;
    return;
  endif
  try
    s = leer_json_local(ruta);
    if isstruct(s), prefs = fusionar_local(base, s); else, prefs = base; endif
  catch
    prefs = base;
  end_try_catch
endfunction

function s = leer_json_local(ruta)
  if ~json_disponible_local('jsondecode')
    error('jsondecode no disponible');
  endif
  fid = fopen(ruta, 'rt');
  if fid < 0, error('no se pudo abrir preferencias'); endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
  s = jsondecode(raw);
endfunction

function tf = json_disponible_local(nombre)
  tf = (exist(nombre, 'builtin') == 5) || (exist(nombre, 'file') == 2);
endfunction

function out = fusionar_local(base, extra)
  out = base;
  if ~isstruct(extra), return; endif
  campos = fieldnames(extra);
  for i = 1:numel(campos), out.(campos{i}) = extra.(campos{i}); endfor
endfunction
