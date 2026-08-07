function ok = VERIFICAR_AOS_0_1_9(ejecutar_tests)
% VERIFICAR_AOS_0_1_9 Verificacion semantica heredada, ejecutada dentro de AOS Suite 0.2.0 DEV1.
% No depende de numeros rigidos del menu: valida registros, entrypoints,
% despachos, contratos, orden del Viewer e integridad Octave-only.
  if nargin<1,ejecutar_tests=false;endif
  raiz=fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(fullfile(raiz,'src'),'-begin');
  iniciar_aos(true);
  ok=true;

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION AOS SUITE 0.2.0 DEV1 - NUCLEOS HEREDADOS Y REPORTES\n');
  fprintf('================================================================\n');

  requeridos={ ...
    'AOS.m','AOS_VERSION.txt','src/iniciar_aos.m','src/menu/AOS_app.m', ...
    'src/menu/AOS_menu_gestion_caso.m','src/menu/aos_menu_abrir_contextual.m', ...
    'src/menu/AOS_menu_SLA.m','src/menu/AOS_menu_wells.m', ...
    'src/menu/AOS_menu_cad_topologia.m','src/menu/AOS_menu_networks.m', ...
    'src/menu/AOS_menu_electrical.m','src/menu/AOS_menu_facilities.m', ...
    'src/menu/AOS_menu_geology.m','src/menu/AOS_menu_fluidos.m', ...
    'src/menu/AOS_menu_scada.m','src/menu/AOS_menu_maintenance.m', ...
    'src/menu/AOS_menu_data.m','src/menu/AOS_menu_solvers.m', ...
    'src/menu/AOS_menu_global.m','src/menu/AOS_menu_roadmap.m', ...
    'src/menu/AOS_menu_suite_config_diag.m','src/menu/AOS_menu_viewer.m', ...
    'src/menu/AOS_menu_3d_core.m','src/menu/AOS_menu_catalogos.m', ...
    'src/menu/AOS_menu_galerias.m','src/menu/aos_solvers_registro.m', ...
    'src/utilidades/intercambio/importar_aosdat.m', ...
    'src/utilidades/intercambio/exportar_aosdat.m', ...
    'src/utilidades/intercambio/importar_catalogo.m', ...
    'src/utilidades/intercambio/exportar_catalogo.m', ...
    'src/utilidades/intercambio/aos_catalogos_fusionar_desde_aosdat.m', ...
    'src/utilidades/intercambio/importar_aosrpt.m', ...
    'src/utilidades/config/aos_texto_seguro.m', ...
    'src/utilidades/config/aos_numero_seguro.m', ...
    'src/utilidades/config/aos_vector_seguro.m', ...
    'src/utilidades/config/aos_logico_seguro.m', ...
    'src/utilidades/varios/aos_preguntar_sn.m', ...
    'src/utilidades/diagnostico/aos_auditar_interacciones.m', ...
    'src/geologia/aos_geologia_administrar.m', ...
    'src/geologia/aos_geologia_commit.m', ...
    'src/geologia/aos_geologia_resolver_punzados.m', ...
    'src/geologia/punzados/aos_punzados_administrar.m', ...
    'src/geologia/punzados/aos_punzados_normalizar.m', ...
    'src/geologia/punzados/aos_punzados_operacion.m', ...
    'src/geologia/punzados/aos_punzados_validar.m', ...
    'src/geologia/punzados/aos_punzados_commit.m', ...
    'src/geologia/punzados/aos_punzados_generar_regular.m', ...
    'src/geologia/punzados/aos_punzados_desde_aosdat.m', ...
    'src/geologia/punzados/aos_punzados_escribir_aosdat.m', ...
    'src/utilidades/config/aos_invalidar_resultados.m', ...
    'src/tests/test_aos_punzados_dependencias_hf3_1.m', ...
    'src/tests/test_aos_gestion_caso_sin_nombre_r2_hf1.m', ...
    'src/tests/test_aos_conversiones_seguras_hf2.m', ...
    'src/tests/test_aos_geologia_transaccional_hf2.m', ...
    'src/tests/test_aos_auditoria_interacciones_hf2.m', ...
    'src/tests/test_aos_path_selftests_hf2.m', ...
    'src/tests/test_aos_contratos_estructuras_hf3_2.m', ...
    'src/tests/test_gf3_signo_tuberia_libre_hf3_3.m', ...
    'src/tests/test_aos_geologia_idempotencia_hf3_4.m', ...
    'src/tests/test_gf3_contrato_espaciamiento_hf3_4.m', ...
    'src/tests/test_aos_report_composition_hf3_5.m', ...
    'src/tests/test_aos_report_module_tables_hf3_5.m', ...
    'src/tests/test_aos_report_sensitivity_hf3_5.m', ...
    'src/tests/test_aos_aoscad_report_composition_hf3_5.m', ...
    'src/utilidades/reportes/aos_report_parse_native_tables.m', ...
    'src/utilidades/reportes/aos_report_print_native_tables.m', ...
    'src/tests/test_aos_report_coverage_hf3_5.m', ...
    'src/utilidades/reportes/aos_report_configure_tables.m', ...
    'src/utilidades/reportes/aos_report_prepare_tables.m', ...
    'src/utilidades/reportes/aos_report_write_manifest.m', ...
    'src/utilidades/intercambio/aos_rpt_escribir_tablas.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_rod_spacing_design.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_upgrade_result_schema.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_validate_result.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_repair_tubing_sign_result.m', ...
    'src/utilidades/varios/aos_rmdir_seguro.m', ...
    'src/core/GL/mandriles/mandriles_cargar_galeria.m', ...
    'src/core/BES3/BES3_menu.m','src/menu/AOS_menu_BES.m', ...
    'src/roadmap/aos_workbenches_0_1_9.json', ...
    'src/roadmap/aos_solvers_0_1_9.json', ...
    'src/roadmap/aos_services_0_1_9.json', ...
    'src/roadmap/aos_roadmap_0_1_9.json', ...
    'src/roadmap/aos_frame_ribbon_contract_0_2_0.json', ...
    'datos/ejemplos/catalogos/AOS_GALERIA_MANDRILES_COMPLETA.aosdat', ...
    'datos/ejemplos/catalogos/AOS_CATALOGO_R2_DEMO.aosdat', ...
    'datos/ejemplos/cad/demo_aos_galerias.dxf'};
  for i=1:numel(requeridos)
    ruta=fullfile(raiz,requeridos{i});
    if exist(ruta,'file')==2,fprintf('OK   %s\n',requeridos{i});
    else,fprintf(2,'FALTA %s\n',requeridos{i});ok=false;endif
  endfor

  menu=fileread(fullfile(raiz,'src','menu','AOS_app.m'));
  menu_up=upper(menu);
  if contiene_local(menu_up,'NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO') && ...
      contiene_local(menu,'AOS_menu_gestion_caso')
    fprintf('OK   gestion transversal del caso visible y despachada\n');
  else
    fprintf(2,'FALLO: gestion transversal del caso incompleta\n');ok=false;
  endif

  productos=aos_suite_registro_productos();
  ids_productos={productos.id};
  esperado=14;
  if any(strcmp(ids_productos,'ENVIRONMENTAL')), esperado=15; endif
  if numel(productos)~=esperado
    fprintf(2,'FALLO: se esperaban %d workbenches y se encontraron %d\n', ...
      esperado,numel(productos));ok=false;
  endif
  for i=1:numel(productos)
    p=productos(i);
    nombre_up=upper(p.nombre);
    visible=contiene_local(menu_up,nombre_up);
    entrada_ok=~isempty(p.entrada)&&exist(p.entrada,'file')==2;
    despacho=contiene_local(menu,p.entrada);
    if visible&&entrada_ok&&despacho
      fprintf('OK   %-16s registrado, visible y despachado -> %s\n',p.id,p.entrada);
    else
      fprintf(2,'FALLO %-16s visible=%d entrypoint=%d despacho=%d\n',p.id,visible,entrada_ok,despacho);
      ok=false;
    endif
  endfor

  if ~isempty(productos)&&strcmp(productos(end).id,'VIEWER')
    pos_viewer=primera_pos_local(menu_up,'AOS VIEWER');
    pos_roadmap=primera_pos_local(menu_up,'ROADMAP GENERAL');
    pos_config=primera_pos_local(menu_up,'CONFIGURACION, VERSIONES');
    if pos_viewer>pos_roadmap&&pos_viewer>pos_config
      fprintf('OK   AOS Viewer es el ultimo workbench visible\n');
    else
      fprintf(2,'FALLO: AOS Viewer no esta al final de los bancos\n');ok=false;
    endif
  else
    fprintf(2,'FALLO: Viewer no es el ultimo workbench del registro\n');ok=false;
  endif

  ok=verificar_contextos_local(raiz,ok);
  ok=verificar_catalogos_local(raiz,ok);

  menu_pz=fileread(fullfile(raiz,'src','menu','AOS_menu_datos_pozo.m'));
  if contiene_local(upper(menu_pz),'ADMINISTRAR / GENERAR PUNZADOS') && ...
     contiene_local(menu_pz,'aos_punzados_administrar')
    fprintf('OK   gestor transversal de punzados visible y despachado\n');
  else
    fprintf(2,'FALLO: gestor transversal de punzados no visible\n');ok=false;
  endif

  bes=fileread(fullfile(raiz,'src','menu','AOS_menu_BES.m'));
  if contiene_local(bes,'BES3_menu')&&contiene_local(bes,'bes3_comparar_v1_v2_v3')
    fprintf('OK   BES3 conectado al menu BES y comparacion V1/V2/V3\n');
  else
    fprintf(2,'FALLO: BES3 continua desconectado del menu BES\n');ok=false;
  endif

  init=fileread(fullfile(raiz,'src','iniciar_aos.m'));
  if isempty(strfind(init,'genpath('))
    fprintf('OK   path operativo controlado sin genpath indiscriminado\n');
  else
    fprintf(2,'FALLO: iniciar_aos aun usa genpath indiscriminado\n');ok=false;
  endif

  duplicados=duplicados_m_local(fullfile(raiz,'src'));
  if isempty(duplicados)
    fprintf('OK   sin funciones publicas duplicadas por nombre de archivo\n');
  else
    fprintf(2,'FALLO: archivos .m duplicados en src:\n');
    for i=1:numel(duplicados),fprintf(2,'  %s\n',duplicados{i});endfor
    ok=false;
  endif

  residuos=listar_extension_local(raiz,'.mat');
  if isempty(residuos),fprintf('OK   arquitectura sin archivos .mat\n');
  else
    fprintf(2,'FALLO: se encontraron archivos .mat:\n');
    for i=1:numel(residuos),fprintf(2,'  %s\n',residuos{i});endfor
    ok=false;
  endif

  sr=aos_solvers_registro();
  if numel(sr)>=30,fprintf('OK   registro transversal de solvers (%d entradas)\n',numel(sr));
  else,fprintf(2,'FALLO: registro de solvers insuficiente\n');ok=false;endif

  try
    auditoria_ui=aos_auditar_interacciones(raiz,false);
    if auditoria_ui.ok
      fprintf('OK   auditoria transversal de interacciones (%d archivos)\n', ...
        auditoria_ui.archivos_revisados);
    else
      fprintf(2,'FALLO: auditoria transversal de interacciones: %d errores\n', ...
        auditoria_ui.errores);
      ok=false;
    endif
  catch err_audit
    fprintf(2,'FALLO: no se pudo ejecutar auditoria transversal: %s\n',err_audit.message);
    ok=false;
  end_try_catch

  if ejecutar_tests
    fprintf('\n--- SELFTESTS R2 ---\n');
    pruebas={'test_aos_punzados_dependencias_hf3_1', ...
      'test_aos_gestion_caso_sin_nombre_r2_hf1', ...
      'test_aos_conversiones_seguras_hf2','test_aos_geologia_transaccional_hf2', ...
      'test_aos_auditoria_interacciones_hf2','test_aos_path_selftests_hf2', ...
      'test_aos_contratos_estructuras_hf3_2', ...
      'test_aos_geologia_idempotencia_hf3_4', ...
      'test_gf3_signo_tuberia_libre_hf3_3', ...
      'test_gf3_contrato_espaciamiento_hf3_4','gibbs3_selftest', ...
      'test_aos_report_composition_hf3_5','test_aos_report_module_tables_hf3_5', ...
      'test_aos_report_sensitivity_hf3_5','test_aos_aoscad_report_composition_hf3_5', ...
      'test_aos_report_coverage_hf3_5', ...
      'test_aos_punzados_crud_hf3','test_aos_punzados_aosdat_roundtrip_hf3', ...
      'test_aos_punzados_sin_geologia_hf3','test_aos_punzados_consumidores_hf3', ...
      'test_aos_menu_punzados_hf3','test_aos_menu_contextual_r2', ...
      'test_aos_catalogos_roundtrip_r2', ...
      'test_aos_galeria_mandriles_r2','test_aosdat_prioridad_r2', ...
      'test_aosdat_legacy_compat_001', ...
      'test_aosdat_roundtrip_001','test_aos_cad_menu_hidraulica', ...
      'test_aos_cad_dominio_hidraulico','test_aos_cad_hidraulica_dxf', ...
      'test_aosbck_r1','bes3_selftest'};
    for i=1:numel(pruebas),ok=ejecutar_test_local(pruebas{i},ok);endfor
  endif

  fprintf('\n================================================================\n');
  if ok,fprintf('RESULTADO: AOS SUITE 0.2.0 DEV1 - NUCLEOS HEREDADOS APROBADOS\n');
  else,fprintf(2,'RESULTADO: AOS SUITE 0.2.0 DEV1 - NUCLEOS HEREDADOS NO APROBADOS\n');endif
  fprintf('================================================================\n');
