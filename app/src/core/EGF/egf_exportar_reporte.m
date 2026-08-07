function archivo = egf_exportar_reporte(sol, enriquecido, archivo)
% EGF_EXPORTAR_REPORTE Reporte EGF con composicion transversal HF3.5.

  if nargin < 2 || isempty(enriquecido), enriquecido = false; endif
  carpeta = fullfile('intercambio','reportes','enviados');
  if exist(carpeta,'dir') ~= 7, mkdir(carpeta); endif
  if nargin < 3 || isempty(archivo)
    global AOSDAT_ACTIVO;
    base = 'EGF_reporte.aosrpt';
    if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
      base = [AOSDAT_ACTIVO '_EGF.aosrpt'];
    endif
    archivo = aos_elegir_nombre_reporte(carpeta,base);
  endif

  param = struct();
  if isfield(sol,'param') && isstruct(sol.param), param = sol.param; endif
  param.aosrpt_es_enriquecido = enriquecido;
  [param, tablas, composicion] = aos_report_prepare_tables(param,'EGF',struct([]),struct());

  graficos = struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if enriquecido
    try
      figs = egf_plot_resultado(sol,'off');
      for i = 1:numel(figs)
        tmp = [tempname(carpeta) '.png'];
        print(figs(i),'-dpng','-r140',tmp);
        close(figs(i));
        graficos(end+1) = entrada_local(sprintf('egf_fig_%02d',i),tmp);
        if exist(tmp,'file') == 2, delete(tmp); endif
      endfor
    catch err
      graficos(end+1) = struct('id','egf_fig_error','titulo','EGF', ...
        'seccion','EGF','estado',['ERROR_' limpiar_id_local(err.message)],'base64','');
    end_try_catch
  endif

  fid = fopen(archivo,'w');
  if fid < 0, error('No se pudo crear reporte EGF.'); endif
  cerrado = false;
  try
    fprintf(fid,'[AOS_REPORT]\nversion=1.8\nviewer_schema=AOS_VIEWER_EGF_1.1\n');
    fprintf(fid,'modulo=EGF\nfecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
    [~,rid,~] = fileparts(archivo);
    info = struct('report_id',rid,'report_type','EGF_SIMULATION', ...
      'module','EGF','workbench','AOS_SLA', ...
      'viewer_schema','AOS_VIEWER_EGF_1.1','graphics_count',numel(graficos));
    aos_report_write_manifest(fid,info,composicion);
    fprintf(fid,'\n[EGF_SUMMARY]\nestado=%s\naceptado=%d\n',clean(sol.estado),sol.aceptado);
    fprintf(fid,'eyector=%s\norigen=%s\n',clean(sol.eyector.modelo),clean(sol.eyector.origen));
    fprintf(fid,'Qg_aspirado_Sm3_d=%.8g\nQg_motriz_Sm3_d=%.8g\nQg_total_Sm3_d=%.8g\n', ...
      sol.Qg_aspirado_Sm3_d,sol.Qg_motriz_Sm3_d,sol.Qg_total_Sm3_d);
    if isfield(sol,'punto') && isstruct(sol.punto)
      p = sol.punto;
      fprintf(fid,'Pwf_bar=%.8g\nPs_bar=%.8g\nPm_fondo_bar=%.8g\n',p.Pwf/1e5,p.Ps/1e5,p.Pm_fondo/1e5);
      fprintf(fid,'Pmix_bar=%.8g\nPd_bar=%.8g\nPd_req_bar=%.8g\n',p.Pmix/1e5,p.Pd_pred/1e5,p.Pd_req/1e5);
      fprintf(fid,'entrainment=%.8g\nMach_mix=%.8g\nregimen=%s\n',p.entrainment,p.Mach_mix,clean(p.regimen));
      fprintf(fid,'P_equiv_superficie_kW=%.8g\n',p.P_equiv_superficie_kW);
    endif
    fprintf(fid,'diagnostico=%s\n',clean(sol.diagnostico));
    aos_rpt_escribir_tablas(fid,tablas,composicion);
    try, aos_exportar_contexto_viewer(fid,param,'EGF',true); catch, end_try_catch
    if enriquecido && exist('aos_rpt_escribir_graficos','file') == 2
      aos_rpt_escribir_graficos(fid,graficos);
    endif
    fclose(fid);
    cerrado = true;
  catch err
    if ~cerrado, try, fclose(fid); catch, end_try_catch, endif
    if exist(archivo,'file') == 2, try, delete(archivo); catch, end_try_catch, endif
    rethrow(err);
  end_try_catch
  if exist('aos_finalizar_archivo_crypto','file') == 2
    aos_finalizar_archivo_crypto(archivo,true);
  endif
  fprintf('Reporte EGF exportado: %s\n',archivo);
endfunction

function g = entrada_local(id,ruta)
  g = struct('id',id,'titulo',id,'seccion','EGF','estado','OK','base64','');
  fid = fopen(ruta,'rb');
  if fid >= 0
    bytes = fread(fid,Inf,'uint8=>uint8');
    fclose(fid);
    try, g.base64 = base64_encode(bytes); catch, g.base64 = ''; end_try_catch
  endif
  if isempty(g.base64), g.estado = 'ERROR_BASE64'; endif
endfunction

function s = clean(x)
  if ~ischar(x), x = ''; endif
  s = regexprep(x,'[\r\n=]',' ');
endfunction
function s = limpiar_id_local(x)
  if ~ischar(x), x = 'DESCONOCIDO'; endif
  s = regexprep(x,'[^A-Za-z0-9]+','_');
endfunction
