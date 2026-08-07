function r = aos_cad_hidraulica_evaluar_multifasico(tramo, nodo_in, nodo_out, P_in, Ql, Qg_std, cfg, modelo_id)
% AOS_CAD_HIDRAULICA_EVALUAR_MULTIFASICO Usa los motores VLP comunes de AOS.
% Para flujo nodo_in -> nodo_out se integra el VLP en sentido inverso:
% desde la presion aguas abajo hacia la presion requerida aguas arriba.
  D = valor_local(tramo, 'diametro_m', 0.1);
  eps_abs = valor_local(tramo, 'rugosidad', 0.045e-3);
  [L, dz] = geometria_local(tramo, nodo_in, nodo_out);
  inc = acosd(min(abs(dz) / max(L, 1e-9), 1));

  survey = struct();
  survey.MD = [0; L];
  % Recorrido inverso: salida -> entrada. TVD positiva hacia abajo.
  survey.TVD = [0; dz];
  survey.inclinacion = [inc; inc];
  survey.azimut = [0; 0];
  survey.ID_tubing = [D; D];
  survey.ID_casing = [NaN; NaN];
  survey.rugosidad = [eps_abs; eps_abs];

  param = struct();
  param.P_wh = max(cfg.P_min_Pa, P_in * 0.5);
  param.API = cfg.fluido.API; param.WC = cfg.fluido.WC;
  param.GLR = cfg.fluido.GLR; param.gamma_g = cfg.fluido.gamma_g;
  param.rho_o = cfg.fluido.rho_o; param.rho_w = cfg.fluido.rho_w;
  param.rho_g_std = cfg.fluido.rho_g_std;
  param.mu_w = cfg.fluido.mu_l_Pas; param.mu_g = cfg.fluido.mu_g_Pas;
  param.T_sup = cfg.fluido.T_sup_K; param.T_fondo = cfg.fluido.T_fondo_K;
  param.P_std = cfg.fluido.P_std_Pa; param.T_std = cfg.fluido.T_std_K;
  param.diam_tbg = D; param.eps_abs = eps_abs; param.Q_iny = 0;

  lo = cfg.P_min_Pa;
  [flo, ~] = residual_local(lo, P_in, param, survey, Ql, Qg_std, modelo_id, L);
  if flo > 0
    P_out = lo;
    convergio = false;
    adv = {'PRESION_REQUERIDA_SUPERA_ENTRADA_AUN_EN_P_MIN'};
  else
    hi = max(P_in * 1.20, P_in + 1e5);
    [fhi, ~] = residual_local(hi, P_in, param, survey, Ql, Qg_std, modelo_id, L);
    n_expand = 0;
    while fhi < 0 && n_expand < 20
      hi = hi * 1.8 + 1e5;
      [fhi, ~] = residual_local(hi, P_in, param, survey, Ql, Qg_std, modelo_id, L);
      n_expand = n_expand + 1;
    endwhile
    if fhi < 0
      P_out = lo; convergio = false;
      adv = {'NO_SE_PUDO_ENCERRAR_RAIZ_DE_PRESION'};
    else
      convergio = false; P_out = (lo + hi) / 2; adv = {};
      for it = 1:cfg.max_iter_presion
        mid = (lo + hi) / 2;
        [fm, ~] = residual_local(mid, P_in, param, survey, Ql, Qg_std, modelo_id, L);
        P_out = mid;
        if abs(fm) <= cfg.tol_presion_Pa
          convergio = true; break;
        endif
        if fm > 0, hi = mid; else lo = mid; endif
      endfor
      if ~convergio, adv{end+1} = 'BISECCION_NO_CONVERGE_TOLERANCIA'; endif
    endif
  endif

  [~, diag] = residual_local(P_out, P_in, param, survey, Ql, Qg_std, modelo_id, L);
  dp_fric = NaN; dp_grav = NaN; HL = NaN; rho_m = NaN; Re = NaN; ff = NaN; reg = 'NO_DISPONIBLE';
  if isstruct(diag)
    if isfield(diag, 'dP_fric') && numel(diag.dP_fric) >= 2, dp_fric = diag.dP_fric(end); endif
    if isfield(diag, 'dP_hidro') && numel(diag.dP_hidro) >= 2, dp_grav = diag.dP_hidro(end); endif
    if isfield(diag, 'HL') && numel(diag.HL) >= 2, HL = diag.HL(end); endif
    if isfield(diag, 'rho_m') && numel(diag.rho_m) >= 2, rho_m = diag.rho_m(end); endif
    if isfield(diag, 'Re') && numel(diag.Re) >= 2, Re = diag.Re(end); endif
    if isfield(diag, 'f') && numel(diag.f) >= 2, ff = diag.f(end); endif
    if isfield(diag, 'regimen') && numel(diag.regimen) >= 2 && ~isempty(diag.regimen{end})
      reg = char(diag.regimen{end});
    endif
  endif

  A = pi * D^2 / 4;
  r = struct();
  r.modelo = modelo_id; r.P_in_Pa = P_in; r.P_out_Pa = P_out;
  r.dp_total_Pa = P_in - P_out; r.dp_fric_Pa = dp_fric;
  r.dp_grav_Pa = dp_grav; r.dp_menores_Pa = 0;
  r.longitud_m = L; r.dz_m = coord_local(nodo_out, 'z') - coord_local(nodo_in, 'z');
  r.diametro_m = D; r.rugosidad_m = eps_abs;
  r.caudal_liquido_m3s = Ql; r.caudal_gas_std_m3s = Qg_std;
  r.velocidad_m_s = Ql / max(A, 1e-12); r.Re = Re; r.factor_friccion = ff;
  r.rho_m_kgm3 = rho_m; r.holdup_liquido = HL; r.regimen = reg;
  r.estado = 'OK'; r.advertencias = adv;
  if ~convergio, r.estado = 'ADVERTENCIA'; endif
  if P_out <= cfg.P_min_Pa && ~isempty(adv), r.estado = 'ERROR'; endif
