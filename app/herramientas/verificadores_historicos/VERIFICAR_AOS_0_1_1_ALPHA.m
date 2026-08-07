function VERIFICAR_AOS_0_1_1_ALPHA()
% Verificación no interactiva de arquitectura y ejecución básica.
  root=fileparts(mfilename('fullpath'));cd(root);addpath(fullfile(root,'src'),'-begin');addpath(fullfile(root,'src','menu'),'-begin');iniciar_aos;
  fprintf('\n=== VERIFICACION AOS 0.1.1 ALPHA ===\n');
  req={'bes2_solver','cgf_solver','egf_solver','aos_electrico_fondo_evaluar','jet_gas_gas_operar','AOS_menu_gas_fondo'};
  for i=1:numel(req),assert(exist(req{i},'file')==2,['Falta ' req{i}]);fprintf('[OK] %s\n',req{i});endfor

  p=base_liquido_local();s=bes2_solver(p);assert(isstruct(s)&&isfield(s,'estado'),'BES2 no devolvio estructura');assert(numel(s.barrido_Q_m3_d)>0,'BES2 sin barrido');fprintf('[OK] BES V2: %s | Ql %.2f m3/d\n',s.estado,s.Ql_m3_d);

  g=base_gas_local();c=cgf_solver(g);assert(isstruct(c)&&isfield(c,'estado'),'CGF no devolvio estructura');assert(numel(c.barrido_Q_Sm3_d)>0,'CGF sin barrido');fprintf('[OK] CGF: %s | Qg %.0f Sm3/d\n',c.estado,c.Qg_Sm3_d);

  e=egf_solver(g);assert(isstruct(e)&&isfield(e,'estado'),'EGF no devolvio estructura');assert(numel(e.barrido_Qs_Sm3_d)>0,'EGF sin barrido');fprintf('[OK] EGF: %s | Qs %.0f Sm3/d\n',e.estado,e.Qg_aspirado_Sm3_d);

  gp=aos_gas_props(100e5,330,g);assert(gp.rho>0&&gp.Z>0,'Propiedades gas invalidas');
  nz=aos_gas_flow_nozzle(140e5,330,60e5,2e-5,0.96,g);assert(nz.m_dot>=0,'Tobera invalida');
  fprintf('[OK] Gas real y tobera compresible.\n');
  fprintf('VERIFICACION AOS 0.1.1 ALPHA APROBADA.\n');
endfunction

function p=base_liquido_local()
  p=struct('P_res',180e5,'P_b',100e5,'IP',10/86400/1e5,'modelo_IPR','Vogel','modelo_VLP','DR', ...
    'P_wh',10e5,'D_res',2500,'D_bomba',1800,'WC',0.40,'GLR',80,'API',32,'gamma_g',0.72, ...
    'rho_o',860,'rho_w',1000,'rho_g_std',0.85,'T_sup',298.15,'T_fondo',363.15,'diam_tbg',0.062, ...
    'ID_casing',0.157,'rugosidad',4.6e-5,'frecuencia',60,'num_etapas',100, ...
    'bes2_bomba_file','config/BES_V2/catalogo/AOS_BES2_1500.txt','bes2_eta_separador',0.70);
  p.survey=survey_vertical_local(2500,0.062,0.157);
endfunction

function p=base_gas_local()
  p=struct('P_res',180e5,'P_wh',20e5,'D_res',3000,'D_cgf',1800,'D_egf',1800,'diam_tbg',0.062,'ID_casing',0.14,'rugosidad',4.6e-5, ...
    'gamma_g',0.68,'rho_g_std',0.82,'T_sup',293.15,'T_fondo',368.15,'gas_ipr_model','BACKPRESSURE','IP_gas_Sm3_d_bar',2500,'gas_ipr_n',0.8, ...
    'cgf_rpm',30000,'cgf_compresor_file','config/CGF/catalogo/AOS_CGF_AXIAL_PM_01.txt','cgf_Qliq_m3_d',2, ...
    'P_motriz_sup',140e5,'egf_P_fuente_sup',20e5,'egf_eyector_file','config/EGF/catalogo/AOS_EGF_GAS_GAS_01.txt');
  p.survey=survey_vertical_local(3000,0.062,0.14);
endfunction

function s=survey_vertical_local(D,idt,idc)
  s=struct();s.MD=[0;0.5*D;D];s.TVD=s.MD;s.inclinacion=[0;0;0];s.azimut=[0;0;0];s.ID_tubing=idt*ones(3,1);s.ID_casing=idc*ones(3,1);s.rugosidad=4.6e-5*ones(3,1);
endfunction
