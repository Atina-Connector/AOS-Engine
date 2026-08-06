function AOS_menu_geology()
% AOS_MENU_GEOLOGY Banco de geologia y modelo espacial.
  while true
    fprintf('\n--- AOS GEOLOGY [BETA / ROADMAP] ---\n');
    fprintf(' 1 - Administrar geologia activa [ACTIVO]\n');
    fprintf(' 2 - Survey, punzados y completacion [ACTIVO]\n');
    fprintf(' 3 - Ver datos geologicos importados\n');
    fprintf(' 4 - Trayectoria y contexto 3D\n');
    fprintf(' 5 - Riesgo de arenamiento, conificacion y erosion [BETA]\n');
    fprintf(' 6 - Superficies, capas y estratigrafia [ROADMAP]\n');
    fprintf(' 7 - Grillas, volumetria y propiedades [ROADMAP]\n');
    fprintf(' 8 - Registro de solvers geologicos\n');
    fprintf(' 9 - Estado y roadmap de AOS Geology\n');
    fprintf('10 - Abrir / importar / configurar geologia, survey o .aosdat\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        if exist('aos_geologia_administrar','file') == 2
          aos_geologia_administrar();
        else
          fprintf('Rutina de administracion geologica no disponible.\n');
        endif
      case 2, AOS_menu_datos_pozo();
      case 3, aos_mostrar_seccion_activa({'geologia','punzados','survey'}, 'DATOS GEOLOGICOS IMPORTADOS');
      case 4, AOS_menu_3d_core('GEOLOGY');
      case 5, mostrar_riesgo_local();
      case 6, aos_modulo_no_disponible('GEOLOGY', 'Superficies, capas y estratigrafia');
      case 7, aos_modulo_no_disponible('GEOLOGY', 'Grillas y volumetria');
      case 8, aos_solvers_menu_disciplina('GEOLOGICAL');
      case 9, aos_workbench_mostrar_ficha('GEOLOGY');
      case 10, aos_menu_abrir_contextual('GEOLOGY');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_riesgo_local()
  global geologia CONFIG_ACTIVA ULTIMO_QL ULTIMO_PARAM;
  if isempty(geologia) || ~isstruct(geologia)
    fprintf('No hay geologia activa. Carguela primero.\n');
    return;
  endif
  q = [];
  if ~isempty(ULTIMO_QL), q = ULTIMO_QL / 86400; endif
  param = struct();
  if isstruct(ULTIMO_PARAM), param = ULTIMO_PARAM;
  elseif isstruct(CONFIG_ACTIVA), param = CONFIG_ACTIVA; endif
  try
    r = calcular_caudales_criticos(geologia, q, param, []);
    disp(r);
  catch err
    fprintf(2, 'No fue posible evaluar el riesgo: %s\n', err.message);
  end_try_catch
endfunction
