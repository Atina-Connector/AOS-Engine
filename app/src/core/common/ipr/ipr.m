function [Ql_max, P_wf_func] = ipr(param, modelo)
  % ipr.m - Curvas IPR para AOS.
  % AOS 0.0.11f:
  %   - corrige la inversion de Vogel compuesto bajo burbuja.
  %   - conserva unidades internas SI: P [Pa], Q [m3/s].
  %   - no aplica factores de ajuste para coincidir con PROSPER.

  if nargin < 1 || ~isstruct(param), error('ipr requiere estructura param'); end
  if nargin < 2 || isempty(modelo), modelo = 'linear'; end

  P_res = getnum_ipr(param, 'P_res', 0);
  IP = getnum_ipr(param, 'IP', 0);
  if ~isfinite(P_res) || P_res <= 0 || ~isfinite(IP) || IP <= 0
      Ql_max = 0;
      P_wf_func = @(Ql) zeros(size(Ql));
      return;
  end

  switch lower(strtrim(modelo))
    case 'linear'
      Ql_max = IP * P_res;
      P_wf_func = @(Ql) max(P_res - max(Ql,0) ./ IP, 0);

    case 'vogel'
      if isfield(param, 'P_b') && ~isempty(param.P_b)
          P_b = aos_normalizar_presion_burbuja(param.P_b, P_res/1e5);
      elseif isfield(param, 'P_b_bar') && ~isempty(param.P_b_bar)
          P_b = aos_normalizar_presion_burbuja(param.P_b_bar, P_res/1e5);
      else
          P_b = P_res;
      end
      % Vogel compuesto: arriba de Pb lineal, debajo de Pb Vogel incremental.
      % Si Pb >= Pres, el reservorio completo opera como saturado y se usa
      % Pb_eff = Pres, que reduce la formulacion al Vogel clasico.
      P_b = min(max(P_b, 1e3), P_res);
      Q_b = max(IP * (P_res - P_b), 0);
      Q_sat_max = IP * P_b / 1.8;
      Ql_max = max(Q_b + Q_sat_max, 0);
      P_wf_func = @(Ql) vogel_compuesto_P_wf(Ql, P_res, P_b, IP, Q_b, Ql_max);

    case 'fetkovich'
      % Fetkovich historico AOS. Se conserva pero se rotula en la auditoria
      % como estimado n=1 si no hay C y n reales.
      n = getnum_ipr(param, 'fetkovich_n', 1);
      C = getnum_ipr(param, 'fetkovich_C', NaN);
      if ~isfinite(C) || C <= 0
          n = 1;
          C = IP / max(2 * P_res, eps);
      end
      n = max(n, 0.05);
      Ql_max = C * P_res^(2*n);
      P_wf_func = @(Ql) max(P_res^2 - (max(Ql,0) ./ C).^(1/n), 0).^0.5;

    otherwise
      error('Modelo IPR no reconocido: %s', modelo);
  end
end

function P_wf = vogel_compuesto_P_wf(Ql, P_res, P_b, IP, Q_b, Ql_max)
  Ql = max(Ql, 0);
  P_wf = zeros(size(Ql));
  for i = 1:numel(Ql)
      q = Ql(i);
      if q <= Q_b || P_b <= 1e3
          P_wf(i) = max(P_res - q / max(IP, eps), 0);
      elseif q < Ql_max
          q_inc = max(q - Q_b, 0);
          denom = max(IP * P_b / 1.8, eps);
          F = min(max(q_inc / denom, 0), 1);
          % F = 1 - 0.2 r - 0.8 r^2, r=Pwf/Pb.
          % 0.8 r^2 + 0.2 r + (F - 1) = 0
          disc = 0.2^2 - 4*0.8*(F - 1);
          disc = max(disc, 0);
          r = (-0.2 + sqrt(disc)) / (2*0.8);
          r = min(max(r, 0), 1);
          P_wf(i) = r * P_b;
      else
          P_wf(i) = 0;
      end
  end
end

function v = getnum_ipr(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
          v = x(1); return;
      elseif ischar(x)
          y = str2double(x);
          if isfinite(y), v = y; return; end
      end
  end
end
