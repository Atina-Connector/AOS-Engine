function aosbck_escribir_json(archivo, valor)
% AOSBCK_ESCRIBIR_JSON Escritura atomica JSON UTF-8.
  if ~((exist('jsonencode','builtin')==5)||(exist('jsonencode','file')==2))
    error('AOSBCK: GNU Octave requiere jsonencode.');
  endif
  txt=jsonencode(valor);
  tmp=[archivo '.tmp_' [datestr(now,'yyyymmddHHMMSS') sprintf('_%06d',randi(999999))]];
  fid=fopen(tmp,'wt');
  if fid<0, error('AOSBCK: no se pudo crear %s',tmp); endif
  n=fprintf(fid,'%s\n',txt); fclose(fid);
  if n<3, delete(tmp); error('AOSBCK: serializacion vacia.'); endif
  if exist(archivo,'file')==2, delete(archivo); endif
  [ok,msg]=movefile(tmp,archivo);
  if ~ok, error('AOSBCK: no se pudo cerrar escritura (%s)',msg); endif
endfunction
