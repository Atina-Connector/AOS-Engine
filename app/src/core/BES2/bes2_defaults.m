function p = bes2_defaults(p)
% Defaults explícitos BES V2.
  if nargin<1||~isstruct(p),p=struct();endif
  if isfield(p,'bes_v2')&&isstruct(p.bes_v2),p=merge_local(p,p.bes_v2);endif
  if isfield(p,'D_bomba_m')&&isfinite(p.D_bomba_m),p.D_bomba=p.D_bomba_m;endif
  p=setdef(p,'bes2_bomba_file','config/BES_V2/catalogo/AOS_BES2_1500.txt');
  p=setdef(p,'D_bomba',getnum_local(p,{'D_intake','D_iny'},2000));
  p=setdef(p,'frecuencia',60);
  p=setdef(p,'frecuencia_base',60);
  p=setdef(p,'num_etapas',100);
  p=setdef(p,'bes2_eta_separador',0.70);
  p=setdef(p,'bes2_gvf_interferencia',0.10);
  p=setdef(p,'bes2_gvf_lock',0.25);
  p=setdef(p,'bes2_head_gas_a',1.8);
  p=setdef(p,'bes2_head_gas_b',2.5);
  p=setdef(p,'bes2_eta_gas_a',1.2);
  p=setdef(p,'bes2_n_puntos_solver',241);
  p=setdef(p,'bes2_tol_P_bar',0.05);
  p=setdef(p,'bes2_max_biseccion',60);
  p=setdef(p,'bes2_visc_screening',1);
  p=setdef(p,'OD_motor',0.114);
  p=setdef(p,'ID_casing',getnum_local(p,{'ID_casing','diam_casing'},0.157));
  p=setdef(p,'velocidad_min_refrig',0.30);
  p=setdef(p,'cp_fluido',3500);
  p=setdef(p,'modelo_IPR','linear');
  p=setdef(p,'modelo_VLP','DR');
  p=setdef(p,'T_sup',298.15);
  p=setdef(p,'T_fondo',358.15);
  p=setdef(p,'rho_o',850);
  p=setdef(p,'rho_w',1000);
  p=setdef(p,'rho_g_std',0.8);
  p=setdef(p,'GLR',0);
  p=setdef(p,'WC',0);
  p=setdef(p,'gamma_g',0.7);
  p=setdef(p,'API',35);
  p=aos_electrico_defaults(p);
  if ~isfinite(p.cable_longitud_m),p.cable_longitud_m=p.D_bomba;endif
endfunction

function o=merge_local(o,x)
  f=fieldnames(x);for i=1:numel(f),o.(f{i})=x.(f{i});endfor
endfunction

function s=setdef(s,f,v)
  if ~isfield(s,f)||isempty(s.(f)),s.(f)=v;endif
endfunction

function v=getnum_local(s,campos,defecto)
  v=defecto;
  for i=1:numel(campos)
    if isfield(s,campos{i})&&isnumeric(s.(campos{i}))&&~isempty(s.(campos{i}))&&isfinite(s.(campos{i})(1))
      v=s.(campos{i})(1);return;
    endif
  endfor
endfunction
