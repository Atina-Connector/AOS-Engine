function [factor, nombre, ok] = aos_units_factor_a_metros(nom)
% AOS_UNITS_FACTOR_A_METROS Convierte nombre de unidad a factor hacia metros (SI).
  ok = true;
  n = lower(strtrim(char(nom)));
  switch n
    case {'m', 'metro', 'metros', 'meter', 'meters'}
      factor = 1; nombre = 'm';
    case {'mm', 'milimetro', 'milimetros', 'millimeter', 'millimeters'}
      factor = 0.001; nombre = 'mm';
    case {'cm', 'centimetro', 'centimetros', 'centimeter', 'centimeters'}
      factor = 0.01; nombre = 'cm';
    case {'in', 'inch', 'inches', 'pulgada', 'pulgadas'}
      factor = 0.0254; nombre = 'in';
    case {'ft', 'foot', 'feet', 'pie', 'pies'}
      factor = 0.3048; nombre = 'ft';
    otherwise
      factor = 1; nombre = 'm'; ok = false;
  endswitch
endfunction
