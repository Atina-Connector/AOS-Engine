function h = aosbck_hash_archivo(archivo)
% AOSBCK_HASH_ARCHIVO SHA-256 del STEP para trazabilidad.
  h = '';
  if exist(archivo,'file') ~= 2, return; endif
  try
    fid=fopen(archivo,'rb'); datos=fread(fid,Inf,'uint8=>uint8'); fclose(fid);
    if (exist('hash','builtin')==5) || (exist('hash','file')==2)
      h=hash('sha256',char(datos(:)'));
      return;
    endif
  catch
    try, fclose(fid); catch, end_try_catch
  end_try_catch
  if isunix()
    [st,out]=system(sprintf('sha256sum %s', shell_quote_local(archivo)));
    if st==0 && numel(out)>=64, h=strtrim(out(1:64)); endif
  endif
endfunction

function q=shell_quote_local(s)
  apos=char(39); repl=[apos char(34) apos char(34) apos];
  q=[apos strrep(char(s),apos,repl) apos];
endfunction
