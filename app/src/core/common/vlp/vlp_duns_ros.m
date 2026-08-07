function [P_req, MD_out, P_out] = vlp_duns_ros(param, survey, Ql, Qg)
  % vlp_duns_ros.m - Versión corregida para GNU Octave / AOS
  %
  % Mantiene la firma original para reemplazo directo.
  %
  % Correcciones aplicadas:
  %   1) gas local con gamma_g y Z, no M_g fijo de metano;
  %   2) caudal local de petróleo corregido por Bo;
  %   3) hidrostática por dTVD y fricción por dMD;
  %   4) rugosidad del survey;
  %   5) transición de régimen acotada;
  %   6) slug/bajo gas estabilizado con drift-flux;
  %   7) régimen niebla/anular sin holdup fijo irreal;
  %   8) convención angular consistente: inclinación desde vertical.

  if nargin < 4
    error('vlp_duns_ros requiere: param, survey, Ql, Qg');
  end

  [P_req, MD_out, P_out] = aos_vlp_integrar(param, survey, Ql, Qg, 'DR');
end
