function rec = bes3_recirculation(Qnet_pump,fluido,geom,curva,param)
% Disena o evalua capilar externo con descarga debajo del motor.
% DEV5 separa suficiencia termica de calidad de diseno. Una recirculacion
% puede refrigerar correctamente y, aun asi, ser excesiva respecto del
% caudal nominal/BEP efectivo de la bomba.
  p=bes3_defaults(param);A=max(geom.area_refrigeracion_m2,1e-12);
  Qmin=A*max(p.velocidad_min_refrig,0);
  Qnatural=max(fluido.Ql_local_m3_s,0)*geom.factor_flujo_natural;
  Qreq=max(Qmin-Qnatural,0);
  qnom_m3_d=num_local(curva,'Q_BEP_m3_d',NaN);
  qmax_diseno_m3_s=NaN;
  if isfinite(qnom_m3_d)&&qnom_m3_d>0
    qmax_diseno_m3_s=qnom_m3_d/86400*p.bes3_limite_recirculacion_pct_nominal/100;
  endif
  rec=base_local(Qmin,Qnatural,Qreq,geom,p,qnom_m3_d,qmax_diseno_m3_s);
  if Qreq<=p.bes3_tol_refrigeracion_frac*max(Qmin,1e-12)
    rec.estado='REFRIGERACION_NATURAL_SUFICIENTE';rec.cumple=true;rec.cumple_refrigeracion=true;rec.cumple_diseno=true;return;
  endif
  if strcmpi(strtrim(p.bes3_recirculacion_modo),'deshabilitada')
    rec.estado='RECIRCULACION_REQUERIDA_DESHABILITADA';return;
  endif
  if ~geom.shroud_habilitado && ~logical(p.bes3_recirculacion_sin_shroud_permitida)
    rec.estado='SHROUD_REQUERIDO_PARA_RETORNO_FORZADO';return;
  endif

  qg=fluido.gvf_bomba/max(1-fluido.gvf_bomba,1e-9)*max(fluido.Ql_local_m3_s,0);
  rho=fluido.rho_l_kg_m3;mu=max(fluido.mu_o_Pa_s,1e-6);
  if strcmpi(strtrim(p.bes3_recirculacion_modo),'instalada')
    cap=struct('id','CAP_INSTALADO','ID_m',p.bes3_capilar_ID_m,'OD_m',p.bes3_capilar_OD_m, ...
      'espesor_m',max((p.bes3_capilar_OD_m-p.bes3_capilar_ID_m)/2,0),'material',p.bes3_capilar_material);
    etapas=p.bes3_etapa_toma;caps=cap;
  else
    etapas=p.bes3_etapas_candidatas(:)';caps=bes3_capillary_catalog(p);
  endif

  cand={};
  for ie=1:numel(etapas)
    etapa=round(etapas(ie));if etapa<1||etapa>=p.num_etapas,continue;endif
    for ic=1:numel(caps)
      cap=caps(ic);fit=bes3_capillary_fit(cap,geom,p);
      dp_fun=@(qr) dp_stage_local(qr,Qnet_pump,qg,rho,etapa,curva,p);
      flow=bes3_capillary_flow(dp_fun,cap,rho,mu,p);
      loss_req=bes3_capillary_loss(Qreq,rho,mu,cap,p);
      dp_req=max(dp_fun(Qreq),0);
      if loss_req.dP_total_Pa>0,margen=(dp_req-loss_req.dP_total_Pa)/loss_req.dP_total_Pa;else,margen=Inf;endif
      presion_ok=dp_req/1e5<=p.bes3_capilar_presion_trabajo_bar;
      cumple_refrig=fit.instalable && presion_ok && flow.Q_m3_s+1e-12>=Qreq*(1-p.bes3_tol_refrigeracion_frac) && margen>=p.bes3_margen_presion_min;
      if isfinite(qmax_diseno_m3_s)
        cumple_limite=flow.Q_m3_s<qmax_diseno_m3_s*(1-1e-9);
        qrec_pct=100*flow.Q_m3_d/max(qnom_m3_d,1e-12);
      else
        cumple_limite=false;qrec_pct=NaN;
      endif
      cumple_diseno=cumple_refrig&&cumple_limite;
      c=struct('etapa',etapa,'capilar',cap,'fit',fit,'flow',flow,'Qreq_m3_s',Qreq, ...
        'dP_req_Pa',dp_req,'dP_loss_req_Pa',loss_req.dP_total_Pa,'margen_presion',margen, ...
        'presion_trabajo_ok',presion_ok,'cumple_refrigeracion',cumple_refrig, ...
        'cumple_limite_recirc',cumple_limite,'cumple_diseno',cumple_diseno, ...
        'Q_recirc_pct_nominal',qrec_pct,'cumple',cumple_refrig);
      cand{end+1}=c;
    endfor
  endfor
  if isempty(cand),rec.estado='SIN_CANDIDATOS_CAPILAR';return;endif

  idx_diseno=[];idx_refrig=[];
  for i=1:numel(cand)
    if cand{i}.cumple_diseno,idx_diseno(end+1)=i;endif
    if cand{i}.cumple_refrigeracion,idx_refrig(end+1)=i;endif
  endfor
  if ~isempty(idx_diseno)
    best=seleccionar_local(cand,idx_diseno,Qreq);c=cand{best};
    rec.estado=sprintf('RECIRCULACION_VIABLE_ETAPA_%d',c.etapa);
  elseif ~isempty(idx_refrig)
    best=seleccionar_local(cand,idx_refrig,Qreq);c=cand{best};
    rec.estado=sprintf('RECIRCULACION_VIABLE_PERO_EXCESIVA_ETAPA_%d',c.etapa);
  else
    best=1;qbest=-Inf;
    for i=1:numel(cand)
      qscore=cand{i}.flow.Q_m3_s;if ~cand{i}.fit.instalable,qscore=-1;endif
      if qscore>qbest,qbest=qscore;best=i;endif
    endfor
    c=cand{best};rec.estado='RECIRCULACION_INSUFICIENTE';
    anyfit=false;for i=1:numel(cand),anyfit=anyfit||cand{i}.fit.instalable;endfor
    if ~anyfit,rec.estado='NINGUN_CAPILAR_INSTALABLE_EN_CASING';endif
  endif

  rec.etapa_toma=c.etapa;rec.capilar=c.capilar;rec.compatibilidad=c.fit;
  rec.Q_recirc_m3_s=c.flow.Q_m3_s;rec.Q_recirc_m3_d=c.flow.Q_m3_d;
  rec.dP_disponible_Pa=c.flow.dP_disponible_Pa;rec.dP_capilar_Pa=c.flow.dP_total_Pa;
  rec.margen_presion=c.margen_presion;rec.Re_capilar=c.flow.Re;rec.regimen_capilar=c.flow.regimen;
  rec.velocidad_total_m_s=(Qnatural+rec.Q_recirc_m3_s)/A;
  rec.cumple=c.cumple_refrigeracion;rec.cumple_refrigeracion=c.cumple_refrigeracion;
  rec.cumple_limite_recirc=c.cumple_limite_recirc;rec.cumple_diseno=c.cumple_diseno;
  rec.Q_recirc_pct_nominal=c.Q_recirc_pct_nominal;rec.candidatos=cand;
