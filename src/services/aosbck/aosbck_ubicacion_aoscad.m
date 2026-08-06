function placement = aosbck_ubicacion_aoscad(node_id, roll_deg)
% AOSBCK_UBICACION_AOSCAD Ubica una instancia en un nodo del modelo activo.
  global CONFIG_ACTIVA;
  if nargin<2||isempty(roll_deg),roll_deg=0;endif
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA)||~isfield(CONFIG_ACTIVA,'cad_topologia')|| ...
      ~isfield(CONFIG_ACTIVA.cad_topologia,'modelo_aoscad')
    error('AOSBCK: no hay modelo AOSCAD activo.');
  endif
  modelo=CONFIG_ACTIVA.cad_topologia.modelo_aoscad; nodos=modelo.tablas_entrada.nodos; nodo=[];
  for i=1:numel(nodos), n=elem_local(nodos,i); if isfield(n,'id')&&strcmp(char(n.id),char(node_id)),nodo=n;break;endif;endfor
  if isempty(nodo),error('AOSBCK: nodo AOSCAD no encontrado: %s',node_id);endif
  x=num_local(nodo,{'x','X'},0);y=num_local(nodo,{'y','Y'},0);z=num_local(nodo,{'z','Z','cota','elevacion_m'},0);
  azi=azimut_local(modelo,node_id,nodo);q=aosbck_quaternion_zyx(azi,0,roll_deg);
  proyecto='';if isfield(modelo,'info')&&isfield(modelo.info,'nombre'),proyecto=char(modelo.info.nombre);endif
  placement=struct('source','AOSCAD_NODE','project_id',proyecto,'node_id',char(node_id), ...
    'position_m',[x y z],'coordinate_convention','RIGHT_HANDED_Z_UP', ...
    'inclination_deg',0,'azimuth_deg',azi,'roll_deg',roll_deg, ...
    'orientation_quaternion_wxyz',q,'source_reference','modelo_aoscad.tablas_entrada.nodos');
endfunction

function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
function v=num_local(s,nombres,d),v=d;for k=1:numel(nombres),if isfield(s,nombres{k})&&isnumeric(s.(nombres{k}))&&isscalar(s.(nombres{k})),v=double(s.(nombres{k}));return;endif;endfor;endfunction
function a=azimut_local(modelo,id,nodo)
  a=0;if ~isfield(modelo,'tablas_entrada')||~isfield(modelo.tablas_entrada,'tramos'),return;endif
  tr=modelo.tablas_entrada.tramos;
  for i=1:numel(tr),t=elem_local(tr,i);dx=[];dy=[];
    if isfield(t,'nodo_o')&&strcmp(char(t.nodo_o),char(id))&&isfield(t,'x2'),dx=t.x2-nodo.x;dy=t.y2-nodo.y;
    elseif isfield(t,'nodo_d')&&strcmp(char(t.nodo_d),char(id))&&isfield(t,'x1'),dx=t.x1-nodo.x;dy=t.y1-nodo.y;endif
    if ~isempty(dx)&&hypot(dx,dy)>eps,a=mod(atan2(dy,dx)*180/pi,360);return;endif
  endfor
endfunction
