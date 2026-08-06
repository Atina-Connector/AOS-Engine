function g = bes3_completion_geometry(param)
% Geometria, posicion respecto de punzados y area de refrigeracion.
  p=bes3_defaults(param);
  Dint=p.D_bomba;
  motor_top=Dint+p.bes3_longitud_protector_m;
  motor_base=motor_top+p.bes3_longitud_motor_m;
  descarga=motor_base+p.bes3_descarga_bajo_motor_m;

  [ptop,pbase,np,origen]=punzados_local(p);
  if np==0
    posicion='PUNZADOS_NO_DISPONIBLES'; factor=0;
  elseif motor_base < ptop
    posicion='CONJUNTO_POR_ENCIMA_PUNZADOS'; factor=1;
  elseif motor_top > pbase || Dint > pbase
    posicion='CONJUNTO_TOTALMENTE_DEBAJO_PUNZADOS'; factor=0;
  else
    posicion='CONJUNTO_FRENTE_O_PARCIAL_PUNZADOS'; factor=min(max(p.bes3_factor_flujo_natural_parcial,0),1);
  endif

  if logical(p.bes3_shroud_habilitado)
    area=pi/4*max(p.bes3_ID_shroud_m^2-p.bes3_OD_motor_m^2,0);
    equipo_OD=p.bes3_OD_shroud_m;
    trayecto='SHROUD';
  else
    area=pi/4*max(p.bes3_ID_casing_m^2-p.bes3_OD_motor_m^2,0);
    equipo_OD=p.bes3_OD_motor_m;
    trayecto='ANULAR_CASING_MOTOR';
  endif

  if isfinite(p.bes3_area_succion_m2) && p.bes3_area_succion_m2>0
    area_succ=p.bes3_area_succion_m2;
  else
    area_succ=pi/4*max(p.bes3_ID_casing_m^2-equipo_OD^2,0);
  endif
  if isfinite(p.bes3_Dh_succion_m) && p.bes3_Dh_succion_m>0
    Dh_succ=p.bes3_Dh_succion_m;
  else
    Dh_succ=max(p.bes3_ID_casing_m-equipo_OD,1e-4);
  endif

  g=struct('D_intake_m',Dint,'D_motor_top_m',motor_top,'D_motor_base_m',motor_base, ...
    'D_descarga_capilar_m',descarga,'punzados_tope_m',ptop,'punzados_base_m',pbase, ...
    'n_tramos_punzados',np,'origen_punzados',origen,'posicion_estado',posicion, ...
    'factor_flujo_natural',factor,'shroud_habilitado',logical(p.bes3_shroud_habilitado), ...
    'trayecto_refrigeracion',trayecto,'area_refrigeracion_m2',area, ...
    'area_succion_m2',area_succ,'Dh_succion_m',Dh_succ,'equipo_OD_m',equipo_OD, ...
    'ID_casing_m',p.bes3_ID_casing_m,'OD_motor_m',p.bes3_OD_motor_m, ...
    'ID_shroud_m',p.bes3_ID_shroud_m,'OD_shroud_m',p.bes3_OD_shroud_m);
endfunction

function [ptop,pbase,np,origen]=punzados_local(p)
  ptop=NaN;pbase=NaN;np=0;origen='NO_DISPONIBLE';x=[];
  if isfield(p,'punzados'),x=p.punzados;origen='param.punzados';endif
  if isempty(x) && isfield(p,'geologia') && isstruct(p.geologia) && isfield(p.geologia,'intervalos')
    x=p.geologia.intervalos;origen='param.geologia.intervalos';
  endif
  if isempty(x)
    try
      [~,x,info]=aos_obtener_geometria_activa();
      if isstruct(info) && isfield(info,'origen_punzados'),origen=info.origen_punzados;endif
    catch
      x=[];
    end_try_catch
  endif
  if isstruct(x) && isfield(x,'tramos'),x=x.tramos;endif
  if isnumeric(x) && size(x,2)>=2
    a=x(:,1);b=x(:,2);act=true(size(a));
  elseif isstruct(x) && ~isempty(x)
    a=NaN(numel(x),1);b=a;act=true(numel(x),1);
    for i=1:numel(x)
      a(i)=alias_num_local(x(i),{'MD_desde','MD_desde_m','tope','top','desde'});
      b(i)=alias_num_local(x(i),{'MD_hasta','MD_hasta_m','base','bottom','hasta','fondo'});
      if isfield(x(i),'activo'),act(i)=logical(x(i).activo);endif
    endfor
  else
    return;
  endif
  ok=isfinite(a)&isfinite(b)&act;
  if any(ok),ptop=min(min(a(ok),b(ok)));pbase=max(max(a(ok),b(ok)));np=sum(ok);endif
endfunction
function v=alias_num_local(s,names)
  v=NaN;for k=1:numel(names),if isfield(s,names{k})&&isnumeric(s.(names{k}))&&~isempty(s.(names{k}))&&isfinite(s.(names{k})(1)),v=s.(names{k})(1);return;endif,endfor
endfunction
