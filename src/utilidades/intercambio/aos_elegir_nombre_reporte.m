function archivo = aos_elegir_nombre_reporte(carpeta, nombre_defecto)
% Pide el nombre final directamente. Enter conserva el propuesto.
  [~,base,~]=fileparts(nombre_defecto);
  fprintf('\nNombre propuesto: %s.aosrpt\n',base);
  nuevo=input(sprintf('Nombre del reporte sin extension [%s]: ',base),'s');
  nuevo=strtrim(nuevo); if isempty(nuevo),nuevo=base;end
  nuevo=regexprep(nuevo,'[\\/:*?"<>|]','_');
  archivo=fullfile(carpeta,[nuevo '.aosrpt']);
  fprintf('El reporte se guardara como: %s\n',archivo);
end
