function AOS_menu_BES()
% AOS_MENU_BES Acceso consolidado BES V1, V2 y BES3.
  while true
    fprintf('\n--- BOMBEO ELECTROSUMERGIBLE (BES) %s ---\n',aos_etiqueta_modulo('BES'));
    fprintf(' 1 - Simular BES V2 [BETA]\n');
    fprintf(' 2 - Simular BES3 recirculacion/capilar [DESARROLLO_NO_VALIDADO]\n');
    fprintf(' 3 - Sensibilidades BES V2 / BES3\n');
    fprintf(' 4 - Seleccion y curva de bomba\n');
    fprintf(' 5 - Analisis electrico y termico\n');
    fprintf(' 6 - Comparar BES V1 / V2 / BES3\n');
    fprintf(' 7 - Ejecutar BES V1 [LEGADO]\n');
    fprintf(' 8 - Catalogos BES\n');
    fprintf(' 9 - Reportes BES y AOS Viewer\n');
    fprintf('10 - Abrir / importar / configurar caso BES\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1
        aos_preparar_config_activa('BES'); BES_V2_menu();
      case 2
        aos_preparar_config_activa('BES'); BES3_menu();
      case 3
        menu_sens_local();
      case 4
        [p,~]=aos_config_base('BES'); p=bes2_defaults(p); b=bes2_cargar_bomba(p);
        fprintf('Modelo: %s | BEP: %.2f m3/d | rango recomendado: %.2f a %.2f m3/d\n', ...
          b.modelo,b.Q_BEP_m3_d,b.Q_min_rec_m3_d,b.Q_max_rec_m3_d);
      case 5
        fprintf('El analisis electrico y termico se ejecuta dentro de BES V2/BES3 y queda en el resultado estructurado.\n');
        aos_preparar_config_activa('BES'); BES_V2_menu();
      case 6
        [p,~]=aos_config_base('BES');
        if exist('bes3_comparar_v1_v2_v3','file')==2
          bes3_comparar_v1_v2_v3(p);
        else
          bes2_comparar_v1_v2(p);
        endif
      case 7
        aos_preparar_config_activa('BES'); BES_app();
      case 8
        AOS_catalogos_listar_tipo('BES'); listar_v2_local();
      case 9
        AOS_menu_reportes();
      case 10
        aos_menu_abrir_contextual('BES');
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_sens_local()
  fprintf('\n--- SENSIBILIDADES BES ---\n');
  fprintf('1 - BES V2\n');
  fprintf('2 - BES3 [DESARROLLO_NO_VALIDADO]\n');
  fprintf('0 - Volver\n');
  op=aos_leer_opcion('Seleccione: ',0);
  switch op
    case 1
      [p,~]=aos_config_base('BES'); p=bes2_defaults(p); bes2_sensibilidad_menu(p);
    case 2
      [p,~]=aos_config_base('BES'); bes3_sensibilidad_menu(p);
  endswitch
endfunction

function listar_v2_local()
  fprintf('Catalogos BES V2/BES3:\n');
  d=dir(fullfile('config','BES_V2','catalogo','*.txt'));
  if isempty(d),fprintf('  (sin archivos)\n');return;endif
  for i=1:numel(d),fprintf('  - %s\n',d(i).name);endfor
endfunction
