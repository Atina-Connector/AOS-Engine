function inst = aosbck_agregar_instancia(placement, datos, instance_id, silencioso)
% AOSBCK_AGREGAR_INSTANCIA Agrega ubicacion al paquete activo.
  if nargin<4,silencioso=false;endif
  if nargin<3,instance_id='';endif
  if nargin<2||~isstruct(datos),datos=struct();endif
  e=aosbck_estado('GET');if isempty(e.paquete),error('AOSBCK: abra o cree un paquete primero.');endif
  inst=aosbck_instancia_nueva(e.manifest,instance_id,placement,datos);
  for i=1:numel(e.manifest.instances),old=elem_local(e.manifest.instances,i);if strcmp(char(old.instance_id),char(inst.instance_id)),error('AOSBCK: instance_id repetido.');endif;endfor
  if isempty(e.manifest.instances),e.manifest.instances={inst};elseif iscell(e.manifest.instances),e.manifest.instances{end+1}=inst;else,e.manifest.instances(end+1)=inst;endif
  e.manifest.validation.instance_count=numel(e.manifest.instances);aosbck_estado('SET',e);aosbck_guardar_activo(true);
  aosbck_registrar_instancia_proyecto(inst,e.paquete);
  if ~silencioso,fprintf('Instancia agregada: %s | origen %s\n',inst.instance_id,inst.placement.source);endif
endfunction
function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
