function egf_sensibilidad_menu(param)
% DEV5.4: toda sensibilidad EGF finaliza mediante aos_report_dispatcher.
  fprintf('\n--- SENSIBILIDADES EGF ---\n1 - Presion motriz superficial\n2 - Profundidad del eyector\n3 - Area de tobera\n4 - Area de garganta\n5 - Presion de cabeza\n0 - Volver\n');op=input('Seleccione: ');if isempty(op)||op==0,return;endif
  switch op,case 1,c='P_motriz_sup';a=0.7*param.P_motriz_sup;b=1.3*param.P_motriz_sup;case 2,c='D_egf';a=0.5*param.D_egf;b=min(param.D_res,1.2*param.D_egf);case 3,c='egf_A_nozzle_override';a=1e-5;b=5e-5;case 4,c='egf_A_throat_override';a=2e-4;b=8e-4;case 5,c='P_wh';a=0.5*param.P_wh;b=1.5*param.P_wh;otherwise,return;endswitch
  v=input(sprintf('Minimo [%g]: ',a));if ~isempty(v),a=v;endif;v=input(sprintf('Maximo [%g]: ',b));if ~isempty(v),b=v;endif;n=input('Puntos [7]: ');if isempty(n),n=7;endif
  vals=linspace(a,b,max(3,round(n)));if strcmp(c,'egf_A_nozzle_override')||strcmp(c,'egf_A_throat_override'),fprintf('Nota: overrides geometricos se aplican en el menu principal en esta alpha.\n');endif
  R=egf_sensibilidad_ejecutar(param,c,vals);global EGF_ULTIMA_SENSIBILIDAD;EGF_ULTIMA_SENSIBILIDAD=R;
  try,ctx=aos_sensibilidad_report_context('EGF',param,R);R.reportes=aos_report_dispatcher(ctx);EGF_ULTIMA_SENSIBILIDAD=R;catch err,fprintf(2,'ADVERTENCIA AOSRPT EGF: %s\n',err.message);end_try_catch
endfunction
