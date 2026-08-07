function archivo = aos_exportar_sensibilidad_core(contexto, archivo, enriquecido)
% AOS_EXPORTAR_SENSIBILIDAD_CORE Exportador transversal de sensibilidad.
% Conserva el bloque historico SENSITIVITY_TABLE y agrega tablas nativas
% embebidas, diagnostico ejecutivo y metadatos para Viewer.
  if nargin<1||~isstruct(contexto)||~isfield(contexto,'sensibilidad'),error('Contexto de sensibilidad incompleto.');endif
  if nargin<2||~ischar(archivo)||isempty(strtrim(archivo)),error('Falta archivo de salida.');endif
  if nargin<3,enriquecido=false;endif
  R=contexto.sensibilidad;
  if ~isfield(contexto,'param')||~isstruct(contexto.param),contexto.param=struct();endif
  p=contexto.param;
  [ruta,nombre_archivo,ext]=fileparts(archivo);if isempty(ext),archivo=[archivo '.aosrpt'];endif;if isempty(ruta),ruta='.';endif
  if exist(ruta,'dir')~=7,[ok,msg]=mkdir(ruta);if ~ok,error('No se pudo crear %s: %s',ruta,msg);endif,endif

  [headers,units,rows]=tabla_local(R);
  tabla=struct('id','sensitivity_points','title','Sensibilidad punto a punto', ...
    'section','SENSIBILIDAD','role','SENSITIVITY_TABLE','source','AOS_SENSITIVITY_SOLVER', ...
    'category','SENSITIVITY','priority','PRIMARY','default_mode','FULL_BODY','mandatory',true, ...
    'columns',{headers},'labels',{etiquetas_local(headers)},'units',{units},'rows',{rows});
  [p,tablas,comp]=aos_report_prepare_tables(p,sistema_contexto_local(contexto),tabla,struct());
  contexto.param=p;
  D=diagnostico_local(contexto,R,p);

  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear %s',archivo);endif
  cerrado=false;
  try
    escribir_cabecera_local(fid,contexto,R,enriquecido);
    ng=0;if enriquecido&&isfield(R,'figures')&&~isempty(R.figures),ng=numel(R.figures);endif
    mi=struct('report_id',nombre_archivo,'report_type',[limpiar_id_local(texto_local(contexto,'tipo','GENERAL')) '_SENSITIVITY'], ...
      'module',limpiar_id_local(texto_local(contexto,'tipo','GENERAL')),'workbench','AOS_SLA', ...
      'viewer_schema','AOS_VIEWER_SENSITIVITY_1.3','graphics_count',ng);
    aos_report_write_manifest(fid,mi,comp);
    aos_rpt_escribir_diagnostico(fid,D);
    escribir_resumen_local(fid,R,D);
    escribir_entradas_local(fid,contexto,R,p);
    aos_rpt_escribir_tablas(fid,tablas,comp);
    aos_report_write_reference(fid,'SENSITIVITY_TABLE',tablas(1),'DISPONIBLE');
    escribir_estados_compat_local(fid,R,contexto);

    incluir=true;if isfield(p,'aosrpt_incluir_contexto_viewer'),incluir=logical(p.aosrpt_incluir_contexto_viewer);endif
    if exist('aos_exportar_contexto_viewer','file')==2,aos_exportar_contexto_viewer(fid,p,sistema_contexto_local(contexto),incluir);endif
    if enriquecido,escribir_graficos_local(fid,R,archivo);endif
    fclose(fid);cerrado=true;
  catch err
    if ~cerrado,try,fclose(fid);catch,end_try_catch,endif
    if exist(archivo,'file')==2,try,delete(archivo);catch,end_try_catch,endif
    rethrow(err);
  end_try_catch
endfunction

