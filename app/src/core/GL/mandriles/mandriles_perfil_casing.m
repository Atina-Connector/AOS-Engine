function prof = mandriles_perfil_casing(param, survey, Qstd_m3d, dinamico)
% Perfil anular de gas compresible integrado por pasos.
% En flujo descendente la friccion resta parte de la ganancia hidrostatica.
  if nargin < 4
    dinamico = false;
  endif
  p = mandriles_defaults(param);
  md = survey.MD(:);
  tvd = survey.TVD(:);
  n = numel(md);

  P = zeros(n,1);
  T = zeros(n,1);
  rho = zeros(n,1);
  fr = zeros(n,1);
  grad_h = zeros(n,1);
  P(1) = max(p.P_iny_sup, p.mand_Pstd_Pa);
  T(1) = p.mand_T_sup_K;

  Qstd = max(Qstd_m3d,0);
  if ~dinamico
    Qstd = 0;
  endif

  for i = 2:n
    dmd = max(md(i)-md(i-1),0);
    dtvd = tvd(i)-tvd(i-1);
    T1 = p.mand_T_sup_K + p.mand_grad_T_K_m * max(tvd(i-1),0);
    T2 = p.mand_T_sup_K + p.mand_grad_T_K_m * max(tvd(i),0);
    Tm = 0.5 * (T1 + T2);
    IDc = 0.5 * (survey.ID_casing(i-1) + survey.ID_casing(i));
    OD = min(p.mand_OD_tubing_m, IDc-1e-3);
    A = pi/4 * max(IDc^2-OD^2,1e-8);
    Dh = max(IDc-OD,1e-4);
    rug = 0.5 * (survey.rugosidad(i-1) + survey.rugosidad(i));

    P2 = P(i-1);
    dPf = 0;
    dPh = 0;
    for it = 1:5
      Pm = max(0.5*(P(i-1)+P2), p.mand_Pstd_Pa*0.25);
      fl = gas_anular_local(p, Pm, Tm, Dh, rug, A, Qstd);
      dPh = fl.rho * 9.80665 * dtvd;
      dPf = fl.grad_fric_Pa_m * dmd;
      nuevo = max(P(i-1) + dPh - dPf, p.mand_Pstd_Pa*0.25);
      P2 = 0.5*P2 + 0.5*nuevo;
    endfor
    P(i) = P2;
    T(i) = T2;
    rho(i-1) = fl.rho;
    fr(i) = dPf;
    if abs(dtvd) > 1e-12
      grad_h(i) = dPh/dtvd;
    endif
  endfor

  if n == 1
    T(1) = p.mand_T_sup_K;
  endif
  fln = gas_anular_local(p, P(end), max(T(end),220), ...
      max(survey.ID_casing(end)-p.mand_OD_tubing_m,1e-4), survey.rugosidad(end), ...
      pi/4*max(survey.ID_casing(end)^2-p.mand_OD_tubing_m^2,1e-8), Qstd);
  rho(end) = fln.rho;

  prof = struct('MD',md,'TVD',tvd,'P',P,'T',T,'rho',rho, ...
      'dP_fric',fr,'grad_hidro_Pa_m',grad_h,'dinamico',dinamico, ...
      'modelo','GAS_COMPRESIBLE_NUMERICO');
endfunction

function fl = gas_anular_local(p, P, T, Dh, rug, A, Qstd_m3d)
  Z = max(p.mand_Z_gas,0.20);
  Rgas = 287.05/max(p.mand_gamma_g,0.10);
  rho = P/(Z*Rgas*T);
  qstd = max(Qstd_m3d,0)/86400;
  q = qstd*(p.mand_Pstd_Pa/P)*(T/p.mand_Tstd_K)*Z;
  v = q/max(A,1e-12);
  Re = max(rho*abs(v)*Dh/max(p.mand_mu_gas_Pa_s,1e-8),1);
  if abs(v)<=1e-12
    f=0;
  elseif Re<2300
    f=64/Re;
  else
    f=0.25/(log10(rug/(3.7*Dh)+5.74/(Re^0.9))^2);
  endif
  fl=struct('rho',rho,'v',v,'Re',Re,'f',f, ...
      'grad_fric_Pa_m',f*0.5*rho*v^2/Dh);
endfunction
