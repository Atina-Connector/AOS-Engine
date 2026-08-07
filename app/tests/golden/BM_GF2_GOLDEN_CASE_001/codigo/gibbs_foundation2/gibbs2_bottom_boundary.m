function [F, estado] = gibbs2_bottom_boundary(t, u_pump, v_pump, param)
  % Fuerza dinámica adicional en la bomba (por encima de la referencia estática).
  if nargin < 4, param = struct(); end
  WC = min(max(leer_num(param,'WC',0.5),0),1);
  rho_l = leer_num(param,'rho_o',850)*(1-WC) + leer_num(param,'rho_w',1000)*WC;
  Dp = max(leer_num(param,'D_bomba_mm',32),1)/1000;
  Ap = pi*(Dp/2)^2;
  Pb = max(leer_num(param,'P_wh',10e5),0) + max(leer_num(param,'D_bomba',1500),0)*rho_l*9.81;
  Pf = Pb*Ap;
  llenado = min(max(leer_num(param,'gibbs2_llenado_bomba',1),0),1.2);
  F_ref = gibbs2_bottom_static_load(param);
  F_up = Pf*llenado;
  F_down = 0.02*Pf;
  v_thresh = max(leer_num(param,'gibbs2_valve_vel_threshold',0.01),1e-6);
  valve = 1 ./ (1 + exp(-max(min(v_pump/v_thresh,60),-60)));
  F_total = F_down + (F_up - F_down)*valve;
  F = F_total - F_ref;   % solo la parte dinámica
  F = max(F, -F_ref);    % evitar tracción excesiva
  estado.valvula = valve;
  estado.llenado = llenado;
end
function v = leer_num(s,c,d)
  v = d; if isstruct(s)&&isfield(s,c), tmp=s.(c); if isnumeric(tmp)&&~isempty(tmp)&&isfinite(tmp(1)), v=tmp(1); end, end
end
