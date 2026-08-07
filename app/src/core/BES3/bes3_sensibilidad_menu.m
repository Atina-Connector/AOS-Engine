function bes3_sensibilidad_menu(param)
% DEV5.3: toda sensibilidad finaliza con el flujo transversal AOSRPT.
  p=bes3_defaults(param);
  fprintf('\n--- SENSIBILIDADES BES3 ---\n');
  fprintf('1 - Frecuencia (incluye 0 Hz / bomba apagada)\n2 - Numero de etapas\n3 - Profundidad de intake\n4 - Presion de cabeza\n');
  fprintf('5 - Eficiencia de separador\n6 - Viscosidad de petroleo\n7 - Velocidad minima de refrigeracion\n');
  fprintf('8 - Diametro interno de capilar instalado\n9 - Comparar toma etapa 2 y 3\n0 - Volver\n');
  op=input('Seleccione: ');if isempty(op)||op==0,return;endif
  if op==1
    fmin=p.bes3_frecuencia_min_operativa_Hz;fmax=max(p.bes3_frecuencia_max_operativa_Hz,fmin);n=9;
    v=input(sprintf('Frecuencia minima con bomba operando [%.1f Hz]: ',fmin));if ~isempty(v),fmin=max(v,0.1);endif
    v=input(sprintf('Frecuencia maxima [%.1f Hz]: ',fmax));if ~isempty(v),fmax=max(v,fmin);endif
    v=input(sprintf('Numero total de puntos, incluyendo 0 Hz [%d]: ',n));if ~isempty(v),n=max(2,round(v));endif
    if n==2,vals=[0 fmax];else,vals=[0 linspace(fmin,fmax,n-1)];endif
    R=bes3_sensibilidad_ejecutar(p,'frecuencia',vals);R=finalizar_reporte_local(p,R);global BES3_ULTIMA_SENSIBILIDAD;BES3_ULTIMA_SENSIBILIDAD=R;return;
  endif
  switch op
    case 2,campo='num_etapas';a=max(10,0.6*p.num_etapas);b=1.4*p.num_etapas;n=9;
    case 3,campo='D_bomba';a=max(100,0.8*p.D_bomba);b=max(1.1*p.D_bomba,p.D_res);n=9;
    case 4,campo='P_wh';a=0.5*p.P_wh;b=1.5*p.P_wh;n=9;
    case 5,campo='bes2_eta_separador';a=0;b=0.95;n=8;
    case 6,campo='mu_o';a=max(0.0005,0.25*getmu_local(p));b=4*getmu_local(p);n=9;
    case 7,campo='velocidad_min_refrig';a=0.15;b=0.60;n=10;
    case 8,campo='bes3_capilar_ID_m';a=0.002;b=0.006;n=9;
    case 9
      p.bes3_recirculacion_modo='instalada';R=bes3_sensibilidad_ejecutar(p,'bes3_etapa_toma',[2 3]);R=finalizar_reporte_local(p,R);global BES3_ULTIMA_SENSIBILIDAD;BES3_ULTIMA_SENSIBILIDAD=R;return;
    otherwise,return;
  endswitch
  v=input(sprintf('Minimo [%g]: ',a));if ~isempty(v),a=v;endif
  v=input(sprintf('Maximo [%g]: ',b));if ~isempty(v),b=v;endif
  v=input(sprintf('Numero de puntos [%d]: ',n));if ~isempty(v),n=max(3,round(v));endif
  vals=linspace(a,b,n);if strcmp(campo,'num_etapas'),vals=round(vals);endif
  R=bes3_sensibilidad_ejecutar(p,campo,vals);R=finalizar_reporte_local(p,R);global BES3_ULTIMA_SENSIBILIDAD;BES3_ULTIMA_SENSIBILIDAD=R;
endfunction
function m=getmu_local(p)
  if isfield(p,'mu_o')&&isfinite(p.mu_o),m=p.mu_o;else,pv=pvt_calcular(p.P_res,p.T_fondo-273.15,p.API,p.gamma_g);m=pv.mu_o;endif
endfunction

function R=finalizar_reporte_local(p,R)
  try
    if exist('aos_registro_graficos','file')==2&&isfield(R,'figures')&&~isempty(R.figures)
      aos_registro_graficos('reset','BES3_SENSIBILIDAD');
      aos_registro_graficos('add',R.figures,'bes3_sensibilidad',['Sensibilidad BES3 - ' R.campo],'SENSIBILIDAD','BES3_SENSIBILIDAD');
    endif
    c=bes3_sensibilidad_report_context(p,R);R.reportes=aos_report_dispatcher(c);
  catch err
    fprintf(2,'ADVERTENCIA: no se pudo completar el flujo AOSRPT de la sensibilidad: %s\n',err.message);
  end_try_catch
endfunction
