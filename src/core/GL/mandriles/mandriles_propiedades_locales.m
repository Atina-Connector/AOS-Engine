function fl = mandriles_propiedades_locales(param, P, T, ID, rug, Qg_std_m3d, Ql_m3d, fase)
% Propiedades locales para los perfiles de mandriles.
% fase: GAS, LIQUIDO o MEZCLA.
  p = mandriles_defaults(param);
  P = max(P, p.mand_Pstd_Pa * 0.25);
  T = max(T, 220);
  ID = max(ID, 1e-4);
  rug = max(rug, 1e-8);

  Z = max(p.mand_Z_gas, 0.20);
  gamma = max(p.mand_gamma_g, 0.10);
  Rgas = 287.05 / gamma;
  rho_g = P / (Z * Rgas * T);
  rho_l = densidad_liquido_local(p);

  qg_std = max(Qg_std_m3d, 0) / 86400;
  ql = max(Ql_m3d, 0) / 86400;
  qg = qg_std * (p.mand_Pstd_Pa / P) * (T / p.mand_Tstd_K) * Z;

  A = pi * ID^2 / 4;
  vsg = qg / A;
  vsl = ql / A;
  fase_u = upper(strtrim(fase));

  if strcmp(fase_u, 'GAS')
    alpha_l = 0;
    rho = rho_g;
    mu = p.mand_mu_gas_Pa_s;
    vm = vsg;
  elseif strcmp(fase_u, 'LIQUIDO')
    alpha_l = 1;
    rho = rho_l;
    mu = p.mand_mu_liq_Pa_s;
    vm = vsl;
  else
    if vsg + vsl <= 1e-12
      alpha_l = 1;
    elseif vsl <= 1e-12
      alpha_l = 0;
    elseif vsg <= 1e-12
      alpha_l = 1;
    else
      lambda_l = vsl / (vsl + vsg);
      alpha_l = min(0.98, max(0.01, p.mand_factor_holdup * lambda_l));
    endif
    rho = alpha_l * rho_l + (1 - alpha_l) * rho_g;
    mu = alpha_l * p.mand_mu_liq_Pa_s + (1 - alpha_l) * p.mand_mu_gas_Pa_s;
    vm = vsg + vsl;
  endif

  Re = max(rho * abs(vm) * ID / max(mu, 1e-8), 1);
  if abs(vm) <= 1e-12
    f = 0;
  elseif Re < 2300
    f = 64 / Re;
  else
    f = 0.25 / (log10(rug/(3.7*ID) + 5.74/(Re^0.9))^2);
  endif
  grad_fric = f * 0.5 * rho * vm^2 / ID;

  fl = struct('rho',rho,'rho_g',rho_g,'rho_l',rho_l,'Z',Z, ...
              'alpha_l',alpha_l,'vsg',vsg,'vsl',vsl,'vm',vm, ...
              'Re',Re,'f',f,'grad_fric_Pa_m',grad_fric);
endfunction

function rho = densidad_liquido_local(p)
  if isfield(p, 'mand_rho_liq_kg_m3') && isnumeric(p.mand_rho_liq_kg_m3) && ...
      isscalar(p.mand_rho_liq_kg_m3) && isfinite(p.mand_rho_liq_kg_m3) && p.mand_rho_liq_kg_m3 > 0
    rho = p.mand_rho_liq_kg_m3;
    return;
  endif
  wc = leer_local(p, {'WC'}, NaN);
  ro = leer_local(p, {'rho_o'}, NaN);
  rw = leer_local(p, {'rho_w'}, NaN);
  if isfinite(wc) && isfinite(ro) && isfinite(rw)
    wc = min(max(wc,0),1);
    rho = ro * (1-wc) + rw * wc;
  else
    rho = p.mand_rho_kill;
  endif
  rho = max(rho, 100);
endfunction

function v = leer_local(s, nombres, defecto)
  v = defecto;
  for i = 1:numel(nombres)
    n = nombres{i};
    if isfield(s,n)
      x = s.(n);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
        v = x(1);
        return;
      endif
    endif
  endfor
endfunction
