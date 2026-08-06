function ok = test_sens_gljgl03_inversion_columna()
% P superficie requerida debe invertir exactamente columna y perdida heredadas.
  ok = false;
  p = struct('P_iny_sup',0,'D_iny',1800,'T_sup',295,'T_fondo',360, ...
    'gamma_g',0.72,'Z',0.88,'rho_g_std',0.82,'A_n',10e-6, ...
    'd_t',0.036,'eta_n',0.96,'rho_o',860,'rho_w',1000,'WC',0.15, ...
    'jgl_k_perdida_gas',2.5e6, ...
    'jgl_condicion_motriz_modo','DERIVADA_DESDE_QINY');
  p = jgl_defaults(p);
  qiny = 9000 / 86400;
  Ps = 70e5;
  C = jgl_condicion_motriz(p,qiny,Ps);
  [Pm_back, det] = jgl_presion_motriz_fondo(p,qiny,C.P_iny_sup_requerida_Pa);

  tol = 1e-9 * max(C.P_motriz_fondo_requerida_Pa,1);
  assert(abs(Pm_back - C.P_motriz_fondo_requerida_Pa) <= tol);
  assert(abs((C.P_iny_sup_requerida_Pa + det.deltaP_columna_Pa - ...
    det.deltaP_friccion_Pa) - C.P_motriz_fondo_requerida_Pa) <= tol);
  assert(abs(C.P_motriz_fondo_requerida_Pa - ...
    (C.P_succion_Pa + C.deltaP_motriz_requerida_Pa)) <= tol);

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_inversion_columna APROBADO\n');
endfunction
