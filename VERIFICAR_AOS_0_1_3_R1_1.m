function ok = VERIFICAR_AOS_0_1_3_R1_1(ejecutar_numerico)
% VERIFICAR_AOS_0_1_3_R1_1 Verificacion estructural y numerica opcional.
  if nargin < 1, ejecutar_numerico = true; end
  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root,'src'),'-begin');
  iniciar_aos();

  fprintf('\n====================================================\n');
  fprintf(' VERIFICACION AOS 0.1.3R1.1 - BES3 COMPLETO\n');
  fprintf('====================================================\n');

  requeridos = {
    'AOS.m'; 'VERSION'; 'AOS_VERSION.txt';
    'src/menu/AOS_app.m'; 'src/menu/BM_menu.m';
    'src/menu/AOS_menu_roadmap.m';
    'src/menu/AOS_menu_cad_topologia.m';
    'src/menu/AOS_menu_gestion_ambiental.m';
    'src/menu/AOS_menu_integridad_confiabilidad.m';
    'src/menu/AOS_menu_mantenimiento_pulling.m';
    'src/menu/AOS_menu_economia_optimizacion.m';
    'src/menu/aos_verificar_requisitos_plataforma.m';
    'src/roadmap/aos_capability_contract_0_1_3_R2.json';
    'src/roadmap/aos_capability_modules_0_1_3_R2.csv';
    'src/docs/ROADMAP_AOS_CAPACIDADES_0_1_3_R2.md';
    'src/core/BM/gibbs_foundation2/gibbs2_menu.m';
    'src/core/BM/gibbs_foundation3/gibbs3_menu.m';
    'src/utilidades/intercambio/aos_report_dispatcher.m';
    'src/utilidades/intercambio/aos_rpt_escribir_tablas.m';
    'src/utilidades/intercambio/aos_rpt_escribir_diagnostico.m';
    'src/utilidades/intercambio/aos_sensibilidad_diagnosticar.m';
    'src/utilidades/intercambio/aos_exportar_sensibilidad_core.m';
    'datos/ejemplos/0_1_3/AOS_0_1_3_BES3_RECIRCULACION_CAPILAR.aosdat';
    'REGRESIONES_AOS_0_1_3_R1_1.md';
    'MANIFEST_AOS_0_1_3_R1_1.txt'
  };

  bes3_archivos = {
    'BES3_menu.m'; 'README_BES3.md'; 'bes3_bomba_apagada_loss.m';
    'bes3_capillary_catalog.m'; 'bes3_capillary_fit.m';
    'bes3_capillary_flow.m'; 'bes3_capillary_loss.m';
    'bes3_comparacion_report_context.m'; 'bes3_comparar_on_off.m';
    'bes3_comparar_v1_v2_v3.m'; 'bes3_completion_geometry.m';
    'bes3_defaults.m'; 'bes3_diagnostico_recirculacion.m';
    'bes3_editar_parametros.m'; 'bes3_electrico_apagado.m';
    'bes3_evaluar_punto.m'; 'bes3_evaluar_punto_natural.m';
    'bes3_exportar_comparacion_core.m';
    'bes3_exportar_comparacion_enriquecido.m';
    'bes3_exportar_comparacion_simple.m'; 'bes3_exportar_reporte.m';
    'bes3_exportar_resultado_enriquecido.m';
    'bes3_exportar_resultado_simple.m';
    'bes3_exportar_sensibilidad_core.m';
    'bes3_exportar_sensibilidad_enriquecido.m';
    'bes3_exportar_sensibilidad_simple.m'; 'bes3_imprimir_resultado.m';
    'bes3_plot_resultado.m'; 'bes3_presion_intake.m';
    'bes3_pump_sections.m'; 'bes3_recirculacion_apagada.m';
    'bes3_recirculation.m'; 'bes3_resultado_report_context.m';
    'bes3_seleccionar_estado_operativo.m'; 'bes3_seleccionar_modelos.m';
    'bes3_selftest.m'; 'bes3_semaforos.m';
    'bes3_sensibilidad_ejecutar.m'; 'bes3_sensibilidad_menu.m';
    'bes3_sensibilidad_report_context.m'; 'bes3_servicios_transversales.m';
    'bes3_solver.m'; 'bes3_solver_flujo_natural.m';
    'bes3_stage_performance.m'
  };
  for i=1:numel(bes3_archivos)
    requeridos{end+1}=fullfile('src','core','BES3',bes3_archivos{i});
  endfor

  fallas = {};
  for k=1:numel(requeridos)
    ruta=fullfile(root,requeridos{k});
    if exist(ruta,'file')==2
      fprintf(' OK  %s\n',requeridos{k});
    else
      fprintf(2,' FALTA  %s\n',requeridos{k});
      fallas{end+1}=requeridos{k};
    endif
  endfor

  try
    txt=fileread(fullfile(root,'VERSION'));
    if isempty(strfind(txt,'0.1.3R1.1'))
      fprintf(2,' VERSION no identifica 0.1.3R1.1.\n');
      fallas{end+1}='VERSION';
    else
      fprintf(' VERSION OK  AOS 0.1.3R1.1\n');
    endif
  catch err
    fprintf(2,' ERROR VERSION: %s\n',err.message);
    fallas{end+1}='VERSION';
  end_try_catch

  try
    menu_txt=fileread(fullfile(root,'src','menu','AOS_app.m'));
    marcas={'AOS Viewer y reportes','Roadmap y arquitectura', ...
            'Seleccione una opcion [1-6]','case 4','case 5','case 6','0.1.3R1.1'};
    for i=1:numel(marcas)
      if isempty(strfind(menu_txt,marcas{i}))
        fprintf(2,' MENU PRINCIPAL INCOMPLETO: falta %s\n',marcas{i});
        fallas{end+1}=['menu:',marcas{i}];
      endif
    endfor
  catch err
    fprintf(2,' ERROR AL VERIFICAR MENU: %s\n',err.message);
    fallas{end+1}='menu_principal';
  end_try_catch

  residuos={'PARCHE_','backup_'};
  listado=dir(root);
  for i=1:numel(listado)
    nombre=listado(i).name;
    for j=1:numel(residuos)
      if strncmp(nombre,residuos{j},length(residuos{j}))
        fprintf(2,' RESIDUO DE DESARROLLO  %s\n',nombre);
        fallas{end+1}=nombre;
      endif
    endfor
  endfor

  funciones={
    'AOS_app','AOS_menu_roadmap','AOS_menu_cad_topologia', ...
    'AOS_menu_gestion_ambiental','AOS_menu_integridad_confiabilidad', ...
    'AOS_menu_mantenimiento_pulling','AOS_menu_economia_optimizacion', ...
    'BM_menu','gibbs2_menu','gibbs3_menu','BES3_menu', ...
    'bes3_capillary_fit','bes3_capillary_flow','bes3_capillary_loss', ...
    'bes3_comparar_v1_v2_v3','bes3_completion_geometry', ...
    'bes3_presion_intake','bes3_servicios_transversales', ...
    'bes3_stage_performance','bes3_solver','bes3_selftest', ...
    'aos_report_dispatcher','aos_rpt_escribir_tablas', ...
    'aos_rpt_escribir_diagnostico','aos_sensibilidad_diagnosticar'};
  for k=1:numel(funciones)
    if exist(funciones{k},'file')==2
      fprintf(' FUNCION OK  %s\n',funciones{k});
    else
      fprintf(2,' FUNCION NO DISPONIBLE  %s\n',funciones{k});
      fallas{end+1}=funciones{k};
    endif
  endfor

  dependencias={
    'BES3_menu.m','bes3_comparar_v1_v2_v3';
    'BES3_menu.m','bes3_servicios_transversales';
    'bes3_evaluar_punto.m','bes3_completion_geometry';
    'bes3_evaluar_punto.m','bes3_presion_intake';
    'bes3_recirculation.m','bes3_capillary_flow';
    'bes3_recirculation.m','bes3_stage_performance';
    'bes3_pump_sections.m','bes3_stage_performance';
    'bes3_selftest.m','bes3_capillary_loss'
  };
  for i=1:rows(dependencias)
    ruta=fullfile(root,'src','core','BES3',dependencias{i,1});
    if exist(ruta,'file')==2
      t=fileread(ruta);
      if isempty(strfind(t,dependencias{i,2}))
        fprintf(2,' DEPENDENCIA NO REFERENCIADA  %s -> %s\n',dependencias{i,1},dependencias{i,2});
        fallas{end+1}=['dep:',dependencias{i,1},':',dependencias{i,2}];
      else
        fprintf(' DEPENDENCIA OK  %s -> %s\n',dependencias{i,1},dependencias{i,2});
      endif
    endif
  endfor

  if ejecutar_numerico && isempty(fallas)
    fprintf('\nSelftest BES3...\n');
    try
      if ~bes3_selftest(), fallas{end+1}='bes3_selftest'; endif
    catch err
      fprintf(2,' ERROR BES3 SELFTEST: %s\n',err.message);
      fallas{end+1}='bes3_selftest';
    end_try_catch

    if isempty(fallas)
      fprintf('\nCaso sintetico BES3 completo...\n');
      try
        ejemplo=fullfile(root,'datos','ejemplos','0_1_3', ...
                         'AOS_0_1_3_BES3_RECIRCULACION_CAPILAR.aosdat');
        p=importar_aosdat(ejemplo); p=bes3_defaults(p);
        g=bes3_completion_geometry(p);
        if ~strcmp(g.posicion_estado,'CONJUNTO_TOTALMENTE_DEBAJO_PUNZADOS')
          error('Geometria inesperada: %s',g.posicion_estado);
        endif
        sol=bes3_solver(p); sol=bes3_servicios_transversales(sol,false);
        campos={'version','estado_validacion','Ql_m3_d','Q_recirc_m3_d', ...
                'geometria','recirculacion','semaforos', ...
                'diagnostico_tuberia','semaforos_globales'};
        for i=1:numel(campos)
          if ~isfield(sol,campos{i}), error('Resultado BES3 incompleto: %s',campos{i}); endif
        endfor
        if isempty(strfind(sol.version,'BES3_0_1_3_R1_1'))
          error('Version BES3 inesperada: %s',sol.version);
        endif
        if ~strcmp(sol.estado_validacion,'DESARROLLO_NO_VALIDADO')
          error('BES3 no conserva estado de desarrollo.');
        endif
        fprintf(' CASO BES3 OK  Ql=%.3f m3/d  Qrec=%.3f m3/d\n', ...
                sol.Ql_m3_d,sol.Q_recirc_m3_d);
      catch err
        fprintf(2,' ERROR CASO BES3: %s\n',err.message);
        fallas{end+1}='bes3_caso_sintetico';
      end_try_catch
    endif

    fprintf('\nSelftest GF3...\n');
    try
      if exist('gibbs3_selftest','file')==2 && ~gibbs3_selftest()
        fallas{end+1}='gibbs3_selftest';
      endif
    catch err
      fprintf(2,' ERROR GF3 SELFTEST: %s\n',err.message);
      fallas{end+1}='gibbs3_selftest';
    end_try_catch
  endif

  ok=isempty(fallas);
  if ok
    if ejecutar_numerico
      fprintf('\nRESULTADO: AOS 0.1.3R1.1 APROBADO PARA PRUEBAS FUNCIONALES.\n');
    else
      fprintf('\nRESULTADO: ESTRUCTURA AOS 0.1.3R1.1 APROBADA.\n');
    endif
    fprintf('BES3 continua DESARROLLO_NO_VALIDADO.\n');
  else
    fprintf(2,'\nRESULTADO: VERIFICACION NO APROBADA. Fallas: %d\n',numel(fallas));
    for k=1:numel(fallas), fprintf(2,' - %s\n',fallas{k}); endfor
  endif
endfunction
