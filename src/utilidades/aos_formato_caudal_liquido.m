function txt = aos_formato_caudal_liquido(Q_m3s, decimales)
% Formato AOS: m3/d como unidad principal y bpd entre parentesis.
  if nargin < 2 || isempty(decimales), decimales = 2; end
  if isempty(Q_m3s) || ~isnumeric(Q_m3s) || ~isscalar(Q_m3s) || ~isfinite(Q_m3s)
      txt = 'n/d';
      return;
  end
  q_m3d = Q_m3s * 86400;
  q_bpd = q_m3d / 0.158987294928;
  fmt = sprintf('%%.%df m3/d (%%.1f bpd)', decimales);
  txt = sprintf(fmt, q_m3d, q_bpd);
end
