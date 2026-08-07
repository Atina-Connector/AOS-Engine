function e = aos_balance_energia_sla(tipo,param,Ql,Qo,Qiny,sol)
% AOS_BALANCE_ENERGIA_SLA
% Balance energetico transversal con frontera en el dispositivo de fondo.
% No usa Pwh como sustituto de la presion de descarga del SLA.
%
% tipo : GL, JGL, BES, BES2, BM, CGF o EGF
% Ql   : caudal liquido local [m3/s]
% Qo   : caudal de petroleo [m3/s]
% Qiny : gas inyectado/motriz estandar [Sm3/s]
% sol  : resultado estructurado opcional del modulo
%
% La salida separa:
%   - potencia_util_fondo_kW: energia transferida al fluido en el SLA
%   - potencia_entrada_kW: energia suministrada al SLA/sistema
%   - eficiencia_dispositivo_pct
%   - eficiencia_sistema_fondo_pct
%
% Modelo de screening auditable. Para gases se utilizan balances de entalpia
% o potencia compresora equivalente, nunca Qgas_std sumado a Ql.

  if nargin < 6 || ~isstruct(sol), sol = struct(); endif
  if nargin < 5 || isempty(Qiny), Qiny = 0; endif
  if nargin < 4 || isempty(Qo), Qo = NaN; endif
  if nargin < 3 || isempty(Ql), Ql = 0; endif
  if nargin < 2 || ~isstruct(param), param = struct(); endif
  if nargin < 1 || isempty(tipo), tipo = 'GENERAL'; endif

  t = upper(strtrim(tipo));
  e = base_local(t,param,Ql,Qo,Qiny);

  switch t
    case {'GL','JGL'}
      e = energia_gl_jgl_local(e,t,param,Ql,Qiny,sol);
    case {'BES','BES2','BES_V2'}
      e = energia_bes_local(e,param,Ql,sol);
    case 'BM'
      e = energia_bm_local(e,param,Ql,sol);
    case 'CGF'
      e = energia_cgf_local(e,param,sol);
    case 'EGF'
      e = energia_egf_local(e,param,sol);
    otherwise
      e.estado = 'NO_IMPLEMENTADO';
      e.advertencias{end+1} = ['Balance no implementado para ' t];
  endswitch

  e = finalizar_local(e);
endfunction