function escribir_cabecera_local(fid,c,R,enriquecido)
  formato='LIGERO';if enriquecido,formato='ENRIQUECIDO';endif
  fprintf(fid,'[AOS_REPORT]\n');
  fprintf(fid,'version=2.0\n');
  fprintf(fid,'viewer_schema=AOS_VIEWER_SENSITIVITY_1.3\n');
  fprintf(fid,'contract_revision=AOSRPT_TABLES_1.1\n');
  fprintf(fid,'fecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid,'sistema=%s\n',limpiar_local(sistema_contexto_local(c)));
  fprintf(fid,'modulo=%s\n',limpiar_local(texto_local(c,'tipo','SENSIBILIDAD')));
  fprintf(fid,'tipo_calculo=SENSIBILIDAD\n');
  fprintf(fid,'variable=%s\n',limpiar_local(texto_local(R,'campo','parametro')));
  fprintf(fid,'solver=%s\n',limpiar_local(texto_local(c,'solver','NO_INFORMADO')));
  fprintf(fid,'nombre_pozo=%s\n',limpiar_local(nombre_pozo_contexto_local(c)));
  fprintf(fid,'formato=%s\n',formato);
  fprintf(fid,'tabla_renderizado=TEXTO_NATIVO\n');
  fprintf(fid,'tabla_como_imagen=NO\n');
endfunction
function escribir_capacidades_local(fid,c,nombre_archivo,enriquecido,R)
  n_graficos=0;
  if enriquecido&&isfield(R,'figures')&&~isempty(R.figures),n_graficos=numel(R.figures);endif
  fprintf(fid,'\n[REPORT_MANIFEST]\n');
  fprintf(fid,'schema=AOS_REPORT_MANIFEST_1.0\n');
  fprintf(fid,'report_id=%s\n',limpiar_id_local(nombre_archivo));
  fprintf(fid,'run_id=%s\n',limpiar_id_local(nombre_archivo));
  fprintf(fid,'report_type=%s_SENSITIVITY\n',limpiar_id_local(texto_local(c,'tipo','GENERAL')));
  fprintf(fid,'generator=AOS_0_1_3_R1_1\n');
  fprintf(fid,'created_at=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid,'module=%s\n',limpiar_id_local(texto_local(c,'tipo','GENERAL')));
  fprintf(fid,'workbench=AOS_SIM\n');
  fprintf(fid,'viewer_schema=AOS_VIEWER_SENSITIVITY_1.3\n');
  fprintf(fid,'encoding=UTF-8\n');
  fprintf(fid,'idioma=es\n');
  fprintf(fid,'sistema_unidades=SI_METRICO\n');
  fprintf(fid,'tablas_embebidas=1\n');
  fprintf(fid,'table_count=1\n');
  fprintf(fid,'embedded_graphics=%d\n',enriquecido~=0);
  fprintf(fid,'graphics_count=%d\n',n_graficos);
  fprintf(fid,'corrida_inmutable=1\n');
  fprintf(fid,'\n[REPORT_CAPABILITIES]\n');
  fprintf(fid,'schema=AOS_REPORT_CAPABILITIES_1.0\n');
  fprintf(fid,'native_tables=1\n');
  fprintf(fid,'supports_native_tables=1\n');
  fprintf(fid,'supports_embedded_graphics=1\n');
  fprintf(fid,'supports_effective_inputs=1\n');
  fprintf(fid,'supports_traceability=1\n');
  fprintf(fid,'table_schema=AOS_NATIVE_TABLE_1.0\n');
  fprintf(fid,'executive_diagnosis=1\n');
  fprintf(fid,'diagnostics_schema=AOS_EXECUTIVE_DIAGNOSIS_1.0\n');
endfunction
function escribir_entradas_local(fid,c,R,p)
  seccion='SENSITIVITY_EFFECTIVE_INPUTS';if strcmpi(texto_local(c,'tipo',''),'BES3'),seccion='BES3_EFFECTIVE_INPUTS';endif
  fprintf(fid,'\n[%s]\n',seccion);
  fprintf(fid,'schema=AOS_EFFECTIVE_INPUTS_1.1\n');
  fprintf(fid,'variable=%s\n',limpiar_local(texto_local(R,'campo','parametro')));
  fprintf(fid,'variable_origen=SENSIBILIDAD_MANUAL\n');
  fprintf(fid,'n_puntos=%d\n',numero_puntos_local(R));
  fprintf(fid,'configuracion_origen=%s\n',limpiar_local(origen_config_local(p)));
  fprintf(fid,'estado_validacion=%s\n',limpiar_local(estado_validacion_local(p)));
  if isfield(c,'effective_inputs')&&isstruct(c.effective_inputs)
    e=c.effective_inputs;fn=fieldnames(e);
    for i=1:numel(fn)
      if strcmpi(fn{i},'schema'),continue;endif
      v=e.(fn{i});
      if ischar(v),fprintf(fid,'%s=%s\n',fn{i},limpiar_local(v));
      elseif (isnumeric(v)||islogical(v))&&isscalar(v)
        if isfinite(double(v)),fprintf(fid,'%s=%.12g\n',fn{i},double(v));else,fprintf(fid,'%s=NA\n',fn{i});endif
      endif
    endfor
  endif
endfunction
function escribir_resumen_local(fid,R,D)
  v=valores_local(R);fprintf(fid,'\n[SENSITIVITY_SUMMARY]\n');
  fprintf(fid,'schema=AOS_SENSITIVITY_SUMMARY_1.2\n');
  fprintf(fid,'variable=%s\n',limpiar_local(texto_local(R,'campo','parametro')));
  fprintf(fid,'unidad_variable=%s\n',unidad_variable_local(R));
  fprintf(fid,'n_puntos=%d\n',numel(v));
  if ~isempty(v),fprintf(fid,'rango_min=%.12g\nrango_max=%.12g\n',min_finito_local(v),max_finito_local(v));endif
  fprintf(fid,'puntos_aceptados=%d\n',D.n_aceptados);
  fprintf(fid,'puntos_rechazados=%d\n',D.n_rechazados);
  fprintf(fid,'puntos_sin_produccion=%d\n',D.n_sin_produccion);
  fprintf(fid,'puntos_no_convergidos=%d\n',D.n_no_convergidos);
  fprintf(fid,'estado_global=%s\n',limpiar_local(D.estado_global));
  fprintf(fid,'semaforo_global=%s\n',limpiar_local(D.semaforo));
  fprintf(fid,'tabla_punto_a_punto=SI\n');
  fprintf(fid,'tabla_schema=AOS_NATIVE_TABLE_1.0\n');
  if isfield(R,'modo')&&iscell(R.modo),fprintf(fid,'puntos_bomba_apagada=%d\n',contar_texto_local(R.modo,'BOMBA_APAGADA'));endif
  if isfield(R,'estado_diseno')&&iscell(R.estado_diseno),fprintf(fid,'puntos_recirc_alta=%d\n',contar_texto_local(R.estado_diseno,'RECIRCULACION_ALTA'));endif
  escribir_max_local(fid,R,'Qprod_m3_d','Qprod_max_m3_d');escribir_max_local(fid,R,'Qrec_m3_d','Qrec_max_m3_d');
  escribir_max_local(fid,R,'BEP_inferior_pct','BEP_inferior_max_pct');escribir_max_local(fid,R,'BEP_superior_pct','BEP_superior_max_pct');
endfunction
function escribir_tabla_legacy_local(fid,h,u,rows)
  fprintf(fid,'\n[SENSITIVITY_TABLE]\n');fprintf(fid,'schema=AOS_SENSITIVITY_TABLE_1.2\n');
  fprintf(fid,'render_preferred=TABLE_NATIVE\n');fprintf(fid,'embedded=1\n');fprintf(fid,'delimiter=,\n');
  fprintf(fid,'n_filas=%d\nn_columnas=%d\n',size(rows,1),numel(h));
  fprintf(fid,'columns=%s\n',strjoin(h,','));fprintf(fid,'units=%s\n',strjoin(u,','));
  fprintf(fid,'data_begin=1\n');
  for i=1:size(rows,1),c=cell(1,size(rows,2));for j=1:size(rows,2),c{j}=csv_local(rows{i,j});endfor;fprintf(fid,'%s\n',strjoin(c,','));endfor
  fprintf(fid,'data_end=1\n');
endfunction
function escribir_resultados_humanos_local(fid,h,u,rows,R)
  fprintf(fid,'\n[RESULTADOS]\n');fprintf(fid,'tipo_resultado=SENSIBILIDAD\n');
  fprintf(fid,'formato_tabla=TEXTO_NATIVO\n');fprintf(fid,'tabla_imagen=NO\n');
  fprintf(fid,'tabla_titulo=Sensibilidad punto a punto\n');
  idx=columnas_visibles_local(h,12);fprintf(fid,'tabla_columnas=%s\n',strjoin(etiquetas_local(h(idx)),' | '));
  fprintf(fid,'tabla_unidades=%s\n',strjoin(u(idx),' | '));
  for i=1:size(rows,1)
    c=cell(1,numel(idx));for k=1:numel(idx),c{k}=display_local(rows{i,idx(k)},u{idx(k)},h{idx(k)});endfor
    fprintf(fid,'punto_%03d=%s\n',i,limpiar_local(strjoin(c,' | ')));
  endfor
  fprintf(fid,'nota_precision=La tabla nativa embebida conserva los valores numericos completos.\n');
endfunction
function escribir_vectores_local(fid,h,u,rows)
  fprintf(fid,'\n[SENSITIVITY_DATA]\n');fprintf(fid,'schema=AOS_SENSITIVITY_VECTORS_1.1\n');fprintf(fid,'render_preferred=TECHNICAL_APPENDIX\n');
  fprintf(fid,'nota=Compatibilidad; la fuente canonica es TABLE_001.\n');
  for j=1:numel(h)
    if columna_numerica_local(rows,j)
      c=cell(1,size(rows,1));for i=1:size(rows,1),c{i}=num_local(rows{i,j});endfor
      clave=limpiar_id_local(h{j});fprintf(fid,'%s=%s\n',clave,strjoin(c,','));fprintf(fid,'%s_unidad=%s\n',clave,limpiar_local(u{j}));
    endif
  endfor
endfunction
function escribir_estados_compat_local(fid,R,c)
  if ~strcmpi(texto_local(c,'tipo',''),'BES3'),return;endif
  fprintf(fid,'\n[BES3_SENSITIVITY_STATES]\n');
  fprintf(fid,'schema=BES3_SENSITIVITY_STATES_1.1\n');fprintf(fid,'render_preferred=TECHNICAL_APPENDIX\n');
  campos={'modo','estado_diseno','estado_operativo','rango_inferior_estado','rango_superior_estado','estado_secciones','estado'};
  claves={'modo','estado_diseno','estado_operativo','rango_inferior','rango_superior','estado_secciones','estado_solver'};
  for k=1:numel(campos)
    if isfield(R,campos{k})&&iscell(R.(campos{k}))
      vals=R.(campos{k})(:);
      for i=1:numel(vals)
        if ~ischar(vals{i}),vals{i}='';else,vals{i}=strrep(vals{i},'|','/');endif
      endfor
      fprintf(fid,'%s=%s\n',claves{k},strjoin(vals','|'));
    endif
  endfor
endfunction
function escribir_max_local(fid,R,campo,clave)
  if isfield(R,campo)&&isnumeric(R.(campo))
    v=max_finito_local(R.(campo));if isfinite(v),fprintf(fid,'%s=%.12g\n',clave,v);endif
  endif
endfunction
function n=contar_texto_local(c,pat)
  n=0;for i=1:numel(c),if ischar(c{i})&&~isempty(strfind(upper(c{i}),upper(pat))),n=n+1;endif,endfor
endfunction

function escribir_graficos_local(fid,R,archivo)
  g=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});carpeta=fileparts(archivo);if isempty(carpeta),carpeta='.';endif
  if isfield(R,'figures')&&~isempty(R.figures)
    hs=R.figures(:)';for i=1:numel(hs),[estado,b64]=figura_local(hs(i),carpeta);g(end+1)=struct('id',sprintf('sensibilidad_%02d',i),'titulo',sprintf('Sensibilidad - %s',texto_local(R,'campo','parametro')),'seccion','SENSIBILIDAD','estado',estado,'base64',b64);endfor
  endif
  if exist('aos_rpt_escribir_graficos','file')==2,aos_rpt_escribir_graficos(fid,g);else,fprintf(fid,'\n[GRAFICOS]\nschema=NO_DISPONIBLE\nn_figuras=0\n');endif
endfunction
function [estado,b64]=figura_local(h,carpeta)
  estado='ERROR_HANDLE_CERRADO';b64='';tmp='';
  try
    if ~ishandle(h)||~strcmpi(get(h,'type'),'figure'),return;endif
    tmp=[tempname(carpeta) '.png'];print(h,'-dpng','-r150',tmp);f=fopen(tmp,'rb');if f>=0,b=fread(f,Inf,'uint8=>uint8');fclose(f);b64=base64_encode(b);endif
    if isempty(b64),estado='ERROR_BASE64';else,estado='OK';endif
  catch err,estado=['ERROR_' limpiar_id_local(err.message)];end_try_catch
  if ischar(tmp)&&~isempty(tmp)&&exist(tmp,'file')==2,try,delete(tmp);catch,end_try_catch,endif
endfunction
function D=diagnostico_local(c,R,p)
  if isfield(c,'diagnostico')&&isstruct(c.diagnostico),D=c.diagnostico;else,D=aos_sensibilidad_diagnosticar(R,texto_local(c,'tipo','GENERAL'),p);endif
endfunction
function [h,u,rows]=tabla_local(R)
  h={};u={};rows={};
  if isfield(R,'headers')&&iscell(R.headers),h=R.headers(:)';endif
  if isfield(R,'units')&&iscell(R.units),u=R.units(:)';endif
  if isfield(R,'rows')&&iscell(R.rows),rows=R.rows;endif
  if isempty(h)
    campos=fieldnames(R);n=numero_puntos_local(R);
    for i=1:numel(campos),v=R.(campos{i});if (isnumeric(v)||iscell(v))&&isvector(v)&&numel(v)==n,h{end+1}=campos{i};endif,endfor
    rows=cell(n,numel(h));for j=1:numel(h),v=R.(h{j});for i=1:n,if iscell(v),rows{i,j}=v{i};else,rows{i,j}=v(i);endif,endfor,endfor
  endif
  if isempty(u),u=repmat({''},1,numel(h));elseif numel(u)~=numel(h),u=[u repmat({''},1,max(0,numel(h)-numel(u)))];u=u(1:numel(h));endif
endfunction
function idx=columnas_visibles_local(h,maxn)
  prioridad={'Valor','Modo','Qprod_m3_d','Ql_m3_d','Qg_Sm3_d','Qs_Sm3_d','Qrec_m3_d','Qrec_pct_nominal','BEP_inferior_pct','BEP_superior_pct','BEP_pct','Pintake_bar','Ps_bar','P_superficie_kW','Estado_diseno','Estado_operativo','Estado','Estado_solver','Aceptado'};
  idx=[];for i=1:numel(prioridad),j=find(strcmpi(h,prioridad{i}),1);if ~isempty(j)&&~any(idx==j),idx(end+1)=j;endif;if numel(idx)>=maxn,break;endif,endfor
  if isempty(idx),idx=1:min(maxn,numel(h));endif
endfunction
function e=etiquetas_local(h)
  e=cell(size(h));
  claves={'valor','modo','n_etapas','num_etapas','etapa_toma','qprod_m3_d','ql_m3_d','qrec_m3_d','qnom_m3_d','qrec_pct_nominal','qinferior_m3_d','qsuperior_m3_d','bep_inferior_pct','bep_superior_pct','pintake_bar','ptoma_bar','dpcapilar_bar','tmotor_c','psuperficie_kw','p_superficie_kw','rango_inferior','rango_superior','estado_secciones','estado_diseno','estado_operativo','convergido','aceptado','aceptado_preliminar','aceptado_certificado','estado','estado_solver'};
  etiquetas={'Valor','Modo','Etapas totales','Etapas totales','Etapa de toma','Produccion superficie','Produccion superficie','Recirculacion','Caudal nominal efectivo','Recirculacion / nominal','Caudal etapas inferiores','Caudal etapas superiores','BEP etapas inferiores','BEP etapas superiores','Presion de intake','Presion en toma','Perdida capilar','Temperatura de motor','Potencia de superficie','Potencia de superficie','Rango etapas inferiores','Rango etapas superiores','Estado de secciones','Estado de diseno','Estado operativo','Convergido','Aceptado','Aceptacion preliminar','Aceptacion certificada','Estado del solver','Estado del solver'};
  for i=1:numel(h)
    j=find(strcmpi(claves,h{i}),1);
    if ~isempty(j),e{i}=etiquetas{j};else,x=strrep(h{i},'_',' ');x=regexprep(x,'\bm3 d\b','m3/d');e{i}=x;endif
  endfor
endfunction
function s=display_local(v,u,h)
  if isnumeric(v)||islogical(v)
    if isempty(v)||~isscalar(v)||~isfinite(double(v)),s='no disponible';return;endif
    x=double(v);if abs(x)<1e-6,x=0;endif
    ul=lower(u);if strcmp(ul,'etapas')||contiene_local(lower(h),'n_etapas'),s=sprintf('%.0f',x);elseif any(strcmp(ul,{'%','bar','m3/d','sm3/d','kw','c'})),s=sprintf('%.2f',x);elseif strcmp(ul,'hz')||strcmp(ul,'m'),s=sprintf('%.3f',x);else,s=sprintf('%.6g',x);endif
  elseif ischar(v),s=v;else,s='no disponible';endif
endfunction
function s=csv_local(v)
  if isnumeric(v)||islogical(v),if isempty(v)||~isscalar(v)||~isfinite(double(v)),s='NA';else,s=sprintf('%.12g',double(v));endif
  elseif ischar(v),x=strrep(regexprep(v,'[\r\n]',' '),'"','""');s=['"' x '"'];else,s='NA';endif
endfunction
function s=num_local(v),if isnumeric(v)&&isscalar(v)&&isfinite(v),s=sprintf('%.12g',v);else,s='';endif,endfunction
function tf=columna_numerica_local(rows,j)
  tf=false;for i=1:size(rows,1),v=rows{i,j};if isempty(v),continue;endif;if isnumeric(v)&&isscalar(v),tf=true;else,tf=false;return;endif,endfor
endfunction
function v=valores_local(R)
  v=[];if isfield(R,'valores')&&isnumeric(R.valores),v=double(R.valores(:));endif
endfunction
function n=numero_puntos_local(R)
  n=0;if isfield(R,'valores')&&isnumeric(R.valores),n=numel(R.valores);elseif isfield(R,'rows')&&iscell(R.rows),n=size(R.rows,1);endif
endfunction
function u=unidad_variable_local(R)
  u='-';if isfield(R,'units')&&iscell(R.units)&&~isempty(R.units)&&ischar(R.units{1})&&~isempty(R.units{1}),u=R.units{1};return;endif
  c=lower(texto_local(R,'campo',''));if strcmp(c,'frecuencia'),u='Hz';elseif contiene_local(c,'etapa'),u='etapas';elseif contiene_local(c,'pres')||strcmp(c,'p_wh'),u='Pa';elseif contiene_local(c,'_m')||contiene_local(c,'prof'),u='m';endif
endfunction
function s=sistema_contexto_local(c)
  s=texto_local(c,'tipo','GENERAL');if strcmpi(s,'BES3')||strcmpi(s,'BES_V2'),s='BES';endif
endfunction
function n=nombre_pozo_contexto_local(c)
  n='Pozo sin identificar';if isfield(c,'nombre_pozo')&&ischar(c.nombre_pozo)&&~isempty(strtrim(c.nombre_pozo)),n=c.nombre_pozo;elseif isfield(c,'param')&&isstruct(c.param),p=c.param;campos={'nombre_pozo','pozo','nombre'};for i=1:numel(campos),if isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i}))),n=p.(campos{i});return;endif,endfor,endif
