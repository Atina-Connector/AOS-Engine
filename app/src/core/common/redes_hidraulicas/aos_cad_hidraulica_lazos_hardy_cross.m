function [q_edge_m3s, diag] = aos_cad_hidraulica_lazos_hardy_cross(red, base, cfg, modelo)
% AOS_CAD_HIDRAULICA_LAZOS_HARDY_CROSS Verificador cruzado independiente.
% Correccion secuencial lazo-por-lazo (metodo de la diagonal). Solo tests.
  if nargin < 4, modelo = struct(); endif
  if nargin < 3 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(modelo); endif
  if nargin < 2 || isempty(base)
    [base, ~] = aos_cad_hidraulica_lazos_base(red, cfg);
  endif

  nE = numel(red.tramos);
  q = red.ql_edge_m3s;
  qg = red.qg_edge_std_m3s;
  for i = 1:numel(base.aristas_excluidas)
    q(base.aristas_excluidas(i)) = 0;
    qg(base.aristas_excluidas(i)) = 0;
  endfor

  q_init = 1e-4;
  if isfield(cfg, 'q_init_lazo_m3s') && isfinite(cfg.q_init_lazo_m3s)
    q_init = cfg.q_init_lazo_m3s;
  endif
  for i = 1:numel(base.lazos)
    if ~strcmp(base.lazos{i}.tipo, 'FUNDAMENTAL'), continue; endif
    for k = 1:numel(base.lazos{i}.aristas)
      ee = base.lazos{i}.aristas(k);
      q(ee) = q(ee) + q_init * base.lazos{i}.signos(k);
    endfor
  endfor

  max_iter = 500;
  if isfield(cfg, 'max_iter_lazo'), max_iter = max(cfg.max_iter_lazo * 10, 200); endif
  tol_lazo = 10;
  if isfield(cfg, 'tol_lazo_Pa'), tol_lazo = cfg.tol_lazo_Pa; endif
  tol_hc = min(tol_lazo, 1);
  dq_fd = 1e-7;
  if isfield(cfg, 'dq_derivada_m3s'), dq_fd = cfg.dq_derivada_m3s; endif

  cfg_iter = cfg;
  cfg_iter.omitir_chequeo_P_min = true;
  P_ref = red.P_root_Pa;
  convergio = false;
  residual_max = Inf;
  iteraciones = 0;

  for it = 1:max_iter
    iteraciones = it;
    residual_max = 0;
    for i = 1:numel(base.lazos)
      lazo = base.lazos{i};
      [R, dRdQ] = residual_y_deriv_local(red, lazo, q, qg, P_ref, cfg_iter, modelo, dq_fd);
      residual_max = max(residual_max, abs(R));
      if abs(dRdQ) < 1e-30
        continue;
      endif
      dQ = -R / dRdQ;
      for k = 1:numel(lazo.aristas)
        ee = lazo.aristas(k);
        q(ee) = q(ee) + dQ * lazo.signos(k);
      endfor
    endfor
    if residual_max <= tol_hc
      convergio = true;
      break;
    endif
  endfor

  q_edge_m3s = q;
  diag = struct('iteraciones', iteraciones, 'convergio', convergio, ...
                'residual_max_Pa', residual_max, 'metodo', 'HARDY_CROSS');
endfunction

function [R, dRdQ] = residual_y_deriv_local(red, lazo, q, qg, P_ref, cfg, modelo, dq_fd)
  R = 0;
  for k = 1:numel(lazo.aristas)
    e = lazo.aristas(k);
    [dp, ~, ~] = aos_cad_hidraulica_dp_orientado( ...
      red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
      P_ref, q(e), qg(e), cfg, modelo);
    R = R + lazo.signos(k) * dp;
  endfor
  if strcmp(lazo.tipo, 'PSEUDO')
    Pa = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_a, 1));
    Pb = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_b, 1));
    R = R - (Pa - Pb);
  endif

  % Derivada de la diagonal: dR/d(circulacion) por diferencia central
  q_p = q; q_m = q;
  dq = max(dq_fd, 1e-9);
  for k = 1:numel(lazo.aristas)
    ee = lazo.aristas(k);
    q_p(ee) = q_p(ee) + dq * lazo.signos(k);
    q_m(ee) = q_m(ee) - dq * lazo.signos(k);
  endfor
  Rp = 0; Rm = 0;
  for k = 1:numel(lazo.aristas)
    e = lazo.aristas(k);
    [dp_p, ~, ~] = aos_cad_hidraulica_dp_orientado( ...
      red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
      P_ref, q_p(e), qg(e), cfg, modelo);
    [dp_m, ~, ~] = aos_cad_hidraulica_dp_orientado( ...
      red.tramos{e}, red.nodos{red.e_o(e)}, red.nodos{red.e_d(e)}, ...
      P_ref, q_m(e), qg(e), cfg, modelo);
    Rp = Rp + lazo.signos(k) * dp_p;
    Rm = Rm + lazo.signos(k) * dp_m;
  endfor
  if strcmp(lazo.tipo, 'PSEUDO')
    Pa = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_a, 1));
    Pb = red.P_nodos_Pa(find(red.nodos_presion == lazo.fuente_b, 1));
    Rp = Rp - (Pa - Pb);
    Rm = Rm - (Pa - Pb);
  endif
  dRdQ = (Rp - Rm) / (2 * dq);
endfunction
