function T = aos_vlp_temperatura(TVD, T_sup, T_fondo)
  % Perfil lineal de temperatura en K contra TVD.
  TVD = TVD(:);
  if isempty(TVD)
    T = [];
    return;
  end
  if abs(TVD(end) - TVD(1)) < 1e-9
    T = T_sup * ones(size(TVD));
  else
    T = T_sup + (T_fondo - T_sup) .* (TVD - TVD(1)) ./ (TVD(end) - TVD(1));
  end
  T = max(T, 250);
end
