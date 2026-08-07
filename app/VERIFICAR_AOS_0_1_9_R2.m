function ok = VERIFICAR_AOS_0_1_9_R2(profundo)
% VERIFICAR_AOS_0_1_9_R2 Verificador oficial de la distribucion R2.
  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos();

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION OFICIAL AOS 0.1.9 R2\n');
  fprintf('================================================================\n');

  ok = VERIFICAR_AOS_0_1_9(logical(profundo));
  version = fileread(fullfile(raiz, 'AOS_VERSION.txt'));
  if isempty(strfind(version, '0.1.9 R2'))
    fprintf(2, 'FALLO: AOS_VERSION.txt no identifica R2\n');
    ok = false;
  else
    fprintf('OK   version R2 declarada\n');
  endif

  historia = fullfile(raiz, 'historial', 'R1', ...
    'README_ARCHIVO_HISTORICO_R1.md');
  if exist(historia, 'file') == 2
    fprintf('OK   referencia historica R1 incluida\n');
  else
    fprintf(2, 'FALLO: falta referencia historica R1\n');
    ok = false;
  endif

  if profundo
    try
      r = VERIFICAR_AOSCAD_0_0_1_DEV1(true);
      ok = ok && logical(r);
    catch err
      fprintf(2, 'FALLO AOSCAD: %s\n', err.message);
      ok = false;
    end_try_catch
    try
      r = VERIFICAR_AOSCAD_DOMINIO_HIDRAULICO_R9(true);
      ok = ok && logical(r);
    catch err
      fprintf(2, 'FALLO dominio R9: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if ok
    fprintf('RESULTADO: AOS 0.1.9 R2 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: AOS 0.1.9 R2 NO APROBADO\n');
  endif
endfunction
