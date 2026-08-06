function niv = mandriles_inferir_nivel_inicial(param, survey)
% Obtiene el nivel inicial con trazabilidad: medido, P fondo estatica o Qiny=0.
  p=mandriles_defaults(param);
  niv=struct('MD_m',NaN,'TVD_m',NaN,'origen','NO_DISPONIBLE','confianza','BAJA', ...
    'Ql_natural_m3d',NaN,'Pwf_natural_bar',NaN,'mensaje','');
  campos={'mand_nivel_estatico_m','nivel_estatico_MD_m','nivel_estatico_m','nivel_estatico'};
  for i=1:numel(campos)
    if isfield(p,campos{i}) && isnumeric(p.(campos{i})) && isscalar(p.(campos{i})) && isfinite(p.(campos{i})) && p.(campos{i})>=0
      niv.MD_m=p.(campos{i}); niv.TVD_m=aos_tvd_at_md(survey,niv.MD_m);
      niv.origen='MEDIDO_AOSDAT'; niv.confianza='ALTA'; return;
    endif
  endfor
  Pbh=leer_num_local(p,{'P_fondo_estatica','P_fondo_estatica_bar','Pws','Pws_bar','Pwf_estatica','Pwf_estatica_bar'},NaN);
  if isfinite(Pbh)
    if Pbh<1e4, Pbh=Pbh*1e5; endif
    Dref=leer_num_local(p,{'D_res','D_packer','D_iny'},max(survey.MD));
    tvdref=aos_tvd_at_md(survey,Dref); rho=mezcla_local(p);
    niv.TVD_m=max(0,tvdref-(Pbh-p.P_wh)/(rho*9.80665));
    niv.MD_m=md_desde_tvd_local(survey,niv.TVD_m);
    niv.origen='CALCULADO_PRESION_FONDO_ESTATICA'; niv.confianza='MEDIA_ALTA'; return;
  endif
  try
    tmp=p; tmp.Q_iny=0;
    [Ql,det]=aos_resolver_gl(tmp,0);
    if isfinite(Ql) && Ql>0
      Pwf=NaN;
      if isfield(det,'balance_solucion') && isfield(det.balance_solucion,'P_s'), Pwf=det.balance_solucion.P_s; endif
      if ~isfinite(Pwf)
        [~,pwff]=ipr(tmp,tmp.modelo_IPR); Pwf=pwff(Ql);
      endif
      Dref=leer_num_local(tmp,{'D_iny','D_packer','D_res'},max(survey.MD)); tvdref=aos_tvd_at_md(survey,Dref);
      rho=mezcla_local(tmp); glr=max(leer_num_local(tmp,{'GLR'},0),0);
      fgas=min(0.65,glr/(glr+120)); rhoeq=max(120,rho*(1-0.65*fgas));
      niv.TVD_m=max(0,tvdref-(Pwf-tmp.P_wh)/(rhoeq*9.80665));
      niv.MD_m=md_desde_tvd_local(survey,niv.TVD_m);
      niv.origen='INFERIDO_FLUJO_NATURAL_QINY_0'; niv.confianza='MEDIA';
      niv.Ql_natural_m3d=Ql*86400; niv.Pwf_natural_bar=Pwf/1e5;
      niv.mensaje='Nivel dinamico natural equivalente; no reemplaza una medicion estatica.'; return;
    endif
  catch err
    niv.mensaje=['Fallo inferencia Qiny=0: ' err.message];
  end_try_catch
  Dref=leer_num_local(p,{'D_res','D_packer','D_iny'},max(survey.MD)); rho=mezcla_local(p);
  niv.TVD_m=max(0,aos_tvd_at_md(survey,Dref)-(p.P_res-p.P_wh)/(rho*9.80665));
  niv.MD_m=md_desde_tvd_local(survey,niv.TVD_m);
  niv.origen='ESTIMACION_SIMPLIFICADA_PRESION_RESERVORIO'; niv.confianza='BAJA';
endfunction
function r=mezcla_local(p), wc=min(max(leer_num_local(p,{'WC'},0.5),0),1); r=leer_num_local(p,{'rho_o'},850)*(1-wc)+leer_num_local(p,{'rho_w'},1000)*wc; endfunction
function md=md_desde_tvd_local(s,t), [tv,ix]=unique(s.TVD(:)); mm=s.MD(ix); md=interp1(tv,mm,t,'linear','extrap'); md=max(min(md,max(s.MD)),min(s.MD)); endfunction
function v=leer_num_local(s,cs,d), v=d; for i=1:numel(cs), if isfield(s,cs{i}),x=s.(cs{i}); if isnumeric(x)&&~isempty(x)&&isfinite(x(1)),v=x(1);return;endif,endif,endfor,endfunction
