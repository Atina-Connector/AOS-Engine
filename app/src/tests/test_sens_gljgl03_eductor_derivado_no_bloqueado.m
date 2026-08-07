function ok = test_sens_gljgl03_eductor_derivado_no_bloqueado()
% La ruta cinetica historica debe ser alcanzable con P_iny_sup=0 y Qiny fijo.
  ok = false;
  p = struct('P_iny_sup',0,'D_iny',1500,'T_sup',298.15,'T_fondo',350, ...
    'gamma_g',0.70,'Z',0.85,'rho_g_std',0.80,'A_n',12e-6, ...
    'd_t',0.038,'eta_n',0.98,'rho_o',850,'rho_w',1000,'WC',0.20, ...
    'jgl_geometria_modo','derivada', ...
    'jgl_condicion_motriz_modo','DERIVADA_DESDE_QINY');
  p = jgl_defaults(p);
  qiny = 10000 / 86400;
  Ql = 20 / 86400;
  Ps = 80e5;
  e = jgl_eductor_comun(p,Ql,qiny,Ps);

  assert(~strcmp(e.estado,'SIN_PRESION_MOTRIZ'));
  assert(isfield(e,'condicion_motriz'));
  assert(~e.condicion_motriz.bloquea_operacion);
  assert(e.Pm > Ps);
  assert(e.Piny_sup_requerida > 0);
  assert(e.pot_disp > 0);
  assert(e.deltaP >= 0);
  assert(isfield(e,'detalle'));
  assert(isfield(e.detalle,'origen_deltaP'));
  assert(strcmp(e.detalle.origen_deltaP,'qiny_impuesto_cinetico_explicito'));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_eductor_derivado_no_bloqueado APROBADO\n');
endfunction
