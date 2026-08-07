function ok = test_gf3_contrato_espaciamiento_hf3_4()
% Valida aliases publicos del espaciamiento y el selftest integral GF3.
  ok = false;
  iniciar_aos(true);

  productor = fileread(which('gibbs3_rod_spacing_design'));
  migrador = fileread(which('gibbs3_upgrade_result_schema'));
  reporte = fileread(which('gibbs3_report_context'));
  validador = fileread(which('gibbs3_validate_result'));
  assert(~isempty(strfind(productor,'e.valido_calculo = e.valido')));
  assert(~isempty(strfind(productor,'e.mensaje_validacion = validacion')));
  assert(~isempty(strfind(migrador,'valido_calculo')));
  assert(~isempty(strfind(migrador,'mensaje_validacion')));
  assert(~isempty(strfind(reporte,'valido_calculo')));
  assert(~isempty(strfind(validador, 'elseif isfield(e, ''valido'')')));

  r = gibbs3_selftest();
  assert(~isempty(r) && logical(r));
  ok = true;
  fprintf('RESULTADO: test_gf3_contrato_espaciamiento_hf3_4 APROBADO\n');
endfunction
