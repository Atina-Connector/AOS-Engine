function ok = test_aos_report_sensitivity_hf3_5()
% TEST_AOS_REPORT_SENSITIVITY_HF3_5 La tabla es resultado primario.
  ok = false;
  t = aos_report_table_from_matrix('sensitivity_points','Sensibilidad de frecuencia', ...
    'SENSIBILIDAD',[(30:5:80)' linspace(10,100,11)'], ...
    {'frequency_Hz','production_m3_d'},{'Frecuencia','Produccion'},{'Hz','m3/d'}, ...
    'role','SENSITIVITY_TABLE','category','SENSITIVITY', ...
    'priority','PRIMARY','default_mode','FULL_BODY','mandatory',true);
  perfiles = {'EXECUTIVE','TECHNICAL','AUDIT','CUSTOM'};
  for i = 1:numel(perfiles)
    [x,c] = aos_report_apply_profile(t,perfiles{i},struct());
    assert(strcmp(x.render_mode,'FULL_BODY'));
    assert(c.table_count_rendered == 1);
  endfor
  ov = struct('sensitivity_points','VIEWER_ONLY');
  [x,c] = aos_report_apply_profile(t,'TECHNICAL',ov);
  assert(strcmp(x.render_mode,'VIEWER_ONLY'));
  assert(c.table_count_archived == 1);
  assert(c.table_count_rendered == 0);
  ok = true;
  fprintf('RESULTADO: test_aos_report_sensitivity_hf3_5 APROBADO\n');
endfunction
