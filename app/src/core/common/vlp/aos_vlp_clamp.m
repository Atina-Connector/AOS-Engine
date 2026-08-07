function y = aos_vlp_clamp(x, xmin, xmax)
  % aos_vlp_clamp.m
  % Limitador escalar/vectorial compatible con GNU Octave.
  y = min(max(x, xmin), xmax);
end
