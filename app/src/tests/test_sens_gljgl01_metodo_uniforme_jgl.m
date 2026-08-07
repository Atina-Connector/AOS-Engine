function ok = test_sens_gljgl01_metodo_uniforme_jgl()
% TEST_SENS_GLJGL01_METODO_UNIFORME_JGL Impide mezclar metodos en una curva.
  ok = false;
  p = base_jgl_local();
  q = [0, 10000/86400];
  R = jgl_sensibilidad_parametrica(p, q, 'abreviado');

  assert(numel(R.modos) == numel(q));
  assert(all(strcmp(R.modos, 'SENS01_ABREVIADO_DIRECTO_UNIFORME_PRELIMINAR')));
  assert(strcmp(R.modo_final_uniforme, 'DIRECTO'));
  assert(R.preliminar);
  assert(~any(R.valido_para_optimo));
  assert(numel(R.Ql_raw) == numel(q));
  assert(numel(R.Ql) == numel(q));
  for i = 1:numel(q)
    if ~R.valido_para_curva(i)
      assert(isnan(R.Ql(i)) && isnan(R.Qo(i)));
    endif
  endfor

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl01_metodo_uniforme_jgl APROBADO\n');
endfunction

function p = base_jgl_local()
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
  MD = p.survey.MD; TVD = p.survey.TVD; ID = p.survey.ID_tubing;
  p.survey.get_TVD = @(md) interp1(MD, TVD, md, 'linear', 'extrap');
  p.survey.get_ID = @(md) interp1(MD, ID, md, 'linear', 'extrap');
  p = jgl_defaults(p);
endfunction
