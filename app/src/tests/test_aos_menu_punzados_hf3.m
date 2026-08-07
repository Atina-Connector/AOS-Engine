function ok = test_aos_menu_punzados_hf3()
% Verifica acceso visible y contratos de importacion/exportacion.
  ok=false; iniciar_aos(true);
  raiz=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  menu=fileread(fullfile(raiz,'src','menu','AOS_menu_datos_pozo.m'));
  geo=fileread(fullfile(raiz,'src','geologia','aos_geologia_administrar.m'));
  imp=fileread(fullfile(raiz,'src','utilidades','intercambio','importar_aosdat.m'));
  exp=fileread(fullfile(raiz,'src','utilidades','intercambio','exportar_aosdat.m'));
  assert(~isempty(strfind(menu,'ADMINISTRAR / GENERAR PUNZADOS')));
  assert(~isempty(strfind(menu,'aos_punzados_administrar')));
  assert(~isempty(strfind(geo,'Administrar / generar punzados')));
  assert(~isempty(strfind(imp,'PUNZADOS_META')));
  assert(~isempty(strfind(exp,'aos_punzados_escribir_aosdat')));
  ok=true;
  fprintf('RESULTADO: test_aos_menu_punzados_hf3 APROBADO\n');
endfunction
