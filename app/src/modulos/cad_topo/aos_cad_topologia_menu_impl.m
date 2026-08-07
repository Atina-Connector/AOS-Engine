function aos_cad_topologia_menu_impl()
% AOS_CAD_TOPOLOGIA_MENU_IMPL Menu jerarquico AOSCAD 0.0.1 DEV1 R16.
% Union Suite R3 (caso/galerias/AOSBCK) + capacidades CAD R16 (sync/STEP).
% Mantiene separado el manejo CAD del nucleo de simulacion hidraulica.
  fprintf('[AOSCAD 0.0.1 DEV1 R16 - GNU Octave] menu jerarquico\n');
  while true
    aos_cad_recargar_si_cambio(false, false);
    fprintf('\n====================================================\n');
    fprintf(' AOSCAD - CAD, TOPOGRAFIA, TOPOLOGIA Y SIMULACION\n');
    fprintf('====================================================\n');
    fprintf('Contrato: DXF=entrada completa | .aoscad=reporte editable/recalculable.\n');
    fprintf(' 1 - CAD 2D / DXF\n');
    fprintf(' 2 - CAD 3D / STEP\n');
    fprintf(' 3 - Topologia, capas y datos tecnicos\n');
    fprintf(' 4 - SIMULACION HIDRAULICA\n');
    fprintf(' 5 - Reportes .aoscad y resultados\n');
    fprintf(' 6 - Sincronizacion y recarga\n');
    fprintf(' 7 - Plataforma y diagnosticos\n');
    fprintf(' 8 - AOS 3D Core transversal\n');
    fprintf(' 9 - Abrir / importar / configurar proyecto o caso\n');
    fprintf('10 - Galerias CAD: camaras, ramales y accesos\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, menu_cad_2d_local();
      case 2, menu_cad_3d_local();
      case 3, menu_topologia_local();
      case 4, aos_cad_hidraulica_menu();
      case 5, menu_reportes_local();
      case 6, menu_sincronizacion_local();
      case 7, menu_diagnosticos_local();
      case 8, AOS_menu_3d_core('CAD');
      case 9, aos_menu_abrir_contextual('CAD');
      case 10, AOS_menu_galerias();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_cad_2d_local()
  while true
    fprintf('\n--- CAD 2D / DXF ---\n');
    fprintf(' 1 - Visor CAD 2D integrado\n');
    fprintf(' 2 - Importar archivo DXF\n');
    fprintf(' 3 - Editar DXF en LibreCAD\n');
    fprintf(' 4 - Administrar capas y bloques [planificado]\n');
    fprintf(' 5 - Exportar DXF revision (*_AOS_REV)\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, try_local(@() aos_cad_visor_2d(false, false));
      case 2, aos_cad_importar_dxf();
      case 3, aos_cad_abrir_externo('DXF');
      case 4, aos_modulo_no_disponible('CAD_TOPO', 'Administrar capas y bloques');
      case 5, try_local(@() aos_cad_exportar_dxf_rev([], false));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_cad_3d_local()
  while true
    fprintf('\n--- CAD 3D / STEP ---\n');
    fprintf(' 1 - AOSBCK: crear componente reutilizable desde STEP [BETA R1]\n');
    fprintf(' 2 - Importar archivo STEP como inventario CAD\n');
    fprintf(' 3 - Editar STEP en FreeCAD\n');
    fprintf(' 4 - Traer STEP exportado (FreeCAD) [ACTIVO]\n');
    fprintf(' 5 - Administrar componentes, instancias y ubicaciones AOSBCK\n');
    fprintf(' 6 - Visualizar pieza seleccionada bajo demanda\n');
    fprintf(' 7 - Puertos y conexiones AOSBCK [BETA R1]\n');
    fprintf(' 8 - Validar interferencias AABB [ACTIVO]\n');
    fprintf(' 9 - Exportar STEP revision (*_AOS_REV)\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, try_local(@() aosbck_crear_interactivo());
      case 2, aos_cad_importar_step();
      case 3, aos_cad_abrir_externo('STEP');
      case 4, try_local(@() aos_cad_traer_step_exportado());
      case 5, AOS_menu_aosbck('CAD');
      case 6, try_local(@() aosbck_visualizar());
      case 7, AOS_menu_aosbck('CAD_PORTS');
      case 8, try_local(@() AOS_menu_3d_core('CAD'));
      case 9, try_local(@() aos_cad_exportar_step_rev([], false));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_topologia_local()
  while true
    fprintf('\n--- TOPOLOGIA, CAPAS Y DATOS TECNICOS ---\n');
    fprintf(' 1 - Reconocer/normalizar objetos AOS (tablas)\n');
    fprintf(' 2 - Construir topologia 2D derivada\n');
    fprintf(' 3 - Validar conexiones y topologia\n');
    fprintf(' 4 - Ver datos CAD/TOPO importados\n');
    fprintf(' 5 - Sincronizar representaciones 2D y 3D [ACTIVO]\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, try_local(@() aos_cad_mapear_objetos([], false));
      case 2, try_local(@() aos_cad_construir_topologia(0.05, false));
      case 3, try_local(@() aos_cad_validar_topologia(false));
      case 4, aos_mostrar_seccion_activa({'cad_topologia','cad','dxf','step','topologia','topografia','modelo_aoscad'}, 'DATOS CAD Y TOPOLOGIA IMPORTADOS');
      case 5, try_local(@() aos_cad_sincronizar_2d_3d(struct()));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_reportes_local()
  while true
    fprintf('\n--- REPORTES .AOSCAD Y RESULTADOS ---\n');
    fprintf(' 1 - Abrir .aoscad en Suite (editar/recalcular)\n');
    fprintf(' 2 - Ver resumen de la ultima simulacion hidraulica\n');
    fprintf(' 3 - Ver tablas de entrada y resultados\n');
    fprintf(' 4 - Guardar .aoscad simple\n');
    fprintf(' 5 - Guardar .aoscad enriquecido\n');
    fprintf(' 6 - Colorear resultados sobre el modelo\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, try_local(@() aos_aoscad_abrir_en_suite([], false));
      case 2, try_local(@() aos_cad_hidraulica_mostrar_resultados('RESUMEN'));
      case 3, try_local(@() aos_cad_hidraulica_mostrar_resultados('TODO'));
      case 4, try_local(@() aos_aoscad_escribir([], 'SIMPLE', false));
      case 5, try_local(@() aos_cad_hidraulica_guardar_enriquecido());
      case 6, try_local(@() aos_cad_visor_2d(true, false));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_sincronizacion_local()
  while true
    fprintf('\n--- SINCRONIZACION Y RECARGA ---\n');
    fprintf(' 1 - Recargar DXF/STEP si cambio (mtime)\n');
    fprintf(' 2 - Forzar recarga DXF/STEP\n');
    fprintf(' 3 - Traer STEP exportado desde FreeCAD [ACTIVO]\n');
    fprintf(' 4 - Sincronizar representaciones 2D y 3D [ACTIVO]\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        hubo = aos_cad_recargar_si_cambio(false, false);
        if ~hubo
          fprintf(['Sin cambios de mtime en DXF/STEP activos.\n' ...
            'FreeCAD: hay que Exportar STEP (no basta guardar el documento).\n' ...
            'Si exporto con otro nombre: opcion 3 Traer STEP exportado.\n']);
        endif
      case 2, aos_cad_recargar_si_cambio(true, false);
      case 3, try_local(@() aos_cad_traer_step_exportado());
      case 4, try_local(@() aos_cad_sincronizar_2d_3d(struct()));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function menu_diagnosticos_local()
  while true
    fprintf('\n--- PLATAFORMA Y DIAGNOSTICOS ---\n');
    fprintf(' 1 - Verificar requisitos de plataforma\n');
    fprintf(' 2 - Diagnosticar editores CAD\n');
    fprintf(' 3 - Diagnosticar rutas y funciones sombreadas\n');
    fprintf(' 4 - Verificar arquitectura Octave-only\n');
    fprintf(' 5 - Verificar AOSCAD DEV1 completo\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, aos_verificar_requisitos_plataforma(true);
      case 2, try_local(@() DIAGNOSTICAR_EDITORES_AOSCAD());
      case 3, try_local(@() aos_cad_verificar_rutas_unicas(true));
      case 4, try_local(@() aos_cad_verificar_octave_only(false));
      case 5, try_local(@() VERIFICAR_AOSCAD_0_0_1_DEV1(true));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function try_local(fn)
  try
    fn();
  catch err
    fprintf(2, 'Error AOSCAD: %s\n', err.message);
  end_try_catch
endfunction
