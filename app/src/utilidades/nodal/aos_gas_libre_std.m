function [Qg_free_std, det] = aos_gas_libre_std(Ql_std, Qg_total_std, param, P_ref, T_ref)
% aos_gas_libre_std.m
% Separa gas libre estándar de gas total estándar considerando Rs.
% - Qiny se conserva siempre como gas libre.
% - Solo el gas de formación puede permanecer disuelto en el petróleo.
  if nargin < 3 || ~isstruct(param), param = struct(); end
  if nargin < 4 || isempty(P_ref), P_ref = 1e5; end
  if nargin < 5 || isempty(T_ref), T_ref = 300; end
  Ql_std = max(Ql_std, 0);
  Qg_total_std = max(Qg_total_std, 0);

  WC = getnum_gas(param, 'WC', 0.5); WC = min(max(WC,0),1);
  API = getnum_gas(param, 'API', 35);
  gamma_g = getnum_gas(param, 'gamma_g', 0.7);
  Qiny = getnum_gas(param, 'Q_iny', getnum_gas(param, 'Qiny_vlp', getnum_gas(param, 'Qiny', 0)));
  Qiny = min(max(Qiny, 0), Qg_total_std);

  Qo_std = max(Ql_std * (1 - WC), 0);
  Qg_form_total = max(Qg_total_std - Qiny, 0);
  T_C = T_ref;
  if T_C > 150, T_C = T_C - 273.15; end
  try
      pvt = pvt_calcular(max(P_ref,1e5), T_C, API, gamma_g);
      Rs = max(pvt.Rs, 0); % m3 gas std / m3 oil std
  catch
      Rs = 0;
  end
  Qg_disuelto = min(Qg_form_total, Qo_std * Rs);
  Qg_form_libre = max(Qg_form_total - Qg_disuelto, 0);
  Qg_free_std = Qiny + Qg_form_libre;

  det = struct();
  det.Qiny_std = Qiny;
  det.Qg_form_total_std = Qg_form_total;
  det.Qo_std = Qo_std;
  det.Rs = Rs;
  det.Qg_disuelto_std = Qg_disuelto;
  det.Qg_form_libre_std = Qg_form_libre;
  det.Qg_free_std = Qg_free_std;
end

function v = getnum_gas(s, campo, defecto)
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
