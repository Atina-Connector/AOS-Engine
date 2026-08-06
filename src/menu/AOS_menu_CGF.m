function AOS_menu_CGF()
  while true
    fprintf('\n--- CGF - COMPRESION DE GAS EN FONDO %s ---\n', aos_etiqueta_modulo('CGF'));
    fprintf('1 - Simulacion CGF\n');
    fprintf('2 - Sensibilidades CGF\n');
    fprintf('3 - Comparar flujo natural / CGF / EGF\n');
    fprintf('4 - Ver catalogo CGF\n');
    fprintf('5 - Abrir / importar / configurar caso CGF\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, CGF_menu();
      case 2, [p,~]=aos_config_base('GENERAL'); p=cgf_defaults(p); cgf_sensibilidad_menu(p);
      case 3, aos_comparar_gas_fondo();
      case 4, listar_local(fullfile('config','CGF','catalogo'));
      case 5, aos_menu_abrir_contextual('CGF');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function listar_local(c)
  d=dir(fullfile(c,'*.txt'));
  if isempty(d), fprintf('Sin catalogos instalados.\n'); return; endif
  for i=1:numel(d), fprintf(' - %s\n',d(i).name); endfor
endfunction
