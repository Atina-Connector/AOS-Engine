function ok = aos_rmdir_seguro(carpeta, raiz_permitida)
% AOS_RMDIR_SEGURO Elimina recursivamente sin preguntas y con limite de raiz.
% Por defecto solo permite borrar dentro de tempdir(). Nunca borra la raiz
% permitida, una ruta vacia ni directorios superiores.
  ok = true;
  if nargin < 1 || isempty(carpeta), return; endif
  if nargin < 2 || isempty(raiz_permitida), raiz_permitida = tempdir(); endif
  if exist(carpeta,'dir') ~= 7, return; endif

  objetivo = canon_local(carpeta);
  raiz = canon_local(raiz_permitida);
  if isempty(objetivo) || isempty(raiz) || strcmp(objetivo,raiz) || ...
      ~(numel(objetivo)>numel(raiz) && strncmp(objetivo,[raiz '/'],numel(raiz)+1))
    error('AOS: rechazo de borrado fuera de la raiz permitida: %s', carpeta);
  endif

  old = true;
  tiene_confirm = (exist('confirm_recursive_rmdir','builtin')==5 || exist('confirm_recursive_rmdir','file')==2);
  if tiene_confirm
    try, old = confirm_recursive_rmdir(false); catch, tiene_confirm=false; end_try_catch
  endif
  unwind_protect
    [ok,msg] = rmdir(carpeta,'s');
    if ~ok, error('AOS: no se pudo eliminar %s (%s)',carpeta,msg); endif
  unwind_protect_cleanup
    if tiene_confirm
      try, confirm_recursive_rmdir(old); catch, end_try_catch
    endif
  end_unwind_protect
endfunction

function p = canon_local(p)
  p = strrep(char(p),'\\','/');
  while numel(p)>1 && p(end)=='/', p(end)=[]; endwhile
  if ispc(), p=lower(p); endif
endfunction
