function ok = VERIFICAR_SENS_GLJGL_02(profundo)
% VERIFICAR_SENS_GLJGL_02 Verifica el tratamiento polinomico explicito.
% rapido  : contrato, menu, modo discreto, grado 5, auto y discontinuidades.
% profundo: agrega la campana profunda SENS-GLJGL-01 de paridad y metodo.

  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(raiz, '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION HOTFIX SENS-GLJGL-02\n');
  fprintf(' Armonizacion polinomica explicita y optimo verificado\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/sensibilidad/sens_menu_tratamiento_curva.m', ...
    'src/sensibilidad/sens_seleccionar_grado_polinomio.m', ...
    'src/sensibilidad/sens_ajuste_polinomico.m', ...
    'src/sensibilidad/sens_validar_ajuste_polinomico.m', ...
    'src/sensibilidad/sens_verificar_optimo_polinomico.m', ...
    'src/sensibilidad/sens_imprimir_diagnostico_polinomio.m', ...
    'src/sensibilidad/sens_optimo_inyeccion.m', ...
    'src/sensibilidad/sens_Qiny_GL.m', ...
    'src/sensibilidad/sens_Qiny_JGL.m', ...
    'src/sensibilidad/sens_Qiny.m', ...
    'src/sensibilidad/sens_balance_energetico.m', ...
    'src/sensibilidad/sens_exportar_resultados.m', ...
    'src/tests/test_sens_gljgl02_contrato_estatico.m', ...
    'src/tests/test_sens_gljgl02_menu_explicito.m', ...
    'src/tests/test_sens_gljgl02_discreto_sin_polinomio.m', ...
    'src/tests/test_sens_gljgl02_informativo_no_recomienda.m', ...
    'src/tests/test_sens_gljgl02_polinomio_grado5.m', ...
    'src/tests/test_sens_gljgl02_grado_automatico.m', ...
    'src/tests/test_sens_gljgl02_mascaras_curva_optimo.m', ...
    'src/tests/test_sens_gljgl02_discontinuidad.m', ...
    'src/roadmap/aos_hotfix_sens_gljgl_02.json'};

  for i = 1:numel(requeridos)
    if exist(fullfile(raiz, requeridos{i}), 'file') == 2
      fprintf('OK   %s\n', requeridos{i});
    else
      fprintf(2, 'FALTA %s\n', requeridos{i});
      ok = false;
    endif
  endfor

  ok = contrato_polyfit_local(raiz, ok);

  pruebas = { ...
    'test_sens_gljgl02_contrato_estatico', ...
    'test_sens_gljgl02_menu_explicito', ...
    'test_sens_gljgl02_discreto_sin_polinomio', ...
    'test_sens_gljgl02_informativo_no_recomienda', ...
    'test_sens_gljgl02_polinomio_grado5', ...
    'test_sens_gljgl02_grado_automatico', ...
    'test_sens_gljgl02_mascaras_curva_optimo', ...
    'test_sens_gljgl02_discontinuidad'};
  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i}, ok);
  endfor

  try
    r = VERIFICAR_SENS_GLJGL_01(profundo);
    ok = ok && ~isempty(r) && logical(r);
  catch err
    fprintf(2, 'FALLO verificacion SENS-GLJGL-01 heredada: %s\n', err.message);
    ok = false;
  end_try_catch

  fprintf('\n================================================================\n');
  if ok
    fprintf('RESULTADO: HOTFIX SENS-GLJGL-02 APROBADO\n');
  else
    fprintf(2, 'RESULTADO: HOTFIX SENS-GLJGL-02 NO APROBADO\n');
  endif
  fprintf('================================================================\n');
endfunction

function ok = contrato_polyfit_local(raiz, ok)
  opt = fileread(fullfile(raiz,'src','sensibilidad','sens_optimo_inyeccion.m'));
  helper = fileread(fullfile(raiz,'src','sensibilidad','sens_ajuste_polinomico.m'));
  if isempty(strfind(opt,'polyfit('))
    fprintf('OK   optimizador discreto sin llamada oculta a polyfit\n');
  else
    fprintf(2,'FALLO: sens_optimo_inyeccion contiene una llamada directa a polyfit\n');
    ok = false;
  endif
  if ~isempty(strfind(helper,'polyfit('))
    fprintf('OK   polyfit confinado al helper explicito y auditable\n');
  else
    fprintf(2,'FALLO: helper polinomico sin polyfit\n');
    ok = false;
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
