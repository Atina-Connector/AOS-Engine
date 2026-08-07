function R=egf_sensibilidad_ejecutar(param,campo,valores)
% DEV5.4: expone aceptacion y regimen al reporte transversal.
  n=numel(valores);R=struct('campo',campo,'valores',valores(:),'Qs_Sm3_d',NaN(n,1),'Qm_Sm3_d',NaN(n,1),'entrainment',NaN(n,1),'P_eq_kW',NaN(n,1), ...
    'aceptado',false(n,1),'convergido',false(n,1),'estado',{cell(n,1)},'regimen',{cell(n,1)},'soluciones',{cell(n,1)});
  for i=1:n
    p=param;p.(campo)=valores(i);s=egf_solver(p);R.soluciones{i}=s;R.Qs_Sm3_d(i)=num_local(s,'Qg_aspirado_Sm3_d',0);R.Qm_Sm3_d(i)=num_local(s,'Qg_motriz_Sm3_d',0);R.estado{i}=txt_local(s,'estado','NO_EVALUADO');R.aceptado(i)=bool_local(s,'aceptado',false);R.convergido(i)=bool_local(s,'convergido',false);
    if isfield(s,'punto')&&isstruct(s.punto),R.entrainment(i)=num_local(s.punto,'entrainment',NaN);R.P_eq_kW(i)=num_local(s.punto,'P_equiv_superficie_kW',NaN);R.regimen{i}=txt_local(s.punto,'regimen','NO_EVALUADO');endif
  endfor
  fprintf('\nValor | Q aspirado | Q motriz | Entrainment | P eq(kW) | Acept | Regimen | Estado\n');for i=1:n,fprintf('%8.3g | %10.0f | %8.0f | %10.3f | %8.2f | %6d | %-12s | %s\n',valores(i),R.Qs_Sm3_d(i),R.Qm_Sm3_d(i),R.entrainment(i),R.P_eq_kW(i),R.aceptado(i),R.regimen{i},R.estado{i});endfor
  f=figure;plot(valores,R.Qs_Sm3_d,'-o','LineWidth',1.6);grid on;xlabel(campo,'Interpreter','none');ylabel('Gas aspirado (Sm3/d)');title(['Sensibilidad EGF - ' campo],'Interpreter','none');
  R.headers={'Valor','Q_aspirado_Sm3_d','Q_motriz_Sm3_d','Entrainment','P_equiv_kW','Regimen','Convergido','Aceptado','Estado'};R.units={unidad_local(campo),'Sm3/d','Sm3/d','','kW','','','',''};R.rows=cell(n,numel(R.headers));
  for i=1:n,R.rows(i,:)={valores(i),R.Qs_Sm3_d(i),R.Qm_Sm3_d(i),R.entrainment(i),R.P_eq_kW(i),R.regimen{i},R.convergido(i),R.aceptado(i),R.estado{i}};endfor;R.figures=f;
endfunction
function v=num_local(s,c,d),v=d;if isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=s.(c)(1);endif,endfunction
function t=txt_local(s,c,d),t=d;if isfield(s,c)&&ischar(s.(c)),t=s.(c);endif,endfunction
function b=bool_local(s,c,d),b=d;if isfield(s,c)&&isscalar(s.(c)),b=logical(s.(c));endif,endfunction
function u=unidad_local(c),u='-';lc=lower(c);if ~isempty(strfind(lc,'p_')),u='Pa';elseif ~isempty(strfind(lc,'d_')),u='m';elseif ~isempty(strfind(lc,'area'))||~isempty(strfind(lc,'_a_')),u='m2';endif,endfunction
