function err = error_gl(Ql, config, P_valv, Q_iny) %#ok<INUSD>
  % error_gl.m - wrapper historico del balance GL.
  % AOS 0.0.11f: usa aos_nodal_balance_gl para no divergir del solver/plot.
  if nargin < 4 || isempty(Q_iny)
      if isstruct(config) && isfield(config, 'Q_iny'), Q_iny = config.Q_iny; else, Q_iny = 0; end
  end
  D_valv = aos_profundidad_inyeccion(config, NaN);
  [err, ~] = aos_nodal_balance_gl(Ql, config, Q_iny, D_valv);
end
