function ok = aosbck_visualizar(instance_id)
% AOSBCK_VISUALIZAR Carga una sola geometria STEP bajo demanda en FreeCAD.
  e=aosbck_estado('GET');ok=false;if isempty(e.paquete),error('AOSBCK: no hay componente activo.');endif
  if nargin<1||isempty(instance_id)
    aosbck_listar(); instance_id=strtrim(input('Instance ID (Enter=solo componente): ','s'));
  endif
  m=e.manifest;fprintf('\n--- VISUALIZACION BAJO DEMANDA ---\n');
  fprintf('Componente : %s\n',m.component.component_id);fprintf('Parte      : %s\n',m.component.part_number);
  fprintf('Proveedor  : %s\n',m.component.supplier_id);fprintf('Material   : %s %s\n',m.component.material_id,m.component.material_description);
  if ~isempty(instance_id)
    x=[];for i=1:numel(m.instances),c=elem_local(m.instances,i);if strcmp(char(c.instance_id),char(instance_id)),x=c;break;endif;endfor
    if isempty(x),error('AOSBCK: instancia no encontrada: %s',instance_id);endif
    fprintf('Instancia  : %s\n',x.instance_id);fprintf('Estado     : %s\n',x.status);disp(x.placement);
  endif
  fprintf('Se abre solo el STEP maestro; no se duplica geometria por instancia.\n');
  ok=aos_cad_abrir_externo('STEP',e.step_extraido);
endfunction
function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