endfunction

function ok=verificar_contextos_local(raiz,ok)
  menus={'AOS_menu_SLA.m','AOS_menu_BM.m','AOS_menu_GL_JGL.m','AOS_menu_BES.m', ...
    'AOS_menu_PCP.m','AOS_menu_CGF.m','AOS_menu_EGF.m','AOS_menu_networks.m', ...
    'AOS_menu_electrical.m','AOS_menu_facilities.m','AOS_menu_geology.m', ...
    'AOS_menu_fluidos.m','AOS_menu_wells.m','AOS_menu_scada.m','AOS_menu_maintenance.m'};
  for i=1:numel(menus)
    ruta=fullfile(raiz,'src','menu',menus{i});
    if exist(ruta,'file')==2&&contiene_local(fileread(ruta),'aos_menu_abrir_contextual')
      fprintf('OK   apertura contextual %s\n',menus{i});
    else
      fprintf(2,'FALLO apertura contextual %s\n',menus{i});ok=false;
    endif
  endfor
endfunction

function ok=verificar_catalogos_local(raiz,ok)
  imp=fileread(fullfile(raiz,'src','utilidades','intercambio','importar_catalogo.m'));
  exp=fileread(fullfile(raiz,'src','utilidades','intercambio','exportar_catalogo.m'));
  aosdat=fileread(fullfile(raiz,'src','utilidades','intercambio','importar_aosdat.m'));
  if contiene_local(imp,'parsear_bombas_local')&&contiene_local(imp,'parsear_valvulas_local')&& ...
      isempty(strfind(lower(imp),'parseo especifico'))
    fprintf('OK   importador de catalogos implementado\n');
  else
    fprintf(2,'FALLO: importador de catalogos incompleto\n');ok=false;
  endif
  if contiene_local(exp,'AOS_CATALOGO_R2')&&contiene_local(exp,'[AOS_CATALOGO]')
    fprintf('OK   exportador de catalogos usa contrato R2\n');
  else
    fprintf(2,'FALLO: exportador de catalogos no usa contrato R2\n');ok=false;
  endif
  patrones={'[AOS_CATALOGO]','[BOMBAS]','[VALVULAS]','[VARILLAS]','[UNIDADES_BM]','[MANDRILES_GALERIA]'};
  for i=1:numel(patrones)
    if ~contiene_local(aosdat,patrones{i}),fprintf(2,'FALLO: importar_aosdat no reconoce %s\n',patrones{i});ok=false;endif
  endfor
  if ok,fprintf('OK   .aosdat reconoce casos, catalogos y galerias\n');endif
