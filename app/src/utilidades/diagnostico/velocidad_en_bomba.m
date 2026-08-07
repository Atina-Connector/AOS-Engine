function [V_real, V_eros] = velocidad_en_bomba(param, Qgas_total_std, survey)
  % Calcula velocidad real y erosiva en la profundidad del eductor JGL.
  % El nombre del archivo conserva 'bomba' solo por compatibilidad historica.
  % param: estructura de parámetros (debe tener D_bomba, P_wh, T_sup, T_fondo, etc.)
  % Qgas_total_std : caudal de gas inyectado (m³/s std)
  % survey: estructura del survey

  % Profundidad del eductor JGL (MD)
  MD_bomba = param.D_bomba;

  % Diámetro en ese punto
  ID_bomba = survey.get_ID(MD_bomba);
  TVD_bomba = survey.get_TVD(MD_bomba);

  % Temperatura en el eductor JGL (gradiente lineal)
  grad_T = (param.T_fondo - param.T_sup) / (max(survey.TVD) - min(survey.TVD));
  T_bomba = param.T_sup + grad_T * TVD_bomba;

  % Presión en el eductor JGL (barométrica simplificada, igual que en velocidad_critica)
  M_g = 0.016; Z = 0.85; R = 8.314;
  P_bomba = param.P_wh * exp(M_g * 9.81 * TVD_bomba / (Z * R * (param.T_sup + grad_T*TVD_bomba/2)));

  % Densidad del gas (kg/m³)
  rho_g = P_bomba * M_g / (Z * R * T_bomba);

  % Área transversal (m²)
  A = pi * (ID_bomba/2)^2;

  % Caudal real de gas en condiciones locales (m³/s)
  P_std = 101325; T_std = 288.15;
  Q_local = Qgas_total_std * (P_std / P_bomba) * (T_bomba / T_std);

  % Velocidad real (m/s)
  V_real = Q_local / A;

  % Velocidad erosiva (API RP 14E) en ese punto
  C = 100;
  V_eros = 0.3048 * C / sqrt(rho_g / 16.0185);
end
