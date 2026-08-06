function F = gibbs18_bottom_boundary(t, u_pump, v_pump, param)
% Condicion inferior bomba v18.
% Signo: fuerza externa positiva hacia abajo en el nodo inferior.
  if nargin < 4, param = struct(); end
  WC = min(max(leer_num(param,'WC',0.5),0),1);
  rho_l = leer_num(param,'rho_o',850)*(1-WC) + leer_num(param,'rho_w',1000)*WC;
  Dp = max(leer_num(param,'D_bomba_mm',32),1)/1000;
  Ap = pi*(Dp/2)^2;
  Pb = max(leer_num(param,'P_wh',10e5),0) + max(leer_num(param,'D_bomba',1500),0)*rho_l*9.81;
  Pf = Pb*Ap;
  llenado = min(max(leer_num(param,'gibbs18_llenado_bomba',1),0),1.2);
  spm = max(leer_num(param,'N_velocidad',6),0.1);
  T = 60/spm;
  tau = t - floor(t/T)*T;
  % Subida durante primera mitad del ciclo: bomba soporta columna completa.
  if tau <= 0.5*T
      F = Pf;
  else
      F = Pf*(1 - llenado);
  end
end

function v = leer_num(s,campo,def)
  v = def;
  if isstruct(s) && isfield(s,campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1)), v = tmp(1); end
  end
end
