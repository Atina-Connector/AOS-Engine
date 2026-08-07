function txt = aos_formato_caudal_gas(Q_m3s, decimales_metricos)
% Formato AOS: Sm3/d como unidad principal y MMscf/d entre parentesis.
  if nargin < 2 || isempty(decimales_metricos), decimales_metricos = 0; end
  if isempty(Q_m3s) || ~isnumeric(Q_m3s) || ~isscalar(Q_m3s) || ~isfinite(Q_m3s)
      txt = 'n/d';
      return;
  end
  q_sm3d = aos_m3s_a_sm3d(Q_m3s);
  q_mmscfd = aos_m3s_a_mmscfd(Q_m3s);
  fmt = sprintf('%%.%df Sm3/d (%%.4f MMscf/d)', decimales_metricos);
  txt = sprintf(fmt, q_sm3d, q_mmscfd);
end
