function VERIFICAR_AOSRPT_VIEWER_1_2()
% Verificacion estructural, sin ejecutar una simulacion.
  req={...
    'src/utilidades/intercambio/aos_exportar_contexto_viewer.m',...
    'src/utilidades/intercambio/aos_generar_imagen_survey.m',...
    'src/utilidades/intercambio/exportar_aosrpt.m',...
    'src/utilidades/intercambio/exportar_aosrpt_enriquecido.m'};
  fprintf('\n=== VERIFICACION AOSRPT VIEWER 1.2 ===\n');
  for k=1:numel(req)
    if exist(req{k},'file')~=2,error('Falta: %s',req{k});end
    fprintf('[OK] %s\n',req{k});
  end
  txt=fileread('src/utilidades/intercambio/exportar_aosrpt.m');
  claves={'version=1.2','viewer_schema=AOS_VIEWER_CONTEXT_1.0','aos_exportar_contexto_viewer'};
  for k=1:numel(claves),if isempty(strfind(txt,claves{k})),error('No se encontro %s',claves{k});end,end
  txt2=fileread('src/utilidades/intercambio/exportar_aosrpt_enriquecido.m');
  if isempty(strfind(txt2,'survey_png_base64')),error('No se encontro survey_png_base64');end
  fprintf('VERIFICACION ESTRUCTURAL APROBADA.\n');
  fprintf('Ejecute una simulacion y exporte ambos formatos para validar el contenido real.\n');
end
