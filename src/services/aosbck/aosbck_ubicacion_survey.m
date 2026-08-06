function placement = aosbck_ubicacion_survey(md_m, roll_deg, well_id)
% AOSBCK_UBICACION_SURVEY Ubica una instancia por MD sobre el survey activo.
  if nargin<2||isempty(roll_deg),roll_deg=0;endif
  if nargin<3,well_id='';endif
  [s,~,info]=aos_obtener_geometria_activa();
  if isempty(s)||~isfield(s,'MD')||numel(s.MD)<2, error('AOSBCK: no hay survey activo valido.'); endif
  if isempty(well_id)&&isfield(info,'pozo'),well_id=info.pozo;endif
  [xv,yv]=coords_local(s);
  x=interp1(s.MD,xv,md_m,'linear','extrap'); y=interp1(s.MD,yv,md_m,'linear','extrap');
  tvd=interp1(s.MD,s.TVD,md_m,'linear','extrap'); inc=interp1(s.MD,s.inclinacion,md_m,'linear','extrap');
  azi=interp1(s.MD,s.azimut,md_m,'linear','extrap'); q=aosbck_quaternion_zyx(azi,inc,roll_deg);
  placement=struct('source','WELL_SURVEY','well_id',char(well_id),'md_m',md_m,'tvd_m',tvd, ...
    'position_m',[x y -tvd],'coordinate_convention','RIGHT_HANDED_Z_UP', ...
    'inclination_deg',inc,'azimuth_deg',azi,'roll_deg',roll_deg, ...
    'orientation_quaternion_wxyz',q,'source_reference',info.origen_survey);
endfunction

function [x,y]=coords_local(s)
  n=numel(s.MD);x=zeros(n,1);y=zeros(n,1);inc=s.inclinacion(:)*pi/180;azi=s.azimut(:)*pi/180;
  for i=2:n
    d=s.MD(i)-s.MD(i-1); im=0.5*(inc(i-1)+inc(i)); am=0.5*(azi(i-1)+azi(i));
    dh=d*sin(im); x(i)=x(i-1)+dh*cos(am); y(i)=y(i-1)+dh*sin(am);
  endfor
endfunction
