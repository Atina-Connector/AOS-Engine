function archivo=bes3_exportar_comparacion_core(contexto,archivo,enriquecido)
% BES3_EXPORTAR_COMPARACION_CORE Comparacion ON/OFF con tabla seleccionable HF3.5.
  if nargin<1||~isstruct(contexto)||~isfield(contexto,'comparacion'),error('Contexto ON/OFF incompleto.');endif
  if nargin<2||~ischar(archivo)||isempty(strtrim(archivo)),error('Falta archivo de salida.');endif
  if nargin<3,enriquecido=false;endif
  C=contexto.comparacion;p=contexto.param;
  [ruta,nombre,ext]=fileparts(archivo);if isempty(ext),archivo=[archivo '.aosrpt'];endif;if isempty(ruta),ruta='.';endif;if exist(ruta,'dir')~=7,mkdir(ruta);endif
  rows={ 'APAGADA',0,C.apagada.Ql_m3_d,C.apagada.Qo_m3_d,0,C.apagada.estado; ...
         'ENCENDIDA',C.frecuencia_on_Hz,C.encendida.Ql_m3_d,C.encendida.Qo_m3_d,C.potencia_incremental_kW,C.encendida.estado };
  t=struct('id','bes3_on_off_comparison','title','Comparacion BES3 apagada / encendida','section','BES3', ...
    'role','PRIMARY_RESULT','source','BES3_COMPARISON','category','COMPARISON','priority','PRIMARY', ...
    'columns',{{'estado','frecuencia_Hz','Ql_m3_d','Qo_m3_d','potencia_kW','estado_solver'}}, ...
    'labels',{{'Estado','Frecuencia','Ql','Qo','Potencia','Estado solver'}}, ...
    'units',{{'','Hz','m3/d','m3/d','kW',''}},'rows',{rows},'default_mode','FULL_BODY','mandatory',true);
  [p,tablas,comp]=aos_report_prepare_tables(p,'BES3',t,struct());
  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear %s',archivo);endif
  try
    fmt='LIGERO';if enriquecido,fmt='ENRIQUECIDO';endif
    fprintf(fid,'[AOS_REPORT]\nversion=2.0\nviewer_schema=AOS_VIEWER_BES3_COMPARISON_1.1\n');
    fprintf(fid,'fecha=%s\nsistema=BES\nmodulo=BES3\ntipo_calculo=COMPARACION_ON_OFF\nformato=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'),fmt);
    ng=0;if enriquecido&&isfield(C,'figures'),ng=numel(C.figures);endif
    mi=struct('report_id',nombre,'report_type','BES3_ON_OFF_COMPARISON','module','BES3','workbench','AOS_SLA','viewer_schema','AOS_VIEWER_BES3_COMPARISON_1.1','graphics_count',ng);aos_report_write_manifest(fid,mi,comp);
    fprintf(fid,'\n[BES3_ON_OFF_SUMMARY]\nmodelo_IPR=%s\nmodelo_VLP=%s\nfrecuencia_on_Hz=%.12g\n',clean(C.modelo_IPR),clean(C.modelo_VLP),C.frecuencia_on_Hz);
    fprintf(fid,'Q_apagada_m3_d=%.12g\nQ_encendida_m3_d=%.12g\ndelta_Ql_m3_d=%.12g\n',C.apagada.Ql_m3_d,C.encendida.Ql_m3_d,C.delta_Ql_m3_d);
    fprintf(fid,'Qo_apagada_m3_d=%.12g\nQo_encendida_m3_d=%.12g\ndelta_Qo_m3_d=%.12g\n',C.apagada.Qo_m3_d,C.encendida.Qo_m3_d,C.delta_Qo_m3_d);
    fprintf(fid,'incremento_pct=%.12g\npotencia_incremental_kW=%.12g\n',C.incremento_pct,C.potencia_incremental_kW);
    aos_rpt_escribir_tablas(fid,tablas,comp);aos_report_write_reference(fid,'RESULTADOS',tablas(1),'DISPONIBLE');
    incluir=true;if isfield(p,'aosrpt_incluir_contexto_viewer'),incluir=logical(p.aosrpt_incluir_contexto_viewer);endif
    if exist('aos_exportar_contexto_viewer','file')==2,aos_exportar_contexto_viewer(fid,p,'BES',incluir);endif
    if enriquecido,graficos_local(fid,C,p,archivo,incluir);endif
    fclose(fid);
  catch err
    try,fclose(fid);catch,end_try_catch;if exist(archivo,'file')==2,try,delete(archivo);catch,end_try_catch,endif;rethrow(err);
  end_try_catch
endfunction
function graficos_local(fid,C,p,archivo,incluir)
  carpeta=fileparts(archivo);if isempty(carpeta),carpeta='.';endif;g=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if isfield(C,'figures')&&~isempty(C.figures),for i=1:numel(C.figures),st='ERROR_HANDLE_CERRADO';b='';h=C.figures(i);try,if ishandle(h),tmp=[tempname(carpeta) '.png'];print(h,'-dpng','-r150',tmp);b=b64(tmp);delete(tmp);if ~isempty(b),st='OK';endif,endif;catch err,st=['ERROR_' regexprep(err.message,'[^A-Za-z0-9]+','_')];end_try_catch;g(end+1)=struct('id',sprintf('bes3_on_off_%02d',i),'titulo','Comparacion BES3 ON/OFF','seccion','COMPARACION','estado',st,'base64',b);endfor,endif
  if incluir&&exist('aos_generar_imagen_survey','file')==2,try,[r,st]=aos_generar_imagen_survey(p,'BES',carpeta);bb='';if exist(r,'file')==2&&strcmpi(st,'OK'),bb=b64(r);delete(r);endif;g(end+1)=struct('id','survey_2d','titulo','Survey del pozo','seccion','SURVEY','estado',st,'base64',bb);catch,end_try_catch,endif
  if exist('aos_rpt_escribir_graficos','file')==2,aos_rpt_escribir_graficos(fid,g);endif
endfunction
function s=b64(r),s='';f=fopen(r,'rb');if f>=0,x=fread(f,Inf,'uint8=>uint8');fclose(f);try,s=base64_encode(x);catch,end_try_catch,endif,endfunction
function s=clean(x),if ~ischar(x),x='';endif,s=regexprep(x,'[\r\n=,]',' ');endfunction
