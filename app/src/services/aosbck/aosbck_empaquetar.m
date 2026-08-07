function salida = aosbck_empaquetar(carpeta, archivo_salida)
% AOSBCK_EMPAQUETAR Crea contenedor ZIP con extension .aosbck.
  [p,n,e]=fileparts(archivo_salida);
  if isempty(e), archivo_salida=fullfile(p,[n '.aosbck']);
  elseif ~strcmpi(e,'.aosbck'), error('AOSBCK: la salida debe terminar en .aosbck'); endif
  if isempty(p), p=pwd(); endif
  if exist(p,'dir')~=7, mkdir(p); endif
  temporal=fullfile(p,[n '.ziptmp_' [datestr(now,'yyyymmddHHMMSS') sprintf('_%06d',randi(999999))] '.zip']);
  if exist(temporal,'file')==2, delete(temporal); endif
  ok=false; msg='';
  if isunix()
    cmd=sprintf('cd %s && zip -q -r %s manifest.json geometry metadata preview', ...
      shell_quote_local(carpeta), shell_quote_local(temporal));
    [st,msg]=system(cmd); ok=(st==0 && exist(temporal,'file')==2);
  endif
  if ~ok && ((exist('zip','file')==2)||(exist('zip','builtin')==5))
    actual=pwd();
    try
      cd(carpeta); zip(temporal,{'manifest.json','geometry','metadata','preview'}); cd(actual);
      ok=(exist(temporal,'file')==2);
    catch err
      cd(actual); msg=err.message;
    end_try_catch
  endif
  if ~ok, error('AOSBCK: no se pudo crear el paquete. %s',msg); endif
  if exist(archivo_salida,'file')==2, delete(archivo_salida); endif
  [mov,msg2]=movefile(temporal,archivo_salida);
  if ~mov, error('AOSBCK: no se pudo finalizar el paquete (%s)',msg2); endif
  salida=char(archivo_salida);
endfunction

function q=shell_quote_local(s)
  apos=char(39); repl=[apos char(34) apos char(34) apos];
  q=[apos strrep(char(s),apos,repl) apos];
endfunction
