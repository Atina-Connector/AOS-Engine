function pvt = pvt_calcular(P, T, API, gamma_g)
  % Calcula propiedades PVT del petróleo (black‑oil).
  % Entradas:
  %   P       : presión (Pa)
  %   T       : temperatura (°C)
  %   API     : gravedad API del petróleo (adimensional)
  %   gamma_g : gravedad específica del gas (aire = 1)
  % Salidas (estructura pvt):
  %   Rs      : relación de solubilidad (m³/m³)
  %   Bo      : factor volumétrico del petróleo (m³/m³)
  %   mu_o    : viscosidad del petróleo (Pa·s)

  % Constantes y conversiones
  P_psia = P * 0.000145038;   % Pa -> psia
  T_F = T * 9/5 + 32;         % °C -> °F

  % 1. Rs (Standing, 1947)  [scf/STB] -> [m³/m³]
  Rs_scf_stb = gamma_g * (P_psia / 18.2 * 10^(0.0125*API - 0.00091*T_F))^1.204;
  Rs = Rs_scf_stb * 0.178107;   % scf/STB -> m³/m³

  % 2. Bo (Standing, 1947)  [bbl/STB] -> [m³/m³]
  Bo_bbl_stb = 0.972 + 0.000147 * (Rs_scf_stb * sqrt(gamma_g / (API^0.5)) + 1.25*T_F)^1.175;
  Bo = Bo_bbl_stb;          % bbl/STB es una relación volumétrica; no se convierte a m³/m³

  % 3. mu_o (Beggs‑Robinson, 1975)  [cp] -> [Pa·s]
  %    a) viscosidad del petróleo muerto (sin gas disuelto)
  mu_od_cp = 10^(10^(3.0324 - 0.02023*API) * T_F^(-1.163)) - 1;
  %    b) viscosidad del petróleo vivo (con gas disuelto)
  A = 10.715 * (Rs_scf_stb + 100)^(-0.515);
  B = 5.44 * (Rs_scf_stb + 150)^(-0.338);
  mu_o_cp = A * mu_od_cp^B;
  mu_o = mu_o_cp * 0.001;   % cp -> Pa·s

  % Empaquetar resultados
  pvt.Rs = Rs;
  pvt.Bo = Bo;
  pvt.mu_o = mu_o;
end
