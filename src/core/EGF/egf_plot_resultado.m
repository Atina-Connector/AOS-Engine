function figs=egf_plot_resultado(sol,visible)
  if nargin<2,visible='on';endif
  figs=[];if isempty(sol.barrido_Qs_Sm3_d),return;endif
  f1=figure('Visible',visible,'Name','EGF - Balance del sistema');plot(sol.barrido_Qs_Sm3_d,sol.barrido_residuo_bar,'LineWidth',1.7);hold on;plot(xlim(),[0 0],'k--');if isfield(sol,'Qg_aspirado_Sm3_d'),plot(sol.Qg_aspirado_Sm3_d,0,'ko','MarkerFaceColor','k');endif;grid on;xlabel('Gas aspirado (Sm3/d)');ylabel('Pd eyector - Pd requerida (bar)');title('EGF V1 - Balance del sistema');figs(end+1)=f1;
  if isfield(sol,'punto')
    p=sol.punto;f2=figure('Visible',visible,'Name','EGF - Presiones y caudales');subplot(1,2,1);bar([p.Ps p.Pmix p.Pd_pred p.Pd_req p.Pm_fondo]/1e5);set(gca,'XTickLabel',{'Ps','Pmix','Pd','Pd req','Pm'});ylabel('bar');grid on;title('Presiones del eyector');subplot(1,2,2);bar([p.Qs_std p.Qm_std p.Qtotal_std]*86400);set(gca,'XTickLabel',{'Aspirado','Motriz','Total'});ylabel('Sm3/d');grid on;title('Caudales');figs(end+1)=f2;
    f3=figure('Visible',visible,'Name','EGF - Perfiles');plot(p.lower_profile.P/1e5,p.lower_profile.MD,'LineWidth',1.5);hold on;plot(p.upper_profile.P/1e5,p.upper_profile.MD,'LineWidth',1.5);plot(p.motive_profile.P/1e5,p.motive_profile.MD,'LineWidth',1.5);set(gca,'YDir','reverse');grid on;xlabel('Presion (bar)');ylabel('MD (m)');legend('Gas producido inferior','Descarga superior requerida','Gas motriz anular','Location','northeast');title('EGF - Perfiles de presion');figs(end+1)=f3;
  endif
endfunction
