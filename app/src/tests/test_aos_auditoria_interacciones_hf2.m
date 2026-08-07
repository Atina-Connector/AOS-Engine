function ok = test_aos_auditoria_interacciones_hf2()
% TEST_AOS_AUDITORIA_INTERACCIONES_HF2 El linter transversal debe aprobar.
  iniciar_aos(true);
  r = aos_auditar_interacciones([], false);
  assert(isstruct(r));
  assert(isfield(r,'hallazgos'));
  assert(isfield(r,'errores'));
  assert(isfield(r,'avisos'));
  assert(r.ok);
  assert(r.errores == 0);
  assert(r.archivos_revisados > 100);
  ok = true;
  fprintf('RESULTADO: test_aos_auditoria_interacciones_hf2 APROBADO\n');
endfunction
