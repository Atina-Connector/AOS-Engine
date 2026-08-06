function tablas = gibbs3_report_build_tables(res)
% GIBBS3_REPORT_BUILD_TABLES Tablas GF3 para el compositor transversal HF3.5.
  tablas=struct([]);if ~isstruct(res),return;endif
  p=struct();if isfield(res,'param')&&isstruct(res.param),p=res.param;endif
  d=struct();if isfield(res,'diseno_sarta_espaciamiento')&&isstruct(res.diseno_sarta_espaciamiento),d=res.diseno_sarta_espaciamiento;endif

  plan=struct([]);if isfield(d,'plan_instalacion_sarta')&&isstruct(d.plan_instalacion_sarta),plan=d.plan_instalacion_sarta;endif
  if ~isempty(plan)
    campos={'desde_m','hasta_m','longitud_m','diametro_mm','grado','longitud_comercial_m','cantidad_varillas_completas','ajuste_pony_rod_m','cantidad_elementos','masa_kg'};
    labels={'Desde MD','Hasta MD','Longitud','Diametro','Grado','Longitud comercial','Varillas completas','Pony rod','Elementos','Masa'};
    units={'m','m','m','mm','','m','','m','','kg'};
    t=aos_report_table_from_structs('gf3_sarta_instalacion','Sarta de varillas - plan de instalacion','BM_GF3',plan,campos,labels,units, ...
      'role','PRIMARY_RESULT','category','DESIGN','priority','PRIMARY','default_mode','FULL_BODY','mandatory',true,'source','GF3_ROD_DESIGN');
    tablas=aos_report_append_tables(tablas,t);
  elseif isfield(p,'gibbs3_secciones_varillas')&&isstruct(p.gibbs3_secciones_varillas)
    sec=p.gibbs3_secciones_varillas;
    t=aos_report_table_from_structs('gf3_sarta_secciones','Sarta de varillas - secciones','BM_GF3',sec, ...
      {'longitud_m','diametro_mm','grado'},{'Longitud','Diametro','Grado'},{'m','mm',''}, ...
      'role','PRIMARY_RESULT','category','DESIGN','priority','PRIMARY','default_mode','FULL_BODY','mandatory',true,'source','GF3_ROD_CONFIG');
    tablas=aos_report_append_tables(tablas,t);
  endif

  if isfield(d,'candidatos')&&isstruct(d.candidatos)&&~isempty(d.candidatos)
    c=d.candidatos;n=numel(c);rows=cell(n,11);
    for i=1:n
      rows(i,:)={i,txt(c(i),'nombre','SIN_NOMBRE'),bool(c(i),'escalonada',false),numel_struct_field(c(i),'secciones'), ...
        num(c(i),'masa_total_kg',NaN),num(c(i),'utilizacion_estimada_max',NaN),bool(c(i),'verificacion_GF3_ok',false), ...
        num(c(i),'utilizacion_dinamica_max',NaN),bool(c(i),'aprobada_dinamica',false), ...
        num(c(i),'carga_superficie_max_kN',NaN),txt(c(i),'motivo','NO_DISPONIBLE')};
    endfor
    t=struct('id','gf3_sarta_candidatas','title','Candidatos de diseno de sarta','section','BM_GF3', ...
      'role','DESIGN_CANDIDATES','source','GF3_ROD_DESIGN','category','DESIGN','priority','SECONDARY', ...
      'columns',{{'idx','nombre','escalonada','n_tramos','masa_kg','goodman_estimado','gf3_verificada','goodman_dinamico','aprobada_gf3','carga_superficie_max_kN','criterio'}}, ...
      'labels',{{'Indice','Nombre','Escalonada','Tramos','Masa','Goodman estimado','GF3 verificada','Goodman dinamico','Aprobada GF3','Carga maxima','Criterio'}}, ...
      'units',{{'','','','','kg','','','','','kN',''}},'rows',{rows}, ...
      'default_mode','FULL_APPENDIX','sample_step',5,'archive_full',true);
    tablas=aos_report_append_tables(tablas,t);
  endif

  if isfield(d,'elementos')&&isstruct(d.elementos)
    e=d.elementos;fields={'x_m','diametro_mm','Fmax_N','Fmin_N','sigma_max_MPa','sigma_min_MPa','sigma_alternante_MPa','sigma_media_MPa','utilizacion'};
    n=min_lengths(e,fields);
    if n>0
      M=[(1:n)',e.x_m(1:n)(:),e.diametro_mm(1:n)(:),e.Fmax_N(1:n)(:)/1000,e.Fmin_N(1:n)(:)/1000, ...
        e.sigma_max_MPa(1:n)(:),e.sigma_min_MPa(1:n)(:),e.sigma_alternante_MPa(1:n)(:),e.sigma_media_MPa(1:n)(:),e.utilizacion(1:n)(:)];
      t=aos_report_table_from_matrix('gf3_sarta_elementos','Esfuerzos por elemento de la sarta','BM_GF3',M, ...
        {'idx','MD_m','diametro_mm','Fmax_kN','Fmin_kN','sigma_max_MPa','sigma_min_MPa','sigma_alt_MPa','sigma_media_MPa','utilizacion_Goodman'}, ...
        {'Indice','MD','Diametro','F max','F min','Sigma max','Sigma min','Sigma alternante','Sigma media','Goodman'}, ...
        {'','m','mm','kN','kN','MPa','MPa','MPa','MPa',''}, ...
        'role','PROFILE_TABLE','category','PROFILE','priority','DETAIL','default_mode','VIEWER_ONLY','sample_step',20,'source','GF3_FATIGUE');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif

  if isfield(res,'promedio')&&isstruct(res.promedio)
    pr=res.promedio;fields={'t_s','u_superficie_m','u_varilla_fondo_m','u_tuberia_fondo_m','u_piston_relativo_m','F_superficie_N','F_bomba_N','apertura_valvula','F_LPP_N','deltaP_LPP_Pa','Q_LPP_m3_s'};
    n=min_lengths(pr,fields);
    if n>0
      rows=cell(n,18);has_ap=isfield(pr,'aparato')&&isstruct(pr.aparato);has_v=isfield(res,'verificacion_aparato')&&isstruct(res.verificacion_aparato);
      for i=1:n
        rows(i,:)={i,pr.t_s(i),pr.u_superficie_m(i),pr.u_varilla_fondo_m(i),pr.u_tuberia_fondo_m(i),pr.u_piston_relativo_m(i), ...
          pr.F_superficie_N(i)/1000,pr.F_bomba_N(i)/1000,pr.apertura_valvula(i),pr.F_LPP_N(i)/1000,pr.deltaP_LPP_Pa(i)/1e5,pr.Q_LPP_m3_s(i), ...
          array_num(pr,'aparato','posicion_m',i,NaN),array_num(pr,'aparato','velocidad_m_s',i,NaN),array_num(pr,'aparato','aceleracion_m_s2',i,NaN),array_num(pr,'aparato','angulo_rad',i,NaN), ...
          direct_array_num(res,'verificacion_aparato','torque_neto_kNm',i,NaN),direct_array_num(res,'verificacion_aparato','potencia_motor_kW',i,NaN)};
      endfor
      t=struct('id','gf3_ciclo_promedio','title','Ciclo promedio GF3','section','BM_GF3', ...
        'role','TIME_SERIES','source','GF3_SOLVER','category','TIME_SERIES','priority','DETAIL', ...
        'columns',{{'idx','t_s','u_superficie_m','u_varilla_fondo_m','u_tuberia_fondo_m','u_piston_relativo_m','F_superficie_kN','F_bomba_kN','apertura_valvula','F_LPP_kN','deltaP_LPP_bar','Q_LPP_m3_s','posicion_PR_m','velocidad_PR_m_s','aceleracion_PR_m_s2','angulo_manivela_rad','torque_neto_kNm','potencia_motor_kW'}}, ...
        'labels',{{'Indice','Tiempo','Posicion superficie','Varilla fondo','Tubing fondo','Piston-barril','Carga superficie','Carga bomba','Apertura valvula','F LPP','Delta P LPP','Q LPP','Posicion PR','Velocidad PR','Aceleracion PR','Angulo','Torque','Potencia'}}, ...
        'units',{{'','s','m','m','m','m','kN','kN','','kN','bar','m3/s','m','m/s','m/s2','rad','kN.m','kW'}}, ...
        'rows',{rows},'default_mode','VIEWER_ONLY','sample_step',20,'archive_full',true);
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
endfunction

