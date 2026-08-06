function ok = test_aos_report_composition_hf3_5()
% TEST_AOS_REPORT_COMPOSITION_HF3_5 Contrato y preservacion de tablas.
  ok = false;
  tmpdir = [tempname() '_aos_report_hf35'];
  mkdir(tmpdir);
  unwind_protect
    t1 = aos_report_table_from_matrix('summary','Resultados principales','GENERAL', ...
      [1 10;2 20],{'idx','value'},{'Indice','Valor'},{'','m3/d'}, ...
      'priority','PRIMARY','default_mode','FULL_BODY');
    t2 = aos_report_table_from_matrix('long_series','Serie extensa','GENERAL', ...
      [(1:721)' linspace(0,1,721)'],{'idx','x'},{'Indice','X'},{'','m'}, ...
      'role','TIME_SERIES','category','TIME_SERIES','priority','DETAIL', ...
      'default_mode','VIEWER_ONLY','sample_step',20);
    t3 = aos_report_table_from_matrix('sensitivity','Sensibilidad','SENSIBILIDAD', ...
      [(1:15)' (10:10:150)'],{'point','production'},{'Punto','Produccion'},{'','m3/d'}, ...
      'role','SENSITIVITY_TABLE','category','SENSITIVITY','priority','PRIMARY', ...
      'default_mode','FULL_BODY','mandatory',true);
    tablas = aos_report_append_tables(t1,t2);
    tablas = aos_report_append_tables(tablas,t3);

    [tablas, comp] = aos_report_apply_profile(tablas,'EXECUTIVE',struct());
    [sens,~] = aos_report_table_find(tablas,'sensitivity');
    assert(strcmp(sens.render_mode,'FULL_BODY'));
    assert(comp.table_count_available == 3);

    ov = struct();
    ov.long_series = struct('render_mode','SAMPLED','sample_step',25);
    ov.summary = 'EXCLUDED_EXPORT';
    [tablas, comp] = aos_report_apply_profile(tablas,'TECHNICAL',ov);
    assert(comp.table_count_excluded == 1);
    assert(comp.table_count_archived >= 2);

    archivo = fullfile(tmpdir,'composition.aosrpt');
    fid = fopen(archivo,'w'); assert(fid >= 0);
    info = struct('report_id','hf35_test','report_type','TEST', ...
      'module','TEST','workbench','AOS_TEST','graphics_count',2);
    aos_report_write_manifest(fid,info,comp);
    aos_rpt_escribir_tablas(fid,tablas,comp);
    fclose(fid);

    txt = fileread(archivo);
    assert(~isempty(strfind(txt,'schema=AOS_REPORT_MANIFEST_1.1')));
    assert(~isempty(strfind(txt,'table_count=3')));
    assert(~isempty(strfind(txt,'embedded_graphics=2')));
    assert(~isempty(strfind(txt,'full_data_policy=ALWAYS_PRESERVE')));
    assert(~isempty(strfind(txt,'render_mode=EXCLUDED_EXPORT')));
    assert(~isempty(strfind(txt,'[TABLE_ARCHIVE_INDEX]')));
    assert(~isempty(strfind(txt,'table_id=summary')));
    assert(~isempty(strfind(txt,'table_id=long_series')));
    assert(~isempty(strfind(txt,'table_id=sensitivity')));
    assert(~isempty(strfind(txt,'721,1')) || ~isempty(strfind(txt,'721,1.')));
    [vis,arc,ri] = aos_report_parse_native_tables(archivo);
    assert(ri.n_total == 3);
    assert(numel(vis) == 2 && numel(arc) == 2);
    [long_arch,~] = aos_report_table_find(arc,'long_series');
    assert(~isempty(long_arch) && long_arch.n_rows == 721);
    [sum_arch,~] = aos_report_table_find(arc,'summary');
    assert(~isempty(sum_arch) && sum_arch.n_rows == 2);
    ok = true;
  unwind_protect_cleanup
    if exist(tmpdir,'dir') == 7
      aos_rmdir_seguro(tmpdir,tempdir());
    endif
  end_unwind_protect
  if ok, fprintf('RESULTADO: test_aos_report_composition_hf3_5 APROBADO\n'); endif
endfunction
