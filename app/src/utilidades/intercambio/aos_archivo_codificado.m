function tf = aos_archivo_codificado(archivo)
% Devuelve true cuando el archivo comienza con la marca AOS_ENCRYPTED.
  tf = false;
  if exist(archivo, 'file') ~= 2, return; end
  fid = fopen(archivo, 'rb');
  if fid < 0, return; end
  linea = fgetl(fid);
  fclose(fid);
  tf = ischar(linea) && strcmp(strtrim(linea), 'AOS_ENCRYPTED');
end
