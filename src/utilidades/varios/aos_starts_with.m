function tf = aos_starts_with(str, pattern)
  % AOS_STARTS_WITH - Implementacion compatible con GNU Octave para startsWith.
  % Devuelve true si str comienza con pattern.
  if isempty(pattern)
      tf = true;
      return;
  end
  if isempty(str) || length(str) < length(pattern)
      tf = false;
      return;
  end
  tf = strncmp(str, pattern, length(pattern));
end
