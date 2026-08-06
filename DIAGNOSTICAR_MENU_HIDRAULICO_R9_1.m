function ok = DIAGNOSTICAR_MENU_HIDRAULICO_R9_1()
  ok = false;
  ruta = which('aos_cad_hidraulica_menu');
  fprintf('\n--- DIAGNOSTICO MENU HIDRAULICO R9.1 ---\n');
  fprintf('Funcion activa: %s\n', ruta);
  if isempty(ruta) || exist(ruta, 'file') ~= 2
    fprintf(2, 'FALLO: menu hidraulico no localizado.\n');
    return;
  endif
  txt = fileread(ruta);
  tiene_r9 = ~isempty(strfind(txt, 'SELECCIONAR DOMINIO'));
  tiene_banner = ~isempty(strfind(txt, 'DEV1 R9.1'));
  tiene_submenu = exist('aos_cad_hidraulica_dominio_menu', 'file') == 2;
  fprintf('Opcion dominio : %s\n', si_no_local(tiene_r9));
  fprintf('Banner R9.1    : %s\n', si_no_local(tiene_banner));
  fprintf('Submenu dominio: %s\n', si_no_local(tiene_submenu));
  ok = tiene_r9 && tiene_banner && tiene_submenu;
  if ok
    fprintf('RESULTADO: MENU R9.1 ACTIVO\n');
  else
    fprintf(2, 'RESULTADO: MENU R9.1 NO ACTIVO\n');
  endif
endfunction
function s = si_no_local(tf)
  if tf, s = 'SI'; else, s = 'NO'; endif
endfunction
