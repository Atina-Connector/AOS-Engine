function AOS_menu_gas_fondo
while true
  fprintf('\n--- PRODUCCION Y COMPRESION DE GAS EN FONDO ---\n');
  fprintf('1 - Simular CGF (compresor axial PM)\n');
  fprintf('2 - Sensibilidades CGF\n');
  fprintf('3 - Simular EGF (eductor gas-gas)\n');
  fprintf('4 - Sensibilidades EGF\n');
  fprintf('5 - Comparar flujo natural / CGF / EGF\n');
  fprintf('6 - Ver catalogos CGF y EGF\n');
  fprintf('0 - Volver\n');
  op=input('Seleccione: ');
  switch op
    case 1
      CGF_menu;
    case 2
      [p,~]=aos_config_base('GENERAL');p=cgf_defaults(p);cgf_sensibilidad_menu(p);
    case 3
      EGF_menu;
    case 4
      [p,~]=aos_config_base('GENERAL');p=egf_defaults(p);egf_sensibilidad_menu(p);
    case 5
      aos_comparar_gas_fondo;
    case 6
      fprintf('CGF:\n');d=dir(fullfile('config','CGF','catalogo','*.txt'));for i=1:numel(d),fprintf('  - %s\n',d(i).name);endfor
      fprintf('EGF:\n');d=dir(fullfile('config','EGF','catalogo','*.txt'));for i=1:numel(d),fprintf('  - %s\n',d(i).name);endfor
    case 0
      break;
    otherwise
      fprintf('Opcion no valida.\n');
  endswitch
endwhile
endfunction
