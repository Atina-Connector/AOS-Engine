function AOS_menu_scada()
  while true
    fprintf('\n--- SCADA Y OPERACION EN TIEMPO REAL %s ---\n',aos_etiqueta_modulo('SCADA'));
    fprintf('1 - Importacion manual de paquete AOSDAT\n');
    fprintf('2 - Procesar bandeja automatica ahora\n');
    fprintf('3 - Iniciar receptor automatico por carpeta\n');
    fprintf('4 - Estado de comunicaciones y bandejas\n');
    fprintf('5 - Variables actuales\n');
    fprintf('6 - Historicos\n');
    fprintf('7 - Alarmas y eventos\n');
    fprintf('8 - Mapeo de tags\n');
    fprintf('9 - Validacion de datos\n');
    fprintf('10 - Calibracion automatica\n');
    fprintf('11 - Recomendaciones operativas\n');
    fprintf('12 - Exportar resultados al servidor\n');
    fprintf('13 - Abrir / importar / configurar caso o historial\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, importar_aosdat();
      case 2, aos_scada_procesar_bandeja(Inf);
      case 3
        intervalo=aos_leer_opcion('Intervalo en segundos [60]: ',60);
        ciclos=aos_leer_opcion('Cantidad de revisiones; 0=continuo [0]: ',0);
        aos_scada_receptor_automatico(intervalo,ciclos);
      case 4, aos_scada_estado();
      case 5, aos_mostrar_seccion_activa({'scada'},'VARIABLES SCADA ACTIVAS');
      case {6,7,8,9,10,11}, aos_modulo_no_disponible('SCADA','Funcion SCADA seleccionada');
      case 12, exportar_servidor_local();
      case 13, aos_menu_abrir_contextual('SCADA');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function exportar_servidor_local()
  r=aos_scada_rutas();
  fprintf('Carpeta de salida SCADA: %s\n',r.salida);
  fprintf('Exporte el .aosrpt o .aosdat y copielo a esta carpeta para el conector de servidor.\n');
  AOS_menu_reportes();
endfunction
