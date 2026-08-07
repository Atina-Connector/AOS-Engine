function [P_d_conv, err] = acople_eductor_vlp(Ql, param, P_m, m_dot_m, Q_iny)
  % acople_eductor_vlp.m
  % Compatibilidad para llamadas heredadas.
  %
  % v06: ya no itera con P_wh artificial. Usa el mismo balance unico JGL:
  %   err = P_d_eductor - P_req_VLP
  %
  % P_d_conv es la presion de descarga calculada por el eductor.

  if nargin < 5 || isempty(Q_iny)
      if isfield(param, 'Q_iny')
          Q_iny = param.Q_iny;
      else
          Q_iny = 0;
      end
  end

  [~, P_d_conv, ~, err] = jgl_nodal_presiones(param, Ql, Q_iny, P_m, m_dot_m);
end
