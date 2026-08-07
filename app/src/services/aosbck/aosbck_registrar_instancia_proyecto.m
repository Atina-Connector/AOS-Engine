function aosbck_registrar_instancia_proyecto(inst, paquete)
% AOSBCK_REGISTRAR_INSTANCIA_PROYECTO Vincula instancia con CONFIG_ACTIVA.
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA),CONFIG_ACTIVA=struct();endif
  if ~isfield(CONFIG_ACTIVA,'componentes_3d')||~isstruct(CONFIG_ACTIVA.componentes_3d)
    CONFIG_ACTIVA.componentes_3d=struct('catalogo',{{}},'instancias',{{}});
  endif
  cat=CONFIG_ACTIVA.componentes_3d.catalogo; existe=false;
  for i=1:numel(cat),c=elem_local(cat,i);if isfield(c,'component_id')&&strcmp(char(c.component_id),char(inst.component_id)),existe=true;break;endif;endfor
  if ~existe
    c=struct('component_id',inst.component_id,'part_number',inst.part_number,'aosbck_file',char(paquete));
    if isempty(cat),cat={c};elseif iscell(cat),cat{end+1}=c;else,cat(end+1)=c;endif
  endif
  its=CONFIG_ACTIVA.componentes_3d.instancias;
  if isempty(its),its={inst};elseif iscell(its),its{end+1}=inst;else,its(end+1)=inst;endif
  CONFIG_ACTIVA.componentes_3d.catalogo=cat;CONFIG_ACTIVA.componentes_3d.instancias=its;
  if strcmp(char(inst.placement.source),'AOSCAD_NODE'),vincular_aoscad_local(inst,paquete);endif
endfunction

function vincular_aoscad_local(inst,paquete)
  global CONFIG_ACTIVA;modelo=CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if ~isfield(modelo.tablas_entrada,'componentes_3d'),modelo.tablas_entrada.componentes_3d={};endif
  if ~isfield(modelo.tablas_entrada,'instancias_3d'),modelo.tablas_entrada.instancias_3d={};endif
  c=struct('component_id',inst.component_id,'part_number',inst.part_number,'aosbck_file',char(paquete));
  modelo.tablas_entrada.componentes_3d=agregar_unico_local(modelo.tablas_entrada.componentes_3d,c,'component_id');
  modelo.tablas_entrada.instancias_3d=agregar_unico_local(modelo.tablas_entrada.instancias_3d,inst,'instance_id');
  nodos=modelo.tablas_entrada.nodos;
  for i=1:numel(nodos),n=elem_local(nodos,i);if isfield(n,'id')&&strcmp(char(n.id),char(inst.placement.node_id))
      n.asset_instance_id=inst.instance_id;n.component_id=inst.component_id;n.part_number=inst.part_number;
      if iscell(nodos),nodos{i}=n;else,nodos(i)=n;endif;break;endif;endfor
  modelo.tablas_entrada.nodos=nodos;CONFIG_ACTIVA.cad_topologia.modelo_aoscad=modelo;
endfunction

function c=agregar_unico_local(c,v,campo)
  for i=1:numel(c),x=elem_local(c,i);if isfield(x,campo)&&strcmp(char(x.(campo)),char(v.(campo))),return;endif;endfor
  if isempty(c),c={v};elseif iscell(c),c{end+1}=v;else,c(end+1)=v;endif
endfunction
function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
