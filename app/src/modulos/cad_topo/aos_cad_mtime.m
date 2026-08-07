function ts = aos_cad_mtime(archivo)
% AOS_CAD_MTIME Marca de tiempo de modificacion del archivo (datenum) o [].
  ts = [];
  if nargin < 1 || isempty(archivo), return; endif
  if exist(archivo, 'file') ~= 2, return; endif
  info = dir(archivo);
  if isempty(info), return; endif
  ts = info(1).datenum;
endfunction