function e = energia_gl_jgl_local(e,t,p,Ql,Qiny,s)
% Indice energetico de fondo propuesto para GL/JGL:
%   I = [(Ql_local + Qg_producido_local) * P_arriba_SLA] /
%       [ Qg_inyectado_local * P_inyeccion_SLA ]
% Todos los caudales gaseosos se convierten desde condiciones estandar a
% condiciones locales de fondo antes de efectuar la relacion.

  D = num_local(p,{'D_iny','D_valvula','D_eductor'},NaN);
  e.profundidad_frontera_MD_m = D;

  % Presion de la corriente producida inmediatamente por encima del SLA.
  Pout = num_local(s,{'Pd','P_descarga','Pdesc_req_Pa','audit.P_req','audit.balance.P_req'},NaN);
  if ~isfinite(Pout) && strcmp(t,'GL')
    Pout = num_local(s,{'Ps','P_succion','audit.P_s','audit.balance.P_s'},NaN);
  endif
  if ~isfinite(Pout) && isfinite(D)
    try
      qgform = max(Ql,0)*num_local(p,{'GLR'},0);
      [Pout,~] = compute_P_req(p,max(Ql,0),max(Qiny,0)+qgform,D);
    catch
      Pout = NaN;
    end_try_catch
  endif

  % Presion del gas de inyeccion inmediatamente antes del dispositivo.
  Pinj = num_local(s,{'Pm','P_motriz','audit.Pm','audit.balance.Pm'},NaN);
  if ~isfinite(Pinj)
    try, Pinj = jgl_presion_motriz_fondo(p,max(Qiny,0)); catch, Pinj = NaN; end_try_catch
  endif
  if ~isfinite(Pinj), Pinj = num_local(p,{'P_iny_fondo','P_iny_sup'},NaN); endif

  % Presion de succion se conserva solo como dato diagnostico del dispositivo.
  Ps = num_local(s,{'Ps','P_succion','Pintake_Pa','audit.P_s','audit.balance.P_s'},NaN);
  if ~isfinite(Ps)
    try, Ps = calcular_columna_succion(max(Ql,0),p); catch, Ps = NaN; end_try_catch
  endif

  Tloc = temperatura_local_local(p,D);
  Qgprod_std = max(Ql,0) * max(num_local(p,{'GLR'},0),0);
  Qgprod_loc = gas_std_a_local_local(Qgprod_std,Pout,Tloc,p);
  Qiny_loc = gas_std_a_local_local(max(Qiny,0),Pinj,Tloc,p);
  Bo = max(num_local(p,{'Bo','B_o'},1.0),0.05);
  Ql_loc = max(Ql,0) * Bo;
  Qprod_loc = Ql_loc + max(Qgprod_loc,0);

  e.P_succion_Pa = Ps;
  e.P_descarga_Pa = Pout;
  e.P_entrada_SLA_Pa = Pinj;
  e.Ql_fondo_m3_s = Ql_loc;
  e.Qg_producido_fondo_m3_s = Qgprod_loc;
  e.Qiny_fondo_m3_s = Qiny_loc;
  e.Qtotal_producido_fondo_m3_s = Qprod_loc;

  if isfinite(Pout) && Pout>0 && isfinite(Qprod_loc)
    e.potencia_flujo_producido_fondo_kW = Qprod_loc*Pout/1000;
    e.potencia_util_fondo_kW = e.potencia_flujo_producido_fondo_kW;
  endif
  if isfinite(Pinj) && Pinj>0 && isfinite(Qiny_loc)
    e.potencia_flujo_inyectado_fondo_kW = Qiny_loc*Pinj/1000;
    e.potencia_entrada_kW = e.potencia_flujo_inyectado_fondo_kW;
  endif

  if isfinite(e.potencia_entrada_kW) && e.potencia_entrada_kW>1e-12 && ...
      isfinite(e.potencia_util_fondo_kW)
    e.indice_energetico_bruto_pct = 100*e.potencia_util_fondo_kW/e.potencia_entrada_kW;
    e.indice_energetico_bruto_fondo_pct = e.indice_energetico_bruto_pct;
    e.estado_indice_energetico_bruto = 'OK';
    % Alias historico: para GL/JGL este campo representa el indice bruto, no la eficiencia interna del jet.
    e.eficiencia_sistema_fondo_pct = e.indice_energetico_bruto_pct;
  else
    e.indice_energetico_bruto_pct = NaN;
    e.indice_energetico_bruto_fondo_pct = NaN;
    if max(Qiny,0)<=1e-12
      e.estado_indice_energetico_bruto='NO_APLICABLE_QINY_CERO';
      e.advertencias{end+1}='Qiny=0: indice energetico de fondo no aplicable.';
    else
      e.estado_indice_energetico_bruto='NO_EVALUABLE';
      e.advertencias{end+1}='No fue posible evaluar caudal o presion local del gas inyectado.';
    endif
  endif

  e.metodo_entrada = 'QINY_FONDO_X_PINY_FONDO';
  e.metodo_util = '(QL_FONDO+QG_PRODUCIDO_FONDO)_X_P_ARRIBA_SLA';
  e.metodo_indice = 'INDICE_BRUTO_QP_PRODUCIDO_FONDO_SOBRE_QP_INYECTADO_FONDO';
  e.nivel_confianza = 'SCREENING_CAUSALES_LOCALES';

  if strcmp(t,'JGL')
    Pdisp = num_local(s,{'potencia_disponible','pot_disp'},NaN);
    Ptrans = num_local(s,{'potencia_transferida','pot_trans'},NaN);
    if isfield(s,'eductor') && isstruct(s.eductor)
      if ~isfinite(Pdisp), Pdisp=num_local(s.eductor,{'pot_disp'},NaN); endif
      if ~isfinite(Ptrans), Ptrans=num_local(s.eductor,{'pot_trans'},NaN); endif
    endif
    e.potencia_disponible_dispositivo_kW = Pdisp/1000;
    e.potencia_transferida_dispositivo_kW = Ptrans/1000;
    if isfinite(Pdisp) && Pdisp>0 && isfinite(Ptrans)
      e.eficiencia_dispositivo_pct = 100*max(Ptrans,0)/Pdisp;
      e.eficiencia_interna_jet_pct = e.eficiencia_dispositivo_pct;
      e.estado_eficiencia_interna_jet = 'OK';
      e.metodo_eficiencia_dispositivo = 'POT_TRANSFERIDA/POT_DISPONIBLE_EDUCTOR';
    else
      e.estado_eficiencia_interna_jet='NO_EVALUABLE';
    endif
  else
    % Alias historico de GL. No existe eficiencia interna de jet en GL.
    e.eficiencia_dispositivo_pct = e.indice_energetico_bruto_pct;
    e.eficiencia_interna_jet_pct = NaN;
    e.estado_eficiencia_interna_jet = 'NO_APLICABLE_GL';
    e.metodo_eficiencia_dispositivo = 'INDICE_ENERGETICO_BRUTO_FONDO_GL';
  endif