function v=num(s,f,d),v=d;if isstruct(s)&&isfield(s,f)&&isnumeric(s.(f))&&!isempty(s.(f))&&isfinite(s.(f)(1)),v=double(s.(f)(1));endif,endfunction
function s=txt(x,f,d),s=d;if isstruct(x)&&isfield(x,f)&&ischar(x.(f))&&!isempty(strtrim(x.(f))),s=strtrim(x.(f));endif,endfunction
function v=bool(s,f,d),v=d;if isstruct(s)&&isfield(s,f),x=s.(f);if islogical(x)&&!isempty(x),v=logical(x(1));elseif isnumeric(x)&&!isempty(x)&&isfinite(x(1)),v=x(1)~=0;endif,endif,endfunction
function n=numel_struct_field(s,f),n=0;if isfield(s,f),n=numel(s.(f));endif,endfunction
function n=min_lengths(s,fields),n=Inf;for k=1:numel(fields),if !isfield(s,fields{k})||isempty(s.(fields{k})),n=0;return;endif;n=min(n,numel(s.(fields{k})));endfor;if isinf(n),n=0;endif,endfunction
function v=array_num(s,sub,f,i,d),v=d;if isfield(s,sub)&&isstruct(s.(sub))&&isfield(s.(sub),f)&&isnumeric(s.(sub).(f))&&numel(s.(sub).(f))>=i&&isfinite(s.(sub).(f)(i)),v=s.(sub).(f)(i);endif,endfunction
function v=direct_array_num(s,sub,f,i,d),v=d;if isfield(s,sub)&&isstruct(s.(sub))&&isfield(s.(sub),f)&&isnumeric(s.(sub).(f))&&numel(s.(sub).(f))>=i&&isfinite(s.(sub).(f)(i)),v=s.(sub).(f)(i);endif,endfunction