endfunction
function s=origen_config_local(p)
  s='CONFIGURACION_EFECTIVA';if isfield(p,'aos_config_origen')&&ischar(p.aos_config_origen)&&~isempty(p.aos_config_origen),s=p.aos_config_origen;elseif isfield(p,'sens_origen')&&ischar(p.sens_origen),s=p.sens_origen;endif
  if ~isempty(strfind(s,'/'))||~isempty(strfind(s,'|'))||~isempty(strfind(s,',')),s='CONFIGURACION_EFECTIVA_NO_TRAZADA';endif
endfunction
function s=estado_validacion_local(p)
  s='NO_INFORMADO';campos={'estado_validacion','bes3_estado_validacion'};for i=1:numel(campos),if isfield(p,campos{i})&&ischar(p.(campos{i})),s=p.(campos{i});return;endif,endfor
endfunction
function v=min_finito_local(x),y=x(isfinite(x));if isempty(y),v=NaN;else,v=min(y);endif,endfunction
function v=max_finito_local(x),y=x(isfinite(x));if isempty(y),v=NaN;else,v=max(y);endif,endfunction
function t=texto_local(s,c,d),t=d;if isstruct(s)&&isfield(s,c)&&ischar(s.(c))&&~isempty(strtrim(s.(c))),t=s.(c);endif,endfunction
function s=limpiar_local(s),if ~ischar(s),s='';endif;s=regexprep(s,'[\r\n=]',' ');endfunction
function s=limpiar_id_local(s),s=regexprep(limpiar_local(s),'[^A-Za-z0-9_-]+','_');if isempty(s),s='campo';endif,endfunction
function tf=contiene_local(a,b),tf=ischar(a)&&ischar(b)&&~isempty(strfind(a,b));endfunction
