function [P_req, MD_out, P_out] = vlp_simplified_corregida(param, Ql, Qg_total_std, profundidad_MD, survey)
  % vlp_simplified_corregida.m
  % Fallback VLP estable cuando no se quiere usar HB/DR o no hay survey real.
  % A diferencia del fallback anterior, usa gas local, Bo, fricción simple
  % y geometría MD/TVD aunque el survey sea sintético vertical.

  p = aos_vlp_parametros(param);
  if nargin < 5
    survey = [];
  end
  survey = aos_vlp_normalizar_survey(survey, p, profundidad_MD);

  % Integrador tipo drift-flux general. No lo presentamos como correlación
  % de validación; solo como fallback físico mínimo.
  modelo = 'simplified';
  g = 9.81;
  eps_num = 1e-12;
  max_iter = 12;
  tol = 1e-4;

  MD = survey.MD(:);
  TVD = survey.TVD(:);
  ID = survey.ID_tubing(:);
  incl = survey.inclinacion(:);
  rug = survey.rugosidad(:);
  T = aos_vlp_temperatura(TVD, p.T_sup, p.T_fondo);

  P = zeros(size(MD));
  P(1) = p.P_wh;
  for seg = 2:length(MD)
    dL = MD(seg) - MD(seg-1);
    dz = TVD(seg) - TVD(seg-1);
    if dL <= 0
      P(seg) = P(seg-1);
      continue;
    end
    d = max((ID(seg-1) + ID(seg)) / 2, 1e-4);
    A = pi * (d/2)^2;
    T_avg = max((T(seg-1) + T(seg)) / 2, 250);
    incl_avg = (incl(seg-1) + incl(seg)) / 2;
    eps_abs = max((rug(seg-1) + rug(seg)) / 2, 1e-8);
    P_old = max(P(seg-1) + 500 * g * dz, p.P_std);

    for iter = 1:max_iter
      P_avg = max((P(seg-1) + P_old) / 2, p.P_std);
      fl = aos_vlp_propiedades_locales(p, P_avg, T_avg, Ql, Qg_total_std);
      vsl = max(fl.Ql_local / A, eps_num);
      vsg = max(fl.Qg_local / A, 0);
      vm = max(vsl + vsg, eps_num);
      [HL, ~] = aos_vlp_holdup_drift_flux(vsl, vsg, d, fl.rho_l, fl.rho_g, incl_avg);
      rho_m = fl.rho_l * HL + fl.rho_g * (1 - HL);
      mu_m = max(fl.mu_l * HL + fl.mu_g * (1 - HL), 1e-6);
      Re = max(rho_m * vm * d / mu_m, 1);
      f = aos_vlp_friccion(Re, eps_abs / d);
      P_new = max(P(seg-1) + rho_m * g * dz + f * rho_m * vm^2 / (2*d) * dL, p.P_std);
      if abs(P_new - P_old) / max(P_new, p.P_std) < tol
        P_old = P_new;
        break;
      end
      P_old = P_new;
    end
    P(seg) = P_old;
  end

  P_req = interp1(MD, P, profundidad_MD, 'linear', 'extrap');
  MD_out = MD;
  P_out = P;
end
