function aos_solvers_menu_disciplina(disciplina)
% AOS_SOLVERS_MENU_DISCIPLINA Lista e inspecciona solvers por disciplina.
  if nargin < 1 || isempty(disciplina), disciplina='HYDRAULIC'; endif
  while true
    lista = filtrar_local(disciplina);
    fprintf('\n--- AOS SOLVERS / %s ---\n', upper(disciplina));
    for i=1:numel(lista)
      fprintf('%2d - %-34s [%s | %s]\n',i,lista(i).nombre,lista(i).estado,estado_local(lista(i).disponible));
    endfor
    fprintf('90 - Ejecutar selftests disponibles de esta disciplina\n');
    fprintf('91 - Ver ficha del workbench propietario\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione solver para ver detalle: ',[]);
    if op==0, break;
    elseif op==90, tests_local(lista);
    elseif op==91, propietarios_local(lista);
    elseif op>=1 && op<=numel(lista), detalle_local(lista(op));
    else, fprintf('Opcion no valida.\n'); endif
  endwhile
endfunction

function lista=filtrar_local(disciplina)
  todos=aos_solvers_registro();
  lista=todos(strcmpi({todos.disciplina},disciplina));
endfunction

function detalle_local(s)
  fprintf('\nID                      : %s\n',s.id);
  fprintf('Nombre                  : %s\n',s.nombre);
  fprintf('Disciplina              : %s\n',s.disciplina);
  fprintf('Estado                  : %s\n',s.estado);
  fprintf('Version                 : %s\n',s.version);
  fprintf('Workbench propietario   : %s\n',s.owner);
  fprintf('Entrypoint              : %s\n',valor_local(s.entrada));
  fprintf('Disponible              : %s\n',estado_local(s.disponible));
  fprintf('Selftest                : %s\n',valor_local(s.selftest));
  fprintf('Descripcion             : %s\n',s.descripcion);
  fprintf('Regla AOS               : el solver no contiene menus ni duplica datos del workbench.\n');
endfunction

function tests_local(lista)
  n=0;
  for i=1:numel(lista)
    if isempty(lista(i).selftest), continue; endif
    n=n+1;
    fprintf('\nEjecutando %s...\n',lista(i).selftest);
    try
      r=feval(lista(i).selftest);
      if isempty(r) || logical(r), fprintf('OK %s\n',lista(i).selftest);
      else, fprintf(2,'NO APROBADO %s\n',lista(i).selftest); endif
    catch err
      fprintf(2,'ERROR %s: %s\n',lista(i).selftest,err.message);
    end_try_catch
  endfor
  if n==0, fprintf('No hay selftests publicados para esta disciplina.\n'); endif
endfunction

function propietarios_local(lista)
  ids=unique({lista.owner});
  for i=1:numel(ids), aos_workbench_mostrar_ficha(ids{i}); endfor
endfunction

function s=estado_local(v)
  if v, s='DISPONIBLE'; else, s='NO PUBLICADO'; endif
endfunction
function s=valor_local(v)
  if isempty(v), s='-'; else, s=v; endif
endfunction
