function d = bes3_diagnostico_recirculacion(curva,bomba_secciones,rec,param,Q_superficie_m3_d)
% Diagnostico de diseno de recirculacion y operacion por secciones.
% El criterio principal compara Qrec con el caudal nominal/BEP efectivo
% de la bomba a la frecuencia y correccion de viscosidad evaluadas.
  p=bes3_defaults(param);
  if nargin<5||isempty(Q_superficie_m3_d)||~isfinite(Q_superficie_m3_d),Q_superficie_m3_d=NaN;endif

  qnom=num_local(curva,'Q_BEP_m3_d',NaN);
  ntotal=round(num_local(curva,'num_etapas',num_local(p,'num_etapas',0)));
  qrec=num_local(rec,'Q_recirc_m3_d',0);qreq=num_local(rec,'Q_requerido_m3_d',0);
  cumple_refrig=logical_local(rec,'cumple',true);
  etapa=round(num_local(rec,'etapa_toma',0));
  qinf=num_local(bomba_secciones,'Q_inferior_m3_d',NaN);
  qsup=num_local(bomba_secciones,'Q_superior_m3_d',NaN);
  ninf=round(num_local(bomba_secciones,'n_etapas_inferiores',etapa));
  nsup=round(num_local(bomba_secciones,'n_etapas_superiores',max(ntotal-ninf,0)));
  limite=max(num_local(p,'bes3_limite_recirculacion_pct_nominal',10),0);
  tolq=max(num_local(p,'bes3_tol_produccion_m3_d',0.01),0);

  if isfinite(qnom)&&qnom>0
    rec_pct=100*qrec/qnom;
    qrec_max=qnom*limite/100;
    bep_inf=100*qinf/qnom;
    bep_sup=100*qsup/qnom;
  else
    rec_pct=NaN;qrec_max=NaN;bep_inf=NaN;bep_sup=NaN;
  endif

  if qrec<=tolq&&qreq>tolq&&~cumple_refrig
    estado_diseno='RECIRCULACION_REQUERIDA_NO_DISPONIBLE';cumple_diseno=false;
  elseif qrec<=tolq
    estado_diseno='SIN_RECIRCULACION';cumple_diseno=true;
  elseif ~isfinite(rec_pct)
    estado_diseno='Q_NOMINAL_NO_DISPONIBLE';cumple_diseno=false;
  elseif rec_pct<limite
    estado_diseno='RECIRCULACION_DENTRO_LIMITE';cumple_diseno=true;
  else
    estado_diseno='RECIRCULACION_ALTA_MAL_DISENO';cumple_diseno=false;
  endif

  if isfinite(Q_superficie_m3_d)&&Q_superficie_m3_d<=tolq&&qrec>tolq
    estado_operativo='RECIRCULACION_INTERNA_SIN_PRODUCCION';
  elseif isfinite(Q_superficie_m3_d)&&Q_superficie_m3_d<=tolq
    estado_operativo='SIN_PRODUCCION_NETA';
  elseif isfinite(Q_superficie_m3_d)&&qrec>Q_superficie_m3_d
    estado_operativo='RECIRCULACION_MAYOR_QUE_PRODUCCION';
  else
    estado_operativo='PRODUCCION_CON_RECIRCULACION';
  endif

  rango_inf=rango_local(qinf,curva);
  rango_sup=rango_local(qsup,curva);
  if strcmp(rango_inf,'DENTRO_RANGO_RECOMENDADO')&&strcmp(rango_sup,'DENTRO_RANGO_RECOMENDADO')
    estado_secciones='AMBAS_SECCIONES_DENTRO_RANGO';
  elseif strcmp(rango_inf,'NO_EVALUADO')||strcmp(rango_sup,'NO_EVALUADO')
    estado_secciones='SECCIONES_NO_EVALUADAS';
  elseif strcmp(rango_inf,'DENTRO_RANGO_RECOMENDADO')||strcmp(rango_sup,'DENTRO_RANGO_RECOMENDADO')
    estado_secciones='UNA_SECCION_FUERA_RANGO';
  else
    estado_secciones='AMBAS_SECCIONES_FUERA_RANGO';
  endif

  d=struct('num_etapas_total',ntotal,'etapa_toma',etapa, ...
    'n_etapas_inferiores',ninf,'n_etapas_superiores',nsup, ...
    'Q_superficie_m3_d',Q_superficie_m3_d,'Q_nominal_efectivo_m3_d',qnom, ...
    'Q_recirc_m3_d',qrec,'Q_requerido_m3_d',qreq,'Q_recirc_max_diseno_m3_d',qrec_max, ...
    'Q_recirc_pct_nominal',rec_pct,'limite_recirc_pct_nominal',limite, ...
    'Q_etapas_inferiores_m3_d',qinf,'Q_etapas_superiores_m3_d',qsup, ...
    'BEP_inferior_pct',bep_inf,'BEP_superior_pct',bep_sup, ...
    'rango_inferior_estado',rango_inf,'rango_superior_estado',rango_sup, ...
    'estado_secciones',estado_secciones,'estado_diseno',estado_diseno, ...
    'estado_operativo',estado_operativo,'cumple_diseno',cumple_diseno, ...
    'dP_toma_bar',num_local(rec,'dP_disponible_Pa',NaN)/1e5, ...
    'dP_capilar_bar',num_local(rec,'dP_capilar_Pa',NaN)/1e5, ...
    'margen_presion',num_local(rec,'margen_presion',NaN));
endfunction

function estado=rango_local(q,curva)
  if ~isfinite(q),estado='NO_EVALUADO';return;endif
  qmin=num_local(curva,'Q_min_rec_m3_d',NaN);qmax=num_local(curva,'Q_max_rec_m3_d',NaN);
  if ~isfinite(qmin)||~isfinite(qmax),estado='NO_EVALUADO';
  elseif q<qmin,estado='BAJO_RANGO_RECOMENDADO';
  elseif q>qmax,estado='ALTO_RANGO_RECOMENDADO';
  else,estado='DENTRO_RANGO_RECOMENDADO';endif
endfunction
function v=num_local(s,campo,defecto)
  v=defecto;if isstruct(s)&&isfield(s,campo)&&isnumeric(s.(campo))&&~isempty(s.(campo))&&isfinite(s.(campo)(1)),v=double(s.(campo)(1));endif
endfunction

function v=logical_local(s,campo,defecto)
  v=defecto;if isstruct(s)&&isfield(s,campo)&&~isempty(s.(campo)),v=logical(s.(campo)(1));endif
endfunction
