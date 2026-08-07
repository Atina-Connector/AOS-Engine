function AOS_menu_reportes()
  while true
    fprintf('\n--- REPORTES Y AOS VIEWER ---\n');
    fprintf('1 - Exportar ultima corrida\n');
    fprintf('2 - Abrir / importar reporte .aosrpt\n');
    fprintf('3 - Contrato AOS Viewer y contexto del pozo\n');
    fprintf('4 - Diagnostico del registro de graficos\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, exportar_ultima_local();
      case 2, importar_aosrpt;
      case 3, contrato_local();
      case 4, auditoria_graficos_local();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function exportar_ultima_local()
  global ULTIMO_TIPO BES2_ULTIMO_RESULTADO CGF_ULTIMO_RESULTADO EGF_ULTIMO_RESULTADO;
  prefs=struct();
  try
    prefs=aos_preferencias_usuario('cargar');
  catch
    prefs=struct();
  end_try_catch
  defecto=2;
  if isfield(prefs,'reportes')&&isfield(prefs.reportes,'formato_predeterminado')&&strcmpi(prefs.reportes.formato_predeterminado,'LIGERO'),defecto=1;endif
  formato=aos_leer_opcion(sprintf('Formato: 1-ligero | 2-enriquecido [%d]: ',defecto),defecto);
  enriquecido=(formato==2);
  if ischar(ULTIMO_TIPO)&&strcmpi(ULTIMO_TIPO,'BES_V2')&&isstruct(BES2_ULTIMO_RESULTADO)
    bes2_exportar_reporte(BES2_ULTIMO_RESULTADO,enriquecido);
  elseif ischar(ULTIMO_TIPO)&&strcmpi(ULTIMO_TIPO,'CGF')&&isstruct(CGF_ULTIMO_RESULTADO)
    cgf_exportar_reporte(CGF_ULTIMO_RESULTADO,enriquecido);
  elseif ischar(ULTIMO_TIPO)&&strcmpi(ULTIMO_TIPO,'EGF')&&isstruct(EGF_ULTIMO_RESULTADO)
    egf_exportar_reporte(EGF_ULTIMO_RESULTADO,enriquecido);
  else
    AOS_exportar_ultima_corrida({});
  endif
endfunction

function contrato_local()
  fprintf('\nEl .aosdat define y transporta el caso; su importacion es automatica e indiferenciada.\n');
  fprintf('El .aosrpt es una fotografia inmutable de la corrida efectiva.\n');
  fprintf('Ligero: texto, resultados, diagnosticos y geometria tabular.\n');
  fprintf('Enriquecido: mismo contenido mas graficos PNG Base64 registrados.\n');
  fprintf('Pantalla, tabla, grafico y reporte deben consumir el mismo resultado estructurado.\n');
endfunction

function auditoria_graficos_local()
  try
    a=aos_registro_graficos('audit');
    disp(a);
  catch err
    fprintf('No fue posible consultar el registro de graficos: %s\n',err.message);
    fprintf('El registro se crea al iniciar una simulacion o sensibilidad compatible.\n');
  end_try_catch
endfunction
