function ok = test_sens_gljgl03_barrido_derivado_jgl()
% Campana corta: con Qiny forzado y P_iny_sup=0 la ruta derivada debe
% publicar la presion requerida, aunque el punto productivo pueda ser
% rechazado por otra causa fisica o numerica.
  ok = false;
  p = base_jgl_local();
  p.P_iny_sup = 0;
  p.P_iny_sup_importada_original = 0;
  p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
  p.jgl_presion_sup_estado = 'NO_INFORMADA_DERIVAR_DESDE_QINY';
  q = [0, 10000/86400];

  R = jgl_sensibilidad_parametrica(p,q,'abreviado');
  assert(numel(R.P_iny_sup_requerida) == numel(q));
  assert(isfinite(R.P_iny_sup_requerida(2)));
  assert(R.P_iny_sup_requerida(2) > 0);
  assert(R.presion_requerida_valida(2));
  assert(strcmp(R.modo_condicion_motriz{2},'DERIVADA_DESDE_QINY'));
  assert(isnan(R.P_iny_sup_disponible(2)));
  assert(~R.factibilidad_presion_evaluada(2));
  assert(~strcmp(R.estado_presion_motriz{2},'SIN_PRESION_MOTRIZ'));
  assert(~strcmp(R.estados{2},'SIN_PRESION_MOTRIZ'));

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl03_barrido_derivado_jgl APROBADO\n');
endfunction

function p = base_jgl_local()
  p = struct();
  p.P_res = 200e5;
  p.IP = 0.1 / 86400 / 1e5;
  p.P_wh = 10e5;
  p.P_iny_sup = 0;
  p.D_iny = 1500;
  p.D_res = 2200;
  p.WC = 0.20;
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
  p.P_b = 100e5;
  p.factor_IP_residual = 1;
  p.A_n = 12e-6;
  p.d_t = 0.038;
  p.eta_n = 0.98;
  p.eta_t = 0.85;
  p.eta_d = 0.80;
  p.jgl_geometria_modo = 'derivada';
  p.survey.MD = [0;1500;2200];
  p.survey.TVD = [0;1450;2100];
  p.survey.inclinacion = [0;10;12];
  p.survey.ID_tubing = [0.062;0.062;0.062];
  p.survey.rugosidad = [4.6e-5;4.6e-5;4.6e-5];
  MD = p.survey.MD;
  TVD = p.survey.TVD;
  ID = p.survey.ID_tubing;
  p.survey.get_TVD = @(md) interp1(MD,TVD,md,'linear','extrap');
  p.survey.get_ID = @(md) interp1(MD,ID,md,'linear','extrap');
  p = jgl_defaults(p);
endfunction
