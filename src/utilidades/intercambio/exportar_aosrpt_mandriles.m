function archivo = exportar_aosrpt_mandriles(R, enriquecido, archivo)
% EXPORTAR_AOSRPT_MANDRILES Reporte de mandriles con composicion HF3.5.

  if nargin < 2 || isempty(enriquecido), enriquecido = false; endif
  carpeta = fullfile('intercambio','reportes','enviados');
  if exist(carpeta,'dir') ~= 7, mkdir(carpeta); endif
  if nargin < 3 || isempty(archivo)
    archivo = aos_elegir_nombre_reporte(carpeta,'diseno_mandriles.aosrpt');
  endif

  param = struct('mandriles_resultado',R,'aosrpt_es_enriquecido',enriquecido);
  tabla = aos_report_table_mandriles(R);
  [param, tablas, composicion] = aos_report_prepare_tables(param,'GL',tabla,struct());

  graficos = struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if enriquecido
    try
      ruta = [tempname(carpeta) '.png'];
      h = mandriles_plot_v2(R);
      print(h,'-dpng','-r150',ruta);
      close(h);
      graficos(end+1) = struct('id','diseno_mandriles', ...
        'titulo','Diseno y espaciamiento de mandriles', ...
        'seccion','MANDRILES','estado','OK','base64',archivo_base64_local(ruta));
      if exist(ruta,'file') == 2, delete(ruta); endif
    catch err
      graficos(end+1) = struct('id','diseno_mandriles', ...
        'titulo','Diseno y espaciamiento de mandriles', ...
        'seccion','MANDRILES','estado',['ERROR_' limpiar_local(err.message)],'base64','');
    end_try_catch
  endif

  fid = fopen(archivo,'w');
  if fid < 0, error('No se pudo crear %s',archivo); endif
  cerrado = false;
  try
    fprintf(fid,'[AOS_REPORT]\nformato=AOSRPT\nversion=1.3\n');
    fprintf(fid,'tipo=MANDRILES_V2\nenriquecido=%d\n',enriquecido);
    [~,rid,~] = fileparts(archivo);
    info = struct('report_id',rid,'report_type','GL_MANDREL_DESIGN', ...
      'module','GL_MANDRILES','workbench','AOS_SLA', ...
      'viewer_schema','AOS_VIEWER_MANDRILES_1.1', ...
      'graphics_count',numel(graficos));
    aos_report_write_manifest(fid,info,composicion);
    aos_rpt_escribir_mandriles(fid,R);
    aos_rpt_escribir_tablas(fid,tablas,composicion);
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
  fprintf('Reporte de mandriles exportado: %s\n',archivo);
endfunction

function txt = archivo_base64_local(ruta)
  txt = '';
  fid = fopen(ruta,'rb');
  if fid < 0, return; endif
  bytes = fread(fid,Inf,'uint8=>uint8');
  fclose(fid);
  try, txt = base64_encode(bytes); catch, txt = ''; end_try_catch
endfunction

function s = limpiar_local(x)
  if ~ischar(x), x = 'DESCONOCIDO'; endif
  s = regexprep(x,'[^A-Za-z0-9]+','_');
endfunction