endfunction

function ok=ejecutar_test_local(nombre,ok)
  % Cada prueba recibe el path de pruebas completo. Algunos tests historicos
  % reconstruyen el path operativo; el ejecutor lo restablece siempre.
  try
    iniciar_aos(true);
    rehash();
  catch err_path
    fprintf(2,'FALLO: no se pudo preparar el path para %s: %s\n',nombre,err_path.message);
    ok=false;
    return;
  end_try_catch

  if exist(nombre,'file')~=2
    fprintf(2,'FALLO: selftest no encontrado: %s\n',nombre);
    ok=false;
    return;
  endif

  unwind_protect
    try
      resultado=feval(nombre);
      if isempty(resultado)||logical(resultado)
        fprintf('OK   selftest %s\n',nombre);
      else
        fprintf(2,'FALLO: selftest sin aprobacion: %s\n',nombre);
        ok=false;
      endif
    catch err
      fprintf(2,'FALLO: selftest %s: %s\n',nombre,err.message);
      ok=false;
    end_try_catch
  unwind_protect_cleanup
    try
      iniciar_aos(true);
      rehash();
    catch err_restore
      fprintf(2,'FALLO: no se pudo restaurar el path despues de %s: %s\n', ...
        nombre,err_restore.message);
      ok=false;
    end_try_catch
  end_unwind_protect
