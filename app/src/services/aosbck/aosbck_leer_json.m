function valor = aosbck_leer_json(archivo)
% AOSBCK_LEER_JSON Lee JSON UTF-8.
  if ~((exist('jsondecode','builtin')==5)||(exist('jsondecode','file')==2))
    error('AOSBCK: GNU Octave requiere jsondecode.');
  endif
  fid=fopen(archivo,'rt');
  if fid<0, error('AOSBCK: no se pudo abrir %s',archivo); endif
  raw=fread(fid,Inf,'char=>char')'; fclose(fid);
  valor=jsondecode(raw);
endfunction
