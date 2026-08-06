function archivo = aos011_exportar_sensibilidad(modulo,R,enriquecido,archivo)
% Compatibilidad 0.1.1/0.1.3. Delega al contrato transversal DEV5.4.
% Mantiene la firma historica y agrega diagnostico, tabla nativa y contexto.
  if nargin<1||~ischar(modulo)||isempty(strtrim(modulo)),modulo='GENERAL';endif
  if nargin<2||~isstruct(R),error('Falta resultado de sensibilidad.');endif
  if nargin<3||isempty(enriquecido),enriquecido=false;endif
  param=struct();
  contexto=aos_sensibilidad_report_context(modulo,param,R);
  contexto.diagnostico=aos_sensibilidad_diagnosticar(R,modulo,param);
  if nargin<4||isempty(archivo)
    carpeta=aos_report_choose_directory(fullfile('intercambio','reportes','enviados'));
    base=regexprep(contexto.nombre_caso,'[^A-Za-z0-9_-]+','_');
    archivo=aos_elegir_nombre_reporte(carpeta,[base '.aosrpt']);
  endif
  archivo=aos_exportar_sensibilidad_core(contexto,archivo,enriquecido);
  fprintf('Sensibilidad exportada: %s\n',archivo);
endfunction