endfunction

function tf=contiene_local(txt,patron),tf=~isempty(strfind(txt,patron));endfunction
function p=primera_pos_local(txt,patron),v=strfind(txt,patron);if isempty(v),p=-1;else,p=v(1);endif,endfunction

function lista=duplicados_m_local(src)
  archivos=listar_m_local(src);nombres=cell(1,numel(archivos));
  for i=1:numel(archivos),[~,n,e]=fileparts(archivos{i});nombres{i}=lower([n e]);endfor
  lista={};u=unique(nombres);
  for i=1:numel(u)
    idx=find(strcmp(nombres,u{i}));
    if numel(idx)>1,lista{end+1}=strjoin(archivos(idx),' | ');endif %#ok<AGROW>
  endfor
endfunction

function lista=listar_m_local(carpeta)
  lista={};d=dir(carpeta);
  for i=1:numel(d)
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..'),continue;endif
    p=fullfile(carpeta,d(i).name);
    if d(i).isdir,lista=[lista,listar_m_local(p)];
    else,[~,~,e]=fileparts(d(i).name);if strcmpi(e,'.m'),lista{end+1}=p;endif,endif
  endfor
endfunction

function lista=listar_extension_local(carpeta,extension)
  lista={};d=dir(carpeta);
  for i=1:numel(d)
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..'),continue;endif
    p=fullfile(carpeta,d(i).name);
    if d(i).isdir,lista=[lista,listar_extension_local(p,extension)];
    else,[~,~,e]=fileparts(d(i).name);if strcmpi(e,extension),lista{end+1}=p;endif,endif
  endfor
endfunction

% Compatibilidad historica R1: helper privado conservado para trazabilidad.
% El verificador R2 ya no valida la numeracion literal del menu.
function ok=comprobar_texto_local(ruta,patron,etiqueta,ok)
  try
    txt=fileread(ruta);
    if isempty(strfind(txt,patron)),fprintf(2,'FALLO: %s no contiene "%s"\n',etiqueta,patron);ok=false;
    else,fprintf('OK   %s\n',etiqueta);endif
  catch err
    fprintf(2,'FALLO: no se pudo leer %s: %s\n',ruta,err.message);ok=false;
  end_try_catch
endfunction
