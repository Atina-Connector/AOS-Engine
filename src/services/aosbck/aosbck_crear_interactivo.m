function paquete = aosbck_crear_interactivo()
% AOSBCK_CREAR_INTERACTIVO Solicita identidad y metadatos antes de convertir STEP.
  meta = struct();
  meta.part_number = strtrim(input('Numero de parte: ', 's'));
  meta.component_type = strtrim(input('Tipo de componente: ', 's'));
  meta.description = strtrim(input('Descripcion: ', 's'));
  meta.manufacturer_id = strtrim(input('Fabricante ID: ', 's'));
  meta.supplier_id = strtrim(input('Proveedor ID: ', 's'));
  meta.material_id = strtrim(input('Material ID: ', 's'));
  meta.material_description = strtrim(input('Descripcion material: ', 's'));
  meta.geometry_units = strtrim(input('Unidades STEP [mm]: ', 's'));
  if isempty(meta.geometry_units), meta.geometry_units = 'mm'; endif
  paquete = aosbck_crear_desde_step([], meta, [], false);
endfunction
