function T = aos_temperatura_at_md(param, md)
% Temperatura lineal de screening [K] entre superficie y profundidad de referencia.
  Ts = getnum_local(param, {'T_sup'}, 298.15);
  Tf = getnum_local(param, {'T_fondo'}, 358.15);
  Dref = getnum_local(param, {'D_res','D_midperf'}, max(md,1));
  f = min(max(md ./ max(Dref,1),0),1.20);
  T = Ts + f .* (Tf - Ts);
endfunction

function v = getnum_local(s, campos, defecto)
  v = defecto;
  for i=1:numel(campos)
    if isfield(s,campos{i}) && isnumeric(s.(campos{i})) && ~isempty(s.(campos{i})) && isfinite(s.(campos{i})(1))
      v=s.(campos{i})(1); return;
    endif
  endfor
endfunction
