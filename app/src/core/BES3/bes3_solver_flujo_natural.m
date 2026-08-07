function sol = bes3_solver_flujo_natural(param)
% Analisis nodal a 0 Hz. No escala ni utiliza la curva de bomba para definir dominio.
% DEV5 no clasifica Q=0 como flujo natural productivo.
  p=bes3_defaults(param);p.frecuencia=0;p.bes3_estado_bomba='apagada';
  p.bes3_frecuencia_efectiva_Hz=0;p.bes3_frecuencia_solicitada_Hz=0;
  try,bomba=bes2_cargar_bomba(p);catch,bomba=struct('modelo','BES_INSTALADA','origen','NO_DISPONIBLE');end_try_catch
  curva=curva_apagada_local(p,bomba);
  [Qipr,Pwf_fun]=ipr(p,p.modelo_IPR);Qipr=max(Qipr,0);
  n=max(round(p.bes3_n_puntos_solver),81);q=linspace(0,Qipr,n);R=NaN(size(q));ev=cell(size(q));
  for i=1:numel(q)
    ev{i}=bes3_evaluar_punto_natural(q(i),p,Pwf_fun);
    if ev{i}.valido,R(i)=ev{i}.residuo;endif
  endfor
  roots=[];revals={};tol=p.bes3_tol_P_bar*1e5;
  for i=1:numel(q)-1
    if isfinite(R(i))&&abs(R(i))<=tol
      roots(end+1)=q(i);revals{end+1}=ev{i};
    elseif isfinite(R(i))&&isfinite(R(i+1))&&R(i)*R(i+1)<0
      [qr,er]=bisect_local(q(i),q(i+1),p,Pwf_fun);roots(end+1)=qr;revals{end+1}=er;
    endif
  endfor
  if isfinite(R(end))&&abs(R(end))<=tol,roots(end+1)=q(end);revals{end+1}=ev{end};endif

  qtol=p.bes3_tol_produccion_m3_d/86400;
  idx_prod=find(roots>qtol);
  if ~isempty(idx_prod)
    [~,jj]=max(roots(idx_prod));ib=idx_prod(jj);best=revals{ib};estado='FLUJO_NATURAL_CONVERGIDO';conv=true;valid=true;
  elseif ~isempty(roots)
    [~,ib]=max(roots);best=revals{ib};estado='POZO_SIN_FLUJO_NATURAL';conv=false;valid=true;
  else
    idx=find(isfinite(R));
    if isempty(idx)
      best=bes3_evaluar_punto_natural(0,p,Pwf_fun);estado='FLUJO_NATURAL_BLOQUEADO_POR_COMPLETACION';conv=false;valid=false;
    elseif all(R(idx)<0)
      best=ev{idx(1)};estado='POZO_SIN_FLUJO_NATURAL';conv=false;valid=true;
    elseif all(R(idx)>0)
      best=ev{idx(end)};estado='FLUJO_NATURAL_LIMITADO_POR_IPR';conv=false;valid=false;
    else
      [~,j]=min(abs(R(idx)));best=ev{idx(j)};estado='SIN_CRUCE_NATURAL_NUMERICO';conv=false;valid=false;
    endif
  endif
  sol=armar_local(p,bomba,curva,best,roots,q,R,ev,estado,conv,valid);
endfunction

function [qr,er]=bisect_local(a,b,p,pwf)
  ea=bes3_evaluar_punto_natural(a,p,pwf);fa=ea.residuo;qr=a;er=ea;
  for k=1:p.bes3_max_biseccion
    m=0.5*(a+b);em=bes3_evaluar_punto_natural(m,p,pwf);
    if ~em.valido,b=m;continue;endif
    fm=em.residuo;qr=m;er=em;if abs(fm)<=p.bes3_tol_P_bar*1e5,break;endif
    if fa*fm<=0,b=m;else,a=m;fa=fm;endif
  endfor
endfunction

