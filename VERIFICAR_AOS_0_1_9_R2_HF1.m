function ok = VERIFICAR_AOS_0_1_9_R2_HF1(profundo)
% VERIFICAR_AOS_0_1_9_R2_HF1 Verifica la correccion del menu de gestion.
  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION AOS 0.1.9 R2 HF1 - GESTION DE CASO SEGURA\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/menu/AOS_menu_gestion_caso.m', ...
    'src/utilidades/config/aos_texto_seguro.m', ...
    'src/tests/test_aos_gestion_caso_sin_nombre_r2_hf1.m'};
  for i = 1:numel(requeridos)
    ruta = fullfile(raiz, requeridos{i});
    if exist(ruta, 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALLO: falta %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  if ok
    try
      resultado = test_aos_gestion_caso_sin_nombre_r2_hf1();
      ok = ok && logical(resultado);
    catch err
      fprintf(2, 'FALLO selftest HF1: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if profundo
    try
      resultado = VERIFICAR_AOS_0_1_9_R2(true);
      ok = ok && logical(resultado);
    catch err
      fprintf(2, 'FALLO verificacion R2 completa: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if ok
    fprintf('RESULTADO: AOS 0.1.9 R2 HF1 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: AOS 0.1.9 R2 HF1 NO APROBADO\n');
  endif
endfunction
