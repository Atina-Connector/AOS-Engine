function [P_req, MD_out, P_out, diag] = aos_vlp_integrar(param, survey, Ql, Qg, modelo)
  % aos_vlp_integrar.m
  % Integrador común para HB y Duns & Ros corregidos.
  %
  % Geometría corregida:
  %   dP_hidro = rho_m * g * dTVD
  %   dP_fric  = grad_fric * dMD
  % No se multiplica hidrostática por cos(theta) si ya se usa dTVD.

  p = aos_vlp_parametros(param);
  survey = aos_vlp_normalizar_survey(survey, p, []);

  g = 9.81;
  eps_num = 1e-12;
  max_iter = 20;
  tol = 1e-4;

  MD = survey.MD(:);
  TVD = survey.TVD(:);
  ID = survey.ID_tubing(:);
  incl = survey.inclinacion(:);
  rug = survey.rugosidad(:);
  n = length(MD);

  T = aos_vlp_temperatura(TVD, p.T_sup, p.T_fondo);

  P = zeros(n, 1);
  P(1) = p.P_wh;

  % Inicialización hidrostática simple con líquido, para que la iteración no
  % arranque con columna de metano liviana cuando gamma_g es alto.
  rho_l_ini = p.rho_o * (1 - p.WC) + p.rho_w * p.WC;
  for k = 2:n
    dz0 = TVD(k) - TVD(k-1);
    P(k) = max(P(k-1) + rho_l_ini * g * dz0 * 0.5, p.P_std);
  end

  diag = struct();
  diag.modelo = modelo;
  diag.MD = MD;
  diag.TVD = TVD;
  diag.HL = NaN(n, 1);
  diag.regimen = cell(n, 1);
  diag.rho_m = NaN(n, 1);
  diag.Re = NaN(n, 1);
  diag.f = NaN(n, 1);
  diag.dP_hidro = NaN(n, 1);
  diag.dP_fric = NaN(n, 1);
  diag.Z = NaN(n, 1);
  diag.M_g = NaN(n, 1);

  for seg = 2:n
    dL = MD(seg) - MD(seg-1);
    dz = TVD(seg) - TVD(seg-1);

    if dL <= 0
      P(seg) = P(seg-1);
      continue;
    end

    d = max((ID(seg-1) + ID(seg)) / 2, 1e-4);
    A = pi * (d / 2)^2;
    T_avg = max((T(seg-1) + T(seg)) / 2, 250);
    incl_avg = (incl(seg-1) + incl(seg)) / 2;
    eps_abs = max((rug(seg-1) + rug(seg)) / 2, 1e-8);
    P_old = max(P(seg), p.P_std);

    for iter = 1:max_iter
      P_avg = max((P(seg-1) + P_old) / 2, p.P_std);
      fl = aos_vlp_propiedades_locales(p, P_avg, T_avg, Ql, Qg);

      vsl = max(fl.Ql_local / A, eps_num);
      vsg = max(fl.Qg_local / A, 0);
      vm = max(vsl + vsg, eps_num);

      if strcmpi(modelo, 'HB')
        [HL, info_h] = aos_vlp_holdup_HB(vsl, vsg, d, fl.rho_l, fl.rho_g, fl.sigma, fl.mu_l, incl_avg, P_avg);
        regimen = info_h.modelo;
      else
        [HL, regimen, info_h] = aos_vlp_holdup_duns_ros(vsl, vsg, d, fl.rho_l, fl.rho_g, fl.sigma, fl.mu_l, incl_avg);
      end

      rho_m = fl.rho_l * HL + fl.rho_g * (1 - HL);
      mu_m = max(fl.mu_l * HL + fl.mu_g * (1 - HL), 1e-6);
      Re = max(rho_m * vm * d / mu_m, 1);
      f = aos_vlp_friccion(Re, eps_abs / d);

      dP_hidro = rho_m * g * dz;
      dP_fric = f * rho_m * vm^2 / (2 * d) * dL;
      P_new = max(P(seg-1) + dP_hidro + dP_fric, p.P_std);

      if abs(P_new - P_old) / max(P_new, p.P_std) < tol
        P_old = P_new;
        break;
      end
      P_old = P_new;
    end

    P(seg) = P_old;
    diag.HL(seg) = HL;
    diag.regimen{seg} = regimen;
    diag.rho_m(seg) = rho_m;
    diag.Re(seg) = Re;
    diag.f(seg) = f;
    diag.dP_hidro(seg) = dP_hidro;
    diag.dP_fric(seg) = dP_fric;
    diag.Z(seg) = fl.Z;
    diag.M_g(seg) = fl.M_g;
  end

  P_req = P(end);
  MD_out = MD;
  P_out = P;
end
