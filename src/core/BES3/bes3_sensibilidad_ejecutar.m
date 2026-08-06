function R = bes3_sensibilidad_ejecutar(param,campo,valores)
% DEV5.4: sensibilidad BES3 con aceptacion y rangos expuestos al reporte.
  p0=bes3_defaults(param);n=numel(valores);
  R=struct('campo',campo,'valores',valores(:),'Qprod_m3_d',NaN(n,1),'Ql_m3_d',NaN(n,1), ...
    'Qrec_m3_d',NaN(n,1),'Qnom_m3_d',NaN(n,1),'Qrec_pct_nominal',NaN(n,1), ...
    'Qrec_limite_m3_d',NaN(n,1),'Qinferior_m3_d',NaN(n,1),'Qsuperior_m3_d',NaN(n,1), ...
    'Pintake_bar',NaN(n,1),'Ptoma_bar',NaN(n,1),'dPcapilar_bar',NaN(n,1), ...
    'Tmotor_C',NaN(n,1),'BEP_inferior_pct',NaN(n,1),'BEP_superior_pct',NaN(n,1), ...
    'Psuperficie_kW',NaN(n,1),'num_etapas',NaN(n,1),'etapa',NaN(n,1), ...
    'n_etapas_inferiores',NaN(n,1),'n_etapas_superiores',NaN(n,1), ...
    'aceptado',false(n,1),'aceptado_certificado',false(n,1),'convergido',false(n,1), ...
    'modo',{cell(n,1)},'estado',{cell(n,1)},'estado_diseno',{cell(n,1)}, ...
    'estado_operativo',{cell(n,1)},'estado_secciones',{cell(n,1)}, ...
    'rango_inferior_estado',{cell(n,1)},'rango_superior_estado',{cell(n,1)}, ...
    'soluciones',{cell(n,1)});
  R.q_min_productivo_m3_d=p0.bes3_tol_produccion_m3_d;
  for i=1:n
    p=p0;
    if strcmp(campo,'bes3_capilar_ID_m')
      p.bes3_recirculacion_modo='instalada';p.bes3_capilar_ID_m=valores(i);p.bes3_capilar_OD_m=valores(i)+2*p.bes3_capilar_espesor_m;
    else,p.(campo)=valores(i);endif
    if strcmp(campo,'D_bomba'),p.cable_longitud_m=valores(i);endif
    if strcmp(campo,'frecuencia')
      p.bes3_frecuencia_solicitada_Hz=max(valores(i),0);p.bes3_frecuencia_efectiva_Hz=max(valores(i),0);
      if valores(i)<=0,p.bes3_estado_bomba='apagada';p.bes3_modo_frecuencia='sensibilidad_0Hz';else,p.bes3_estado_bomba='encendida';p.bes3_modo_frecuencia='sensibilidad';endif
    endif
    s=bes3_solver(p);R.soluciones{i}=s;R.Qprod_m3_d(i)=num_local(s,'Ql_m3_d',0);R.Ql_m3_d(i)=R.Qprod_m3_d(i);
    R.Qrec_m3_d(i)=num_local(s,'Q_recirc_m3_d',0);R.estado{i}=texto_local(s,'estado','NO_EVALUADO');R.modo{i}=texto_local(s,'modo_operacion','NO_EVALUADO');
    R.aceptado(i)=bool_local(s,'aceptado_preliminar',bool_local(s,'aceptado',false));R.aceptado_certificado(i)=bool_local(s,'aceptado',false);R.convergido(i)=bool_local(s,'convergido',false);
    R.num_etapas(i)=num_local(s,'num_etapas_total',p.num_etapas);R.etapa(i)=num_local(s,'etapa_toma',0);
    R.Qnom_m3_d(i)=num_local(s,'Q_nominal_efectivo_m3_d',NaN);R.Qrec_pct_nominal(i)=num_local(s,'Q_recirc_pct_nominal',NaN);
    R.Qrec_limite_m3_d(i)=num_local(s,'Q_recirc_max_diseno_m3_d',NaN);
    R.Qinferior_m3_d(i)=num_local(s,'Q_etapas_inferiores_m3_d',NaN);R.Qsuperior_m3_d(i)=num_local(s,'Q_etapas_superiores_m3_d',NaN);
    R.BEP_inferior_pct(i)=num_local(s,'BEP_inferior_pct',NaN);R.BEP_superior_pct(i)=num_local(s,'BEP_superior_pct',NaN);
    R.estado_diseno{i}=texto_local(s,'estado_diseno_recirculacion','NO_EVALUADO');R.estado_operativo{i}=texto_local(s,'estado_operativo_recirculacion','NO_EVALUADO');
    R.rango_inferior_estado{i}=texto_local(s,'rango_inferior_estado','NO_EVALUADO');R.rango_superior_estado{i}=texto_local(s,'rango_superior_estado','NO_EVALUADO');
    if isfield(s,'diagnostico_recirculacion')&&isstruct(s.diagnostico_recirculacion)
      d=s.diagnostico_recirculacion;R.n_etapas_inferiores(i)=num_local(d,'n_etapas_inferiores',NaN);R.n_etapas_superiores(i)=num_local(d,'n_etapas_superiores',NaN);
      R.Ptoma_bar(i)=num_local(d,'dP_toma_bar',NaN);R.dPcapilar_bar(i)=num_local(d,'dP_capilar_bar',NaN);R.estado_secciones{i}=texto_local(d,'estado_secciones','NO_EVALUADO');
    endif
    if isfield(s,'punto')&&isstruct(s.punto)
      if isfield(s.punto,'Pintake_Pa'),R.Pintake_bar(i)=s.punto.Pintake_Pa/1e5;endif
      if isfield(s.punto,'electrico')&&isstruct(s.punto.electrico)
        if isfield(s.punto.electrico,'termica')&&isstruct(s.punto.electrico.termica)&&isfield(s.punto.electrico.termica,'T_motor_C'),R.Tmotor_C(i)=s.punto.electrico.termica.T_motor_C;endif
        if isfield(s.punto.electrico,'P_superficie_kW'),R.Psuperficie_kW(i)=s.punto.electrico.P_superficie_kW;endif
      endif
    endif
  endfor

  fprintf('\n=== SENSIBILIDAD BES3: %s ===\n',campo);
  fprintf('Valor | Modo | Ntot | Sang | Qprod | Qrec | Qnom | Rec%% | Qinferior | Qsuperior | BEPinf | BEPsup | Acept | Estado\n');
  for i=1:n
    fprintf('%8.4g | %-16s | %4.0f | %4.0f | %6.2f | %6.2f | %6.2f | %5.1f | %9.2f | %9.2f | %6.1f | %6.1f | %6d | %s\n', ...
      valores(i),R.modo{i},R.num_etapas(i),R.etapa(i),R.Qprod_m3_d(i),R.Qrec_m3_d(i),R.Qnom_m3_d(i),R.Qrec_pct_nominal(i), ...
      R.Qinferior_m3_d(i),R.Qsuperior_m3_d(i),R.BEP_inferior_pct(i),R.BEP_superior_pct(i),R.aceptado(i),R.estado{i});
  endfor
  fprintf('\nDetalle de presion y operacion:\n');
  fprintf('Valor | Pintake(bar) | Ptoma(bar) | dPcap(bar) | Tmotor(C) | kW sup. | Estado operativo\n');
  for i=1:n,fprintf('%8.4g | %12.2f | %10.2f | %10.2f | %9.1f | %7.2f | %s\n',valores(i),R.Pintake_bar(i),R.Ptoma_bar(i),R.dPcapilar_bar(i),R.Tmotor_C(i),R.Psuperficie_kW(i),R.estado_operativo{i});endfor

  f=figure('Name',['Sensibilidad BES3 - ' campo]);subplot(2,1,1);
  h1=plot(valores,R.Qprod_m3_d,'-o','LineWidth',1.5);hold on;h2=plot(valores,R.Qrec_m3_d,'-s','LineWidth',1.3);h3=plot(valores,R.Qrec_limite_m3_d,'--','LineWidth',1.2);
  grid on;xlabel(campo,'Interpreter','none');ylabel('Caudal (m3/d)');title(['Sensibilidad BES3 - ' campo ' | caudales'],'Interpreter','none');
  if strcmp(campo,'frecuencia')&&any(valores==0)&&any(valores>0)
    yf=R.Qrec_limite_m3_d(isfinite(R.Qrec_limite_m3_d));ymin=min([R.Qprod_m3_d(:);R.Qrec_m3_d(:);yf(:)]);ymax=max([R.Qprod_m3_d(:);R.Qrec_m3_d(:);yf(:)]);
    if isempty(ymin)||~isfinite(ymin),ymin=0;endif;if isempty(ymax)||~isfinite(ymax)||ymax<=ymin,ymax=ymin+1;endif
    xsep=0.5*min(valores(valores>0));hs=plot([xsep xsep],[ymin ymax],'k--');set(hs,'HandleVisibility','off');text(0,ymax,'Bomba apagada','VerticalAlignment','top');
  endif
  legend([h1(:);h2(:);h3(:)],{'Produccion superficie','Recirculacion','Limite recirc (% Qnom)'},'Location','best');
  subplot(2,1,2);hb1=plot(valores,R.BEP_inferior_pct,'-o','LineWidth',1.4);hold on;hb2=plot(valores,R.BEP_superior_pct,'-s','LineWidth',1.4);
  plot([min(valores) max(valores)],[100 100],'k--','HandleVisibility','off');grid on;xlabel(campo,'Interpreter','none');ylabel('BEP por seccion (%)');legend([hb1 hb2],{'Etapas inferiores','Etapas superiores'},'Location','best');title('Operacion de las secciones de la bomba');

  R.headers={'Valor','Modo','N_etapas','Etapa_toma','Qprod_m3_d','Qrec_m3_d','Qnom_m3_d','Qrec_pct_nominal','Qinferior_m3_d','Qsuperior_m3_d','BEP_inferior_pct','BEP_superior_pct','Pintake_bar','Ptoma_bar','dPcapilar_bar','Tmotor_C','Psuperficie_kW','Rango_inferior','Rango_superior','Estado_secciones','Estado_diseno','Estado_operativo','Convergido','Aceptado_preliminar','Aceptado_certificado','Estado_solver'};
  R.units={unidad_campo_local(campo),'','','','m3/d','m3/d','m3/d','%','m3/d','m3/d','%','%','bar','bar','bar','C','kW','','','','','','','','',''};
  R.rows=cell(n,numel(R.headers));
  for i=1:n,R.rows(i,:)={valores(i),R.modo{i},R.num_etapas(i),R.etapa(i),R.Qprod_m3_d(i),R.Qrec_m3_d(i),R.Qnom_m3_d(i),R.Qrec_pct_nominal(i),R.Qinferior_m3_d(i),R.Qsuperior_m3_d(i),R.BEP_inferior_pct(i),R.BEP_superior_pct(i),R.Pintake_bar(i),R.Ptoma_bar(i),R.dPcapilar_bar(i),R.Tmotor_C(i),R.Psuperficie_kW(i),R.rango_inferior_estado{i},R.rango_superior_estado{i},R.estado_secciones{i},R.estado_diseno{i},R.estado_operativo{i},R.convergido(i),R.aceptado(i),R.aceptado_certificado(i),R.estado{i}};endfor
  R.figures=f;
endfunction
function v=num_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=double(s.(c)(1));endif,endfunction
function t=texto_local(s,c,d),t=d;if isstruct(s)&&isfield(s,c)&&ischar(s.(c)),t=s.(c);endif,endfunction
function b=bool_local(s,c,d),b=d;if isstruct(s)&&isfield(s,c)&&isscalar(s.(c)),b=logical(s.(c));endif,endfunction
function u=unidad_campo_local(c),u='-';lc=lower(c);if strcmp(lc,'frecuencia'),u='Hz';elseif ~isempty(strfind(lc,'etapa')),u='etapas';elseif ~isempty(strfind(lc,'p_wh'))||~isempty(strfind(lc,'pres')),u='Pa';elseif ~isempty(strfind(lc,'_m'))||~isempty(strfind(lc,'prof')),u='m';endif,endfunction
