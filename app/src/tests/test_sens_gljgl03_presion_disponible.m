function ok = test_sens_gljgl03_presion_disponible()
% La presion disponible debe verificar o rechazar el Qiny solicitado.
  ok = false;
  p = base_motriz_local();
  qiny = 12000 / 86400;
  Ps = 75e5;

  p.P_iny_sup = 0;
  p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
  D = jgl_condicion_motriz(p,qiny,Ps);
  assert(isfinite(D.P_iny_sup_requerida_Pa));

  p.P_iny_sup = D.P_iny_sup_requerida_Pa * 1.05;
  p.jgl_condicion_motriz_modo = 'PRESION_DISPONIBLE';
  C1 = jgl_condicion_motriz(p,qiny,Ps);
  assert(C1.factibilidad_evaluada);
  assert(C1.factible_por_presion);
  assert(~C1.bloquea_operacion);
  assert(strcmp(C1.estado,'QINY_FORZADO_PRESION_VERIFICADA'));

  p.P_iny_sup = D.P_iny_sup_requerida_Pa * 0.95;
  C2 = jgl_condicion_motriz(p,qiny,Ps);
  assert(C2.factibilidad_evaluada);
  assert(~C2.factible_por_presion);
  assert(C2.bloquea_operacion);
  assert(strcmp(C2.estado,'QINY_NO_FACTIBLE_POR_PRESION'));

  % En modo derivado, la misma falta de presion se informa pero no oculta
  % la curva de diseno; el optimo queda sujeto a factibilidad posterior.
  p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
  C3 = jgl_condicion_motriz(p,qiny,Ps);
  assert(~C3.bloquea_operacion);
  assert(C3.factibilidad_evaluada);
  assert(~C3.factible_por_presion);
  assert(strcmp(C3.estado,'QINY_FORZADO_PRESION_DERIVADA_SUPERA_DISPONIBLE'));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_presion_disponible APROBADO\n');
endfunction

function p = base_motriz_local()
  p = struct('D_iny',1500,'T_sup',298.15,'T_fondo',350, ...
    'gamma_g',0.70,'Z',0.85,'rho_g_std',0.80,'A_n',12e-6, ...
    'd_t',0.038,'eta_n',0.98,'rho_o',850,'rho_w',1000,'WC',0.20, ...
    'jgl_k_perdida_gas',0,'jgl_tol_presion_factibilidad_bar',0.10);
  p = jgl_defaults(p);
endfunction
