function R = bes2_sensibilidad_ejecutar(param,campo,valores)
% DEV5.4: expone aceptacion, convergencia y rango al reporte transversal.
  n=numel(valores);R=struct('campo',campo,'valores',valores(:),'Ql_m3_d',NaN(n,1),'Pintake_bar',NaN(n,1), ...
    'GVF_pct',NaN(n,1),'BEP_pct',NaN(n,1),'P_superficie_kW',NaN(n,1), ...
    'aceptado',false(n,1),'convergido',false(n,1),'estado',{cell(n,1)}, ...
    'rango_estado',{cell(n,1)},'gas_estado',{cell(n,1)},'soluciones',{cell(n,1)});
  for i=1:n
    p=param;p.(campo)=valores(i);if strcmp(campo,'D_bomba'),p.cable_longitud_m=valores(i);endif
    s=bes2_solver(p);R.soluciones{i}=s;R.Ql_m3_d(i)=num_local(s,'Ql_m3_d',0);R.estado{i}=txt_local(s,'estado','NO_EVALUADO');
    R.aceptado(i)=bool_local(s,'aceptado',false);R.convergido(i)=bool_local(s,'convergido',false);R.rango_estado{i}=txt_local(s,'rango_estado','NO_EVALUADO');R.gas_estado{i}=txt_local(s,'gas_estado','NO_EVALUADO');
    if isfield(s,'punto')&&isstruct(s.punto)
      if isfield(s.punto,'Pintake_Pa'),R.Pintake_bar(i)=s.punto.Pintake_Pa/1e5;endif
      if isfield(s.punto,'fluido')&&isstruct(s.punto.fluido)&&isfield(s.punto.fluido,'gvf_bomba'),R.GVF_pct(i)=100*s.punto.fluido.gvf_bomba;endif
    endif
    if isfield(s,'percent_BEP'),R.BEP_pct(i)=s.percent_BEP;endif
    if isfield(s,'electrico')&&isstruct(s.electrico)&&isfield(s.electrico,'P_superficie_kW'),R.P_superficie_kW(i)=s.electrico.P_superficie_kW;endif
  endfor
  fprintf('\n=== SENSIBILIDAD BES V2: %s ===\n',campo);fprintf('Valor | Ql(m3/d) | Pintake(bar) | GVF(%%) | BEP(%%) | Psup(kW) | Acept | Rango | Estado\n');
  for i=1:n,fprintf('%8.3g | %9.2f | %12.2f | %6.2f | %6.1f | %8.2f | %6d | %-25s | %s\n',valores(i),R.Ql_m3_d(i),R.Pintake_bar(i),R.GVF_pct(i),R.BEP_pct(i),R.P_superficie_kW(i),R.aceptado(i),R.rango_estado{i},R.estado{i});endfor
  f=figure;plot(valores,R.Ql_m3_d,'-o','LineWidth',1.6);grid on;xlabel(campo,'Interpreter','none');ylabel('Ql (m3/d)');title(['Sensibilidad BES V2 - ' campo],'Interpreter','none');
  R.headers={'Valor','Ql_m3_d','Pintake_bar','GVF_pct','BEP_pct','P_superficie_kW','Rango','Gas','Convergido','Aceptado','Estado'};
  R.units={unidad_local(campo),'m3/d','bar','%','%','kW','','','','',''};R.rows=cell(n,numel(R.headers));
  for i=1:n,R.rows(i,:)={valores(i),R.Ql_m3_d(i),R.Pintake_bar(i),R.GVF_pct(i),R.BEP_pct(i),R.P_superficie_kW(i),R.rango_estado{i},R.gas_estado{i},R.convergido(i),R.aceptado(i),R.estado{i}};endfor;R.figures=f;
endfunction
function v=num_local(s,c,d),v=d;if isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=s.(c)(1);endif,endfunction
function t=txt_local(s,c,d),t=d;if isfield(s,c)&&ischar(s.(c)),t=s.(c);endif,endfunction
function b=bool_local(s,c,d),b=d;if isfield(s,c)&&isscalar(s.(c)),b=logical(s.(c));endif,endfunction
function u=unidad_local(c),u='-';lc=lower(c);if strcmp(lc,'frecuencia'),u='Hz';elseif ~isempty(strfind(lc,'etapa')),u='etapas';elseif strcmp(lc,'p_wh'),u='Pa';elseif ~isempty(strfind(lc,'_m'))||~isempty(strfind(lc,'prof')),u='m';endif,endfunction
