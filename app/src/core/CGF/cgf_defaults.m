function p = cgf_defaults(p)
  if nargin<1||~isstruct(p),p=struct();endif
  if isfield(p,'cgf')&&isstruct(p.cgf),p=merge_local(p,p.cgf);endif
  if isfield(p,'D_cgf_m')&&isfinite(p.D_cgf_m),p.D_cgf=p.D_cgf_m;endif
  p=setdef(p,'cgf_compresor_file','config/CGF/catalogo/AOS_CGF_AXIAL_PM_01.txt');
  p=setdef(p,'D_cgf',getnum_local(p,{'D_bomba','D_iny'},1500));
  p=setdef(p,'cgf_rpm',30000);
  p=setdef(p,'gas_ipr_model','BACKPRESSURE');
  p=setdef(p,'gas_ipr_C_Sm3_d_bar2n',NaN);
  p=setdef(p,'gas_ipr_n',0.80);
  p=setdef(p,'IP_gas_Sm3_d_bar',1500);
  p=setdef(p,'cgf_n_puntos_solver',241);
  p=setdef(p,'cgf_tol_P_bar',0.05);
  p=setdef(p,'cgf_max_biseccion',60);
  p=setdef(p,'cgf_Qliq_m3_d',0);
  p=setdef(p,'cgf_rho_liq',850);
  p=setdef(p,'diam_tbg',0.062);
  p=setdef(p,'D_res',2500);
  p=setdef(p,'P_res',200e5);
  p=setdef(p,'P_wh',10e5);
  p=setdef(p,'gamma_g',0.7);
  p=setdef(p,'T_sup',298.15);
  p=setdef(p,'T_fondo',358.15);
  p=setdef(p,'motor_pm_rpm_nominal',p.cgf_rpm);
  p=setdef(p,'motor_pm_potencia_nominal_kW',250);
  p=setdef(p,'OD_motor',0.12);
  p=setdef(p,'ID_casing',0.157);
  p=aos_electrico_defaults(p);
  if ~isfinite(p.cable_longitud_m),p.cable_longitud_m=p.D_cgf;endif
endfunction
function o=merge_local(o,x),f=fieldnames(x);for i=1:numel(f),o.(f{i})=x.(f{i});endfor,endfunction
function s=setdef(s,f,v),if ~isfield(s,f)||isempty(s.(f)),s.(f)=v;endif,endfunction
function v=getnum_local(s,c,d),v=d;for i=1:numel(c),if isfield(s,c{i})&&isnumeric(s.(c{i}))&&~isempty(s.(c{i}))&&isfinite(s.(c{i})(1)),v=s.(c{i})(1);return;endif,endfor,endfunction