endfunction

function rec=base_local(Qmin,Qnat,Qreq,g,p,qnom,qmax)
  rec=struct('estado','NO_EVALUADO','cumple',false,'cumple_refrigeracion',false, ...
    'cumple_limite_recirc',false,'cumple_diseno',false,'Q_min_refrig_m3_s',Qmin, ...
    'Q_min_refrig_m3_d',Qmin*86400,'Q_natural_m3_s',Qnat,'Q_natural_m3_d',Qnat*86400, ...
    'Q_requerido_m3_s',Qreq,'Q_requerido_m3_d',Qreq*86400,'Q_recirc_m3_s',0,'Q_recirc_m3_d',0, ...
    'Q_nominal_efectivo_m3_d',qnom,'Q_recirc_max_diseno_m3_s',qmax, ...
    'Q_recirc_max_diseno_m3_d',qmax*86400,'Q_recirc_pct_nominal',0, ...
    'limite_recirc_pct_nominal',p.bes3_limite_recirculacion_pct_nominal, ...
    'etapa_toma',0,'capilar',struct(),'compatibilidad',struct(),'dP_disponible_Pa',0, ...
    'dP_capilar_Pa',0,'margen_presion',NaN,'Re_capilar',0,'regimen_capilar','SIN_FLUJO', ...
    'velocidad_total_m_s',Qnat/max(g.area_refrigeracion_m2,1e-12),'candidatos',{{}}, ...
    'modo',p.bes3_recirculacion_modo);
endfunction
function dp=dp_stage_local(qr,Qnet,qg,rho,nstage,curva,p)
  qliq=max(Qnet+qr,0);gvf=qg/max(qg+qliq,1e-12);
  st=bes3_stage_performance(qliq,gvf,curva,p);
  if ~st.valido,dp=0;else,dp=rho*9.80665*st.head_m*nstage;endif
endfunction
function best=seleccionar_local(cand,idx,Qreq)
  best=idx(1);score_best=score_local(cand{best},Qreq);
  for j=2:numel(idx),ii=idx(j);sc=score_local(cand{ii},Qreq);if sc<score_best,best=ii;score_best=sc;endif,endfor
endfunction
function s=score_local(c,qreq)
  exceso=max(c.flow.Q_m3_s-qreq,0)/max(qreq,1e-12);
  penaliza_limite=0;if isfield(c,'cumple_limite_recirc')&&~c.cumple_limite_recirc,penaliza_limite=10;endif
  s=1e6*c.capilar.OD_m+exceso+penaliza_limite;
endfunction
function v=num_local(s,campo,defecto)
  v=defecto;if isstruct(s)&&isfield(s,campo)&&isnumeric(s.(campo))&&~isempty(s.(campo))&&isfinite(s.(campo)(1)),v=double(s.(campo)(1));endif
endfunction
