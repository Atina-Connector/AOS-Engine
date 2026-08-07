function ok = VERIFICAR_AOS_0_1_9_R2_HF3_4(profundo)
% VERIFICAR_AOS_0_1_9_R2_HF3_4
% Verifica HF3.4: idempotencia geologica y contrato GF3 de espaciamiento.

  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(raiz, '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION AOS 0.1.9 R2 HF3.4 - CIERRE GEOLOGIA / GF3\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/geologia/aos_geologia_commit.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_rod_spacing_design.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_upgrade_result_schema.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_report_context.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_validate_result.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_selftest.m', ...
    'src/tests/test_aos_geologia_idempotencia_hf3_4.m', ...
    'src/tests/test_gf3_contrato_espaciamiento_hf3_4.m'};

  for i = 1:numel(requeridos)
    if exist(fullfile(raiz, requeridos{i}), 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALTA %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  pruebas = { ...
    'test_aos_geologia_idempotencia_hf3_4', ...
    'test_aos_geologia_transaccional_hf2', ...
    'test_gf3_signo_tuberia_libre_hf3_3', ...
    'test_gf3_contrato_espaciamiento_hf3_4'};

  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i}, ok);
  endfor

  if profundo
    try
      r = VERIFICAR_AOS_0_1_9(true);
      ok = ok && ~isempty(r) && logical(r);
    catch err
      fprintf(2, 'FALLO verificacion integral: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if ok
    fprintf('RESULTADO: AOS 0.1.9 R2 HF3.4 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: AOS 0.1.9 R2 HF3.4 NO APROBADO\n');
  endif
endfunction

function ok = ejecutar_local(nombre, ok)
  try
    iniciar_aos(true);
    rehash();
    if exist(nombre, 'file') ~= 2
      fprintf(2, 'FALLO: selftest no encontrado: %s\n', nombre);
      ok = false;
      return;
    endif
    r = feval(nombre);
    if ~isempty(r) && logical(r)
      fprintf('OK   selftest %s\n', nombre);
    else
      fprintf(2, 'FALLO: selftest sin aprobacion: %s\n', nombre);
      ok = false;
    endif
  catch err
    fprintf(2, 'FALLO selftest %s: %s\n', nombre, err.message);
    ok = false;
  end_try_catch
endfunction
