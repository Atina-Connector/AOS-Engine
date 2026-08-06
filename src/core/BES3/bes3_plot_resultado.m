function figs = bes3_plot_resultado(sol,visible)
  if nargin<2,visible='on';endif;figs=[];
  if ~isfield(sol,'barrido_Q_m3_d')||isempty(sol.barrido_Q_m3_d),return;endif
  apagada=strcmp(texto_local(sol,'modo_operacion'),'BOMBA_APAGADA');q=sol.barrido_Q_m3_d;
  f1=figure('Visible',visible,'Name','BES3 - Analisis nodal completo');
  subplot(2,1,1);
  if apagada,hdisp=plot(q,sol.barrido_Pdesc_disponible_bar,'k--','LineWidth',1.8);else,hdisp=plot(q,sol.barrido_Pdesc_disponible_bar,'b-','LineWidth',1.8);endif
  hold on;hreq=plot(q,sol.barrido_Pdesc_requerida_bar,'r-','LineWidth',1.8);hint=plot(q,sol.barrido_Pintake_bar,'c--','LineWidth',1.3);hipr=plot(q,sol.barrido_Pwf_bar,'g-.','LineWidth',1.2);
  leg=[hdisp hreq hint hipr];labels={disponible_label_local(apagada),'VLP requerida a profundidad BES','P intake disponible','IPR: Pwf en punzados'};
  if isfield(sol,'punto')&&isfield(sol.punto,'Pdesc_req_Pa')
    if sol.punto_operacion_valido
      hp=plot(sol.Ql_m3_d,sol.punto.Pdesc_disponible_Pa/1e5,'ko','MarkerSize',8,'MarkerFaceColor','k');leg(end+1)=hp;labels{end+1}='Punto evaluado';
    else
      hp1=plot(sol.Ql_m3_d,sol.punto.Pdesc_disponible_Pa/1e5,'k^','MarkerSize',8,'LineWidth',1.4);hp2=plot(sol.Ql_m3_d,sol.punto.Pdesc_req_Pa/1e5,'kv','MarkerSize',8,'LineWidth',1.4);
      leg=[leg hp1 hp2];labels=[labels {'Disponible en referencia','Requerida en referencia'}];
    endif
  endif
  legend(leg,labels,'Location','best');grid on;xlabel('Produccion liquida superficie (m3/d)');ylabel('Presion (bar)');
  title(sprintf('BES3 nodal | %s | %.2f Hz | IPR %s | VLP %s (efectiva %s)',texto_local(sol,'modo_operacion'),num_local(sol,'frecuencia_efectiva_Hz'),texto_local(sol,'modelo_IPR'),texto_local(sol,'modelo_VLP'),texto_local(sol,'vlp_efectivo')),'Interpreter','none');

  subplot(2,1,2);hr=plot(q,sol.barrido_residuo_bar,'LineWidth',1.6);hold on;hz=plot([min(q) max(q)],[0 0],'k--','LineWidth',1.0);set(hz,'HandleVisibility','off');
  if isfield(sol,'punto')&&isfield(sol.punto,'residuo')
    if sol.convergido,plot(sol.Ql_m3_d,0,'ko','MarkerSize',8,'MarkerFaceColor','k','HandleVisibility','off');else,plot(sol.Ql_m3_d,sol.punto.residuo/1e5,'kd','MarkerSize',8,'LineWidth',1.5,'HandleVisibility','off');endif
  endif
  grid on;xlabel('Produccion liquida superficie (m3/d)');ylabel('P disponible - requerida (bar)');
  if sol.convergido
    if apagada,title(sprintf('Flujo natural convergido | Q %.2f m3/d',sol.Ql_m3_d));else,title(sprintf('Cruce nodal BES | produccion %.2f m3/d',sol.Ql_m3_d));endif
  else,title(sprintf('SIN CRUCE | referencia %.2f bar | %s',sol.margen_nodal_bar,sol.estado),'Interpreter','none');endif
  figs(end+1)=f1;

  if apagada
    f2=figure('Visible',visible,'Name','BES3 - Bomba apagada');axis off;text(0.05,0.78,'BOMBA APAGADA / 0 Hz','FontWeight','bold','FontSize',14);
    text(0.05,0.62,sprintf('Etapas instaladas: %d\nHead aportado: 0 m\nPotencia al eje: 0 kW\nCorriente: 0 A\nRecirculacion capilar: inactiva\nPerdida pasiva: %.2f bar (%s)', ...
      sol.num_etapas_total,sol.punto.dP_bomba_apagada_Pa/1e5,texto_local(sol.punto.bomba_apagada_loss,'modelo')),'FontSize',11);
    figs(end+1)=f2;return;
  endif

  d=sol.diagnostico_recirculacion;
  f2=figure('Visible',visible,'Name','BES3 - Bomba y secciones');
  subplot(2,1,1);hcurve=plot(sol.curva.Q_m3_d,sol.curva.head_m,'LineWidth',1.7);hold on;
  hp=plot(sol.Q_etapas_superiores_m3_d,sol.punto.head_m,'ko','MarkerFaceColor','k');grid on;ylabel('Head combinado (m)');
  legend([hcurve hp],{'Curva total de referencia','Punto combinado por secciones'},'Location','best');
  title(sprintf('%s | %.1f Hz | %d etapas | toma etapa %d',sol.bomba.modelo,sol.curva.frecuencia_Hz,sol.num_etapas_total,sol.etapa_toma));
  subplot(2,1,2);bar([d.BEP_inferior_pct d.BEP_superior_pct]);hold on;
  plot([0.5 2.5],[100 100],'k--','HandleVisibility','off');set(gca,'XTick',[1 2],'XTickLabel',{'Etapas inferiores','Etapas superiores'});
  grid on;ylabel('Caudal / Q nominal efectivo (%)');title(sprintf('Q inferior %.2f m3/d | Q superior %.2f m3/d',d.Q_etapas_inferiores_m3_d,d.Q_etapas_superiores_m3_d));figs(end+1)=f2;

  if isfield(sol,'punto')
    r=sol.recirculacion;f3=figure('Visible',visible,'Name','BES3 - Refrigeracion y capilar');
    subplot(2,1,1);bar([r.Q_natural_m3_d r.Q_recirc_m3_d r.Q_min_refrig_m3_d d.Q_recirc_max_diseno_m3_d]);
    set(gca,'XTickLabel',{'Natural','Capilar','Minimo termico','Maximo diseno'});ylabel('m3/d');grid on;title(sprintf('%s | %.2f %% Qnom',d.estado_diseno,d.Q_recirc_pct_nominal),'Interpreter','none');
    subplot(2,1,2);
    if isstruct(r.capilar)&&isfield(r.capilar,'ID_m')&&r.Q_recirc_m3_d>0
      qcap=linspace(0,max(1.2*r.Q_recirc_m3_s,r.Q_requerido_m3_s*1.5),80);dp=zeros(size(qcap));
      for i=1:numel(qcap),z=bes3_capillary_loss(qcap(i),sol.punto.fluido.rho_l_kg_m3,sol.punto.fluido.mu_o_Pa_s,r.capilar,sol.param);dp(i)=z.dP_total_Pa/1e5;endfor
      plot(qcap*86400,dp,'LineWidth',1.6);hold on;plot(r.Q_recirc_m3_d,r.dP_disponible_Pa/1e5,'ko','MarkerFaceColor','k');xlabel('Recirculacion (m3/d)');ylabel('Perdida capilar (bar)');grid on;
    else,text(0.05,0.5,'Sin capilar activo','Units','normalized');axis off;endif
    figs(end+1)=f3;
  endif
endfunction
function s=disponible_label_local(apagada),if apagada,s='P disponible con BES apagada';else,s='P descarga disponible con BES';endif,endfunction
function s=texto_local(x,campo),s='N/A';if isstruct(x)&&isfield(x,campo)&&ischar(x.(campo)),s=x.(campo);endif,endfunction
function v=num_local(x,campo),v=NaN;if isstruct(x)&&isfield(x,campo)&&isnumeric(x.(campo))&&~isempty(x.(campo)),v=x.(campo)(1);endif,endfunction
