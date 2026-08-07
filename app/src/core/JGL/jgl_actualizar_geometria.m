function p = jgl_actualizar_geometria(p, modo)
% JGL_ACTUALIZAR_GEOMETRIA Mantiene coherentes A_n, d_t y coeficientes.
% GNU Octave objetivo.
%
% modo = 'derivada'  : a_eductor y b_eductor se recalculan desde A_t/A_n.
% modo = 'calibrada' : se conservan a_eductor y b_eductor ingresados.
%
% Las sensibilidades de A_n y d_t deben usar 'derivada'; de lo contrario la
% geometria puede cambiar mientras el modelo sigue usando coeficientes viejos.

  if nargin < 1 || ~isstruct(p), p = struct(); end
  if nargin < 2 || isempty(modo)
    if isfield(p,'jgl_geometria_modo') && ischar(p.jgl_geometria_modo)
      modo = p.jgl_geometria_modo;
    else
      modo = 'derivada';
    end
  end
  modo = lower(strtrim(modo));
  if ~any(strcmp(modo, {'derivada','calibrada'})), modo = 'derivada'; end

  if ~isfield(p,'A_n') || ~es_numero(p.A_n) || p.A_n <= 0, p.A_n = 12e-6; end
  if ~isfield(p,'d_t') || ~es_numero(p.d_t) || p.d_t <= 0, p.d_t = 0.038; end

  if strcmp(modo,'derivada')
    A_t = pi * (p.d_t/2)^2;
    R_area = A_t / max(p.A_n, 1e-12);
    p.a_eductor = 0.0020 * R_area;
    p.b_eductor = 0.00010 * R_area;
    p.jgl_coeficientes_origen = 'GEOMETRIA_DERIVADA';
  else
    if ~isfield(p,'a_eductor') || ~es_numero(p.a_eductor), p.a_eductor = 0.01; end
    if ~isfield(p,'b_eductor') || ~es_numero(p.b_eductor), p.b_eductor = 0.005; end
    p.jgl_coeficientes_origen = 'CALIBRACION_FIJA';
  end
  p.jgl_geometria_modo = modo;

  if ~isfield(p,'jgl') || ~isstruct(p.jgl), p.jgl = struct(); end
  p.jgl.A_n = p.A_n;
  p.jgl.d_t = p.d_t;
  p.jgl.a_eductor = p.a_eductor;
  p.jgl.b_eductor = p.b_eductor;
  p.jgl.geometria_modo = modo;
end

function tf = es_numero(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x);
end
