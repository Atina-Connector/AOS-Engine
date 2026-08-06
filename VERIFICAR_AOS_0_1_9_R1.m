function ok = VERIFICAR_AOS_0_1_9_R1(ejecutar_tests)
% VERIFICAR_AOS_0_1_9_R1 Compatibilidad e historial de la baseline R1.
% En una instalacion R2 no ejecuta el verificador numerico rigido original;
% valida que la evidencia R1 este archivada y que AOSBCK siga compatible.
  if nargin < 1, ejecutar_tests = false; endif
  raiz = fileparts(mfilename('fullpath'));
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos();
  ok = true;

  fprintf('\n================================================================\n');
  fprintf(' COMPATIBILIDAD E HISTORIAL AOS SUITE 0.1.9 R1\n');
  fprintf('================================================================\n');

  requeridos = {
    'historial/R1/README_ARCHIVO_HISTORICO_R1.md';
    'historial/R1/HISTORIAL_R1_A_R2.md';
    'historial/R1/CHANGELOG_AOS_0_1_9_R1.md';
    'historial/R1/MANIFEST_AOS_0_1_9_R1.txt';
    'historial/R1/SHA256SUMS_AOS_0_1_9_R1.txt';
    'historial/R1/SHA256_ARCHIVO_R1_ORIGINAL.txt';
    'historial/R1/VERIFICAR_AOS_0_1_9_ORIGINAL.m.txt';
    'historial/R1/VERIFICAR_AOS_0_1_9_R1_ORIGINAL.m.txt';
    'src/services/aosbck/test_aosbck_r1.m';
    'src/roadmap/aosbck_contract_0_1_9_r1.json'
  };
  for i = 1:numel(requeridos)
    if exist(fullfile(raiz, requeridos{i}), 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALTA %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  if ejecutar_tests
    try
      r = test_aosbck_r1();
      if r
        fprintf('OK   compatibilidad dinamica AOSBCK R1\n');
      else
        fprintf(2, 'FALLO: compatibilidad AOSBCK R1\n');
        ok = false;
      endif
    catch err
      fprintf(2, 'FALLO AOSBCK R1: %s\n', err.message);
      ok = false;
    end_try_catch
  endif

  if ok
    fprintf('RESULTADO: HISTORIAL Y COMPATIBILIDAD R1 APROBADOS\n');
  else
    fprintf(2, 'RESULTADO: HISTORIAL Y COMPATIBILIDAD R1 NO APROBADOS\n');
  endif
endfunction
