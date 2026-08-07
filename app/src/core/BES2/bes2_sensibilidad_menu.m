function bes2_sensibilidad_menu(param)
% DEV5.4: toda sensibilidad BES2 finaliza mediante aos_report_dispatcher.
  fprintf('\n--- SENSIBILIDADES BES V2 ---\n1 - Frecuencia\n2 - Numero de etapas\n3 - Profundidad de instalacion\n4 - Presion de cabeza\n5 - Eficiencia del separador\n0 - Volver\n');
  op=input('Seleccione: ');if isempty(op)||op==0,return;endif
  switch op
    case 1,campo='frecuencia';a=40;b=70;
    case 2,campo='num_etapas';a=max(10,0.5*param.num_etapas);b=1.5*param.num_etapas;
    case 3,campo='D_bomba';a=max(100,0.7*param.D_bomba);b=min(param.D_res,1.1*param.D_bomba);
    case 4,campo='P_wh';a=0.5*param.P_wh;b=1.5*param.P_wh;
    case 5,campo='bes2_eta_separador';a=0;b=0.95;
    otherwise,return;
  endswitch
  v=input(sprintf('Minimo [%g]: ',a));if isempty(v),v=a;endif;a=v;v=input(sprintf('Maximo [%g]: ',b));if isempty(v),v=b;endif;b=v;
  n=input('Numero de puntos [9]: ');if isempty(n),n=9;endif
  vals=linspace(a,b,max(3,round(n)));if strcmp(campo,'num_etapas'),vals=round(vals);endif
  R=bes2_sensibilidad_ejecutar(param,campo,vals);global BES2_ULTIMA_SENSIBILIDAD;BES2_ULTIMA_SENSIBILIDAD=R;
  try,c=aos_sensibilidad_report_context('BES_V2',param,R);R.reportes=aos_report_dispatcher(c);BES2_ULTIMA_SENSIBILIDAD=R;catch err,fprintf(2,'ADVERTENCIA AOSRPT BES2: %s\n',err.message);end_try_catch
endfunction
