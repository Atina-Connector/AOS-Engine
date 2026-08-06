function ok = VERIFICAR_AOSCAD_HIDRAULICA_0_0_1_DEV1(ejecutar_pruebas)
% Verifica el modulo hidraulico DXF de AOSCAD.
  if nargin < 1, ejecutar_pruebas = false; endif
  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root, 'src'), '-begin');
  addpath(genpath(fullfile(root, 'src')), '-begin');

  fprintf('\n====================================================\n');
  fprintf(' VERIFICAR AOSCAD HIDRAULICA 0.0.1 DEV1\n');
  fprintf('====================================================\n');
  requeridos = {
    'src/modulos/cad_topo/aos_cad_hidraulica_ejecutar.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_defaults.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_extraer_config_dxf.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_aplicar_metadatos.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_registro_modelos.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_preparar.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_evaluar_tramo.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_evaluar_monofasico.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_evaluar_multifasico.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_resolver.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_imprimir.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_curva_bomba.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_catalogo_bombas.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_diagnosticar_topologia.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_dominio_resolver_pp.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_lazos_base.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_dp_orientado.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_resolver_lazos.m'
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_lazos_hardy_cross.m'
    'src/modulos/cad_topo/test_aos_cad_hidraulica_dxf.m'
    'src/modulos/cad_topo/test_aos_cad_red_ramificada.m'
    'src/modulos/cad_topo/test_aos_cad_equipo_activo_curva.m'
    'src/modulos/cad_topo/test_aos_cad_benchmark_red.m'
    'src/modulos/cad_topo/test_hyd_loop_selftest.m'
    'src/modulos/cad_topo/test_aos_cad_red_lazos.m'
    'datos/ejemplos/cad/demo_aos_hidraulica_dev1.dxf'
    'datos/ejemplos/cad/demo_aos_red_ramificada.dxf'
    'datos/ejemplos/cad/demo_aos_bomba_curva.dxf'
    'datos/ejemplos/cad/demo_aos_anillo.dxf'
    'datos/ejemplos/cad/demo_aos_dos_lazos.dxf'
    'datos/catalogos/aos_bombas_catalogo_0_0_1.json'
    'src/modulos/cad_topo/LEEME_HIDRAULICA_DXF_DEV1.md'
    'src/modulos/cad_topo/LEEME_RED_RAMIFICADA_Y_BOMBAS.md'
    'src/modulos/cad_topo/LEEME_SOLVER_LAZOS_KIRCHHOFF.md'
  };
  fallas = {};
  for i = 1:numel(requeridos)
    if exist(fullfile(root, requeridos{i}), 'file') == 2
      fprintf('OK  %s\n', requeridos{i});
    else
      fprintf(2, 'FALTA  %s\n', requeridos{i});
      fallas{end+1} = requeridos{i}; %#ok<AGROW>
    endif
  endfor

  funcs = {'aos_cad_hidraulica_ejecutar','aos_cad_hidraulica_defaults', ...
           'aos_cad_hidraulica_preparar','aos_cad_hidraulica_evaluar_tramo', ...
           'aos_cad_hidraulica_resolver','aos_cad_hidraulica_registro_modelos', ...
           'aos_cad_hidraulica_curva_bomba','aos_cad_hidraulica_catalogo_bombas', ...
           'aos_cad_hidraulica_diagnosticar_topologia', ...
           'aos_cad_hidraulica_dominio_resolver_pp', ...
           'aos_cad_hidraulica_lazos_base', 'aos_cad_hidraulica_dp_orientado', ...
           'aos_cad_hidraulica_resolver_lazos', 'aos_cad_hidraulica_lazos_hardy_cross'};
  for i = 1:numel(funcs)
    if exist(funcs{i}, 'file') == 2
      fprintf('FUNCION OK  %s\n', funcs{i});
    else
      fprintf(2, 'FUNCION FALTA  %s\n', funcs{i});
      fallas{end+1} = funcs{i}; %#ok<AGROW>
    endif
  endfor

  if exist('aos_cad_verificar_octave_only', 'file') == 2
    try
      if ~aos_cad_verificar_octave_only(false), fallas{end+1} = 'octave_only'; endif %#ok<AGROW>
    catch err
      fprintf(2, 'ERROR octave-only: %s\n', err.message);
      fallas{end+1} = 'octave_only'; %#ok<AGROW>
    end_try_catch
  endif

  if ejecutar_pruebas && isempty(fallas)
    tests = {'test_aos_cad_hidraulica_dxf', 'test_aos_cad_red_ramificada', ...
             'test_aos_cad_equipo_activo_curva', 'test_aos_cad_benchmark_red', ...
             'test_hyd_loop_selftest', 'test_aos_cad_red_lazos'};
    for it = 1:numel(tests)
      try
        fh = str2func(tests{it});
        if ~fh()
          fallas{end+1} = tests{it}; %#ok<AGROW>
        endif
      catch err
        fprintf(2, 'ERROR selftest %s: %s\n', tests{it}, err.message);
        fallas{end+1} = tests{it}; %#ok<AGROW>
      end_try_catch
    endfor
  elseif ~ejecutar_pruebas
    fprintf('Prueba numerica no ejecutada. Use VERIFICAR_AOSCAD_HIDRAULICA_0_0_1_DEV1(true).\n');
  endif

  ok = isempty(fallas);
  if ok
    fprintf('RESULTADO: AOSCAD HIDRAULICA DEV1 APROBADA\n');
  else
    fprintf(2, 'RESULTADO: AOSCAD HIDRAULICA DEV1 NO APROBADA. Fallas: %d\n', numel(fallas));
  endif
endfunction
