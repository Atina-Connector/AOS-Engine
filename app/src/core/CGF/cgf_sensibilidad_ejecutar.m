function R=cgf_sensibilidad_ejecutar(param,campo,valores)
% DEV5.4: expone aceptacion y estados del compresor al reporte transversal.
  n=numel(valores);R=struct('campo',campo,'valores',valores(:),'Qg_Sm3_d',NaN(n,1),'Ps_bar',NaN(n,1),'PR',NaN(n,1),'P_kW',NaN(n,1), ...
    'aceptado',false(n,1),'convergido',false(n,1),'estado',{cell(n,1)},'mapa_estado',{cell(n,1)},'liquid_state',{cell(n,1)},'electrico_estado',{cell(n,1)},'soluciones',{cell(n,1)});
  for i=1:n
    p=param;p.(campo)=valores(i);if strcmp(campo,'D_cgf'),p.cable_longitud_m=valores(i);endif;s=cgf_solver(p);R.soluciones{i}=s;
    R.Qg_Sm3_d(i)=num_local(s,'Qg_Sm3_d',0);R.estado{i}=txt_local(s,'estado','NO_EVALUADO');R.aceptado(i)=bool_local(s,'aceptado',false);R.convergido(i)=bool_local(s,'convergido',false);R.liquid_state{i}=txt_local(s,'liquid_state','NO_EVALUADO');
    if isfield(s,'punto')&&isstruct(s.punto)
      if isfield(s.punto,'Ps_Pa'),R.Ps_bar(i)=s.punto.Ps_Pa/1e5;endif
      if isfield(s.punto,'mapa')&&isstruct(s.punto.mapa),R.PR(i)=num_local(s.punto.mapa,'PR',NaN);R.mapa_estado{i}=txt_local(s.punto.mapa,'estado','NO_EVALUADO');endif
    endif
    if isfield(s,'electrico')&&isstruct(s.electrico),R.P_kW(i)=num_local(s.electrico,'P_superficie_kW',NaN);R.electrico_estado{i}=txt_local(s.electrico,'estado','NO_EVALUADO');endif
  endfor
  fprintf('\nValor | Qg(Sm3/d) | Ps(bar) | PR | Psup(kW) | Acept | Mapa | Estado\n');for i=1:n,fprintf('%8.3g | %10.0f | %7.2f | %4.2f | %8.2f | %6d | %-12s | %s\n',valores(i),R.Qg_Sm3_d(i),R.Ps_bar(i),R.PR(i),R.P_kW(i),R.aceptado(i),R.mapa_estado{i},R.estado{i});endfor
  f=figure;plot(valores,R.Qg_Sm3_d,'-o','LineWidth',1.6);grid on;xlabel(campo,'Interpreter','none');ylabel('Qg (Sm3/d)');title(['Sensibilidad CGF - ' campo],'Interpreter','none');
  R.headers={'Valor','Qg_Sm3_d','Ps_bar','PR','P_superficie_kW','Mapa','Liquidos','Electrico','Convergido','Aceptado','Estado'};R.units={unidad_local(campo),'Sm3/d','bar','','kW','','','','','',''};R.rows=cell(n,numel(R.headers));
  for i=1:n,R.rows(i,:)={valores(i),R.Qg_Sm3_d(i),R.Ps_bar(i),R.PR(i),R.P_kW(i),R.mapa_estado{i},R.liquid_state{i},R.electrico_estado{i},R.convergido(i),R.aceptado(i),R.estado{i}};endfor;R.figures=f;
endfunction
function v=num_local(s,c,d),v=d;if isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=s.(c)(1);endif,endfunction
function t=txt_local(s,c,d),t=d;if isfield(s,c)&&ischar(s.(c)),t=s.(c);endif,endfunction
function b=bool_local(s,c,d),b=d;if isfield(s,c)&&isscalar(s.(c)),b=logical(s.(c));endif,endfunction
function u=unidad_local(c),u='-';lc=lower(c);if ~isempty(strfind(lc,'rpm')),u='rpm';elseif ~isempty(strfind(lc,'p_')),u='Pa';elseif ~isempty(strfind(lc,'d_')),u='m';elseif ~isempty(strfind(lc,'qliq')),u='m3/d';endif,endfunction
