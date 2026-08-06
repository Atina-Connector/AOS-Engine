function txt = aos_formato_presion(P_pa, decimales)
% Formato AOS: bar como unidad principal y psi entre parentesis.
  if nargin < 2 || isempty(decimales), decimales = 1; end
  if isempty(P_pa) || ~isnumeric(P_pa) || ~isscalar(P_pa) || ~isfinite(P_pa)
      txt = 'n/d';
      return;
  end
  P_bar = P_pa / 1e5;
  P_psi = P_bar * 14.5037738;
  fmt = sprintf('%%.%df bar (%%.%df psi)', decimales, max(decimales, 0));
  txt = sprintf(fmt, P_bar, P_psi);
end
