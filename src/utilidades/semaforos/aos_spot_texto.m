function s = aos_spot_texto(estado)
  e = upper(strtrim(estado));
  if strcmp(e, 'VERDE') || strcmp(e, 'AMARILLO') || strcmp(e, 'ROJO')
      s = char(9679);
  else
      s = char(9675);
  end
end
