function [Ql, detalle] = aos_resolver_gl(param, Qiny)
% aos_resolver_gl.m - Solver nodal robusto para Gas Lift.
% Usa el mismo balance que plot_nodal: aos_nodal_balance_gl.
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(Qiny)
      if isfield(param, 'Q_iny'), Qiny = param.Q_iny; else, Qiny = 0; end
  end
  Qiny = max(Qiny, 0);
  try
      param = aos_normalizar_config(param, 'GL');
  catch
  end
  D_iny = aos_profundidad_inyeccion(param, getnum_rgl(param,'D_bomba', getnum_rgl(param,'D_res',0)));
  try
      param = aos_set_profundidad(param, 'GL', D_iny);
  catch
      param.D_iny = D_iny; param.D_iny_m = D_iny;
  end
  param.Q_iny = Qiny;

  ip.P_res = getnum_rgl(param, 'P_res', 0);
  ip.IP = getnum_rgl(param, 'IP', 0);
  if isfield(param, 'P_b'), ip.P_b = param.P_b; end
  modelo = 'linear';
  if isfield(param, 'modelo_IPR') && ischar(param.modelo_IPR), modelo = param.modelo_IPR; end
  [Ql_max, ~] = ipr(ip, modelo);

  f = @(q) solo_residuo(q, param, Qiny, D_iny);
  npts = getnum_rgl(param, 'sens_nodal_n_puntos', 1201);
  npts = max(31, min(5001, round(npts)));
  tolP = getnum_rgl(param, 'sens_nodal_tol_P', 0.05e5);
  tolQ = getnum_rgl(param, 'sens_nodal_tol_Q_rel', 1e-7);
  opts = struct('n_puntos', npts, 'tol_P', tolP, 'tol_Q_rel', tolQ);
  busq = aos_buscar_cruce_nodal(f, Ql_max, opts);
  Ql = busq.Ql;

  detalle = busq;
  detalle.D_iny = D_iny;
  detalle.Qiny_solicitado = Qiny;
  detalle.Qiny = Qiny;
  detalle.Ql_max_IPR = Ql_max;
  if isfinite(Ql)
      try
          [~, detbal] = aos_nodal_balance_gl(Ql, param, Qiny, D_iny);
          detalle.balance_solucion = detbal;
      catch err
          detalle.balance_error = err.message;
      end
  end
end

function r = solo_residuo(q, p, qiny, D)
  [r, ~] = aos_nodal_balance_gl(q, p, qiny, D);
end

function v = getnum_rgl(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
          v = x(1); return;
      elseif ischar(x)
          y = str2double(x);
          if isfinite(y), v = y; return; end
      end
  end
end
