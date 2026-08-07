function P_pa = aos_presion_bar_a_pa(valor, defecto)
% aos_presion_bar_a_pa.m
% Normalizador defensivo: valores <2000 se interpretan como bar; valores
% >=2000 como Pa. El defecto puede venir en bar (100) o Pa (100e5).
  if nargin < 2 || isempty(defecto)
      defecto = 100;
  end
  if defecto >= 2000
      defecto_pa = defecto;
  else
      defecto_pa = defecto * 1e5;
  end
  if nargin < 1 || isempty(valor)
      P_pa = defecto_pa;
      return;
  end
  if ischar(valor)
      v = str2double(strtrim(valor));
  elseif isnumeric(valor)
      v = valor(1);
  else
      v = NaN;
  end
  if ~isfinite(v) || isnan(v) || v <= 0
      P_pa = defecto_pa;
      return;
  end
  if abs(v) < 2000
      P_pa = v * 1e5;
  else
      P_pa = v;
  end
end
