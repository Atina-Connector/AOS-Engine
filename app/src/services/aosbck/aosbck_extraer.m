function carpeta = aosbck_extraer(paquete)
% AOSBCK_EXTRAER Extrae un paquete en una carpeta temporal.
  if exist(paquete,'file')~=2, error('AOSBCK: no existe %s',paquete); endif
  carpeta=[tempname() '_aosbck']; mkdir(carpeta);
  ok=false; msg='';
  if isunix()
    [st,msg]=system(sprintf('unzip -q %s -d %s',shell_quote_local(paquete),shell_quote_local(carpeta)));
    ok=(st==0);
  endif
  if ~ok && ((exist('unzip','file')==2)||(exist('unzip','builtin')==5))
    try, unzip(paquete,carpeta); ok=true; catch err, msg=err.message; end_try_catch
  endif
  if ~ok, try, aos_rmdir_seguro(carpeta,tempdir()); catch, end_try_catch; error('AOSBCK: no se pudo extraer (%s)',msg); endif
  if exist(fullfile(carpeta,'manifest.json'),'file')~=2
    try, aos_rmdir_seguro(carpeta,tempdir()); catch, end_try_catch
    error('AOSBCK: paquete sin manifest.json');
  endif
endfunction

function q=shell_quote_local(s)
  apos=char(39); repl=[apos char(34) apos char(34) apos];
  q=[apos strrep(char(s),apos,repl) apos];
endfunction
