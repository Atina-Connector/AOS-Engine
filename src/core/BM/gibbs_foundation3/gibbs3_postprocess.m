function res = gibbs3_postprocess(res)
% GIBBS3_POSTPROCESS Promedia por fase y aplica movimiento de tuberia.
% Positivo axial = hacia arriba; elongacion de tubing mueve el barril abajo.

  ppc = res.param.gibbs3_puntos_por_ciclo;
  ncy = res.param.gibbs3_n_ciclos;
  nd = res.param.gibbs3_descartar_ciclos;
  ciclos = (nd+1):ncy;
  nc = numel(ciclos);

  n = res.malla.n;
  Uavg=zeros(ppc,n); Vavg=zeros(ppc,n);
  Fsa=zeros(ppc,1); Fba=zeros(ppc,1); Ava=zeros(ppc,1);
  Fla=zeros(ppc,1); DPa=zeros(ppc,1); Qa=zeros(ppc,1);

  for c=ciclos
    idx=(c-1)*ppc+(1:ppc);
    Uavg=Uavg+res.U(idx,:);
    Vavg=Vavg+res.V(idx,:);
    Fsa=Fsa+res.F_superficie_N(idx);
    Fba=Fba+res.F_bomba_N(idx);
    Ava=Ava+res.apertura_valvula(idx);
    Fla=Fla+res.F_LPP_N(idx); DPa=DPa+res.deltaP_LPP_Pa(idx); Qa=Qa+res.Q_LPP_m3_s(idx);
  end

  Uavg=Uavg/nc; Vavg=Vavg/nc;
  Fsa=Fsa/nc; Fba=Fba/nc; Ava=Ava/nc; Fla=Fla/nc; DPa=DPa/nc; Qa=Qa/nc;

  tphase=(0:ppc)'*(60/res.param.N_velocidad/ppc);
  Uc=[Uavg;Uavg(1,:)];
  Vc=[Vavg;Vavg(1,:)];
  Fsc=[Fsa;Fsa(1)];
  Fbc=[Fba;Fba(1)];
  Avc=[Ava;Ava(1)]; Flc=[Fla;Fla(1)]; DPc=[DPa;DPa(1)]; Qc=[Qa;Qa(1)];

  % Movimiento de tuberia: no altera la solucion de varillas ni las cargas.
  tub=gibbs3_tubing_motion(res.param,Fbc);
  u_varilla_fondo=Uc(:,end);
  u_tuberia_fondo=tub.u_fondo_m;
  % Posicion relativa piston-barril. Cuando el tubing libre se elonga,
  % el barril baja (u_tuberia_fondo < 0); por eso la rama elastica debe
  % conservar rigidez positiva.
  u_piston_relativo=u_varilla_fondo-u_tuberia_fondo;

  prom=struct();
  prom.t_s=tphase;
  prom.U_m=Uc;
  prom.V_m_s=Vc;
  prom.u_superficie_m=Uc(:,1);
  prom.u_varilla_fondo_m=u_varilla_fondo;
  prom.u_tuberia_fondo_m=u_tuberia_fondo;
  prom.elongacion_tuberia_m=tub.elongacion_m;
  prom.u_piston_relativo_m=u_piston_relativo;
  % Alias historico: desde GF3 v1.1 la posicion de bomba es piston-barril.
  prom.u_bomba_m=u_piston_relativo;
  prom.F_superficie_N=Fsc;
  prom.F_bomba_N=Fbc;
  prom.apertura_valvula=Avc;
  prom.F_LPP_N=Flc; prom.deltaP_LPP_Pa=DPc; prom.Q_LPP_m3_s=Qc;
  prom.ciclos_promediados=ciclos;
  prom.tuberia=tub;
  prom.aparato=gibbs3_pumping_unit_cycle(res.param,tphase);

  if res.param.gibbs3_normalizar_posiciones_grafico
    prom.u_superficie_plot_m=normalizar(prom.u_superficie_m);
    prom.u_varilla_fondo_plot_m=normalizar(prom.u_varilla_fondo_m);
    prom.u_tuberia_fondo_plot_m=normalizar(prom.u_tuberia_fondo_m);
    prom.u_piston_relativo_plot_m=normalizar(prom.u_piston_relativo_m);
    prom.u_bomba_plot_m=prom.u_piston_relativo_plot_m;
  else
    prom.u_superficie_plot_m=prom.u_superficie_m;
    prom.u_varilla_fondo_plot_m=prom.u_varilla_fondo_m;
    prom.u_tuberia_fondo_plot_m=prom.u_tuberia_fondo_m;
    prom.u_piston_relativo_plot_m=prom.u_piston_relativo_m;
    prom.u_bomba_plot_m=prom.u_piston_relativo_m;
  end

  res.promedio=prom;
  res.tuberia=tub;
  res.metricas=gibbs3_metrics(res);
  res.diseno_sarta_espaciamiento=gibbs3_rod_spacing_design(res);
  res.verificacion_aparato=gibbs3_pumping_unit_verify(res);
end

function y=normalizar(x)
  y=x-min(x);
end
