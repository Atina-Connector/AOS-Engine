function figs = cgf_plot_resultado(sol,visible)
  if nargin<2,visible='on';endif
  figs=[];if isempty(sol.barrido_Q_Sm3_d),return;endif
  f1=figure('Visible',visible,'Name','CGF - Balance del sistema');plot(sol.barrido_Q_Sm3_d,sol.barrido_residuo_bar,'LineWidth',1.7);hold on;plot(xlim(),[0 0],'k--');if isfield(sol,'Qg_Sm3_d'),plot(sol.Qg_Sm3_d,0,'ko','MarkerFaceColor','k');endif;grid on;xlabel('Qg (Sm3/d)');ylabel('Pd compresor - Pd requerida (bar)');title('CGF V1 - Balance del sistema');figs(end+1)=f1;
  f2=figure('Visible',visible,'Name','CGF - Mapa compresor');c=sol.compresor;s=sol.param.cgf_rpm/c.rpm_base;q=c.Qcorr_Sm3_d*s;pr=exp(log(c.PR_base)*s^2);plot(q,pr,'LineWidth',1.8);hold on;if isfield(sol,'punto'),plot(sol.punto.mapa.Qcorr_Sm3_d,sol.punto.mapa.PR,'ko','MarkerFaceColor','k');endif;plot([c.Q_surge*s c.Q_surge*s],ylim(),'r--');plot([c.Q_choke*s c.Q_choke*s],ylim(),'m--');grid on;xlabel('Caudal corregido (Sm3/d)');ylabel('Relacion de presion');title(sprintf('%s | %.0f rpm',c.modelo,sol.param.cgf_rpm));legend('Mapa','Operacion','Surge','Choke','Location','northeast');figs(end+1)=f2;
  if isfield(sol,'punto')
    f3=figure('Visible',visible,'Name','CGF - Perfiles P/T');subplot(1,2,1);plot(sol.punto.lower_profile.P/1e5,sol.punto.lower_profile.MD,'LineWidth',1.5);hold on;plot(sol.punto.upper_profile.P/1e5,sol.punto.upper_profile.MD,'LineWidth',1.5);set(gca,'YDir','reverse');grid on;xlabel('Presion (bar)');ylabel('MD (m)');legend('Tramo inferior','Tramo superior');title('Perfil de presion');subplot(1,2,2);bar([sol.punto.T_s_K-273.15 sol.punto.T_d_K-273.15]);set(gca,'XTickLabel',{'Succion','Descarga'});ylabel('Temperatura (C)');grid on;title('Temperatura del gas');figs(end+1)=f3;
  endif
endfunction
