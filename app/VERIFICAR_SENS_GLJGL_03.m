function ok = VERIFICAR_SENS_GLJGL_03(profundo)
% VERIFICAR_SENS_GLJGL_03 Verifica condicion motriz y presiones JGL.
% rapido  : contrato, inversion de columna, factibilidad, limite y ruta eductor.
% profundo: agrega SENS-GLJGL-02, SENS-GLJGL-01 y sus regresiones heredadas.

  if nargin < 1, profundo = false; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz);
  addpath(raiz, '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n================================================================\n');
  fprintf(' VERIFICACION HOTFIX SENS-GLJGL-03\n');
  fprintf(' Condicion motriz explicita y presiones requeridas JGL\n');
  fprintf('================================================================\n');

  ok = true;
  requeridos = { ...
    'src/core/JGL/jgl_modo_condicion_motriz.m', ...
    'src/core/JGL/jgl_deltaP_cinetica_qiny.m', ...
    'src/core/JGL/jgl_condicion_motriz.m', ...
    'src/core/JGL/jgl_presion_motriz_fondo.m', ...
    'src/core/JGL/jgl_eductor_comun.m', ...
    'src/utilidades/nodal/eductor_jgl.m', ...
    'src/sensibilidad/sens_menu_condicion_motriz_jgl.m', ...
    'src/menu/JGL_menu.m', ...
    'src/sensibilidad/sens_jgl_construir_presiones.m', ...
    'src/sensibilidad/sens_jgl_imprimir_presiones.m', ...
    'src/sensibilidad/sens_jgl_graficar_presiones.m', ...
    'src/sensibilidad/sens_jgl_limite_presion.m', ...
    'src/sensibilidad/sens_Qiny_JGL.m', ...
    'src/sensibilidad/sens_Qiny.m', ...
    'src/sensibilidad/sens_exportar_resultados.m', ...
    'src/tests/test_sens_gljgl03_contrato_estatico.m', ...
    'src/tests/test_sens_gljgl03_condicion_motriz_derivada.m', ...
    'src/tests/test_sens_gljgl03_presion_disponible.m', ...
    'src/tests/test_sens_gljgl03_eductor_derivado_no_bloqueado.m', ...
    'src/tests/test_sens_gljgl03_inversion_columna.m', ...
    'src/tests/test_sens_gljgl03_limite_presion.m', ...
    'src/tests/test_sens_gljgl03_barrido_derivado_jgl.m', ...
    'src/roadmap/aos_hotfix_sens_gljgl_03.json'};

  for i = 1:numel(requeridos)
    if exist(fullfile(raiz,requeridos{i}),'file') == 2
      fprintf('OK   %s\n',requeridos{i});
    else
      fprintf(2,'FALTA %s\n',requeridos{i});
      ok = false;
    endif
  endfor

  ok = contrato_local(raiz,ok);

  pruebas = { ...
    'test_sens_gljgl03_contrato_estatico', ...
    'test_sens_gljgl03_condicion_motriz_derivada', ...
    'test_sens_gljgl03_presion_disponible', ...
    'test_sens_gljgl03_eductor_derivado_no_bloqueado', ...
    'test_sens_gljgl03_inversion_columna', ...
    'test_sens_gljgl03_limite_presion'};
  if profundo
    pruebas{end+1} = 'test_sens_gljgl03_barrido_derivado_jgl';
  endif
  for i = 1:numel(pruebas)
    ok = ejecutar_local(pruebas{i},ok);
  endfor

  try
    r = VERIFICAR_SENS_GLJGL_02(profundo);
    ok = ok && ~isempty(r) && logical(r);
  catch err
    fprintf(2,'FALLO verificacion SENS-GLJGL-02 heredada: %s\n',err.message);
    ok = false;
  end_try_catch

  fprintf('\n================================================================\n');
  if ok
    fprintf('RESULTADO: HOTFIX SENS-GLJGL-03 APROBADO\n');
  else
    fprintf(2,'RESULTADO: HOTFIX SENS-GLJGL-03 NO APROBADO\n');
  endif
  fprintf('================================================================\n');
endfunction

function ok = contrato_local(raiz,ok)
  comun = fileread(fullfile(raiz,'src','core','JGL','jgl_eductor_comun.m'));
  i_cond = strfind(comun,'jgl_condicion_motriz(p,Qiny,Ps)');
  i_block = strfind(comun,'C.bloquea_operacion');
  if ~isempty(i_cond) && ~isempty(i_block) && i_cond(1) < i_block(1)
    fprintf('OK   condicion motriz evaluada antes de bloquear el eductor\n');
  else
    fprintf(2,'FALLO: la validacion prematura vuelve a bloquear la ruta derivada\n');
    ok = false;
  endif
  menu = fileread(fullfile(raiz,'src','sensibilidad','sens_menu_condicion_motriz_jgl.m'));
  menu_punto = fileread(fullfile(raiz,'src','menu','JGL_menu.m'));
  if ~isempty(strfind(menu,'Derivar la presion minima requerida desde Qiny')) && ...
      ~isempty(strfind(menu,'Confirmar que no existe presion motriz')) && ...
      ~isempty(strfind(menu_punto,'SIMULACION PUNTUAL JGL')) && ...
      ~isempty(strfind(menu_punto,'sens_menu_condicion_motriz_jgl'))
    fprintf('OK   seleccion motriz explicita en sensibilidad y punto JGL\n');
  else
    fprintf(2,'FALLO: menu de condicion motriz incompleto\n');
    ok = false;
  endif
  exp = fileread(fullfile(raiz,'src','sensibilidad','sens_exportar_resultados.m'));
  if ~isempty(strfind(exp,'[JGL_MOTIVE_PRESSURE]')) && ...
      ~isempty(strfind(exp,'sobrescritura_oculta=NO'))
    fprintf('OK   reporting de presion motriz auditable\n');
  else
    fprintf(2,'FALLO: reporting SENS03 incompleto\n');
    ok = false;
  endif
endfunction

function ok = ejecutar_local(nombre,ok)
  try
    iniciar_aos(true);
    rehash();
    if exist(nombre,'file') ~= 2
      fprintf(2,'FALLO: selftest no encontrado: %s\n',nombre);
      ok = false;
      return;
    endif
    r = feval(nombre);
    if ~isempty(r) && logical(r)
      fprintf('OK   selftest %s\n',nombre);
    else
      fprintf(2,'FALLO: selftest sin aprobacion: %s\n',nombre);
      ok = false;
    endif
  catch err
    fprintf(2,'FALLO selftest %s: %s\n',nombre,err.message);
    ok = false;
  end_try_catch
endfunction
