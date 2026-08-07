function c = aos_color_estado(estado)
  e = upper(strtrim(estado));
  if strcmp(e, 'VERDE'), c = [0.0 0.65 0.0];
  elseif strcmp(e, 'AMARILLO'), c = [1.0 0.80 0.0];
  elseif strcmp(e, 'ROJO'), c = [0.85 0.0 0.0];
  else, c = [0.55 0.55 0.55]; end
end
