function C = bes3_comparar_on_off(param)
% Ejecuta el mismo pozo con bomba apagada y encendida, preservando IPR/VLP.
  p=bes3_defaults(param);f_on=p.bes3_frecuencia_on_comparacion_Hz;
  if ~isfinite(f_on)||f_on<=0,f_on=max(p.bes3_frecuencia_configurada_Hz,60);endif
  poff=p;poff.frecuencia=0;poff.bes3_estado_bomba='apagada';poff.bes3_modo_frecuencia='comparacion_off';
  poff.bes3_frecuencia_solicitada_Hz=0;poff.bes3_frecuencia_efectiva_Hz=0;
  pon=p;pon.frecuencia=f_on;pon.bes3_estado_bomba='encendida';pon.bes3_modo_frecuencia='comparacion_on';
  pon.bes3_frecuencia_solicitada_Hz=f_on;pon.bes3_frecuencia_efectiva_Hz=f_on;
  off=bes3_solver(poff);on=bes3_solver(pon);
  dQ=on.Ql_m3_d-off.Ql_m3_d;dQo=on.Qo_m3_d-off.Qo_m3_d;
  if off.Ql_m3_d>1e-9,inc=100*dQ/off.Ql_m3_d;else,inc=NaN;endif
  C=struct('version',p.bes3_version,'modelo_IPR',p.modelo_IPR,'modelo_VLP',p.modelo_VLP, ...
    'frecuencia_on_Hz',f_on,'apagada',off,'encendida',on,'delta_Ql_m3_d',dQ, ...
    'delta_Qo_m3_d',dQo,'incremento_pct',inc,'potencia_incremental_kW',potencia_local(on), ...
    'figures',[]);
  fprintf('\n========== COMPARACION BES3 ON / OFF ==========\n');
  fprintf('IPR / VLP                 : %s / %s\n',p.modelo_IPR,p.modelo_VLP);
  fprintf('Bomba apagada (0 Hz)      : %.2f m3/d | %s\n',off.Ql_m3_d,off.estado);
  fprintf('Bomba encendida (%.2f Hz): %.2f m3/d | %s\n',f_on,on.Ql_m3_d,on.estado);
  fprintf('Ganancia de liquido       : %.2f m3/d\n',dQ);
  fprintf('Ganancia de petroleo      : %.2f m3/d\n',dQo);
  if isfinite(inc),fprintf('Incremento relativo       : %.1f %%\n',inc);else,fprintf('Incremento relativo       : N/A (Q natural = 0)\n');endif
  fprintf('Potencia superficial ON   : %.2f kW\n',potencia_local(on));
  fprintf('================================================\n');
  f=figure('Name','BES3 - Comparacion bomba apagada vs encendida');
  subplot(2,1,1);hold on;
  plot(off.barrido_Q_m3_d,off.barrido_Pdesc_disponible_bar,'k--','LineWidth',1.5);
  plot(off.barrido_Q_m3_d,off.barrido_Pdesc_requerida_bar,'r-','LineWidth',1.3);
  plot(on.barrido_Q_m3_d,on.barrido_Pdesc_disponible_bar,'b-','LineWidth',1.7);
  if off.punto_operacion_valido,plot(off.Ql_m3_d,off.punto.Pdesc_disponible_Pa/1e5,'ko','MarkerFaceColor','k');endif
  if on.punto_operacion_valido,plot(on.Ql_m3_d,on.punto.Pdesc_disponible_Pa/1e5,'bo','MarkerFaceColor','b');endif
  grid on;xlabel('Ql superficie (m3/d)');ylabel('Presion (bar)');
  title(sprintf('BES3 ON/OFF | IPR %s | VLP %s',p.modelo_IPR,p.modelo_VLP),'Interpreter','none');
  legend({'Disponible OFF','VLP requerida','Disponible ON','Punto OFF','Punto ON'},'Location','northeast');
  subplot(2,1,2);bar([off.Ql_m3_d on.Ql_m3_d;0 potencia_local(on)]);
  set(gca,'XTickLabel',{'Produccion m3/d','Potencia kW'});legend({'OFF','ON'});grid on;
  title(sprintf('Delta Ql = %.2f m3/d',dQ));C.figures=f;
endfunction
function v=potencia_local(s),v=NaN;if isfield(s,'electrico')&&isstruct(s.electrico)&&isfield(s.electrico,'P_superficie_kW'),v=s.electrico.P_superficie_kW;endif,endfunction
