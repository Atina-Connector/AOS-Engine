function ok = VERIFICAR_AOS_0_1_9_R2_HF2(profundo)
% VERIFICAR_AOS_0_1_9_R2_HF2 Verifica auditoria transversal y correcciones.
  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION AOS 0.1.9 R2 HF2 - AUDITORIA TRANSVERSAL\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/utilidades/config/aos_texto_seguro.m', ...
    'src/utilidades/config/aos_numero_seguro.m', ...
    'src/utilidades/config/aos_vector_seguro.m', ...
    'src/utilidades/config/aos_logico_seguro.m', ...
    'src/utilidades/varios/aos_preguntar_sn.m', ...
    'src/utilidades/diagnostico/aos_auditar_interacciones.m', ...
    'src/geologia/aos_geologia_administrar.m', ...
    'src/geologia/aos_geologia_commit.m', ...
    'src/geologia/aos_geologia_resolver_punzados.m', ...
    'src/tests/test_aos_conversiones_seguras_hf2.m', ...
    'src/tests/test_aos_geologia_transaccional_hf2.m', ...
    'src/tests/test_aos_auditoria_interacciones_hf2.m', ...
    'src/tests/test_aos_path_selftests_hf2.m'};
  for i = 1:numel(requeridos)
    ruta = fullfile(raiz, requeridos{i});
    if exist(ruta, 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALLO: falta %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  pruebas = {'test_aos_conversiones_seguras_hf2', ...
    'test_aos_geologia_transaccional_hf2', ...
    'test_aos_auditoria_interacciones_hf2', ...
    'test_aos_path_selftests_hf2', ...
    'test_aos_catalogos_roundtrip_r2', ...
    'test_aos_galeria_mandriles_r2'};
  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i}, ok);
  endfor

  if profundo
    try
      resultado = VERIFICAR_AOS_0_1_9(true);
      ok = ok && logical(resultado);
    catch err
      fprintf(2, 'FALLO verificacion R2 completa: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if ok
    fprintf('RESULTADO: AOS 0.1.9 R2 HF2 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: AOS 0.1.9 R2 HF2 NO APROBADO\n');
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
    resultado = feval(nombre);
    if isempty(resultado) || logical(resultado)
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
