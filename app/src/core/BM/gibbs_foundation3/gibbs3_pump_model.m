function bomba = gibbs3_pump_model(param, malla)
% GIBBS3_PUMP_MODEL Carga hidraulica y estados limite de la bomba.
% No impone una fraccion oculta de carga descendente.

  g = param.gibbs3_gravedad_m_s2;
  rho_l = malla.rho_liquido_kg_m3;
  Ap = pi * (param.D_bomba_mm/1000.0/2.0)^2;

  if isfinite(param.D_bomba_TVD)
    tvd = param.D_bomba_TVD;
  else
    tvd = sum(malla.dx_m .* malla.factor_vertical_e);
  end

  if isfinite(param.P_intake)
    Pintake = param.P_intake;
  elseif isfinite(param.P_intake_min)
    Pintake = param.P_intake_min;
  else
    error('GF3 requiere P_intake o P_intake_min finita.');
  end

  Pdescarga = param.P_wh + rho_l*g*tvd;
  deltaP = max(Pdescarga-Pintake, 0);

  if isfinite(param.gibbs3_llenado_bomba)
    llenado = param.gibbs3_llenado_bomba;
  else
    llenado = param.eta_vol;
  end

  Fhid = deltaP * Ap * llenado;
  Fup = Fhid + param.gibbs3_friccion_ascenso_N;
  Fdown = param.gibbs3_friccion_descenso_N;
  r = param.gibbs3_fraccion_referencia_carga;
  Fref = Fdown + r*(Fup-Fdown);

  bomba = struct();
  bomba.area_piston_m2 = Ap;
  bomba.rho_liquido_kg_m3 = rho_l;
  bomba.TVD_bomba_m = tvd;
  bomba.P_descarga_Pa = Pdescarga;
  bomba.P_intake_Pa = Pintake;
  bomba.deltaP_Pa = deltaP;
  bomba.llenado = llenado;
  bomba.F_hidraulica_N = Fhid;
  bomba.F_up_N = Fup;
  bomba.F_down_N = Fdown;
  bomba.F_ref_N = Fref;
  bomba.velocidad_transicion_m_s = ...
    param.gibbs3_velocidad_transicion_valvula_m_s;
  bomba.tau_valvula_s = param.gibbs3_constante_tiempo_valvula_s;

  bomba.lpp_activa = logical(param.bomba_lpp);
  bomba.lpp_longitud_piston_m = param.lpp_longitud_piston_m;
  bomba.lpp_id_piston_mm = param.lpp_id_piston_mm;
end