endfunction

function e = energia_bes_local(e,p,Ql,s)
  punto = s;
  if isfield(s,'punto') && isstruct(s.punto), punto=s.punto; endif
  D = num_local(p,{'D_bomba','D_intake'},NaN);
  e.profundidad_frontera_MD_m = D;
  Pint = num_local(punto,{'Pintake_Pa','P_intake','Pintake'},NaN);
  Pdesc = num_local(punto,{'Pdesc_req_Pa','P_descarga_req','Pdescarga_Pa'},NaN);
  dP = num_local(punto,{'dP_bomba_Pa','deltaP_bomba_Pa'},NaN);
  if ~isfinite(dP) && isfinite(Pint) && isfinite(Pdesc), dP=max(Pdesc-Pint,0); endif
  if ~isfinite(Pdesc) && isfinite(Pint) && isfinite(dP), Pdesc=Pint+dP; endif
  e.P_succion_Pa=Pint;e.P_descarga_Pa=Pdesc;e.deltaP_util_Pa=dP;
  if isfinite(dP), e.potencia_util_fondo_kW=max(Ql,0)*max(dP,0)/1000; endif
  Peje=num_local(punto,{'P_eje_kW'},NaN);
  if isfield(s,'electrico') && isstruct(s.electrico)
    e.potencia_entrada_kW=num_local(s.electrico,{'P_superficie_kW'},NaN);
  endif
  if ~isfinite(e.potencia_entrada_kW), e.potencia_entrada_kW=Peje; endif
  if isfinite(Peje) && Peje>0
    e.eficiencia_dispositivo_pct=100*e.potencia_util_fondo_kW/Peje;
  endif
  e.metodo_util='QL_INTAKE_X_DELTA_P_BOMBA';
  e.metodo_entrada='POTENCIA_ELECTRICA_SUPERFICIE_O_EJE';
  e.metodo_eficiencia_dispositivo='P_HIDRAULICA/P_EJE';
endfunction

function e = energia_bm_local(e,p,Ql,s)
  D=num_local(p,{'D_bomba'},NaN);e.profundidad_frontera_MD_m=D;
  Pint=num_local(s,{'P_intake','Pintake_Pa','P_wf'},NaN);
  if isfield(s,'detalle')&&isstruct(s.detalle),Pint=num_local(s.detalle,{'P_intake','P_wf'},Pint);endif
  Pdesc=NaN;
  if isfinite(D)
    try,[Pdesc,~]=compute_P_req(p,max(Ql,0),max(Ql,0)*num_local(p,{'GLR'},0),D);catch,Pdesc=NaN;end_try_catch
  endif
  e.P_succion_Pa=Pint;e.P_descarga_Pa=Pdesc;
  if isfinite(Pdesc)&&isfinite(Pint)
    e.deltaP_util_Pa=max(Pdesc-Pint,0);
    e.potencia_util_fondo_kW=max(Ql,0)*e.deltaP_util_Pa/1000;
  endif
  e.potencia_entrada_kW=num_local(s,{'potencia_eje_kW','potencia_superficie_kW'},NaN);
  e.metodo_util='QL_BOMBA_X_(PDESC_BOMBA-PSUCCION_BOMBA)';
  e.metodo_entrada='POTENCIA_MECANICA_BARRA_O_MOTOR';
endfunction

