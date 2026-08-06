function r = aos_cad_hidraulica_evaluar_monofasico(tramo, nodo_in, nodo_out, P_in, Ql, cfg)
% AOS_CAD_HIDRAULICA_EVALUAR_MONOFASICO Darcy-Weisbach + gravedad.
  D = valor_local(tramo, 'diametro_m', 0.1);
  eps_abs = valor_local(tramo, 'rugosidad', 0.045e-3);
  L = longitud_local(tramo, nodo_in, nodo_out);
  z1 = coord_local(nodo_in, 'z'); z2 = coord_local(nodo_out, 'z');
  dz = z2 - z1; Q = abs(Ql);

  rho = cfg.fluido.rho_o * (1 - cfg.fluido.WC) + cfg.fluido.rho_w * cfg.fluido.WC;
  mu = max(cfg.fluido.mu_l_Pas, 1e-9);
  A = pi * D^2 / 4;
  V = Q / max(A, 1e-12);
  Re = rho * abs(V) * D / mu;
  if Re < 1e-12
    f = 0;
  elseif exist('aos_vlp_friccion', 'file') == 2
    f = aos_vlp_friccion(max(Re, 1), eps_abs / D);
  elseif Re < 2300
    f = 64 / max(Re, 1);
  else
    invsqrtf = -1.8 * log10((eps_abs / D / 3.7)^1.11 + 6.9 / max(Re, 1));
    f = 1 / max(invsqrtf, 1e-6)^2;
  endif

  dp_fric = f * (L / D) * rho * V^2 / 2;
  dp_grav = rho * cfg.g * dz;
  P_out = P_in - dp_fric - dp_grav;

  r = struct();
  r.modelo = 'MONOFASICO_DARCY';
  r.P_in_Pa = P_in; r.P_out_Pa = P_out;
  r.dp_total_Pa = P_in - P_out;
  r.dp_fric_Pa = dp_fric; r.dp_grav_Pa = dp_grav; r.dp_menores_Pa = 0;
  r.longitud_m = L; r.dz_m = dz; r.diametro_m = D; r.rugosidad_m = eps_abs;
  r.caudal_liquido_m3s = Ql; r.caudal_gas_std_m3s = 0;
  r.velocidad_m_s = V; r.Re = Re; r.factor_friccion = f;
  r.rho_m_kgm3 = rho; r.holdup_liquido = 1;
  r.regimen = 'MONOFASICO_LIQUIDO';
  r.estado = 'OK'; r.advertencias = {};
  omitir_pmin = isstruct(cfg) && isfield(cfg, 'omitir_chequeo_P_min') && ...
    logical(cfg.omitir_chequeo_P_min);
  if ~omitir_pmin && P_out < cfg.P_min_Pa
    r.estado = 'ERROR';
    r.advertencias{end+1} = 'PRESION_SALIDA_MENOR_QUE_MINIMA';
  endif
endfunction

function v = valor_local(s, f, d)
  v = d;
  if isstruct(s) && isfield(s, f)
    x = aos_aoscad_valor(s.(f));
    if ~isempty(x) && isnumeric(x), v = x(1); endif
  endif
  v = max(v, 1e-9);
endfunction

function L = longitud_local(tr, n1, n2)
  L = valor_local(tr, 'longitud_m', 0);
  dx = coord_local(n2, 'x') - coord_local(n1, 'x');
  dy = coord_local(n2, 'y') - coord_local(n1, 'y');
  dz = coord_local(n2, 'z') - coord_local(n1, 'z');
  L3 = sqrt(dx^2 + dy^2 + dz^2);
  if L <= 0, L = L3; endif
  L = max(L, L3);
  L = max(L, 1e-6);
endfunction

function v = coord_local(n, f)
  v = 0;
  if isstruct(n) && isfield(n, f) && isnumeric(n.(f)) && ~isempty(n.(f))
    v = n.(f)(1);
  elseif strcmp(f, 'z') && isstruct(n) && isfield(n, 'cota')
    x = aos_aoscad_valor(n.cota); if ~isempty(x), v = x(1); endif
  endif
endfunction
