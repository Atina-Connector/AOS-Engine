function c = cgf_cargar_compresor(param)
  p=cgf_defaults(param);f=p.cgf_compresor_file;if ~exist(f,'file'),error('CGF: no existe mapa %s',f);endif
  x=load_config(f);c=struct();c.archivo=f;c.modelo=gettext_local(x,{'modelo'},f);c.tipo=gettext_local(x,{'tipo'},'AXIAL_PM');c.origen=gettext_local(x,{'origen'},'DESCONOCIDO');
  c.rpm_base=getnum_local(x,{'rpm_base'},30000);c.rpm_min=getnum_local(x,{'rpm_min'},0.6*c.rpm_base);c.rpm_max=getnum_local(x,{'rpm_max'},1.4*c.rpm_base);
  c.Qcorr_Sm3_d=getvec_local(x,{'Qcorr_Sm3_d'});c.PR_base=getvec_local(x,{'PR_base'});c.eta_p=getvec_local(x,{'eta_p'});
  n=min([numel(c.Qcorr_Sm3_d),numel(c.PR_base),numel(c.eta_p)]);c.Qcorr_Sm3_d=c.Qcorr_Sm3_d(1:n);c.PR_base=c.PR_base(1:n);c.eta_p=c.eta_p(1:n);
  [c.Qcorr_Sm3_d,idx]=sort(c.Qcorr_Sm3_d);c.PR_base=c.PR_base(idx);c.eta_p=c.eta_p(idx);
  c.Q_surge=getnum_local(x,{'Q_surge_Sm3_d'},min(c.Qcorr_Sm3_d));c.Q_choke=getnum_local(x,{'Q_choke_Sm3_d'},max(c.Qcorr_Sm3_d));
  c.presion_max_bar=getnum_local(x,{'presion_max_bar'},350);c.temperatura_max_C=getnum_local(x,{'temperatura_max_C'},190);c.fraccion_liquida_max=getnum_local(x,{'fraccion_liquida_max'},0.03);
  c.motor_pm_potencia_nominal_kW=getnum_local(x,{'motor_pm_potencia_nominal_kW'},250);c.motor_pm_eta_nominal=getnum_local(x,{'motor_pm_eta_nominal'},0.94);c.motor_pm_rpm_nominal=getnum_local(x,{'motor_pm_rpm_nominal'},c.rpm_base);
endfunction
function v=getvec_local(s,c),v=[];for i=1:numel(c),if isfield(s,c{i})&&isnumeric(s.(c{i})),v=s.(c{i})(:);return;endif,endfor,endfunction
function v=getnum_local(s,c,d),v=d;for i=1:numel(c),if isfield(s,c{i})&&isnumeric(s.(c{i}))&&~isempty(s.(c{i}))&&isfinite(s.(c{i})(1)),v=s.(c{i})(1);return;endif,endfor,endfunction
function t=gettext_local(s,c,d),t=d;for i=1:numel(c),if isfield(s,c{i})&&ischar(s.(c{i})),t=strtrim(s.(c{i}));return;endif,endfor,endfunction
