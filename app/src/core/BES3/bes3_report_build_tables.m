function tablas=bes3_report_build_tables(sol)
% BES3_REPORT_BUILD_TABLES Tablas BES3 para compositor transversal.
  tablas=struct([]);if ~isstruct(sol),return;endif
  if isfield(sol,'semaforos')&&isstruct(sol.semaforos)&&~isempty(sol.semaforos)
    t=aos_report_table_from_structs('bes3_semaforos','Semaforos BES3','BES3',sol.semaforos, ...
      {'id','estado','mensaje'},{'ID','Estado','Mensaje'},{'','',''}, ...
      'role','DIAGNOSTIC_TABLE','category','DIAGNOSTIC','priority','PRIMARY','default_mode','FULL_BODY','mandatory',true,'source','BES3_VALIDATION');
    tablas=aos_report_append_tables(tablas,t);
  endif
  if isfield(sol,'barrido_Q_m3_d')&&isnumeric(sol.barrido_Q_m3_d)
    fields={'barrido_Q_m3_d','barrido_Pwf_bar','barrido_Pintake_bar','barrido_Pdesc_disponible_bar','barrido_Pdesc_requerida_bar','barrido_residuo_bar','barrido_dP_bomba_bar','barrido_dP_bomba_apagada_bar'};
    n=min_lengths_local(sol,fields);
    if n>0
      M=zeros(n,numel(fields));for j=1:numel(fields),M(:,j)=sol.(fields{j})(1:n)(:);endfor
      t=aos_report_table_from_matrix('bes3_nodal','Analisis nodal BES3','BES3',M, ...
        {'Q_superficie_m3_d','Pwf_bar','Pintake_bar','Pdesc_disponible_bar','Pdesc_requerida_bar','Residuo_bar','dP_bomba_bar','dP_bomba_apagada_bar'}, ...
        {'Q superficie','Pwf','P intake','P descarga disponible','P descarga requerida','Residuo','Delta P bomba','Delta P bomba apagada'}, ...
        {'m3/d','bar','bar','bar','bar','bar','bar','bar'}, ...
        'role','PRIMARY_RESULT','category','NODAL','priority','PRIMARY','default_mode','FULL_BODY','mandatory',true,'source','BES3_SOLVER');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
  if isfield(sol,'curva')&&isstruct(sol.curva)&&isfield(sol.curva,'Q_m3_d')&&isfield(sol.curva,'head_m')&&isfield(sol.curva,'eta')
    n=min([numel(sol.curva.Q_m3_d),numel(sol.curva.head_m),numel(sol.curva.eta)]);
    if n>0
      M=[sol.curva.Q_m3_d(1:n)(:),sol.curva.head_m(1:n)(:),100*sol.curva.eta(1:n)(:)];
      t=aos_report_table_from_matrix('bes3_pump_curve','Curva de la bomba BES3','BES3',M, ...
        {'Q_m3_d','Head_m','Eficiencia_pct'},{'Caudal','Head','Eficiencia'},{'m3/d','m','%'}, ...
        'role','CURVE_TABLE','category','CATALOG','priority','SECONDARY','default_mode','FULL_APPENDIX','source','BES3_PUMP_CATALOG');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
  if isfield(sol,'diagnostico_tuberia')&&isstruct(sol.diagnostico_tuberia)&&isfield(sol.diagnostico_tuberia,'perfil')&&isstruct(sol.diagnostico_tuberia.perfil)
    p=sol.diagnostico_tuberia.perfil;fn=fieldnames(p);n=Inf;use={};
    for i=1:numel(fn),v=p.(fn{i});if (isnumeric(v)||iscell(v))&&isvector(v)&&numel(v)>1,use{end+1}=fn{i};n=min(n,numel(v));endif,endfor
    if ~isempty(use)&&isfinite(n)&&n>0
      rows=cell(n,numel(use));for j=1:numel(use),v=p.(use{j});for i=1:n,if iscell(v),rows{i,j}=v{i};else,rows{i,j}=v(i);endif,endfor,endfor
      t=struct('id','bes3_tubing_profile','title','Diagnostico de tuberia BES3','section','BES3', ...
        'role','PROFILE_TABLE','source','BES3_TUBING_DIAGNOSTIC','category','PROFILE','priority','DETAIL', ...
        'columns',{use},'labels',{use},'units',{repmat({''},1,numel(use))},'rows',{rows}, ...
        'default_mode','VIEWER_ONLY','sample_step',10,'archive_full',true);
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
endfunction
function n=min_lengths_local(s,f),n=Inf;for i=1:numel(f),if ~isfield(s,f{i})||~isnumeric(s.(f{i}))||isempty(s.(f{i})),n=0;return;endif;n=min(n,numel(s.(f{i})));endfor;if isinf(n),n=0;endif,endfunction
