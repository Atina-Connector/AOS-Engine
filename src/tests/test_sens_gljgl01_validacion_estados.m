function ok = test_sens_gljgl01_validacion_estados()
% TEST_SENS_GLJGL01_VALIDACION_ESTADOS Rechazo estricto y firma inmutable.
  ok = false;
  p = base_gljgl_local();

  vb = sens_validar_base_gl_jgl(p, 'JGL');
  assert(vb.ok);

  p_bad = p;
  p_bad.WC = 65;
  vb_bad = sens_validar_base_gl_jgl(p_bad, 'JGL');
  assert(~vb_bad.ok);
  assert(~isempty(vb_bad.errores));

  p2 = p;
  p2.Q_iny = 12345 / 86400;
  p2.Qiny_plot = 54321 / 86400;
  p2.sens_nodal_n_puntos = 61;
  p2.sens_jgl_n_puntos = 81;
  [f1, ~] = sens_firma_config_gl_jgl(p);
  [f2, ~] = sens_firma_config_gl_jgl(p2);
  assert(strcmp(f1, f2));

  p3 = p;
  p3.P_wh = p.P_wh + 1e5;
  [f3, ~] = sens_firma_config_gl_jgl(p3);
  assert(~strcmp(f1, f3));

  % Un cero de auditoria sin cruce no se publica como produccion valida.
  det0 = struct('estado', 'SIN_CRUCE_PRESION_INSUFICIENTE', ...
                'tol_P', 0.05e5, 'Ql_max_IPR', 100 / 86400);
  vg0 = sens_validar_punto_gl(p, 10000/86400, 0, 0, 10000/86400, det0, struct());
  assert(~vg0.aceptado);
  assert(~vg0.valido_para_curva);
  assert(~vg0.valido_para_optimo);

  % Un resultado negativo nunca se publica aunque el texto diga cruce.
  detn = struct('estado', 'CRUCE_RESUELTO', ...
                'tol_P', 0.05e5, 'Ql_max_IPR', 100 / 86400);
  vgn = sens_validar_punto_gl(p, 10000/86400, 10/86400, -1/86400, ...
                              10000/86400, detn, struct());
  assert(~vgn.aceptado);
  assert(~vgn.valido_para_curva);

  % El ultimo iterado de NO_CONVERGE se conserva como raw, pero se rechaza.
  ed = struct('estado','OK','pot_disp',1000,'pot_trans',500, ...
              'deltaP',1e5,'Ps',50e5,'Pd',51e5,'Pm',80e5, ...
              'eta',0.5,'entrainment',0.1);
  sj = struct('estado','NO_CONVERGE','modo_utilizado','ITERATIVO', ...
              'Ql',10/86400,'Qo',5/86400,'Qiny',10000/86400, ...
              'deltaP',1e5,'eductor',ed,'iteraciones',10);
  vj = sens_validar_punto_jgl(p, 10000/86400, sj, struct());
  assert(~vj.aceptado);
  assert(~vj.valido_para_curva);
  assert(~vj.valido_para_optimo);

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl01_validacion_estados APROBADO\n');
endfunction

function p = base_gljgl_local()
  p = struct();
  p.P_res = 200e5;
  p.IP = 0.1 / 86400 / 1e5;
  p.P_wh = 10e5;
  p.P_iny_sup = 80e5;
  p.D_iny = 1500;
  p.D_res = 2200;
  p.WC = 0.5;
  p.GLR = 50;
  p.rho_o = 850;
  p.rho_w = 1000;
  p.rho_g_std = 0.8;
  p.API = 35;
  p.gamma_g = 0.7;
  p.T_sup = 298.15;
  p.T_fondo = 360;
  p.diam_tbg = 0.062;
  p.modelo_IPR = 'linear';
  p.modelo_VLP = 'simplified';
  p.factor_IP_residual = 1;
  p.P_b = 100e5;
  p.A_n = 12e-6;
  p.d_t = 0.038;
  p.eta_n = 0.98;
  p.eta_t = 0.85;
  p.eta_d = 0.80;
  p.a_eductor = 1;
  p.b_eductor = 1;
  p.jgl_geometria_modo = 'calibrada';
  p.jgl_tol_P_bar = 0.25;
  p.jgl_tol_Q_rel = 0.005;
  p.jgl_tol_dP_bar = 0.25;
  p.jgl_min_iter = 3;
  p.jgl_max_iter = 10;
  p.survey.MD = [0;1500;2200];
  p.survey.TVD = [0;1450;2100];
  p.survey.inclinacion = [0;10;12];
  p.survey.ID_tubing = [0.062;0.062;0.062];
  p.survey.rugosidad = [4.6e-5;4.6e-5;4.6e-5];
endfunction