function e = energia_cgf_local(e,p,s)
  punto=s;if isfield(s,'punto')&&isstruct(s.punto),punto=s.punto;endif
  e.profundidad_frontera_MD_m=num_local(p,{'D_cgf'},NaN);
  e.P_succion_Pa=num_local(punto,{'Ps_Pa','Ps'},NaN);
  e.P_descarga_Pa=num_local(punto,{'Pd_Pa','Pd_pred','Pd'},NaN);
  e.potencia_util_fondo_kW=num_local(punto,{'P_gas_kW','Pgas_kW'},NaN);
  e.potencia_entrada_kW=num_local(punto,{'P_eje_kW'},NaN);
  if isfield(s,'electrico')&&isstruct(s.electrico),e.potencia_entrada_kW=num_local(s.electrico,{'P_superficie_kW'},e.potencia_entrada_kW);endif
  e.eficiencia_dispositivo_pct=100*num_local(punto,{'mapa.eta_p'},NaN);
  if isfield(punto,'mapa')&&isstruct(punto.mapa),e.eficiencia_dispositivo_pct=100*num_local(punto.mapa,{'eta_p'},NaN);endif
  e.metodo_util='MDOT_X_DELTA_ENTALPIA_GAS';
  e.metodo_entrada='POTENCIA_EJE_O_ELECTRICA';
  e.metodo_eficiencia_dispositivo='EFICIENCIA_POLITROPICA_MAPA';
endfunction

function e = energia_egf_local(e,p,s)
  punto=s;if isfield(s,'punto')&&isstruct(s.punto),punto=s.punto;endif
  e.profundidad_frontera_MD_m=num_local(p,{'D_egf'},NaN);
  e.P_succion_Pa=num_local(punto,{'Ps_Pa','Ps'},NaN);
  e.P_descarga_Pa=num_local(punto,{'Pd_Pa','Pd_pred','Pd'},NaN);
  e.potencia_entrada_kW=num_local(punto,{'P_equivalente_kW','P_eq_kW','P_equiv_superficie_kW'},NaN);
  e.potencia_util_fondo_kW=num_local(punto,{'P_util_aspirada_kW'},NaN);
  if ~isfinite(e.potencia_util_fondo_kW)
    % Si no hay balance entalpico completo, no inventar Q*Pwh.
    e.advertencias{end+1}='EGF: potencia util no disponible sin balance entalpico de la corriente aspirada.';
  endif
  e.metodo_util='DELTA_ENTALPIA_CORRIENTE_ASPIRADA';
  e.metodo_entrada='POTENCIA_EQUIVALENTE_GAS_MOTRIZ';
  e.metodo_eficiencia_dispositivo='P_UTIL_ASPIRADA/P_EQ_MOTRIZ';
endfunction

function e = finalizar_local(e)
  es_gl_jgl=any(strcmp(e.sistema,{'GL','JGL'}));
  if ~es_gl_jgl && isfinite(e.potencia_entrada_kW) && e.potencia_entrada_kW>1e-12 && isfinite(e.potencia_util_fondo_kW)
    e.eficiencia_sistema_fondo_pct=100*max(e.potencia_util_fondo_kW,0)/e.potencia_entrada_kW;
  endif
  if ~es_gl_jgl && ~isfinite(e.eficiencia_dispositivo_pct) && isfinite(e.eficiencia_sistema_fondo_pct)
    e.eficiencia_dispositivo_pct=e.eficiencia_sistema_fondo_pct;
  endif
  if es_gl_jgl
    if ~isfinite(e.indice_energetico_bruto_fondo_pct) && isfinite(e.indice_energetico_bruto_pct)
      e.indice_energetico_bruto_fondo_pct=e.indice_energetico_bruto_pct;
    endif
    e.eficiencia_sistema_fondo_pct=e.indice_energetico_bruto_fondo_pct;
  endif
  if isfinite(e.P_descarga_Pa)&&isfinite(e.P_succion_Pa)
    e.deltaP_util_Pa=max(e.P_descarga_Pa-e.P_succion_Pa,0);
  endif
  if isfinite(e.potencia_util_fondo_kW),e.estado='EVALUADO';else,e.estado='PARCIAL';endif
endfunction

