function f = aos_vlp_friccion(Re, rr)
  % aos_vlp_friccion.m
  % Factor de fricción Darcy-Weisbach.
  % Laminar: 64/Re. Turbulento: Swamee-Jain explícito.

  Re = max(Re, 1);
  rr = max(rr, 0);

  if Re < 2000
    f = 64 / Re;
  elseif Re < 4000
    f_lam = 64 / Re;
    f_turb = 0.25 / (log10(rr/3.7 + 5.74/(Re^0.9)))^2;
    w = (Re - 2000) / 2000;
    f = (1 - w) * f_lam + w * f_turb;
  else
    f = 0.25 / (log10(rr/3.7 + 5.74/(Re^0.9)))^2;
  end

  f = aos_vlp_clamp(f, 0.005, 0.2);
end
