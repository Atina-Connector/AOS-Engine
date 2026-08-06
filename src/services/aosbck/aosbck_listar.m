function aosbck_listar()
% AOSBCK_LISTAR Imprime ficha y todas las instancias del paquete activo.
  e=aosbck_estado('GET');if isempty(e.paquete),fprintf('No hay AOSBCK activo.\n');return;endif
  m=e.manifest;fprintf('\n--- COMPONENTE AOSBCK ---\n');
  fprintf('ID           : %s\n',m.component.component_id);fprintf('Parte        : %s\n',m.component.part_number);
  fprintf('Descripcion  : %s\n',m.component.description);fprintf('Fabricante   : %s\n',m.component.manufacturer_id);
  fprintf('Proveedor    : %s\n',m.component.supplier_id);fprintf('Material     : %s %s\n',m.component.material_id,m.component.material_description);
  fprintf('Geometria    : %s\n',m.geometry.source_file_name);fprintf('Instancias   : %d\n',numel(m.instances));
  fprintf('\n%-5s %-24s %-15s %-20s %-12s\n','N','INSTANCE_ID','ORIGEN','UBICACION','ESTADO');
  for i=1:numel(m.instances),x=elem_local(m.instances,i);fprintf('%-5d %-24s %-15s %-20s %-12s\n',i,x.instance_id,x.placement.source,ubicacion_local(x.placement),x.status);endfor
endfunction
function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
function s=ubicacion_local(p)
  if strcmp(char(p.source),'WELL_SURVEY'),s=sprintf('MD %.2f m',p.md_m);
  elseif strcmp(char(p.source),'AOSCAD_NODE'),s=['Nodo ' char(p.node_id)];
  elseif isfield(p,'position_m'),s=sprintf('[%.1f %.1f %.1f]',p.position_m(1),p.position_m(2),p.position_m(3));else,s='N/D';endif
endfunction
