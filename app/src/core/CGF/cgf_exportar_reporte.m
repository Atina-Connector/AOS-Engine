function archivo=cgf_exportar_reporte(sol,enriquecido,archivo)
% CGF_EXPORTAR_REPORTE Reporte CGF con composicion transversal HF3.5.
  if nargin<2||isempty(enriquecido),enriquecido=false;endif
  carpeta=fullfile('intercambio','reportes','enviados');if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  if nargin<3||isempty(archivo),global AOSDAT_ACTIVO;base='CGF_reporte.aosrpt';if ischar(AOSDAT_ACTIVO)&&~isempty(AOSDAT_ACTIVO),base=[AOSDAT_ACTIVO '_CGF.aosrpt'];endif;archivo=aos_elegir_nombre_reporte(carpeta,base);endif
  p=struct();if isfield(sol,'param')&&isstruct(sol.param),p=sol.param;endif
  p.aosrpt_es_enriquecido=enriquecido;
  g=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if enriquecido
    figs=cgf_plot_resultado(sol,'off');for i=1:numel(figs),tmp=[tempname(carpeta) '.png'];print(figs(i),'-dpng','-r140',tmp);close(figs(i));g(end+1)=entry(sprintf('cgf_fig_%02d',i),tmp);delete(tmp);endfor
  endif
  p.aosrpt_graficos_count=numel(g);
  [p,tablas,comp]=aos_report_prepare_tables(p,'CGF',cgf_report_build_tables(sol),struct());
  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear reporte CGF');endif
  fprintf(fid,'[AOS_REPORT]\nversion=1.8\nviewer_schema=AOS_VIEWER_CGF_1.1\nmodulo=CGF\nfecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  [~,rid,~]=fileparts(archivo);info=struct('report_id',rid,'report_type','CGF_SIMULATION','module','CGF','workbench','AOS_SLA','viewer_schema','AOS_VIEWER_CGF_1.1','graphics_count',numel(g));aos_report_write_manifest(fid,info,comp);
  fprintf(fid,'\n[CGF_SUMMARY]\nestado=%s\naceptado=%d\ncompresor=%s\norigen_mapa=%s\nQg_Sm3_d=%.8g\n',sol.estado,sol.aceptado,clean(sol.compresor.modelo),clean(sol.compresor.origen),sol.Qg_Sm3_d);
  if isfield(sol,'punto'),q=sol.punto;fprintf(fid,'Pwf_bar=%.8g\nPs_bar=%.8g\nPd_bar=%.8g\nPd_req_bar=%.8g\nPR=%.8g\nTdesc_C=%.8g\neta_p=%.8g\nP_eje_kW=%.8g\n',q.Pwf_Pa/1e5,q.Ps_Pa/1e5,q.Pd_Pa/1e5,q.Pd_req_Pa/1e5,q.mapa.PR,q.T_d_K-273.15,q.mapa.eta_p,q.P_eje_kW);endif
  fprintf(fid,'estado_liquidos=%s\ndiagnostico=%s\n',sol.liquid_state,clean(sol.diagnostico));
  [tm,~]=aos_report_table_find(tablas,'cgf_compressor_map');if ~isempty(tm),aos_report_write_reference(fid,'CGF_MAP_TABLE',tm,'DISPONIBLE');endif
  aos_rpt_escribir_tablas(fid,tablas,comp);
  try,aos_exportar_contexto_viewer(fid,p,'CGF',true);catch,end_try_catch
  if enriquecido,try,aos_rpt_escribir_graficos(fid,g);catch,end_try_catch,endif
  fclose(fid);if exist('aos_finalizar_archivo_crypto','file')==2,aos_finalizar_archivo_crypto(archivo,true);endif;fprintf('Reporte CGF exportado: %s\n',archivo);
endfunction
function g=entry(id,r),g=struct('id',id,'titulo',id,'seccion','CGF','estado','OK','base64','');f=fopen(r,'rb');if f>=0,b=fread(f,Inf,'uint8=>uint8');fclose(f);g.base64=base64_encode(b);endif,endfunction
function s=clean(x),if ~ischar(x),x='';endif,s=regexprep(x,'[\r\n=]',' ');endfunction
