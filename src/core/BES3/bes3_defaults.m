function p = bes3_defaults(p)
% Defaults y normalizacion explicita BES3. Reutiliza BES2 sin modificarlo.
% DEV2: convierte vectores de .aosdat que el importador general preserva
% como texto, por ejemplo "[2,3]" y listas de diametros de capilar.
  if nargin<1 || ~isstruct(p), p=struct(); endif
  p=bes2_defaults(p);
  if isfield(p,'bes3') && isstruct(p.bes3), p=merge_local(p,p.bes3); endif

  p.bes3_version='BES3_0_1_3_R1_1';
  p.bes3_estado_validacion='DESARROLLO_NO_VALIDADO';
  p=setdef(p,'bes3_bomba_file',p.bes2_bomba_file);
  p.bes2_bomba_file=p.bes3_bomba_file;
  p=setdef(p,'bes3_n_puntos_solver',161);
  p=setdef(p,'bes3_tol_P_bar',0.05);
  p=setdef(p,'bes3_max_biseccion',70);

  % Estado operativo y frecuencia. 0 Hz se resuelve con rama de flujo natural.
  p=setdef(p,'bes3_frecuencia_min_operativa_Hz',35.0);
  p=setdef(p,'bes3_frecuencia_max_operativa_Hz',80.0);
  p=setdef(p,'bes3_frecuencia_configurada_Hz',p.frecuencia);
  p=setdef(p,'bes3_frecuencia_solicitada_Hz',p.frecuencia);
  p=setdef(p,'bes3_frecuencia_efectiva_Hz',p.frecuencia);
  p=setdef(p,'bes3_modo_frecuencia','configurada');
  p=setdef(p,'bes3_estado_bomba','encendida');
  p=setdef(p,'bes3_frecuencia_on_comparacion_Hz',max(getnum_local(p,{'frecuencia'},60),60));

  % Flujo natural con la BES detenida. El modo ideal reproduce el equivalente
  % de Qiny=0 de GL/JGL; el modo instalada agrega perdida pasiva configurable.
  p=setdef(p,'bes3_bomba_apagada_modelo','ideal'); % ideal, instalada, bloqueada
  p=setdef(p,'bes3_bomba_apagada_K',8.0);
  p=setdef(p,'bes3_bomba_apagada_dP_fijo_bar',0.0);
  p=setdef(p,'bes3_bomba_apagada_area_m2',0.0030);
  p=setdef(p,'bes3_bomba_apagada_permite_flujo',1);
  p=setdef(p,'bes3_check_valve_estado','PERMITE_FLUJO_ASCENDENTE');

  % Geometria del conjunto. D_bomba representa la profundidad MD del intake.
  p=setdef(p,'bes3_longitud_bomba_m',10.0);
  p=setdef(p,'bes3_longitud_protector_m',3.0);
  p=setdef(p,'bes3_longitud_motor_m',8.0);
  p=setdef(p,'bes3_OD_motor_m',getnum_local(p,{'OD_motor'},0.114));
  p=setdef(p,'bes3_ID_casing_m',getnum_local(p,{'ID_casing','diam_casing'},0.157));
  p=setdef(p,'bes3_shroud_habilitado',1);
  p=setdef(p,'bes3_ID_shroud_m',0.117);
  p=setdef(p,'bes3_OD_shroud_m',0.127);
  p=setdef(p,'bes3_descarga_bajo_motor_m',1.0);
  p=setdef(p,'bes3_factor_flujo_natural_parcial',0.35);
  p=setdef(p,'bes3_recirculacion_sin_shroud_permitida',0);

  % Cable y envolvente mecanica.
  p=setdef(p,'bes3_OD_cable_m',0.010);
  p=setdef(p,'bes3_tolerancia_corrida_m',0.002);
  p=setdef(p,'bes3_dogleg_max_deg_30m',3.0);
  p=setdef(p,'bes3_dogleg_deg_30m',0.0);

  % Capilar externo, descarga por debajo del motor.
  p=setdef(p,'bes3_recirculacion_modo','automatico'); % automatico, instalada, deshabilitada
  p=setdef(p,'bes3_etapa_toma',2);
  p=setdef(p,'bes3_etapas_candidatas',[2 3]);
  p=setdef(p,'bes3_capilar_ID_candidatos_m',[0.0020 0.0030 0.0040 0.0050 0.0060 0.0080 0.0100]);
  p=setdef(p,'bes3_capilar_espesor_m',0.0010);
  p=setdef(p,'bes3_capilar_ID_m',0.0030);
  p=setdef(p,'bes3_capilar_OD_m',0.0050);
  p=setdef(p,'bes3_capilar_longitud_m',NaN);
  p=setdef(p,'bes3_capilar_rugosidad_m',1.5e-6);
  p=setdef(p,'bes3_capilar_K_entrada',1.0);
  p=setdef(p,'bes3_capilar_K_salida',1.0);
  p=setdef(p,'bes3_capilar_K_accesorios',2.0);
  p=setdef(p,'bes3_capilar_presion_trabajo_bar',350);
  p=setdef(p,'bes3_capilar_Q_max_m3_d',300);
  p=setdef(p,'bes3_capilar_material','ACERO_INOXIDABLE');
  p=setdef(p,'bes3_margen_presion_min',0.20);
  p=setdef(p,'bes3_tol_refrigeracion_frac',0.02);
  % Criterio de diseno del circuito de recirculacion. El valor se
  % compara contra el caudal nominal/BEP efectivo de la bomba.
  p=setdef(p,'bes3_limite_recirculacion_pct_nominal',10.0);
  p=setdef(p,'bes3_tol_produccion_m3_d',0.01);

  % Normalizacion segura de vectores importados desde .aosdat.
  % aos_parse_valor convierte escalares, pero conserva listas como texto.
  p.bes3_etapas_candidatas=vector_num_local(p.bes3_etapas_candidatas,[2 3]);
  p.bes3_etapas_candidatas=round(p.bes3_etapas_candidatas(:)');
  p.bes3_etapas_candidatas=p.bes3_etapas_candidatas(isfinite(p.bes3_etapas_candidatas) & p.bes3_etapas_candidatas>=1);
  p.bes3_etapas_candidatas=unique(p.bes3_etapas_candidatas);
  if isempty(p.bes3_etapas_candidatas), p.bes3_etapas_candidatas=[2 3]; endif

  p.bes3_capilar_ID_candidatos_m=vector_num_local(p.bes3_capilar_ID_candidatos_m, ...
    [0.0020 0.0030 0.0040 0.0050 0.0060 0.0080 0.0100]);
  p.bes3_capilar_ID_candidatos_m=p.bes3_capilar_ID_candidatos_m(:)';
  p.bes3_capilar_ID_candidatos_m=p.bes3_capilar_ID_candidatos_m( ...
    isfinite(p.bes3_capilar_ID_candidatos_m) & p.bes3_capilar_ID_candidatos_m>0 & ...
    p.bes3_capilar_ID_candidatos_m<0.1);
  p.bes3_capilar_ID_candidatos_m=unique(p.bes3_capilar_ID_candidatos_m);
  if isempty(p.bes3_capilar_ID_candidatos_m)
    p.bes3_capilar_ID_candidatos_m=[0.0020 0.0030 0.0040 0.0050 0.0060 0.0080 0.0100];
  endif

  % Refrigeracion.
  p=setdef(p,'velocidad_min_refrig',0.30);
  p=setdef(p,'bes3_velocidad_amarillo_frac',0.90);
  p=setdef(p,'bes3_margen_termico_amarillo_C',10);

  % Succion en anular/completacion; NaN => calcular con casing y equipo.
  p=setdef(p,'bes3_area_succion_m2',NaN);
  p=setdef(p,'bes3_Dh_succion_m',NaN);
  p=setdef(p,'bes3_rugosidad_succion_m',getnum_local(p,{'rugosidad'},4.6e-5));

  if ~isfinite(p.bes3_capilar_longitud_m)
    p.bes3_capilar_longitud_m=1.10*(p.bes3_longitud_protector_m+p.bes3_longitud_motor_m+p.bes3_descarga_bajo_motor_m)+2.0;
  endif
  % Normalizacion final del estado operativo.
  if ~isnumeric(p.frecuencia) || isempty(p.frecuencia) || ~isfinite(p.frecuencia(1))
    p.frecuencia=0;
  else
    p.frecuencia=max(double(p.frecuencia(1)),0);
  endif
  p.bes3_frecuencia_configurada_Hz=getnum_local(p,{'bes3_frecuencia_configurada_Hz'},p.frecuencia);
  p.bes3_frecuencia_solicitada_Hz=getnum_local(p,{'bes3_frecuencia_solicitada_Hz'},p.frecuencia);
  p.bes3_frecuencia_efectiva_Hz=getnum_local(p,{'bes3_frecuencia_efectiva_Hz'},p.frecuencia);
  estado_txt='encendida';if ischar(p.bes3_estado_bomba),estado_txt=lower(strtrim(p.bes3_estado_bomba));endif
  if p.frecuencia<=0 || strcmp(estado_txt,'apagada')
    p.frecuencia=0;
    p.bes3_estado_bomba='apagada';
    p.bes3_frecuencia_efectiva_Hz=0;
  else
    p.bes3_estado_bomba='encendida';
    p.bes3_frecuencia_efectiva_Hz=p.frecuencia;
  endif
  p.bes3_frecuencia_solicitada_Hz=p.frecuencia;

  p.num_etapas=max(round(getnum_local(p,{'num_etapas'},1)),1);
  p.bes3_num_etapas_total=p.num_etapas;
  p.bes3_limite_recirculacion_pct_nominal=max(getnum_local(p,{'bes3_limite_recirculacion_pct_nominal'},10),0);
  p.bes3_tol_produccion_m3_d=max(getnum_local(p,{'bes3_tol_produccion_m3_d'},0.01),0);

  p.OD_motor=p.bes3_OD_motor_m;
  p.ID_casing=p.bes3_ID_casing_m;
endfunction

function o=merge_local(o,x)
  f=fieldnames(x); for i=1:numel(f), o.(f{i})=x.(f{i}); endfor
endfunction
function s=setdef(s,f,v)
  if ~isfield(s,f) || isempty(s.(f)), s.(f)=v; endif
endfunction
function v=getnum_local(s,campos,defecto)
  v=defecto;
  for i=1:numel(campos)
    if isfield(s,campos{i})
      x=s.(campos{i});
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
        v=x(1); return;
      elseif ischar(x)
        z=str2double(strtrim(x));
        if isfinite(z), v=z; return; endif
      endif
    endif
  endfor
endfunction
function v=vector_num_local(x,defecto)
% Convierte vectores numericos o texto tipo "[2,3]" sin usar eval/str2num.
  v=[];
  if isnumeric(x) || islogical(x)
    v=double(x(:)');
  elseif ischar(x)
    txt=char(x);
    tokens=regexp(txt,'[-+]?[0-9]*\.?[0-9]+([eEdD][-+]?[0-9]+)?','match');
    for i=1:numel(tokens)
      t=strrep(tokens{i},'D','e');t=strrep(t,'d','e');
      z=str2double(t);
      if isfinite(z), v(end+1)=z; endif
    endfor
  endif
  v=v(isfinite(v));
  if isempty(v), v=defecto; endif
endfunction
