function txt = aos_formato_longitud(L_m, decimales)
% Formato AOS: metros como unidad principal y pies entre parentesis.
  if nargin < 2 || isempty(decimales), decimales = 1; end
  if isempty(L_m) || ~isnumeric(L_m) || ~isscalar(L_m) || ~isfinite(L_m)
      txt = 'n/d';
      return;
  end
  L_ft = L_m * 3.280839895;
  fmt = sprintf('%%.%df m (%%.%df ft)', decimales, decimales);
  txt = sprintf(fmt, L_m, L_ft);
end
