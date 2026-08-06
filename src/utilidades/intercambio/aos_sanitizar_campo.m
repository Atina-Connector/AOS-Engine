function nombre = aos_sanitizar_campo(nombre_original)
% Convierte nombres de seccion/campo .aosdat en identificadores de struct.
  if nargin < 1 || isempty(nombre_original)
      nombre = 'sin_nombre';
      return;
  end
  nombre = strtrim(nombre_original);
  nombre = regexprep(nombre, '[^A-Za-z0-9_]', '_');
  nombre = regexprep(nombre, '_+', '_');
  nombre = regexprep(nombre, '^_+|_+$', '');
  if isempty(nombre), nombre = 'sin_nombre'; end
  if ~isletter(nombre(1))
      nombre = ['f_', nombre];
  end
end