endfunction

function [res, diag] = residual_local(P_down, P_up_obj, param, survey, Ql, Qg, modelo, L)
  param.P_wh = max(P_down, param.P_std);
  diag = struct();
  if strcmp(modelo, 'MULTIFASICO_HB')
    [P_req, ~, ~, diag] = aos_vlp_integrar(param, survey, Ql, Qg, 'HB');
  elseif strcmp(modelo, 'MULTIFASICO_DR')
    [P_req, ~, ~, diag] = aos_vlp_integrar(param, survey, Ql, Qg, 'DR');
  else
    [P_req, ~, ~] = vlp_simplified_corregida(param, Ql, Qg, L, survey);
  endif
  res = P_req - P_up_obj;
endfunction

function v = valor_local(s, f, d)
  v = d;
  if isstruct(s) && isfield(s, f)
    x = aos_aoscad_valor(s.(f));
    if ~isempty(x) && isnumeric(x), v = x(1); endif
  endif
  v = max(v, 1e-9);
endfunction

function [L, dz_rev] = geometria_local(tr, n1, n2)
  dx = coord_local(n2, 'x') - coord_local(n1, 'x');
  dy = coord_local(n2, 'y') - coord_local(n1, 'y');
  dz_flow = coord_local(n2, 'z') - coord_local(n1, 'z');
  L3 = sqrt(dx^2 + dy^2 + dz_flow^2);
  L = valor_local(tr, 'longitud_m', L3);
  L = max(L, L3); L = max(L, 1e-6);
  % En el survey inverso, TVD final = z_salida - z_entrada.
  dz_rev = dz_flow;
endfunction

function v = coord_local(n, f)
  v = 0;
  if isstruct(n) && isfield(n, f) && isnumeric(n.(f)) && ~isempty(n.(f))
    v = n.(f)(1);
  elseif strcmp(f, 'z') && isstruct(n) && isfield(n, 'cota')
    x = aos_aoscad_valor(n.cota); if ~isempty(x), v = x(1); endif
  endif
endfunction
