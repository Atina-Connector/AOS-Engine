function p=egf_defaults(p)
  if nargin<1||~isstruct(p),p=struct();endif
  if isfield(p,'egf')&&isstruct(p.egf),p=merge_local(p,p.egf);endif
  if isfield(p,'D_egf_m')&&isfinite(p.D_egf_m),p.D_egf=p.D_egf_m;endif
  if isfield(p,'P_motriz_sup_bar')&&isfinite(p.P_motriz_sup_bar),p.P_motriz_sup=p.P_motriz_sup_bar*1e5;endif
  if isfield(p,'egf_P_fuente_sup_bar')&&isfinite(p.egf_P_fuente_sup_bar),p.egf_P_fuente_sup=p.egf_P_fuente_sup_bar*1e5;endif
  p=setdef(p,'egf_eyector_file','config/EGF/catalogo/AOS_EGF_GAS_GAS_01.txt');
  p=setdef(p,'D_egf',getnum_local(p,{'D_iny','D_bomba'},1500));
  p=setdef(p,'P_motriz_sup',getnum_local(p,{'P_iny_sup'},120e5));
  p=setdef(p,'egf_P_fuente_sup',getnum_local(p,{'P_wh'},10e5));
  p=setdef(p,'egf_eta_comp_superficie',0.75);
  p=setdef(p,'gas_ipr_model','BACKPRESSURE');p=setdef(p,'IP_gas_Sm3_d_bar',1500);p=setdef(p,'gas_ipr_n',0.8);p=setdef(p,'gas_ipr_C_Sm3_d_bar2n',NaN);
  p=setdef(p,'egf_n_puntos_solver',121);p=setdef(p,'egf_tol_P_bar',0.10);p=setdef(p,'egf_max_biseccion',50);
  p=setdef(p,'diam_tbg',0.062);p=setdef(p,'OD_tubing',0.073);p=setdef(p,'ID_casing',0.14);p=setdef(p,'D_res',2500);p=setdef(p,'P_res',200e5);p=setdef(p,'P_wh',10e5);p=setdef(p,'gamma_g',0.7);p=setdef(p,'T_sup',298.15);p=setdef(p,'T_fondo',358.15);
endfunction
function o=merge_local(o,x),f=fieldnames(x);for i=1:numel(f),o.(f{i})=x.(f{i});endfor,endfunction
function s=setdef(s,f,v),if ~isfield(s,f)||isempty(s.(f)),s.(f)=v;endif,endfunction
function v=getnum_local(s,c,d),v=d;for i=1:numel(c),if isfield(s,c{i})&&isnumeric(s.(c{i}))&&~isempty(s.(c{i}))&&isfinite(s.(c{i})(1)),v=s.(c{i})(1);return;endif,endfor,endfunction
