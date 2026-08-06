function archivo = bes2_exportar_reporte(sol,enriquecido,archivo)
% BES2_EXPORTAR_REPORTE Reporte BES2 con composicion transversal HF3.5.
  if nargin<2||isempty(enriquecido),enriquecido=false;endif
  carpeta=fullfile('intercambio','reportes','enviados');if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  if nargin<3||isempty(archivo)
    base='BES_V2_reporte.aosrpt';global AOSDAT_ACTIVO;
    if ischar(AOSDAT_ACTIVO)&&~isempty(AOSDAT_ACTIVO),base=[AOSDAT_ACTIVO '_BES_V2.aosrpt'];endif
    archivo=aos_elegir_nombre_reporte(carpeta,base);
  endif
  p=struct();if isfield(sol,'param')&&isstruct(sol.param),p=sol.param;endif
  p.aosrpt_es_enriquecido=enriquecido;
  graficos=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if enriquecido
    figs=bes2_plot_resultado(sol,'off');
    for i=1:numel(figs)
      tmp=[tempname(carpeta) '.png'];print(figs(i),'-dpng','-r140',tmp);close(figs(i));
      id=sprintf('bes2_figura_%02d',i);graficos(end+1)=entry_local(id,id,'BES_V2','OK',tmp);delete(tmp);
    endfor
  endif
  p.aosrpt_graficos_count=numel(graficos);
  [p,tablas,comp]=aos_report_prepare_tables(p,'BES',bes2_report_build_tables(sol),struct());

  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear %s',archivo);endif
  fprintf(fid,'[AOS_REPORT]\nversion=1.8\nviewer_schema=AOS_VIEWER_BES2_1.1\nmodulo=BES_V2\nfecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  [~,rid,~]=fileparts(archivo);info=struct('report_id',rid,'report_type','BES2_SIMULATION','module','BES2','workbench','AOS_SLA','viewer_schema','AOS_VIEWER_BES2_1.1','graphics_count',numel(graficos));
  aos_report_write_manifest(fid,info,comp);
  fprintf(fid,'\n[BES2_SUMMARY]\nestado=%s\naceptado=%d\nmodelo_bomba=%s\norigen_curva=%s\n',sol.estado,sol.aceptado,clean_local(sol.bomba.modelo),clean_local(sol.bomba.origen));
  fprintf(fid,'Ql_m3_d=%.8g\nQo_m3_d=%.8g\nQg_total_Sm3_d=%.8g\n',sol.Ql_m3_d,sol.Qo_m3_d,sol.Qg_total_Sm3_d);
  if isfield(sol,'punto')
    q=sol.punto;fprintf(fid,'P_intake_bar=%.8g\nP_descarga_req_bar=%.8g\ndeltaP_bomba_bar=%.8g\nhead_m=%.8g\neta_bomba=%.8g\n',q.Pintake_Pa/1e5,q.Pdesc_req_Pa/1e5,q.dP_bomba_Pa/1e5,q.head_m,q.eta_bomba);
    fprintf(fid,'GVF_libre_pct=%.8g\nGVF_bomba_pct=%.8g\nP_eje_kW=%.8g\n',100*q.fluido.gvf_free,100*q.fluido.gvf_bomba,q.P_eje_kW);
  endif
  if isfield(sol,'electrico')
    fprintf(fid,'P_superficie_kW=%.8g\ncorriente_A=%.8g\nT_motor_C=%.8g\nestado_electrico=%s\n',sol.electrico.P_superficie_kW,sol.electrico.corriente_A,sol.electrico.termica.T_motor_C,sol.electrico.estado);
  endif
  [tc,~]=aos_report_table_find(tablas,'bes2_pump_curve');if ~isempty(tc),aos_report_write_reference(fid,'BES2_CURVE_TABLE',tc,'DISPONIBLE');endif
  aos_rpt_escribir_tablas(fid,tablas,comp);
  try,aos_exportar_contexto_viewer(fid,p,'BES',true);catch,end_try_catch
  if enriquecido,try,aos_rpt_escribir_graficos(fid,graficos);catch,end_try_catch,endif
  fclose(fid);
  if exist('aos_finalizar_archivo_crypto','file')==2,aos_finalizar_archivo_crypto(archivo,true);endif
  fprintf('Reporte BES V2 exportado: %s\n',archivo);
endfunction
function g=entry_local(id,tit,sec,st,ruta),g=struct('id',id,'titulo',tit,'seccion',sec,'estado',st,'base64','');fid=fopen(ruta,'rb');if fid>=0,b=fread(fid,Inf,'uint8=>uint8');fclose(fid);g.base64=base64_encode(b);endif,endfunction
function s=clean_local(x),if ~ischar(x),x='';endif,s=regexprep(x,'[\r\n=]',' ');endfunction
