function test_parche_0_0_11f_nodal_gl()
% Test básico de funciones instaladas. No reemplaza benchmark contra PROSPER.
  fprintf('Test AOS 0.0.11f - Nodal GL...\n');
  assert(exist('aos_nodal_balance_gl','file') == 2);
  assert(exist('aos_buscar_cruce_nodal','file') == 2);
  assert(exist('aos_profundidad_inyeccion','file') == 2);
  assert(exist('aos_tvd_at_md','file') == 2);

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
  p.Q_iny = 10000/86400;
  p.survey.MD = [0;1500;2200];
  p.survey.TVD = [0;1450;2100];
  p.survey.inclinacion = [0;10;12];
  p.survey.ID_tubing = [0.062;0.062;0.062];
  p.survey.rugosidad = [4.6e-5;4.6e-5;4.6e-5];
  MD = p.survey.MD; TVD = p.survey.TVD; ID = p.survey.ID_tubing;
  p.survey.get_TVD = @(md) interp1(MD, TVD, md, 'linear', 'extrap');
  p.survey.get_ID = @(md) interp1(MD, ID, md, 'linear', 'extrap');

  [qmax, ~] = ipr(p, 'linear');
  assert(qmax > 0);
  [Ql, det] = aos_resolver_gl(p, p.Q_iny);
  assert(isfield(det, 'estado'));
  assert(Ql >= 0);
  fprintf('  Estado solver: %s | Ql %.3f m3/d\n', det.estado, Ql*86400);
  fprintf('OK test AOS 0.0.11f.\n');
end
