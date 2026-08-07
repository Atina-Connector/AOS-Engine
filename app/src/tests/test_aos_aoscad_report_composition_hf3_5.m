function ok = test_aos_aoscad_report_composition_hf3_5()
% TEST_AOS_AOSCAD_REPORT_COMPOSITION_HF3_5 Metadata sin perder JSON.
  ok = false;
  m = struct();
  m.tablas_entrada.nodos = struct('id',{'N1','N2'},'x',{0,1},'y',{0,0});
  m.tablas_entrada.tramos = struct('id',{'T1'},'desde',{'N1'},'hasta',{'N2'});
  m.tablas_resultados.resultados_nodales = [1 10;2 9];
  antes = m;
  m = aos_aoscad_report_composition(m,true);
  assert(isfield(m,'report_composition'));
  assert(m.report_composition.table_count_available == 3);
  assert(strcmp(m.report_composition.data_policy,'ALWAYS_PRESERVED_IN_AOSCAD_JSON'));
  assert(isequaln(m.tablas_entrada,antes.tablas_entrada));
  assert(isequaln(m.tablas_resultados,antes.tablas_resultados));
  assert(numel(m.report_composition.table_presentation) == 3);
  ok = true;
  fprintf('RESULTADO: test_aos_aoscad_report_composition_hf3_5 APROBADO\n');
endfunction
