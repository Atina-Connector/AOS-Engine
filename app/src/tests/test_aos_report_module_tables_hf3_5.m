function ok = test_aos_report_module_tables_hf3_5()
% TEST_AOS_REPORT_MODULE_TABLES_HF3_5 Verifica inventario por modulo.
  ok = false;

  p = struct();
  n = 721;
  p.cartas_sup = [(0:n-1)'/n, 30000 + (1:n)'];
  p.cartas_fondo = [(0:n-1)'/n, 10000 + (1:n)'];
  t = aos_report_collect_standard_tables(p,'BM');
  assert(tiene_id_local(t,'bm_carta_gibbs'));
  [carta,~] = aos_report_table_find(t,'bm_carta_gibbs');
  assert(carta.n_rows == 721 && carta.n_columns == 5);
  assert(strcmp(carta.default_mode,'VIEWER_ONLY'));

  res = struct();
  res.param = struct();
  pr = struct();
  campos = {'t_s','u_superficie_m','u_varilla_fondo_m','u_tuberia_fondo_m', ...
    'u_piston_relativo_m','F_superficie_N','F_bomba_N','apertura_valvula', ...
    'F_LPP_N','deltaP_LPP_Pa','Q_LPP_m3_s'};
  for i = 1:numel(campos), pr.(campos{i}) = linspace(0,1,n); endfor
  res.promedio = pr;
  tg = gibbs3_report_build_tables(res);
  assert(tiene_id_local(tg,'gf3_ciclo_promedio'));
  [ciclo,~] = aos_report_table_find(tg,'gf3_ciclo_promedio');
  assert(ciclo.n_rows == 721 && strcmp(ciclo.default_mode,'VIEWER_ONLY'));

  sol2 = struct('curva',struct('Q_m3_d',[1 2 3],'head_m',[100 90 70],'eta',[0.5 0.6 0.55]));
  tb2 = bes2_report_build_tables(sol2);
  assert(tiene_id_local(tb2,'bes2_pump_curve'));

  sol3 = struct();
  sol3.curva = sol2.curva;
  sol3.barrido_Q_m3_d = [1 2 3];
  sol3.barrido_Pwf_bar = [10 9 8];
  sol3.barrido_Pintake_bar = [8 7 6];
  sol3.barrido_Pdesc_disponible_bar = [30 30 30];
  sol3.barrido_Pdesc_requerida_bar = [20 21 22];
  sol3.barrido_residuo_bar = [10 9 8];
  sol3.barrido_dP_bomba_bar = [12 13 14];
  sol3.barrido_dP_bomba_apagada_bar = [0 0 0];
  sol3.semaforos = struct('id',{'A','B'},'estado',{'VERDE','AMARILLO'}, ...
    'mensaje',{'OK','REVISAR'});
  tb3 = bes3_report_build_tables(sol3);
  assert(tiene_id_local(tb3,'bes3_nodal'));
  assert(tiene_id_local(tb3,'bes3_pump_curve'));
  assert(tiene_id_local(tb3,'bes3_semaforos'));

  cgf = struct('compresor',struct('Qcorr_Sm3_d',[100 200 300], ...
    'PR_base',[1.2 1.4 1.6],'eta_p',[0.6 0.7 0.65]));
  tc = cgf_report_build_tables(cgf);
  assert(tiene_id_local(tc,'cgf_compressor_map'));

  ok = true;
  fprintf('RESULTADO: test_aos_report_module_tables_hf3_5 APROBADO\n');
endfunction

function tf = tiene_id_local(tablas,id)
  tf = false;
  if isempty(tablas), return; endif
  for i = 1:numel(tablas)
    if isfield(tablas(i),'id') && strcmp(tablas(i).id,id), tf = true; return; endif
  endfor
endfunction
