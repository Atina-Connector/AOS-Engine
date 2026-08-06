function AOS_menu_EGF()
  while true
    fprintf('\n--- EGF - EDUCTOR GAS-GAS DE FONDO %s ---\n', aos_etiqueta_modulo('EGF'));
    fprintf('1 - Simulacion EGF\n');
    fprintf('2 - Sensibilidades EGF\n');
    fprintf('3 - Comparar flujo natural / CGF / EGF\n');
    fprintf('4 - Ver catalogo EGF\n');
    fprintf('5 - Abrir / importar / configurar caso EGF\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, EGF_menu();
      case 2, [p,~]=aos_config_base('GENERAL'); p=egf_defaults(p); egf_sensibilidad_menu(p);
      case 3, aos_comparar_gas_fondo();
      case 4, listar_local(fullfile('config','EGF','catalogo'));
      case 5, aos_menu_abrir_contextual('EGF');
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
