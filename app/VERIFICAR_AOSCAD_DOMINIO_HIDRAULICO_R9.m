function ok = VERIFICAR_AOSCAD_DOMINIO_HIDRAULICO_R9(ejecutar_pruebas)
% Verifica el modulo de dominio hidraulico selectivo AOSCAD DEV1 R9.
  if nargin < 1
    ejecutar_pruebas = true;
  endif
  ok = false;
  root = fileparts(mfilename('fullpath'));
  addpath(root, '-begin');
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n====================================================\n');
  fprintf(' VERIFICAR AOSCAD DOMINIO HIDRAULICO DEV1 R9\n');
  fprintf('====================================================\n');
  fprintf('Raiz AOS: %s\n', root);

  requeridos = { ...
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_dominio_activo.m', ...
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_dominio_filtrar_modelo.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_dominio_menu.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_dominio_seleccionar.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_dominio_programatico.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_dominio_definir_condiciones.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_dominio_validar.m', ...
    'src/modulos/cad_topo/aos_cad_hidraulica_encontrar_caminos.m', ...
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_lazos_base.m', ...
    'src/core/common/redes_hidraulicas/aos_cad_hidraulica_resolver_lazos.m', ...
    'src/modulos/cad_topo/test_aos_cad_dominio_hidraulico.m', ...
    'src/modulos/cad_topo/LEEME_DOMINIO_HIDRAULICO_R9.md'};
  fallas = {};
  for i = 1:numel(requeridos)
    if exist(fullfile(root, requeridos{i}), 'file') ~= 2
      fallas{end+1} = ['Falta ' requeridos{i}];
      fprintf(2, 'FALLO  %s\n', requeridos{i});
    else
      fprintf('OK  %s\n', requeridos{i});
    endif
  endfor

  funciones = { ...
    'aos_cad_hidraulica_dominio_activo', ...
    'aos_cad_hidraulica_dominio_filtrar_modelo', ...
    'aos_cad_hidraulica_dominio_menu', ...
    'aos_cad_hidraulica_dominio_seleccionar', ...
    'aos_cad_hidraulica_dominio_programatico', ...
    'aos_cad_hidraulica_dominio_definir_condiciones', ...
    'aos_cad_hidraulica_dominio_validar', ...
    'aos_cad_hidraulica_encontrar_caminos', ...
    'aos_cad_hidraulica_lazos_base', ...
    'aos_cad_hidraulica_resolver_lazos', ...
    'test_aos_cad_dominio_hidraulico'};
  for i = 1:numel(funciones)
    if exist(funciones{i}, 'file') ~= 2
      fallas{end+1} = ['Funcion no disponible ' funciones{i}];
      fprintf(2, 'FALLO FUNCION  %s\n', funciones{i});
    else
      fprintf('OK FUNCION  %s\n', funciones{i});
    endif
  endfor

  if isempty(fallas) && ejecutar_pruebas
    try
      if ~test_aos_cad_dominio_hidraulico()
        fallas{end+1} = 'Selftest de dominio no aprobado';
      endif
    catch err
      fallas{end+1} = ['Selftest con error: ' err.message];
    end_try_catch
  endif

  if isempty(fallas)
    ok = true;
    fprintf('\nRESULTADO: DOMINIO HIDRAULICO R9 APROBADO\n');
  else
    fprintf(2, '\nRESULTADO: DOMINIO HIDRAULICO R9 NO APROBADO. Fallas: %d\n', numel(fallas));
    for i = 1:numel(fallas)
      fprintf(2, ' - %s\n', fallas{i});
    endfor
  endif
endfunction
