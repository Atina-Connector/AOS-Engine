function ok = test_sens_gljgl03_condicion_motriz_derivada()
% Qiny forzado con P_iny_sup=0 debe derivar una presion, no bloquear JGL.
  ok = false;
  p = base_motriz_local();
  p.P_iny_sup = 0;
  p.P_iny_sup_importada_original = 0;
  p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
  qiny = 10000 / 86400;
  Ps = 80e5;
  C = jgl_condicion_motriz(p,qiny,Ps);

  assert(strcmp(C.modo_efectivo,'DERIVADA_DESDE_QINY'));
  assert(~C.bloquea_operacion);
  assert(C.presion_requerida_valida);
  assert(isfinite(C.deltaP_motriz_requerida_Pa));
  assert(C.deltaP_motriz_requerida_Pa > 0);
  assert(abs(C.P_motriz_fondo_requerida_Pa - ...
    (Ps + C.deltaP_motriz_requerida_Pa)) < 1e-7 * max(Ps,1));
  assert(isfinite(C.P_iny_sup_requerida_Pa));
  assert(C.P_iny_sup_requerida_Pa > 0);
  assert(C.P_iny_sup_importada_Pa == 0);
  assert(C.P_iny_sup_configurada_Pa == 0);
  assert(isnan(C.P_iny_sup_disponible_Pa));
  assert(~C.factibilidad_evaluada);
  assert(~isempty(strfind(C.estado,'PRESION_DERIVADA')));
  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_condicion_motriz_derivada APROBADO\n');
endfunction

function p = base_motriz_local()
  p = struct('D_iny',1500,'T_sup',298.15,'T_fondo',350, ...
    'gamma_g',0.70,'Z',0.85,'rho_g_std',0.80,'A_n',12e-6, ...
    'd_t',0.038,'eta_n',0.98,'rho_o',850,'rho_w',1000,'WC',0.20, ...
    'jgl_k_perdida_gas',0,'jgl_tol_presion_factibilidad_bar',0.10);
  p = jgl_defaults(p);
endfunction
