function [P_req, MD_out, P_out] = vlp_HB_full(param, survey, Ql, Qg)
  % vlp_HB_full.m - Versión corregida para GNU Octave / AOS
  %
  % Motor Hagedorn-Brown simplificado y estabilizado.
  % Mantiene la firma original para reemplazo directo.
  %
  % Correcciones aplicadas:
  %   1) gas local con gamma_g y Z, no M_g fijo de metano;
  %   2) caudal local de petróleo corregido por Bo;
  %   3) hidrostática integrada por dTVD;
  %   4) fricción integrada por dMD;
  %   5) rugosidad tomada del survey;
  %   6) holdup HB estabilizado para que HL -> 1 cuando vsg -> 0;
  %   7) convención angular consistente: inclinación desde vertical.

  if nargin < 4
    error('vlp_HB_full requiere: param, survey, Ql, Qg');
  end

  [P_req, MD_out, P_out] = aos_vlp_integrar(param, survey, Ql, Qg, 'HB');
end
