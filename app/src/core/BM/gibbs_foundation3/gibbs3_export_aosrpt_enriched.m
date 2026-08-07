function archivo = gibbs3_export_aosrpt_enriched(contexto, archivo)
% GIBBS3_EXPORT_AOSRPT_ENRICHED Informe GF3 con graficos y manifiesto exacto.
  graficos = gibbs3_report_graphics(contexto);
  n=0;if isstruct(graficos)&&~isempty(graficos)&&isfield(graficos,'estado'),n=sum(strcmpi({graficos.estado},'OK'));endif
  contexto.param.aosrpt_es_enriquecido=true;
  contexto.param.aosrpt_graficos_count=n;
  archivo = gibbs3_export_aosrpt_simple(contexto, archivo);
  fid = fopen(archivo, 'a');
  if fid < 0,error('No se pudo reabrir el informe enriquecido: %s', archivo);endif
  try
    fprintf(fid, '\n[GF3_INFORME_ENRIQUECIDO]\n');
    fprintf(fid, 'schema=GF3_GRAPHICS_1.1\n');
    fprintf(fid, 'fecha=%s\n', datestr(now(), 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'graphics_count=%d\n',n);
    aos_rpt_escribir_graficos(fid, graficos);
    fclose(fid);
  catch err
    fclose(fid);rethrow(err);
  end_try_catch
  if exist(archivo, 'file') ~= 2,error('No se creo el informe GF3 enriquecido: %s', archivo);endif
endfunction
