function Ffluid = gibbs_carga_fluido(param)
  % Carga diferencial de fluido sobre el piston BM [N].
  Dp = leer_campo(param, 'D_bomba_mm', 32) / 1000;
  Ap = pi * (Dp/2)^2;
  rho_o = leer_campo(param, 'rho_o', 850);
  rho_w = leer_campo(param, 'rho_w', 1000);
  WC = min(max(leer_campo(param, 'WC', 0.5), 0), 1);
  rho_l = rho_o*(1-WC) + rho_w*WC;
  D = max(leer_campo(param, 'D_bomba', 1500), 0);
  Pwh = max(leer_campo(param, 'P_wh', 0), 0);
  Pint = max(leer_campo(param, 'P_intake', leer_campo(param,'P_intake_min',1e5)), 0);
  Pcsg = max(leer_campo(param, 'P_casing', 0), 0);
  dP = max(rho_l*9.81*D + Pwh - max(Pint, Pcsg), 0);
  Ffluid = Ap * dP;
end

function v = leer_campo(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end
