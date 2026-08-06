function tablas = aos_report_collect_standard_tables(param, tipo)
% AOS_REPORT_COLLECT_STANDARD_TABLES Tablas comunes detectadas en todo AOS.
  if nargin<1||~isstruct(param),param=struct();endif
  if nargin<2||isempty(tipo),tipo='GENERAL';endif
  tablas=struct([]);

  % Carta dinamometrica BM/Gibbs.
  if isfield(param,'cartas_sup')&&isnumeric(param.cartas_sup)&&size(param.cartas_sup,2)>=2&& ...
      isfield(param,'cartas_fondo')&&isnumeric(param.cartas_fondo)&&size(param.cartas_fondo,2)>=2
    n=min(size(param.cartas_sup,1),size(param.cartas_fondo,1));
    if n>0
      M=[(1:n)',param.cartas_sup(1:n,1),param.cartas_sup(1:n,2)/1000, ...
        param.cartas_fondo(1:n,1),param.cartas_fondo(1:n,2)/1000];
      t=aos_report_table_from_matrix('bm_carta_gibbs','Carta Gibbs - superficie y fondo','BM',M, ...
        {'idx','pos_sup_m','carga_sup_kN','pos_fondo_m','carga_fondo_kN'}, ...
        {'Indice','Posicion superficie','Carga superficie','Posicion fondo','Carga fondo'}, ...
        {'','m','kN','m','kN'},'role','TIME_SERIES','category','TIME_SERIES', ...
        'priority','DETAIL','default_mode','VIEWER_ONLY','sample_step',20, ...
        'description','Puntos completos de las cartas de superficie y fondo.');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif

  survey=survey_local(param);
  if ~isempty(survey)
    n=numel(survey.MD);inc=vector_local(survey,{'inclinacion','INC','inc'},n,NaN);
    azi=vector_local(survey,{'azimut','AZI','azi'},n,NaN);
    idt=vector_local(survey,{'ID_tubing','id_tubing','diam_tbg'},n,NaN);
    idc=vector_local(survey,{'ID_casing','id_casing'},n,NaN);
    rug=vector_local(survey,{'rugosidad','roughness'},n,NaN);
    rows=num2cell([(1:n)',survey.MD(:),survey.TVD(:),inc(:),azi(:),idt(:),idc(:),rug(:)]);
    t=struct('id','well_survey','title','Survey del pozo','section','POZO', ...
      'role','PROFILE_TABLE','source','CONFIG_ACTIVA_SURVEY','category','PROFILE', ...
      'priority','SECONDARY','columns',{{'idx','MD_m','TVD_m','inclinacion_deg','azimut_deg','ID_tubing_m','ID_casing_m','rugosidad_m'}}, ...
      'labels',{{'Indice','MD','TVD','Inclinacion','Azimut','ID tubing','ID casing','Rugosidad'}}, ...
      'units',{{'','m','m','deg','deg','m','m','m'}},'rows',{rows}, ...
      'default_mode','FULL_APPENDIX','sample_step',10,'archive_full',true);
    tablas=aos_report_append_tables(tablas,t);

    rows2=num2cell([(1:n)',survey.MD(:),idt(:),idc(:),rug(:)]);
    t2=struct('id','well_tubing_profile','title','Perfil de tubing y casing','section','POZO', ...
      'role','PROFILE_TABLE','source','CONFIG_ACTIVA_SURVEY','category','PROFILE', ...
      'priority','DETAIL','columns',{{'idx','MD_m','ID_tubing_m','ID_casing_m','rugosidad_m'}}, ...
      'labels',{{'Indice','MD','ID tubing','ID casing','Rugosidad'}}, ...
      'units',{{'','m','m','m','m'}},'rows',{rows2}, ...
      'default_mode','VIEWER_ONLY','sample_step',10,'archive_full',true);
    tablas=aos_report_append_tables(tablas,t2);
  endif

  pz=punzados_local(param);
  if ~isempty(pz)
    campos={'id','nombre','MD_desde_m','MD_hasta_m','TVD_desde_m','TVD_hasta_m', ...
      'densidad_tiros_m','diametro_punzado_mm','n_tiros','activo','formacion', ...
      'permeabilidad_mD','skin','origen','estado_validacion'};
    labels={'ID','Nombre','MD desde','MD hasta','TVD desde','TVD hasta', ...
      'Densidad','Diametro','Tiros','Activo','Formacion','Permeabilidad','Skin','Origen','Validacion'};
    units={'','','m','m','m','m','tiros/m','mm','','','','mD','','',''};
    t=aos_report_table_from_structs('well_perforations','Intervalos de punzados activos','POZO', ...
      pz,campos,labels,units,'role','PRIMARY_RESULT','category','COMPLETION', ...
      'priority','PRIMARY','default_mode','FULL_BODY','mandatory',true, ...
      'source','CONFIG_ACTIVA_PUNZADOS');
    tablas=aos_report_append_tables(tablas,t);
  endif

  if isfield(param,'mandriles_resultado')&&isstruct(param.mandriles_resultado)
    tablas=aos_report_append_tables(tablas,aos_report_table_mandriles(param.mandriles_resultado));
  endif
endfunction

function survey=survey_local(param)
  survey=[];global CONFIG_ACTIVA;
  f={param,CONFIG_ACTIVA};
  for k=1:numel(f)
    a=f{k};if ~isstruct(a),continue;endif
    if isfield(a,'survey')&&isstruct(a.survey),x=a.survey;else,x=a;endif
    if isfield(x,'MD')&&isfield(x,'TVD')&&isnumeric(x.MD)&&isnumeric(x.TVD)
      n=min(numel(x.MD),numel(x.TVD));if n<1,continue;endif
      survey=x;survey.MD=x.MD(1:n)(:);survey.TVD=x.TVD(1:n)(:);
      [survey.MD,ord]=sort(survey.MD);survey.TVD=survey.TVD(ord);
      names={'inclinacion','INC','inc','azimut','AZI','azi','ID_tubing','id_tubing','diam_tbg','ID_casing','id_casing','rugosidad','roughness'};
      for j=1:numel(names)
        nm=names{j};if isfield(survey,nm)&&isnumeric(survey.(nm))
          v=survey.(nm)(:);if numel(v)>=n,survey.(nm)=v(1:n)(ord);endif
        endif
      endfor
      return;
    endif
  endfor
endfunction
function v=vector_local(s,names,n,d)
  v=d*ones(n,1);for j=1:numel(names),nm=names{j};if isfield(s,nm)&&isnumeric(s.(nm))
    x=s.(nm)(:);m=min(n,numel(x));v(1:m)=x(1:m);return;endif,endfor
endfunction
function pz=punzados_local(param)
  pz=struct([]);global geologia CONFIG_ACTIVA;
  x=[];
  if exist('aos_obtener_punzados_activos','file')==2
    try,x=aos_obtener_punzados_activos(geologia,param);catch,x=[];end_try_catch
  endif
  if isempty(x)
    f={param,CONFIG_ACTIVA,geologia};names={'punzados','perforaciones','intervalos_punzados','intervalos'};
    for i=1:numel(f),a=f{i};if ~isstruct(a),continue;endif
      for j=1:numel(names),if isfield(a,names{j})&&~isempty(a.(names{j})),x=a.(names{j});break;endif,endfor
      if ~isempty(x),break;endif
    endfor
  endif
  if isempty(x),return;endif
  if exist('aos_punzados_normalizar','file')==2
    try,pz=aos_punzados_normalizar(x);catch,pz=normalizar_basico_local(x);end_try_catch
  else,pz=normalizar_basico_local(x);endif
  if isempty(pz),return;endif
  % Filtrar inactivos si el contrato los conserva.
  keep=true(1,numel(pz));for i=1:numel(pz),if isfield(pz(i),'activo'),keep(i)=logical_safe_local(pz(i).activo);endif,endfor
  pz=pz(keep);
  % Completar TVD desde survey cuando sea posible.
  sv=survey_local(param);
  for i=1:numel(pz)
    if ~isfield(pz(i),'TVD_desde_m')||~finite_scalar_local(pz(i).TVD_desde_m),pz(i).TVD_desde_m=interp_local(sv,field_num_local(pz(i),{'MD_desde_m','MD_desde'},NaN));endif
    if ~isfield(pz(i),'TVD_hasta_m')||~finite_scalar_local(pz(i).TVD_hasta_m),pz(i).TVD_hasta_m=interp_local(sv,field_num_local(pz(i),{'MD_hasta_m','MD_hasta'},NaN));endif
  endfor
endfunction
function p=normalizar_basico_local(x)
  p=struct([]);if isnumeric(x)&&size(x,2)>=2
    for i=1:size(x,1),p(i)=struct('id',sprintf('PZ-%03d',i),'nombre',sprintf('Intervalo %d',i), ...
      'MD_desde_m',min(x(i,1:2)),'MD_hasta_m',max(x(i,1:2)),'TVD_desde_m',NaN,'TVD_hasta_m',NaN, ...
      'densidad_tiros_m',field_matrix_local(x,i,3,NaN),'diametro_punzado_mm',1000*field_matrix_local(x,i,4,NaN), ...
      'n_tiros',NaN,'activo',true,'formacion','','permeabilidad_mD',NaN,'skin',NaN,'origen','IMPORTADO','estado_validacion','NO_VALIDADO');endfor
  elseif isstruct(x),p=x;endif
endfunction
function v=field_matrix_local(x,i,j,d),v=d;if size(x,2)>=j&&isfinite(x(i,j)),v=x(i,j);endif,endfunction
function v=field_num_local(s,names,d),v=d;for k=1:numel(names),if isfield(s,names{k})&&finite_scalar_local(s.(names{k})),v=double(s.(names{k}));return;endif,endfor,endfunction
function tf=finite_scalar_local(x),tf=isnumeric(x)&&isscalar(x)&&isfinite(x);endfunction
function tf=logical_safe_local(x),tf=true;if islogical(x)&&isscalar(x),tf=x;elseif isnumeric(x)&&isscalar(x)&&isfinite(x),tf=x~=0;elseif ischar(x),tf=any(strcmpi(strtrim(x),{'1','s','si','true','yes'}));endif,endfunction
function tvd=interp_local(sv,md),tvd=NaN;if isempty(sv)||~isfinite(md),return;endif;try,tvd=interp1(sv.MD,sv.TVD,md,'linear','extrap');catch,tvd=NaN;end_try_catch,endfunction
