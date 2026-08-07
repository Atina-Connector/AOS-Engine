function res = gibbs18_postprocess(res)
% Extrae ciclos estables, genera cartas promedio cerradas y metricas basicas.
% Regla v18:
%   - simular N ciclos
%   - descartar el/los primeros ciclos transitorios
%   - promediar punto a punto los ciclos restantes
%   - graficar una sola carta cerrada carga-posicion para superficie y fondo

  param = res.param;
  spm = max(param.N_velocidad,0.1);
  T = 60/spm;
  ncy = max(1, round(param.gibbs18_n_ciclos));
  ppc = max(120, round(param.gibbs18_puntos_por_ciclo));
  desc = max(0, round(param.gibbs18_descartar_ciclos));
  desc = min(desc, ncy-1);

  idx = find(res.t >= desc*T);
  if isempty(idx), idx = 1:length(res.t); end

  t = res.t(idx);
  U = res.U(idx,:);
  Fs = res.F_superficie_N(idx);
  if isfield(res,'F_superficie_dinamica_N')
      Fs_dyn = res.F_superficie_dinamica_N(idx);
  else
      Fs_dyn = Fs;
  end
  Fb = res.F_bomba_N(idx);
  up = U(:,end);
  us = U(:,1);

  res.estable.t = t;
  res.estable.u_superficie_m = us;
  res.estable.u_bomba_m = up;
  res.estable.F_superficie_N = Fs;
  res.estable.F_superficie_dinamica_N = Fs_dyn;
  res.estable.F_bomba_N = Fb;

  ciclos_validos = (desc+1):ncy;
  nvalidos = length(ciclos_validos);
  fase = (0:ppc)'/ppc;

  us_c = zeros(ppc+1, nvalidos);
  up_c = zeros(ppc+1, nvalidos);
  Fs_c = zeros(ppc+1, nvalidos);
  Fs_dyn_c = zeros(ppc+1, nvalidos);
  Fb_c = zeros(ppc+1, nvalidos);

  for k = 1:nvalidos
      c = ciclos_validos(k);
      i1 = (c-1)*ppc + 1;
      i2 = c*ppc + 1;
      if i2 > length(res.t)
          i2 = length(res.t);
          i1 = max(1, i2-ppc);
      end
      ii = i1:i2;
      if length(ii) == ppc+1
          us_c(:,k) = res.U(ii,1);
          up_c(:,k) = res.U(ii,end);
          Fs_c(:,k) = res.F_superficie_N(ii);
          if isfield(res,'F_superficie_dinamica_N')
              Fs_dyn_c(:,k) = res.F_superficie_dinamica_N(ii);
          else
              Fs_dyn_c(:,k) = res.F_superficie_N(ii);
          end
          Fb_c(:,k) = res.F_bomba_N(ii);
      else
          fase_i = linspace(0,1,length(ii))';
          us_c(:,k) = interp1(fase_i, res.U(ii,1), fase, 'linear', 'extrap');
          up_c(:,k) = interp1(fase_i, res.U(ii,end), fase, 'linear', 'extrap');
          Fs_c(:,k) = interp1(fase_i, res.F_superficie_N(ii), fase, 'linear', 'extrap');
          if isfield(res,'F_superficie_dinamica_N')
              Fs_dyn_c(:,k) = interp1(fase_i, res.F_superficie_dinamica_N(ii), fase, 'linear', 'extrap');
          else
              Fs_dyn_c(:,k) = interp1(fase_i, res.F_superficie_N(ii), fase, 'linear', 'extrap');
          end
          Fb_c(:,k) = interp1(fase_i, res.F_bomba_N(ii), fase, 'linear', 'extrap');
      end
  end

  us_prom = mean(us_c, 2);
  up_prom = mean(up_c, 2);
  Fs_prom = mean(Fs_c, 2);
  Fs_dyn_prom = mean(Fs_dyn_c, 2);
  Fb_prom = mean(Fb_c, 2);

  % Forzar cierre geometrico numerico de la carta promedio.
  us_prom(end) = us_prom(1);
  up_prom(end) = up_prom(1);
  Fs_prom(end) = Fs_prom(1);
  Fs_dyn_prom(end) = Fs_dyn_prom(1);
  Fb_prom(end) = Fb_prom(1);

  res.promedio.fase = fase;
  res.promedio.ciclos = ciclos_validos;
  res.promedio.n_ciclos = nvalidos;
  res.promedio.u_superficie_m = us_prom;
  res.promedio.u_bomba_m = up_prom;
  res.promedio.F_superficie_N = Fs_prom;
  res.promedio.F_superficie_dinamica_N = Fs_dyn_prom;
  res.promedio.F_bomba_N = Fb_prom;
  res.promedio.u_superficie_ciclos_m = us_c;
  res.promedio.u_bomba_ciclos_m = up_c;
  res.promedio.F_superficie_ciclos_N = Fs_c;
  res.promedio.F_superficie_dinamica_ciclos_N = Fs_dyn_c;
  res.promedio.F_bomba_ciclos_N = Fb_c;

  res.metricas.stroke_superficie_m = max(us_prom)-min(us_prom);
  res.metricas.stroke_fondo_m = max(up_prom)-min(up_prom);
  Dp = max(param.D_bomba_mm,1)/1000;
  Ap = pi*(Dp/2)^2;
  res.metricas.Q_teorico_fondo_m3s = Ap*res.metricas.stroke_fondo_m*spm/60;
  res.metricas.Q_teorico_fondo_m3d = res.metricas.Q_teorico_fondo_m3s*86400;
  res.metricas.carga_sup_max_N = max(Fs_prom);
  res.metricas.carga_sup_min_N = min(Fs_prom);
  res.metricas.carga_sup_dinamica_max_N = max(Fs_dyn_prom);
  res.metricas.carga_sup_dinamica_min_N = min(Fs_dyn_prom);
  res.metricas.carga_bomba_max_N = max(Fb_prom);
  res.metricas.carga_bomba_min_N = min(Fb_prom);
  res.metricas.ciclos_promediados = ciclos_validos;
  res.metricas.n_ciclos_promediados = nvalidos;
  res.metricas.promedio_punto_a_punto = 1;
  if isfield(res,'diagnostico_cargas')
      res.metricas.offset_superficie_N = res.diagnostico_cargas.offset_superficie_N;
  else
      res.metricas.offset_superficie_N = 0;
  end

  % Desde v18.1 las cartas principales son las cartas promedio cerradas.
  res.cartas.superficie = [us_prom Fs_prom];
  res.cartas.fondo = [up_prom Fb_prom];
end
