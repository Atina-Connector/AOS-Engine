function n = aos_sensibilidad_n_puntos_default(defecto)
% Devuelve la cantidad predeterminada de puntos configurada por el usuario.
  if nargin<1||isempty(defecto),defecto=15;endif
  n=defecto;
  try
    p=aos_preferencias_usuario('cargar');
    if isfield(p,'sensibilidades')&&isfield(p.sensibilidades,'n_puntos')
      v=p.sensibilidades.n_puntos;
      if isnumeric(v)&&isscalar(v)&&isfinite(v)&&v>=2,n=round(v);endif
    endif
  catch
  end_try_catch
endfunction
