function met = gibbs2_metrics(res)
  % Métricas básicas postprocesadas.
  us = res.promedio.u_superficie_m;
  up = res.promedio.u_bomba_m;
  Fs = res.promedio.F_superficie_N;
  Fb = res.promedio.F_bomba_N;
  spm = max(res.param.N_velocidad,0.1);
  Dp = max(res.param.D_bomba_mm,1)/1000;
  Ap = pi*(Dp/2)^2;
  met.stroke_superficie_m = max(us)-min(us);
  met.stroke_fondo_m = max(up)-min(up);
  met.Q_teorico_fondo_m3s = Ap * met.stroke_fondo_m * spm/60;
  met.carga_sup_max_N = max(Fs); met.carga_sup_min_N = min(Fs);
  met.carga_fondo_max_N = max(Fb); met.carga_fondo_min_N = min(Fb);
end
