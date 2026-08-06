function err = error_presion_JGL(Ql, param, P_m, m_dot_m, Q_iny)
  % error_presion_JGL.m
  % Residuo del balance JGL para solvers heredados.
  % Convencion v06: err = P_d_eductor - P_req_VLP.
  [~, err] = acople_eductor_vlp(Ql, param, P_m, m_dot_m, Q_iny);
end
