function [gan_abs, gan_pct, gan_inc_pct, info] = sens_calcular_ganancias(y, x, preferir_cero)
% AOS 0.1.0: helper transversal de ganancias.
% SENS_CALCULAR_GANANCIAS Metricas trazables para curvas de sensibilidad.
% GNU Octave.
%
% gan_abs      : diferencia respecto del punto de referencia.
% gan_pct      : diferencia porcentual respecto del punto de referencia.
% gan_inc_pct  : diferencia porcentual respecto del punto valido anterior.
% info         : origen y valor de la referencia utilizada.

  if nargin < 2 || isempty(x)
    x = 1:numel(y);
  endif
  if nargin < 3 || isempty(preferir_cero)
    preferir_cero = false;
  endif

  y = double(y(:)');
  x = double(x(:)');
  n = numel(y);
  if numel(x) ~= n
    error('sens_calcular_ganancias: x e y deben tener igual cantidad de puntos.');
  endif

  gan_abs = NaN(1,n);
  gan_pct = NaN(1,n);
  gan_inc_pct = NaN(1,n);
  info = struct('indice',NaN,'x',NaN,'base',NaN,'tipo','SIN_REFERENCIA', ...
    'porcentaje_calculable',false,'mensaje','No existe un punto valido de referencia.');

  validos = find(isfinite(y));
  if isempty(validos)
    return;
  endif

  idx_ref = [];
  if preferir_cero
    escala = max(1,max(abs(x(isfinite(x)))));
    tol = 1e-10 * escala;
    candidatos = find(isfinite(x) & abs(x) <= tol & isfinite(y));
    if ~isempty(candidatos)
      idx_ref = candidatos(1);
      tipo = 'VARIABLE_CERO';
    endif
  endif
  if isempty(idx_ref)
    idx_ref = validos(1);
    tipo = 'PRIMER_PUNTO_VALIDO';
  endif

  base = y(idx_ref);
  gan_abs = y - base;
  escala_base = max(1,max(abs(y(isfinite(y)))));
  pct_ok = isfinite(base) && abs(base) > eps(escala_base);
  if pct_ok
    gan_pct = 100 * gan_abs / base;
  endif

  anterior = [];
  for i = 1:n
    if ~isfinite(y(i))
      continue;
    endif
    if isempty(anterior)
      gan_inc_pct(i) = 0;
    else
      den = y(anterior);
      escala_den = max(1,max(abs(y(isfinite(y)))));
      if abs(den) > eps(escala_den)
        gan_inc_pct(i) = 100 * (y(i)-den) / den;
      endif
    endif
    anterior = i;
  endfor

  info.indice = idx_ref;
  info.x = x(idx_ref);
  info.base = base;
  info.tipo = tipo;
  info.porcentaje_calculable = pct_ok;
  if pct_ok
    info.mensaje = sprintf('Referencia %s en x=%.10g; valor base=%.10g.',tipo,info.x,base);
  else
    info.mensaje = sprintf('Referencia %s en x=%.10g con valor base cero; porcentaje no calculable.',tipo,info.x);
  endif
endfunction
