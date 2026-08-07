function ok = test_aos_cad_galerias()
% TEST_AOS_CAD_GALERIAS Clase GALERIAS + conteos tablas; sim no inventa hidraulica de pozos.
  ok = true;
  cand = fileparts(mfilename('fullpath'));
  while ~isempty(cand) && exist(fullfile(cand, 'AOS.m'), 'file') ~= 2
    parent = fileparts(cand);
    if strcmp(parent, cand), break; endif
    cand = parent;
  endwhile
  root = cand;
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n=== test_aos_cad_galerias ===\n');
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_galerias.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA %s\n', dxf);
    ok = false;
    return;
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO import galerias\n');
    ok = false;
    return;
  endif

  m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if ~strcmp(m.info.dxf_clase, 'GALERIAS')
    fprintf(2, 'FALLO: dxf_clase=%s (esperado GALERIAS)\n', m.info.dxf_clase);
    ok = false;
  else
    fprintf('OK  dxf_clase=GALERIAS\n');
  endif

  nc = numel(m.tablas_entrada.camaras);
  nr = numel(m.tablas_entrada.ramales);
  na = numel(m.tablas_entrada.accesos);
  if nc < 2
    fprintf(2, 'FALLO: camaras=%d (esperado >=2)\n', nc);
    ok = false;
  else
    fprintf('OK  camaras=%d\n', nc);
  endif
  if nr < 1
    fprintf(2, 'FALLO: ramales=%d\n', nr);
    ok = false;
  else
    fprintf('OK  ramales=%d\n', nr);
  endif
  if na < 1
    fprintf(2, 'FALLO: accesos=%d\n', na);
    ok = false;
  else
    fprintf('OK  accesos=%d\n', na);
  endif

  % Sim no debe escribir resultados hidraulicos de red de pozos
  try
    aos_cad_eval_hidraulica_demo(true);
  catch err
    fprintf(2, 'FALLO eval: %s\n', err.message);
    ok = false;
  end_try_catch
  m2 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if isfield(m2.simulacion, 'advertencias')
    adv = m2.simulacion.advertencias;
    blob = '';
    if iscell(adv)
      for i = 1:numel(adv), blob = [blob ' ' char(adv{i})]; endfor %#ok<AGROW>
    endif
    if isempty(strfind(upper(blob), 'GALERIAS')) && isempty(strfind(upper(blob), 'SIN_SOLVER'))
      fprintf(2, 'FALLO: sim galerias sin advertencia GALERIAS/SIN_SOLVER\n');
      ok = false;
    else
      fprintf('OK  sim advertencia galerias presente\n');
    endif
  endif
  % No inventar tramos de resultados como si fuera red de pozos con caudal falso
  if isfield(m2, 'tablas_resultados') && isfield(m2.tablas_resultados, 'tramos') ...
      && numel(m2.tablas_resultados.tramos) > 0 ...
      && numel(m2.tablas_entrada.tramos) == 0
    fprintf(2, 'FALLO: resultados.tramos inventados sin tramos de entrada\n');
    ok = false;
  else
    fprintf('OK  sin resultados hidraulicos falsos de pozos\n');
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_galerias APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_galerias NO APROBADO\n');
  endif
endfunction
