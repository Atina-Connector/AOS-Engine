function ok = test_sens_gljgl01_paridad_gl()
% TEST_SENS_GLJGL01_PARIDAD_GL El punto del barrido reproduce GL_sim.
  ok = false;
  p = base_gl_local();
  p = sens_preparar_base(p, 'SENS_GL');
  p.sens_nodal_n_puntos = 1201;
  p = aos_sincronizar_config(p, 'GL');
  qvals = [0, 10000/86400, 50000/86400];

  for i = 1:numel(qvals)
    q = qvals(i);
    [ql, qo, qg, qef, ~, det] = GL_sim(p, q);
    E = sens_gl_evaluar_punto(p, q, struct('n_puntos',1201,'preliminar',false));

    assert(cerca_local(E.Ql_raw, ql));
    assert(cerca_local(E.Qo_raw, qo));
    assert(cerca_local(E.Qgas_total_raw, qg));
    assert(cerca_local(E.Qiny_efectivo, qef));
    assert(strcmp(E.estado, det.estado));
    assert(E.Qiny_solicitado == q);
    if E.valido_para_curva
      assert(cerca_local(E.Ql, ql));
      assert(cerca_local(E.Qo, qo));
      assert(E.Ql >= 0 && E.Qo >= 0 && E.Qo <= E.Ql + 1e-12);
    else
      assert(isnan(E.Ql) && isnan(E.Qo));
    endif
  endfor

  ok = true;
  fprintf('RESULTADO: test_sens_gljgl01_paridad_gl APROBADO\n');
endfunction

function tf = cerca_local(a, b)
  if isnan(a) && isnan(b)
    tf = true;
    return;
  endif
  tf = isfinite(a) && isfinite(b) && ...
       abs(a-b) <= max(1e-12, 1e-10 * max([abs(a), abs(b), 1e-9]));
endfunction

function p = base_gl_local()
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
  p.survey.MD = [0;1500;2200];
  p.survey.TVD = [0;1450;2100];
  p.survey.inclinacion = [0;10;12];
  p.survey.ID_tubing = [0.062;0.062;0.062];
  p.survey.rugosidad = [4.6e-5;4.6e-5;4.6e-5];
  MD = p.survey.MD; TVD = p.survey.TVD; ID = p.survey.ID_tubing;
  p.survey.get_TVD = @(md) interp1(MD, TVD, md, 'linear', 'extrap');
  p.survey.get_ID = @(md) interp1(MD, ID, md, 'linear', 'extrap');
endfunction
