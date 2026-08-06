function ok = test_aos_contratos_estructuras_hf3_2()
% TEST_AOS_CONTRATOS_ESTRUCTURAS_HF3_2
% Regresion para estructuras vacias y aliases de compatibilidad.

  ok = false;
  iniciar_aos(true);

  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  r = aos_auditar_interacciones(raiz, false);
  assert(isstruct(r));
  assert(isfield(r, 'hallazgos'));
  assert(isfield(r, 'errores'));
  assert(isfield(r, 'avisos'));
  assert(r.errores == 0);

  actual = struct('intervalos', struct('tramos', tramo_local(1000, 1010)));
  nueva = struct('intervalos', struct('tramos', tramo_local(1020, 1030)));

  [c, info_c] = aos_geologia_resolver_punzados(actual, nueva, ...
    'CONSERVAR_ACTUALES');
  assert(isfield(info_c, 'n_salida'));
  assert(isfield(info_c, 'n_finales'));
  assert(info_c.n_salida == 1 && info_c.n_finales == 1);
  assert(c.intervalos.tramos.MD_desde == 1000);

  [f, info_f] = aos_geologia_resolver_punzados(actual, nueva, 'FUSIONAR');
  assert(info_f.n_salida == 2 && info_f.n_finales == 2);
  assert(numel(f.intervalos.tramos) == 2);

  ok = true;
  fprintf('RESULTADO: test_aos_contratos_estructuras_hf3_2 APROBADO\n');
endfunction

function t = tramo_local(a, b)
  t = struct('MD_desde', a, 'MD_hasta', b, 'densidad_tpm', 10, ...
    'diametro_punzado_m', 0.010);
endfunction
