function h = aos_asset_hash(texto, n_hex)
% AOS_ASSET_HASH Digest hex determinista truncado (md5sum o fallback polinomial).
%
% h = aos_asset_hash(texto, n_hex)
%   Preferencia: md5sum(texto, true) truncado a n_hex.
%   Fallback: hash polinomial puro Octave (sin dependencias externas).

  if nargin < 1 || isempty(texto)
    texto = '';
  endif
  if nargin < 2 || isempty(n_hex)
    n_hex = 8;
  endif
  n_hex = max(1, round(double(n_hex(1))));
  texto = char(texto);

  dig = '';
  try
    dig = md5sum(texto, true);
    dig = normalizar_hex_local(dig);
  catch
    dig = '';
  end_try_catch

  if isempty(dig)
    try
      dig = hash('md5', texto);
      dig = normalizar_hex_local(dig);
    catch
      dig = '';
    end_try_catch
  endif

  if isempty(dig)
    dig = hash_polinomial_local(texto, n_hex);
  endif

  if numel(dig) < n_hex
    dig = [dig hash_polinomial_local([texto '|pad'], n_hex)];
  endif
  h = dig(1:n_hex);
endfunction

function dig = normalizar_hex_local(raw)
  dig = '';
  if isempty(raw), return; endif
  if isstring(raw), raw = char(raw); endif
  if iscell(raw)
    if isempty(raw), return; endif
    raw = raw{1};
  endif
  dig = lower(strtrim(char(raw)));
  dig = regexprep(dig, '[^0-9a-f]', '');
endfunction

function dig = hash_polinomial_local(texto, n_hex)
  % FNV-1a 32-bit encadenado hasta cubrir n_hex digitos hex.
  texto = char(texto);
  n_need = max(8, 2 * ceil(n_hex / 8) * 4);
  out = '';
  seed = uint32(2166136261);
  pass = 0;
  while numel(out) < n_need
    h = seed;
    for i = 1:numel(texto)
      h = bitxor(h, uint32(texto(i)));
      h = uint32(mod(double(h) * 16777619, 2^32));
    endfor
    h = bitxor(h, uint32(pass));
    out = [out sprintf('%08x', double(h))]; %#ok<AGROW>
    % Mezcla determinista para el siguiente bloque
    seed = bitxor(h, uint32(2654435761));
    pass = pass + 1;
    texto = [texto char(mod(pass, 255) + 1)]; %#ok<AGROW>
  endwhile
  dig = out(1:max(n_hex, 8));
endfunction
