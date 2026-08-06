function version = aos_version_actual()
% AOS_VERSION_ACTUAL Devuelve la version declarada por la distribucion activa.
  version = 'AOS Suite version no informada';
  aqui = fileparts(mfilename('fullpath'));
  raiz = fileparts(fileparts(fileparts(aqui)));
  archivo = fullfile(raiz, 'AOS_VERSION.txt');
  if exist(archivo, 'file') ~= 2
    return;
  endif
  fid = fopen(archivo, 'rt');
  if fid < 0, return; endif
  linea = fgetl(fid);
  fclose(fid);
  if ischar(linea) && ~isempty(strtrim(linea))
    version = strtrim(linea);
  endif
endfunction
