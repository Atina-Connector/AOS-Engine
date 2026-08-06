function [F_bomba, estado, info] = gibbs_modelo_bomba(param, pos_fondo, vel_fondo, estado)
  % Modelo local de bomba para Gibbs forward.
  % F_bomba positiva = carga hacia abajo aplicada al extremo inferior de la sarta.
  if nargin < 4 || ~isstruct(estado), estado = struct(); end
  if ~isfield(estado, 'valvula'), estado.valvula = 0; end

  Ffluid = gibbs_carga_fluido(param);
  Ffric = abs(leer_campo(param, 'friccion_bomba_N', 0));
  llenado = min(max(leer_campo(param, 'llenado_bomba', leer_campo(param,'eta_vol',0.85)), 0), 1.2);
  relax = 0.18;

  % Valvula viajera cerrada principalmente cuando el piston se mueve hacia arriba.
  if vel_fondo >= 0
      objetivo = 1.0;
  else
      objetivo = 0.0;
  end
  estado.valvula = (1 - relax) * estado.valvula + relax * objetivo;
  valve = min(max(estado.valvula, 0), 1);

  % Llenado reduce la porcion de carrera con carga efectiva de fluido.
  carga_valvula = Ffluid * min(valve * llenado, 1.2);
  carga_fric = Ffric * sign_seguro(vel_fondo);
  F_bomba = max(carga_valvula + carga_fric, 0);

  info = struct();
  info.valvula = valve;
  info.llenado = llenado;
  info.Ffluid_N = Ffluid;
  info.Ffric_N = Ffric;
  info.pos_fondo_m = pos_fondo;
end

function Ffluid = gibbs_carga_fluido(param)
  % Carga diferencial de fluido sobre el piston.
  Dp = leer_campo(param, 'D_bomba_mm', 32) / 1000;
  Ap = pi * (Dp/2)^2;
  rho_l = leer_rho_l(param);
  g = 9.81;
  D = max(leer_campo(param, 'D_bomba', 1500), 0);
  Pwh = max(leer_campo(param, 'P_wh', 0), 0);
  Pint = max(leer_campo(param, 'P_intake', leer_campo(param,'P_intake_min',1e5)), 0);
  Pcsg = max(leer_campo(param, 'P_casing', 0), 0);

  % Diferencial simplificado: columna + cabeza - soporte intake/casing.
  dP = max(rho_l*g*D + Pwh - max(Pint, Pcsg), 0);
  Ffluid = Ap * dP;
end

function rho_l = leer_rho_l(param)
  rho_o = leer_campo(param, 'rho_o', 850);
  rho_w = leer_campo(param, 'rho_w', 1000);
  WC = min(max(leer_campo(param, 'WC', 0.5), 0), 1);
  rho_l = rho_o*(1-WC) + rho_w*WC;
end

function s = sign_seguro(x)
  if x > 0
      s = 1;
  elseif x < 0
      s = -1;
  else
      s = 0;
  end
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
