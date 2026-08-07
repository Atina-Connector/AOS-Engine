function cgf_sensibilidad_menu(param)
% DEV5.4: toda sensibilidad CGF finaliza mediante aos_report_dispatcher.
  fprintf('\n--- SENSIBILIDADES CGF ---\n1 - RPM\n2 - Profundidad\n3 - Presion de cabeza\n4 - Presion de reservorio\n5 - Liquido producido\n0 - Volver\n');op=input('Seleccione: ');if isempty(op)||op==0,return;endif
  switch op,case 1,c='cgf_rpm';a=0.7*param.cgf_rpm;b=1.2*param.cgf_rpm;case 2,c='D_cgf';a=0.5*param.D_cgf;b=min(param.D_res,1.2*param.D_cgf);case 3,c='P_wh';a=0.5*param.P_wh;b=1.5*param.P_wh;case 4,c='P_res';a=0.7*param.P_res;b=1.1*param.P_res;case 5,c='cgf_Qliq_m3_d';a=0;b=max(10,param.cgf_Qliq_m3_d*2+10);otherwise,return;endswitch
  v=input(sprintf('Minimo [%g]: ',a));if ~isempty(v),a=v;endif;v=input(sprintf('Maximo [%g]: ',b));if ~isempty(v),b=v;endif;n=input('Puntos [9]: ');if isempty(n),n=9;endif
  R=cgf_sensibilidad_ejecutar(param,c,linspace(a,b,max(3,round(n))));global CGF_ULTIMA_SENSIBILIDAD;CGF_ULTIMA_SENSIBILIDAD=R;
  try,ctx=aos_sensibilidad_report_context('CGF',param,R);R.reportes=aos_report_dispatcher(ctx);CGF_ULTIMA_SENSIBILIDAD=R;catch err,fprintf(2,'ADVERTENCIA AOSRPT CGF: %s\n',err.message);end_try_catch
endfunction
