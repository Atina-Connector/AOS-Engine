function P_descarga_vlp = presion_descarga_VLP_bajando(Ql, Qiny, P_wh, param)
  % Calcula la presión en D_bomba partiendo de P_wh hacia abajo.
  % Si modelo_VLP es 'HB' y hay survey, usa vlp_HB_full en modo inverso.
  % Si no, usa gradiente simplificado.

  Qg_total_std = Qiny + Ql * param.GLR;

  if strcmp(param.modelo_VLP, 'HB') && isfield(param, 'survey') && ~isempty(param.survey)
      % --- Modo Hagedorn-Brown inverso ---
      % vlp_HB_full calcula desde P_wh hacia el fondo; devuelve perfil de P.
      [~, ~, P_out] = vlp_HB_full(param, param.survey, Ql, Qg_total_std);
      % Interpolar en la profundidad D_bomba
      P_descarga_vlp = interp1(param.survey.MD, P_out, param.D_bomba, 'linear', 'extrap');
  else
      % --- Modo simplificado (mezcla homogénea) ---
      rho_l = param.rho_o * (1-param.WC) + param.rho_w * param.WC;
      P_prom = P_wh + 20e5;
      T_prom = param.T_sup + (param.T_fondo - param.T_sup) * param.D_bomba / max(param.D_res, 1);
      Qg_local = Qg_total_std * (101325 / max(P_prom, 1e5)) * (T_prom / 288.15);
      A_tbg = pi * (param.diam_tbg/2)^2;
      v_sl = Ql / A_tbg;
      v_sg = Qg_local / A_tbg;
      C0 = 1.1; v_inf = 0.3;
      v_m = v_sl + v_sg;
      H_l = 1 - v_sg / (C0 * max(v_m, 1e-6) + v_inf);
      H_l = min(max(H_l, 0.05), 1);
      rho_mezcla = rho_l * H_l + param.rho_g_std * (1-H_l);
      P_descarga_vlp = P_wh + rho_mezcla * 9.81 * param.D_bomba;
  end
end