function sol=armar_local(p,b,c,e,roots,q,R,ev,estado,conv,valid)
  s=series_local(ev);[vlp_sel,vlp_eff]=modelos_local(p);
  if conv,punto_tipo='CRUCE_NODAL_FLUJO_NATURAL';
  elseif strcmp(estado,'POZO_SIN_FLUJO_NATURAL'),punto_tipo='SIN_FLUJO_NATURAL';
  elseif strcmp(estado,'FLUJO_NATURAL_LIMITADO_POR_IPR'),punto_tipo='REFERENCIA_LIMITE_IPR_SIN_CRUCE';
  else,punto_tipo='REFERENCIA_NATURAL_SIN_CRUCE';endif
  qd=e.Q_m3_d;if strcmp(estado,'POZO_SIN_FLUJO_NATURAL'),qd=0;endif
  d=diag_apagada_local(p);
  sol=struct('version',p.bes3_version,'estado_validacion',p.bes3_estado_validacion,'estado',estado, ...
    'modo_operacion','BOMBA_APAGADA','estado_bomba','APAGADA','modo_frecuencia',p.bes3_modo_frecuencia, ...
    'frecuencia_configurada_Hz',p.bes3_frecuencia_configurada_Hz,'frecuencia_solicitada_Hz',0, ...
    'frecuencia_efectiva_Hz',0,'frecuencia_estado','BOMBA_APAGADA', ...
    'convergido',conv,'punto_operacion_valido',valid,'punto_tipo',punto_tipo, ...
    'aceptado_preliminar',conv,'aceptado',false,'param',p,'bomba',b,'curva',c, ...
    'modelo_IPR',p.modelo_IPR,'modelo_VLP',vlp_sel,'vlp_efectivo',vlp_eff, ...
    'punto',e,'Ql_m3_d',qd,'Qo_m3_d',qd*(1-p.WC),'Qg_total_Sm3_d',qd*p.GLR, ...
    'Q_pump_neto_m3_d',0,'Q_recirc_m3_d',0,'percent_BEP',NaN, ...
    'num_etapas_total',p.num_etapas,'etapa_toma',0,'Q_nominal_efectivo_m3_d',NaN, ...
    'Q_recirc_pct_nominal',0,'Q_recirc_max_diseno_m3_d',NaN, ...
    'Q_etapas_inferiores_m3_d',0,'Q_etapas_superiores_m3_d',0, ...
    'BEP_inferior_pct',NaN,'BEP_superior_pct',NaN, ...
    'estado_diseno_recirculacion','NO_APLICA_BOMBA_APAGADA', ...
    'estado_operativo_recirculacion','NO_APLICA_BOMBA_APAGADA', ...
    'diagnostico_recirculacion',d,'margen_nodal_bar',e.residuo/1e5, ...
    'rango_estado','BOMBA_APAGADA','rango_inferior_estado','NO_APLICA_BOMBA_APAGADA', ...
    'rango_superior_estado','NO_APLICA_BOMBA_APAGADA', ...
    'gas_estado','NO_APLICA_BOMBA_APAGADA','refrigeracion_estado','INACTIVA_POR_BOMBA_APAGADA', ...
    'electrico',e.electrico,'geometria',e.geometria,'recirculacion',e.recirculacion, ...
    'bomba_apagada_loss',e.bomba_apagada_loss,'raices_m3_d',roots*86400,'n_raices',numel(roots), ...
    'barrido_Q_m3_d',q*86400,'barrido_residuo_bar',R/1e5,'barrido_Pwf_bar',s.Pwf/1e5, ...
    'barrido_Pintake_bar',s.Pintake/1e5,'barrido_Pdesc_disponible_bar',s.Pdisp/1e5, ...
    'barrido_Pdesc_requerida_bar',s.Preq/1e5,'barrido_dP_bomba_bar',zeros(size(q)), ...
    'barrido_dP_bomba_apagada_bar',s.dPloss/1e5);
  sol.semaforos=bes3_semaforos(sol);
  sol.diagnostico=sprintf('Modo=BOMBA_APAGADA | Solver=%s | Punto=%s | IPR=%s | VLP=%s/%s | Perdida_pasiva=%s | Validacion=%s', ...
    estado,punto_tipo,p.modelo_IPR,vlp_sel,vlp_eff,e.bomba_apagada_loss.modelo,p.bes3_estado_validacion);
endfunction

function d=diag_apagada_local(p)
  d=struct('num_etapas_total',p.num_etapas,'etapa_toma',0,'n_etapas_inferiores',0, ...
    'n_etapas_superiores',p.num_etapas,'Q_superficie_m3_d',0,'Q_nominal_efectivo_m3_d',NaN, ...
    'Q_recirc_m3_d',0,'Q_recirc_max_diseno_m3_d',NaN,'Q_recirc_pct_nominal',0, ...
    'limite_recirc_pct_nominal',p.bes3_limite_recirculacion_pct_nominal, ...
    'Q_etapas_inferiores_m3_d',0,'Q_etapas_superiores_m3_d',0, ...
    'BEP_inferior_pct',NaN,'BEP_superior_pct',NaN,'rango_inferior_estado','NO_APLICA', ...
    'rango_superior_estado','NO_APLICA','estado_secciones','NO_APLICA_BOMBA_APAGADA', ...
    'estado_diseno','NO_APLICA_BOMBA_APAGADA','estado_operativo','NO_APLICA_BOMBA_APAGADA', ...
    'cumple_diseno',true,'dP_toma_bar',0,'dP_capilar_bar',0,'margen_presion',NaN);
endfunction
function c=curva_apagada_local(p,b)
  modelo='BES_INSTALADA';if isstruct(b)&&isfield(b,'modelo'),modelo=b.modelo;endif
  c=struct('Q_m3_d',[],'Q_m3_s',[],'head_m',[],'eta',[],'Q_BEP_m3_d',NaN, ...
    'Q_min_rec_m3_d',NaN,'Q_max_rec_m3_d',NaN,'frecuencia_Hz',0, ...
    'num_etapas',p.num_etapas,'modelo',modelo,'estado','BOMBA_APAGADA');
endfunction
function s=series_local(ev)
  n=numel(ev);s=struct('Pwf',NaN(1,n),'Pintake',NaN(1,n),'Pdisp',NaN(1,n),'Preq',NaN(1,n),'dPloss',NaN(1,n));
  for i=1:n
    x=ev{i};if ~isstruct(x)||~isfield(x,'valido'),continue;endif
    s.Pwf(i)=x.Pwf_Pa;s.Pintake(i)=x.Pintake_Pa;s.Pdisp(i)=x.Pdesc_disponible_Pa;s.Preq(i)=x.Pdesc_req_Pa;s.dPloss(i)=x.dP_bomba_apagada_Pa;
  endfor
endfunction
function [sel,eff]=modelos_local(p)
  sel=p.modelo_VLP;eff=sel;
  try,info=aos_vlp_info(p,p.D_bomba);if isfield(info,'seleccionado'),sel=info.seleccionado;endif;if isfield(info,'efectivo'),eff=info.efectivo;endif,catch,end_try_catch
endfunction
