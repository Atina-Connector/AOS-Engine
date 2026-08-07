function res = gibbs2_postprocess(res)
  param = res.param;
  spm = max(param.N_velocidad,0.1); T = 60/spm;
  ncy = max(1, round(param.gibbs2_n_ciclos));
  ppc = max(120, round(param.gibbs2_puntos_por_ciclo));
  desc = max(0, round(param.gibbs2_descartar_ciclos));
  desc = min(desc, ncy-1);
  idx = find(res.t >= desc*T);
  if isempty(idx), idx = 1:length(res.t); end
  t = res.t(idx); U = res.U(idx,:);
  Fs = res.F_superficie_N(idx); Fb = res.F_bomba_N(idx);
  us = U(:,1); up = U(:,end);
  res.estable.t = t; res.estable.u_superficie_m = us; res.estable.u_bomba_m = up;
  res.estable.F_superficie_N = Fs; res.estable.F_bomba_N = Fb;
  ciclos_validos = (desc+1):ncy; nvalidos = length(ciclos_validos);
  fase = (0:ppc)'/ppc;
  us_c=zeros(ppc+1,nvalidos); up_c=zeros(ppc+1,nvalidos);
  Fs_c=zeros(ppc+1,nvalidos); Fb_c=zeros(ppc+1,nvalidos);
  for k=1:nvalidos
      c=ciclos_validos(k); i1=(c-1)*ppc+1; i2=c*ppc+1;
      if i2>length(res.t), i2=length(res.t); i1=max(1,i2-ppc); end
      ii=i1:i2;
      if length(ii)==ppc+1
          us_c(:,k)=res.U(ii,1); up_c(:,k)=res.U(ii,end);
          Fs_c(:,k)=res.F_superficie_N(ii); Fb_c(:,k)=res.F_bomba_N(ii);
      else
          fase_i=linspace(0,1,length(ii))';
          us_c(:,k)=interp1(fase_i,res.U(ii,1),fase,'linear','extrap');
          up_c(:,k)=interp1(fase_i,res.U(ii,end),fase,'linear','extrap');
          Fs_c(:,k)=interp1(fase_i,res.F_superficie_N(ii),fase,'linear','extrap');
          Fb_c(:,k)=interp1(fase_i,res.F_bomba_N(ii),fase,'linear','extrap');
      end
  end
  us_prom=mean(us_c,2); up_prom=mean(up_c,2);
  Fs_prom=mean(Fs_c,2); Fb_prom=mean(Fb_c,2);
  us_prom(end)=us_prom(1); up_prom(end)=up_prom(1);
  Fs_prom(end)=Fs_prom(1); Fb_prom(end)=Fb_prom(1);
  res.promedio.fase=fase; res.promedio.ciclos=ciclos_validos; res.promedio.n_ciclos=nvalidos;
  res.promedio.u_superficie_m=us_prom; res.promedio.u_bomba_m=up_prom;
  res.promedio.F_superficie_N=Fs_prom; res.promedio.F_bomba_N=Fb_prom;
  % Métricas
  met = gibbs2_metrics(res);
  res.metricas = met;
  % Cartas
  res.cartas.superficie = [us_prom Fs_prom];
  res.cartas.fondo = [up_prom Fb_prom];
end
