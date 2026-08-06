function ok = VERIFICAR_SENS_GLJGL_01(profundo)
% VERIFICAR_SENS_GLJGL_01 Verifica el hotfix de sensibilidades GL/JGL.
% rapido  : contrato, estados y paridad GL puntual-sensibilidad.
% profundo: agrega corrida JGL uniforme abreviada de dos puntos.

  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(raiz, '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION HOTFIX SENS-GLJGL-01\n');
  fprintf(' Paridad puntual, metodo uniforme y publicacion estricta\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/sensibilidad/sens_firma_config_gl_jgl.m', ...
    'src/sensibilidad/sens_validar_base_gl_jgl.m', ...
    'src/sensibilidad/sens_validar_punto_gl.m', ...
    'src/sensibilidad/sens_validar_punto_jgl.m', ...
    'src/sensibilidad/sens_gl_evaluar_punto.m', ...
    'src/sensibilidad/sens_jgl_evaluar_punto.m', ...
    'src/tests/test_sens_gljgl01_contrato_estatico.m', ...
    'src/tests/test_sens_gljgl01_validacion_estados.m', ...
    'src/tests/test_sens_gljgl01_paridad_gl.m', ...
    'src/tests/test_sens_gljgl01_metodo_uniforme_jgl.m'};

  for i = 1:numel(requeridos)
    if exist(fullfile(raiz, requeridos{i}), 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALTA %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  pruebas = { ...
    'test_sens_gljgl01_contrato_estatico', ...
    'test_sens_gljgl01_validacion_estados', ...
    'test_sens_gljgl01_paridad_gl'};
  if profundo
    pruebas{end+1} = 'test_sens_gljgl01_metodo_uniforme_jgl';
  endif

  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i}, ok);
  endfor

  fprintf('\n================================================================\n');
  if ok
    fprintf('RESULTADO: HOTFIX SENS-GLJGL-01 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: HOTFIX SENS-GLJGL-01 NO APROBADO\n');
  endif
  fprintf('================================================================\n');
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
