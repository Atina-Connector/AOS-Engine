function BES3_menu()
% Menu operativo de desarrollo BES3 0.1.3R1.1.
% Todos los resultados BES3 usan el dispatcher transversal AOSRPT.
  [p,origen]=aos_config_base('BES');p=bes3_defaults(p);p=seleccionar_bomba_local(p);
  while true
    fprintf('\n--- BES3 / AOS 0.1.3R1.1 [DESARROLLO NO VALIDADO] ---\n');
    fprintf('Origen configuracion: %s\n',origen);resumen_local(p);
    fprintf('\n1 - Simular BES3 / flujo natural / comparar ON-OFF\n2 - Editar hidraulica y operacion\n3 - Editar completacion, refrigeracion y capilar\n');
    fprintf('4 - Sensibilidades BES3 (incluye 0 Hz)\n5 - Comparar BES1 / BES2 / BES3\n6 - Survey, punzados y completacion\n');
    fprintf('7 - Cambiar bomba de catalogo\n8 - Ejecutar selftest BES3\n9 - Reporte geologico del ultimo resultado\n0 - Volver\n');
    op=input('Seleccione: ');if isempty(op),op=0;endif
    switch op
      case 1
        p=bes3_seleccionar_modelos(p);[prun,accion]=bes3_seleccionar_estado_operativo(p);
        if strcmp(accion,'cancelar'),continue;endif
        if strcmp(accion,'comparar')
          C=bes3_comparar_on_off(prun);C=finalizar_comparacion_local(prun,C);global BES3_ULTIMA_COMPARACION;BES3_ULTIMA_COMPARACION=C;continue;
        endif
        sol=bes3_solver(prun);bes3_imprimir_resultado(sol);bes3_plot_resultado(sol,'on');sol=bes3_servicios_transversales(sol,true);
        global BES3_ULTIMO_RESULTADO ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
        BES3_ULTIMO_RESULTADO=sol;ULTIMO_QL=sol.Ql_m3_d/86400;ULTIMO_QO=sol.Qo_m3_d/86400;ULTIMO_QINY=0;
        if strcmp(sol.modo_operacion,'BOMBA_APAGADA'),ULTIMO_TIPO='BES3_FLUJO_NATURAL';else,ULTIMO_TIPO='BES3';endif
        ULTIMO_PARAM=sol.param;
        sol=finalizar_resultado_local(sol);BES3_ULTIMO_RESULTADO=sol;
      case 2,p=bes3_editar_parametros(p,1);
      case 3,p=bes3_editar_parametros(p,2);
      case 4,p=bes3_seleccionar_modelos(p);bes3_sensibilidad_menu(p);
      case 5,bes3_comparar_v1_v2_v3(p);
      case 6,AOS_menu_datos_pozo();
      case 7,p=seleccionar_bomba_local(p);
      case 8,bes3_selftest();
      case 9
        global BES3_ULTIMO_RESULTADO;
        if isempty(BES3_ULTIMO_RESULTADO)||~isstruct(BES3_ULTIMO_RESULTADO)||~isfield(BES3_ULTIMO_RESULTADO,'Ql_m3_d')
          fprintf('No hay un resultado BES3 disponible. Ejecute primero una simulacion.\n');
        else
          try,preguntar_reporte(BES3_ULTIMO_RESULTADO.Ql_m3_d/86400,BES3_ULTIMO_RESULTADO.param);catch err,fprintf('No se pudo generar reporte geologico: %s\n',err.message);end_try_catch
        endif
      case 0,break;
      otherwise,fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction
function p=seleccionar_bomba_local(p)
  d=dir(fullfile('config','BES_V2','catalogo','*.txt'));if isempty(d),return;endif
  fprintf('\nCatalogo base BES2 reutilizado por BES3:\n');for i=1:numel(d),fprintf(' %d - %s\n',i,d(i).name);endfor
  fprintf(' 0 - Mantener %s\n',p.bes3_bomba_file);op=input('Seleccione [0]: ');if isempty(op),op=0;endif
  if op>=1&&op<=numel(d),p.bes3_bomba_file=fullfile('config','BES_V2','catalogo',d(op).name);p.bes2_bomba_file=p.bes3_bomba_file;endif
endfunction
function resumen_local(p)
  g=bes3_completion_geometry(p);
  fprintf('Bomba / frecuencia / etapas : %s / %.1f Hz / %d\n',p.bes3_bomba_file,p.frecuencia,p.num_etapas);
  if p.frecuencia<=0,fprintf('Estado operativo             : BOMBA APAGADA / FLUJO NATURAL\n');else,fprintf('Estado operativo             : BOMBA ENCENDIDA\n');endif
  fprintf('IPR / VLP configuradas      : %s / %s\n',p.modelo_IPR,p.modelo_VLP);
  fprintf('Intake / motor base         : %.1f / %.1f m MD\n',g.D_intake_m,g.D_motor_base_m);
  fprintf('Posicion vs punzados        : %s\n',g.posicion_estado);
  fprintf('Shroud / ID casing          : %d / %.1f mm\n',g.shroud_habilitado,1000*g.ID_casing_m);
  fprintf('Recirculacion               : %s | etapas candidatas %s\n',p.bes3_recirculacion_modo,mat2str(p.bes3_etapas_candidatas));
  fprintf('Limite recirculacion        : %.1f %% del Q nominal efectivo\n',p.bes3_limite_recirculacion_pct_nominal);
  fprintf('Bomba apagada               : modelo %s\n',p.bes3_bomba_apagada_modelo);
endfunction

function sol=finalizar_resultado_local(sol)
  try
    c=bes3_resultado_report_context(sol);sol.reportes=aos_report_dispatcher(c);
  catch err
    fprintf(2,'ADVERTENCIA: no se pudo completar el flujo de reportes BES3: %s\n',err.message);
  end_try_catch
endfunction
function C=finalizar_comparacion_local(p,C)
  try
    c=bes3_comparacion_report_context(p,C);C.reportes=aos_report_dispatcher(c);
  catch err
    fprintf(2,'ADVERTENCIA: no se pudo completar el reporte ON/OFF: %s\n',err.message);
  end_try_catch
endfunction
