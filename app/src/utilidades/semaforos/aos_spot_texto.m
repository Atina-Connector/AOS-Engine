function s = aos_spot_texto(estado)
  % Marcador ASCII seguro para CLI: char(9679)/char(9675) (circulos Unicode)
  % producen "range error for conversion to character value" en Octave.
  e = upper(strtrim(estado));
  if strcmp(e, 'VERDE')
      s = '[OK]';
  elseif strcmp(e, 'AMARILLO')
      s = '[!]';
  elseif strcmp(e, 'ROJO')
      s = '[X]';
  else
      s = '[?]';
  end
end