function e=base_local(t,p,Ql,Qo,Qiny)
  e=struct('version','AOS_ENERGIA_SLA_FONDO_1_2_CONTRATO_CANONICO','sistema',t,'estado','NO_EVALUADO', ...
    'profundidad_frontera_MD_m',NaN,'profundidad_frontera_TVD_m',NaN, ...
    'P_succion_Pa',NaN,'P_descarga_Pa',NaN,'P_entrada_SLA_Pa',NaN,'deltaP_util_Pa',NaN, ...
    'Ql_local_m3_s',Ql,'Qo_m3_s',Qo,'Qiny_std_m3_s',Qiny, ...
    'Ql_fondo_m3_s',NaN,'Qg_producido_fondo_m3_s',NaN,'Qiny_fondo_m3_s',NaN, ...
    'Qtotal_producido_fondo_m3_s',NaN, ...
    'potencia_entrada_kW',NaN,'potencia_util_fondo_kW',NaN, ...
    'potencia_flujo_producido_fondo_kW',NaN,'potencia_flujo_inyectado_fondo_kW',NaN, ...
    'indice_energetico_bruto_pct',NaN,'indice_energetico_bruto_fondo_pct',NaN, ...
    'estado_indice_energetico_bruto','NO_EVALUADO','metodo_indice','', ...
    'potencia_disponible_dispositivo_kW',NaN,'potencia_transferida_dispositivo_kW',NaN, ...
    'eficiencia_dispositivo_pct',NaN,'eficiencia_sistema_fondo_pct',NaN, ...
    'eficiencia_interna_jet_pct',NaN,'estado_eficiencia_interna_jet','NO_APLICABLE', ...
    'metodo_util','','metodo_entrada','','metodo_eficiencia_dispositivo','', ...
    'nivel_confianza','SCREENING_AUDITABLE','advertencias',{{}});
  D=num_local(p,{'D_iny','D_bomba','D_cgf','D_egf'},NaN);
  if isfinite(D)
    try,e.profundidad_frontera_TVD_m=aos_tvd_at_md(num_struct_local(p,'survey'),D);catch,e.profundidad_frontera_TVD_m=D;end_try_catch
  endif
endfunction

function PkW=potencia_compresion_gas_local(Qstd,p,P2,eta)
  PkW=NaN;if ~isfinite(Qstd)||Qstd<=0,PkW=0;return;endif
  if ~isfinite(P2)||P2<=101325,PkW=0;return;endif
  rho=num_local(p,{'rho_g_std'},0.85);mdot=Qstd*rho;
  cp=num_local(p,{'cp_gas'},2300);T=num_local(p,{'T_sup'},298.15);if T<150,T=T+273.15;endif
  k=num_local(p,{'k_gas','gamma_adiabatico'},1.30);eta=max(min(eta,1),0.05);
  ratio=max(P2/101325,1);
  PkW=mdot*cp*T*(ratio^((k-1)/k)-1)/eta/1000;
endfunction

function qloc=gas_std_a_local_local(qstd,P,T,p)
  qloc=NaN;
  if ~isfinite(qstd),return;endif
  if qstd<=0,qloc=0;return;endif
  if ~isfinite(P)||P<=0||~isfinite(T)||T<=0,return;endif
  try
    gp=aos_gas_props(P,T,p);
    qloc=qstd*(gp.Pstd/P)*(T/gp.Tstd)*gp.Z;
  catch
    Pstd=num_local(p,{'P_std','Pstd'},101325);
    Tstd=num_local(p,{'T_std','Tstd'},288.15);
    Z=max(num_local(p,{'Z_gas'},0.90),0.20);
    qloc=qstd*(Pstd/P)*(T/Tstd)*Z;
  end_try_catch
endfunction

function T=temperatura_local_local(p,D)
  Ts=num_local(p,{'T_sup','T_cabeza_K'},298.15);if Ts<150,Ts=Ts+273.15;endif
  Tf=num_local(p,{'T_fondo','T_res','T_res_K'},Ts);if Tf<150,Tf=Tf+273.15;endif
  Dr=max(num_local(p,{'D_res','D_reservorio','prof_res'},max(D,1)),1);
  if ~isfinite(D),T=Ts;else,T=Ts+(Tf-Ts)*min(max(D/Dr,0),1);endif
endfunction

function v=num_local(s,nombres,d)
  v=d;if ~isstruct(s),return;endif
  if ischar(nombres),nombres={nombres};endif
  for i=1:numel(nombres)
    n=nombres{i};
    if ~isempty(strfind(n,'.'))
      partes=strsplit(n,'.');x=s;ok=true;
      for j=1:numel(partes),if isstruct(x)&&isfield(x,partes{j}),x=x.(partes{j});else,ok=false;break;endif,endfor
      if ok&&isnumeric(x)&&~isempty(x)&&isfinite(x(1)),v=x(1);return;endif
    elseif isfield(s,n)
      x=s.(n);if isnumeric(x)&&~isempty(x)&&isfinite(x(1)),v=x(1);return;endif
    endif
  endfor
endfunction
function x=num_struct_local(s,n),x=struct();if isstruct(s)&&isfield(s,n)&&isstruct(s.(n)),x=s.(n);endif,endfunction
