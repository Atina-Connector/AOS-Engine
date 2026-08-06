function [P_s, P_d, P_req, residuo, detalle] = jgl_nodal_presiones(param, Ql, Q_iny, P_m, m_dot_m)
  % jgl_nodal_presiones.m
  % AOS 0.0.11 - Balance nodal JGL unico y auditable.
  %
  % Formulacion fisica:
  %   GL convencional: P_succion disponible contra VLP aliviada por gas.
  %   JGL:             GL + trabajo transferido por el eductor.
  %
  %   P_d = P_s + DeltaP_eductor
  %   residuo = P_d - P_req_VLP
  %
  % Con Qiny = 0, DeltaP_eductor = 0 y JGL degenera a GL/base.

  if nargin < 2 || isempty(Ql), Ql = 0; end
  if nargin < 3 || isempty(Q_iny), Q_iny = leer_num_jgl(param, {'Q_iny','Qiny','Qiny_plot'}, 0); end

  Ql = max(Ql, 0);
  Q_iny = max(Q_iny, 0);

  if nargin < 4 || isempty(P_m) || ~isfinite(P_m)
      P_m = presion_motriz_jgl(param);
  end
  if nargin < 5 || isempty(m_dot_m) || ~isfinite(m_dot_m)
      rho_g_std = leer_num_jgl(param, {'rho_g_std'}, 0.8);
      m_dot_m = Q_iny * rho_g_std;
  end

  D_levant = leer_num_jgl(param, {'D_bomba','D_eductor','D_valvula','D_levantamiento'}, NaN);
  if ~isfinite(D_levant)
      D_levant = leer_num_jgl(param, {'D_res','D_tubing'}, 3000);
  end

  GLR = leer_num_jgl(param, {'GLR'}, 0);
  Qg_total_std = Q_iny + Ql * max(GLR, 0);

  [P_s, det_succion] = calcular_columna_succion(Ql, param);
  [P_req, detalle_vlp] = compute_P_req(param, Ql, Qg_total_std, D_levant);

  detalle_eductor = struct();
  deltaP_eductor = 0;
  if Q_iny <= 1e-12
      P_d = P_s;
  else
      [P_d, deltaP_eductor, detalle_eductor] = eductor_jgl(P_s, P_m, Ql, m_dot_m, param);
  end

  residuo = P_d - P_req;

  % El intake guard diagnostica condiciones fuera de rango del reservorio.
  % No modifica el residuo nodal: el solver entrega el balance calculado y
  % el diagnostico informa si el escenario SLA es operacionalmente no factible.
  guard = aos_sla_intake_guard('JGL', Ql, P_s, param, det_succion);

  detalle = struct();
  detalle.P_s = P_s;
  detalle.P_d = P_d;
  detalle.P_req = P_req;
  detalle.residuo = residuo;
  detalle.deltaP_eductor = max(deltaP_eductor, max(P_d - P_s, 0));
  detalle.Qg_total_std = Qg_total_std;
  detalle.Qiny = Q_iny;
  detalle.P_m = P_m;
  detalle.m_dot_m = m_dot_m;
  detalle.D_levantamiento = D_levant;
  detalle.intake_guard = guard;
  detalle.succion = det_succion;
  detalle.vlp = detalle_vlp;
  detalle.eductor = detalle_eductor;
end

function P_m = presion_motriz_jgl(param)
  M_g = 0.016;
  Z = 0.85;
  R = 8.314;
  P_iny_sup = leer_num_jgl(param, {'P_iny_sup'}, 100e5);
  D_levant = leer_num_jgl(param, {'D_bomba','D_eductor','D_valvula','D_levantamiento'}, 2000);
  T_sup = leer_num_jgl(param, {'T_sup'}, 298.15);
  T_fondo = leer_num_jgl(param, {'T_fondo'}, 358.15);
  if T_sup < 150, T_sup = T_sup + 273.15; end
  if T_fondo < 150, T_fondo = T_fondo + 273.15; end
  T_prom = max((T_sup + T_fondo) / 2, 200);
  P_m = P_iny_sup * exp(M_g * 9.81 * D_levant / (Z * R * T_prom));
end

function v = leer_num_jgl(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
      nombre = nombres{k};
      if isfield(s, nombre)
          tmp = s.(nombre);
          if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
              v = tmp(1); return;
          end
      end
  end
end
