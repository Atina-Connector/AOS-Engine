function s = ternario_txt(cond, v_true, v_false)
% ternario_txt.m - Helper simple para scripts Octave sin funciones locales.
  if cond
      s = v_true;
  else
      s = v_false;
  end
end
