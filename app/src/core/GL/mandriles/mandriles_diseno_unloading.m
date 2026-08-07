function R = mandriles_diseno_unloading(param)
  p = mandriles_defaults(param);
  Dmax = p.D_iny;
  if isfield(p,'D_packer') && isfinite(p.D_packer)
    Dmax = min(Dmax,p.D_packer);
  endif

  s = mandriles_normalizar_survey(p,Dmax);
  niv = mandriles_inferir_nivel_inicial(p,s);
  p.mand_nivel_estatico_m = niv.MD_m;
  Qobj = qiny_local(p);

  [Ql_diseno,fuente_Ql,det_Ql] = mandriles_estimar_ql_diseno(p,Qobj,niv);
  p.mand_Ql_diseno_m3d = Ql_diseno;
  Qg_unload = qg_unloading_local(p,Qobj);
  Ql_unload = ql_unloading_local(p,Ql_diseno);
  p.mand_Qg_unloading_m3d = Qg_unload;

  cstat = mandriles_perfil_casing(p,s,0,false);
  cdyn = mandriles_perfil_casing(p,s,Qobj,true);
  [gal,fuente,avisos] = mandriles_cargar_galeria(p);

  if p.mand_N_max > 0
    Nlim = round(p.mand_N_max);
    modo = 'LIMITADA_USUARIO';
  else
    Nlim = round(p.mand_N_limite_tecnico);
    modo = 'AUTOMATICA';
  endif

  valves = struct([]);
  perfiles_tubing = {};
  Dprev = max(0,niv.MD_m);
  diagnosticos = struct([]);
  motivos = {};

  for k = 1:max(Nlim,1)
    if k == 1
      qg_etapa = 0;
      ql_etapa = 0;
    else
      qg_etapa = Qg_unload;
      ql_etapa = Ql_unload;
    endif
    tub = mandriles_perfil_tubing_unloading(p,s,niv.MD_m,Dprev,qg_etapa,ql_etapa);
    perfiles_tubing{end+1} = tub;

    Dmin = Dprev + p.mand_espaciado_min_m;
    if Dmin > Dmax
      break;
    endif
    [D,sel,diag] = buscar_local(p,s,cstat,cdyn,tub,gal,Qobj,Dmin,Dmax,k,Qg_unload);
    diagnosticos = agregar_local(diagnosticos,diag);
    if ~isfinite(D)
      motivos{end+1}=diag.motivo;
      break;
    endif

    PcO = interp1(cstat.MD,cstat.P,D)/1e5;
    PcF = interp1(cdyn.MD,cdyn.P,D)/1e5;
    Pt = interp1(tub.MD,tub.P,D)/1e5;
    g = sel.item;
    cap = sel.capacidad;
    v = struct('n',k,'MD_m',D,'TVD_m',aos_tvd_at_md(s,D), ...
      'Pc_est_bar',PcO,'Pc_flujo_bar',PcF,'Pt_bar',Pt,'dP_bar',PcO-Pt, ...
      'puerto_mm',cap.puerto_mm,'capacidad_m3d',cap.capacidad_m3d, ...
      'utilizacion',cap.utilizacion,'flujo_critico',cap.critico, ...
      'estado_capacidad',cap.estado,'rating_ok',max(PcO,Pt)<=g.rating_bar, ...
      'tipo','UNLOADING_IPO','cierre_superior_ok',true, ...
      'galeria_id',g.id,'fabricante',g.fabricante,'mandril_modelo',g.mandril, ...
      'valvula_modelo',g.valvula,'rating_bar',g.rating_bar, ...
      'seleccion_motivo',sel.motivo,'Qg_perfil_m3d',qg_etapa, ...
      'Ql_perfil_m3d',ql_etapa,'modelo_tubing',tub.metodo);
    if isempty(valves)
      valves=v;
    else
      valves(end+1)=v;
    endif
    Dprev=D;
    if Dmax-Dprev < p.mand_espaciado_min_m
      break;
    endif
  endfor

  if ~isempty(valves)
    valves(end).tipo='OPERATING_ORIFICE';
    valves(end).Qg_perfil_m3d=Qobj;
    valves(end).Ql_perfil_m3d=Ql_diseno;
    tub_oper = mandriles_perfil_tubing_unloading(p,s,niv.MD_m,valves(end).MD_m,Qobj,Ql_diseno);
  else
    tub_oper = struct([]);
  endif

  Dalc=0;
  if ~isempty(valves)
    Dalc=valves(end).MD_m;
  endif
  if isempty(valves)
    estado='SIN_CAPACIDAD_DE_INYECCION';
  elseif Dalc>=Dmax-p.mand_espaciado_min_m
    estado='DISENO_COMPLETO';
  else
    estado='DISENO_PARCIAL';
  endif

  deficit=deficit_local(p,s,cstat,niv.MD_m,Dalc,Dmax,Qg_unload,Ql_unload);
  R=struct('version','MANDRILES_V2_PERFILES_COMPRESIBLES_FISICA2', ...
    'param',p,'survey',s,'nivel_inicial',niv, ...
    'casing_estatico',cstat,'casing_dinamico',cdyn, ...
    'perfiles_tubing',{perfiles_tubing},'tubing_operativo',tub_oper, ...
    'valvulas',valves,'Qiny_objetivo_m3d',Qobj, ...
    'Qg_unloading_m3d',Qg_unload,'Ql_unloading_m3d',Ql_unload, ...
    'Ql_diseno_m3d',Ql_diseno,'fuente_Ql_diseno',fuente_Ql, ...
    'detalle_Ql_diseno',det_Ql,'estado',estado,'modo_cantidad',modo, ...
    'N_limite',Nlim,'profundidad_objetivo_m',Dmax, ...
    'profundidad_alcanzable_m',Dalc, ...
    'presion_adicional_requerida_bar',deficit, ...
    'modelo_casing',cstat.modelo, ...
    'modelo_tubing','HOMOGENEO_COMPRESIBLE_POR_TRAMOS', ...
    'galeria',gal,'fuente_galeria',fuente,'avisos_galeria',{avisos}, ...
    'motivos_fin',{motivos},'diagnosticos_busqueda',diagnosticos);
