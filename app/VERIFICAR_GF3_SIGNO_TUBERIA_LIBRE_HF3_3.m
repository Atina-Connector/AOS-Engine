function ok = VERIFICAR_GF3_SIGNO_TUBERIA_LIBRE_HF3_3(profundo)
% Verifica estructura, signo fisico, rigidez positiva y selftest GF3.
  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(raiz, '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n============================================================\n');
  fprintf(' GF3 HF3.3 - SIGNO FISICO DE TUBERIA LIBRE\n');
  fprintf('============================================================\n');
  ok = true;

  requeridos = { ...
    'src/core/BM/gibbs_foundation3/gibbs3_defaults.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_tubing_motion.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_postprocess.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_rod_spacing_design.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_repair_tubing_sign_result.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_validate_result.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_report_append_sections.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_export_case.m', ...
    'src/core/BM/gibbs_foundation3/gibbs3_selftest.m', ...
    'src/tests/test_gf3_signo_tuberia_libre_hf3_3.m'};

  for i = 1:numel(requeridos)
    if exist(fullfile(raiz,requeridos{i}), 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALLO: falta %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  if ok
    ruta_post = fullfile(raiz, 'src', 'core', 'BM', ...
      'gibbs_foundation3', 'gibbs3_postprocess.m');
    ruta_tub = fullfile(raiz, 'src', 'core', 'BM', ...
      'gibbs_foundation3', 'gibbs3_tubing_motion.m');
    ruta_spacing = fullfile(raiz, 'src', 'core', 'BM', ...
      'gibbs_foundation3', 'gibbs3_rod_spacing_design.m');
    txt_post = fileread(ruta_post);
    txt_tub = fileread(ruta_tub);
    txt_spacing = fileread(ruta_spacing);
    checks = { ...
      ~isempty(strfind(txt_post, ...
        'u_piston_relativo=u_varilla_fondo-u_tuberia_fondo')), ...
        'postproceso usa posicion firmada del barril'; ...
      isempty(strfind(txt_post, ...
        'u_piston_relativo=u_varilla_fondo-tub.x_tuberia_m')), ...
        'formula de signo invertido ausente'; ...
      ~isempty(strfind(txt_tub, 'tub.u_fondo_m = u_fondo')), ...
        'posicion firmada de tubing presente'; ...
      ~isempty(strfind(txt_tub, 'tub.elongacion_m = elongacion')), ...
        'elongacion positiva explicita'; ...
      ~isempty(strfind(txt_spacing, ...
        'isfield(res.tuberia, ''elongacion_m'')')), ...
        'spacing usa magnitud positiva de elongacion'};
    for j = 1:size(checks, 1)
      if checks{j, 1}
        fprintf('OK   %s\n', checks{j, 2});
      else
        fprintf(2, 'FALLO: %s\n', checks{j, 2});
        ok = false;
      endif
    endfor
  endif

  pruebas = {'test_gf3_signo_tuberia_libre_hf3_3'};
  if profundo, pruebas{end+1} = 'gibbs3_selftest'; endif
  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i}, ok);
  endfor

  if ok
    fprintf('RESULTADO: GF3 SIGNO TUBERIA LIBRE HF3.3 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: GF3 SIGNO TUBERIA LIBRE HF3.3 NO APROBADO\n');
  endif
endfunction

function ok = ejecutar_local(nombre, ok)
  try
    iniciar_aos(true); rehash();
    r = feval(nombre);
    if isempty(r) || logical(r)
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
