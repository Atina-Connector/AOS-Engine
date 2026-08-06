function figs = bes2_plot_resultado(sol,visible)
  if nargin<2,visible='on';endif
  figs=[];
  if isempty(sol.barrido_Q_m3_d),return;endif
  f1=figure('Visible',visible,'Name','BES V2 - Balance nodal');
  plot(sol.barrido_Q_m3_d,sol.barrido_residuo_bar,'LineWidth',1.7);hold on;
  plot(xlim(),[0 0],'k--');
  if isfield(sol,'Ql_m3_d'),plot(sol.Ql_m3_d,0,'ko','MarkerFaceColor','k');endif
  grid on;xlabel('Ql (m3/d)');ylabel('Residuo P disponible - P requerida (bar)');title('BES V2 - Balance nodal');
  figs(end+1)=f1;
  f2=figure('Visible',visible,'Name','BES V2 - Curva de bomba');
  subplot(2,1,1);plot(sol.curva.Q_m3_d,sol.curva.head_m,'LineWidth',1.8);hold on;
  if isfield(sol,'punto'),plot(sol.Ql_m3_d,sol.punto.head_m,'ko','MarkerFaceColor','k');endif
  grid on;ylabel('Head total (m)');title(sprintf('%s | %.1f Hz | %d etapas',sol.bomba.modelo,sol.curva.frecuencia_Hz,sol.curva.num_etapas));
  subplot(2,1,2);plot(sol.curva.Q_m3_d,100*sol.curva.eta,'LineWidth',1.5);hold on;
  if isfield(sol,'punto'),plot(sol.Ql_m3_d,100*sol.punto.eta_bomba,'ko','MarkerFaceColor','k');endif
  grid on;xlabel('Ql (m3/d)');ylabel('Eficiencia (%)');
  figs(end+1)=f2;
endfunction