endfunction

function [D,sel,diag] = buscar_local(p,s,cs,cd,tub,gal,Q,Dmin,Dmax,k,Qg_unload)
  D=NaN;
  sel=struct();
  diag=struct('etapa',k,'motivo','SIN_ESTACION','max_dP_bar',-Inf, ...
      'prof_max_dP_m',NaN,'hay_presion',false);
  paso=max(1,p.mand_paso_busqueda_m);
  cand=Dmax:-paso:Dmin;
  if isempty(cand) || cand(end)>Dmin
    cand(end+1)=Dmin;
  endif
  for j=1:numel(cand)
    x=cand(j);
    Pc=interp1(cs.MD,cs.P,x)/1e5;
    Pt=interp1(tub.MD,tub.P,x)/1e5;
    dp=Pc-Pt;
    if dp>diag.max_dP_bar
      diag.max_dP_bar=dp;
      diag.prof_max_dP_m=x;
    endif
    if dp<p.mand_dP_apertura_bar
      continue;
    endif
    diag.hay_presion=true;
    T=p.mand_T_sup_K+p.mand_grad_T_K_m*aos_tvd_at_md(s,x);
    if k==1
      Qscreen=max(1000,min(Q,max(Qg_unload,0.35*Q)));
    else
      Qscreen=max(1000,min(Q,Qg_unload));
    endif
    sc=mandriles_seleccionar_galeria(p,gal,Pc,Pt,T,Qscreen);
    if sc.ok
      D=x;
      sel=sc;
      diag.motivo='OK';
      return;
    endif
  endfor
  if diag.hay_presion
    diag.motivo='GALERIA_O_CAPACIDAD_INCOMPATIBLE';
  else
    diag.motivo='PRESION_INSUFICIENTE';
  endif
endfunction

function d=deficit_local(p,s,cs,niv,Dalc,Dobj,Qg,Ql)
  tub=mandriles_perfil_tubing_unloading(p,s,niv,max(Dalc,niv),Qg,Ql);
  inicio=max(niv,Dalc)+p.mand_espaciado_min_m;
  if inicio>Dobj
    d=0;
    return;
  endif
  md=linspace(inicio,Dobj,200);
  req=interp1(tub.MD,tub.P,md)/1e5+p.mand_dP_apertura_bar- ...
      interp1(cs.MD,cs.P,md)/1e5;
  d=max(0,min(req));
endfunction

function Q=qiny_local(p)
  Q=0;
  if isfield(p,'Q_iny') && isnumeric(p.Q_iny) && isfinite(p.Q_iny)
    Q=max(p.Q_iny*86400,0);
  endif
  if isfield(p,'Qiny_Sm3_d') && isnumeric(p.Qiny_Sm3_d) && isfinite(p.Qiny_Sm3_d)
    Q=max(p.Qiny_Sm3_d,0);
  endif
endfunction

function q=qg_unloading_local(p,Qobj)
  if isfield(p,'mand_Qg_unloading_m3d') && isnumeric(p.mand_Qg_unloading_m3d) && ...
      isscalar(p.mand_Qg_unloading_m3d) && isfinite(p.mand_Qg_unloading_m3d)
    q=max(p.mand_Qg_unloading_m3d,0);
  else
    q=max(1000,p.mand_fraccion_Qg_unloading*max(Qobj,0));
    if Qobj>0
      q=min(q,Qobj);
    endif
  endif
endfunction

function q=ql_unloading_local(p,Ql)
  if Ql>0
    q=max(p.mand_Ql_min_unloading_m3d,p.mand_fraccion_Ql_unloading*Ql);
  else
    q=max(p.mand_Ql_min_unloading_m3d,0);
  endif
endfunction

function a=agregar_local(a,x)
  if isempty(a)
    a=x;
  else
    a(end+1)=x;
  endif
endfunction
