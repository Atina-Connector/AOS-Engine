function prof = mandriles_perfil_tubing_unloading(param, survey, nivel_inicial, prof_activa, Qg_std_m3d, Ql_m3d)
% Perfil de tubing por tramos con propiedades dependientes de presion.
%
% Etapa inicial:
%   gas estatico desde cabeza hasta el nivel inicial y liquido por debajo.
% Etapa de unloading:
%   mezcla gas-liquido desde cabeza hasta la valvula activa y liquido por
%   debajo. La integracion se hace hacia abajo; para flujo ascendente la
%   friccion se suma a la presion requerida en profundidad.
  p = mandriles_defaults(param);
  if nargin < 5 || isempty(Qg_std_m3d) || ~isfinite(Qg_std_m3d)
    Qg_std_m3d = leer_qg_local(p);
  endif
  if nargin < 6 || isempty(Ql_m3d) || ~isfinite(Ql_m3d)
    Ql_m3d = leer_ql_local(p);
  endif

  md = survey.MD(:);
  tvd = survey.TVD(:);
  n = numel(md);
  P = zeros(n,1);
  T = zeros(n,1);
  rho = zeros(n,1);
  alpha_l = zeros(n,1);
  fr = zeros(n,1);
  fase = cell(n,1);
  P(1) = max(p.P_wh, p.mand_Pstd_Pa*0.25);
  T(1) = p.mand_T_sup_K;

  inicial = prof_activa <= nivel_inicial + max(1,p.mand_paso_integracion_m);
  for i = 2:n
    dmd = max(md(i)-md(i-1),0);
    dtvd = tvd(i)-tvd(i-1);
    mdm = 0.5*(md(i)+md(i-1));
    T1 = p.mand_T_sup_K + p.mand_grad_T_K_m*max(tvd(i-1),0);
    T2 = p.mand_T_sup_K + p.mand_grad_T_K_m*max(tvd(i),0);
    Tm = 0.5*(T1+T2);
    ID = 0.5*(survey.ID_tubing(i-1)+survey.ID_tubing(i));
    rug = 0.5*(survey.rugosidad(i-1)+survey.rugosidad(i));

    if inicial
      if mdm <= nivel_inicial
        fase_i = 'GAS';
        qg_i = 0;
        ql_i = 0;
      else
        fase_i = 'LIQUIDO';
        qg_i = 0;
        ql_i = 0;
      endif
    else
      if mdm <= prof_activa
        fase_i = 'MEZCLA';
        qg_i = max(Qg_std_m3d,0);
        ql_i = max(Ql_m3d,0);
      else
        fase_i = 'LIQUIDO';
        qg_i = 0;
        ql_i = max(Ql_m3d,0);
      endif
    endif

    P2 = P(i-1);
    dPh = 0;
    dPf = 0;
    for it = 1:5
      Pm = max(0.5*(P(i-1)+P2),p.mand_Pstd_Pa*0.25);
      fl = mandriles_propiedades_locales(p,Pm,Tm,ID,rug,qg_i,ql_i,fase_i);
      dPh = fl.rho*9.80665*dtvd;
      if inicial
        dPf = 0;
      else
        dPf = fl.grad_fric_Pa_m*dmd;
      endif
      nuevo = max(P(i-1)+dPh+dPf,p.mand_Pstd_Pa*0.25);
      P2 = 0.5*P2+0.5*nuevo;
    endfor

    P(i)=P2;
    T(i)=T2;
    rho(i-1)=fl.rho;
    alpha_l(i-1)=fl.alpha_l;
    fr(i)=dPf;
    fase{i-1}=fase_i;
  endfor

  if inicial
    metodo='INICIAL_GAS_COMPRESIBLE_MAS_COLUMNA_LIQUIDA';
  else
    metodo='UNLOADING_HOMOGENEO_COMPRESIBLE_POR_TRAMOS';
  endif
  if n>1
    rho(end)=rho(end-1);
    alpha_l(end)=alpha_l(end-1);
    fase{end}=fase{end-1};
  else
    fase{1}='GAS';
  endif

  prof=struct('MD',md,'TVD',tvd,'P',P,'T',T,'rho',rho, ...
      'alpha_l',alpha_l,'dP_fric',fr,'fase',{fase}, ...
      'nivel_inicial_m',nivel_inicial,'profundidad_activa_m',prof_activa, ...
      'Qg_std_m3d',Qg_std_m3d,'Ql_m3d',Ql_m3d,'metodo',metodo);
endfunction

function q = leer_qg_local(p)
  q = 0;
  if isfield(p,'mand_Qg_unloading_m3d') && isnumeric(p.mand_Qg_unloading_m3d) && ...
      isscalar(p.mand_Qg_unloading_m3d) && isfinite(p.mand_Qg_unloading_m3d)
    q = max(p.mand_Qg_unloading_m3d,0);
  endif
endfunction

function q = leer_ql_local(p)
  q = 0;
  if isfield(p,'mand_Ql_diseno_m3d') && isnumeric(p.mand_Ql_diseno_m3d) && ...
      isscalar(p.mand_Ql_diseno_m3d) && isfinite(p.mand_Ql_diseno_m3d)
    q = max(p.mand_Ql_diseno_m3d,0);
  endif
endfunction
