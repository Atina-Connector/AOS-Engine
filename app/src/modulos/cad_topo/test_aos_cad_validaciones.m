function ok = test_aos_cad_validaciones()
% TEST_AOS_CAD_VALIDACIONES DXF sintetico roto + validacion topologica.
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

  fprintf('\n=== test_aos_cad_validaciones ===\n');
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA %s\n', dxf);
    ok = false;
    return;
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO import\n');
    ok = false;
    return;
  endif
  aos_cad_construir_topologia(0.05, true);
  v = aos_cad_validar_topologia(true);
  if ~isfield(v, 'estado')
    fprintf(2, 'FALLO: validaciones sin estado\n');
    ok = false;
  else
    fprintf('OK  validacion demo estado=%s items=%d\n', v.estado, numel(v.items));
  endif

  % Modelo sintetico roto
  m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  % Nodo huerfano
  n = m.tablas_entrada.nodos{1};
  n.id = 'NORPHAN';
  n.x = 999; n.y = 999;
  m.tablas_entrada.nodos{end+1} = n;
  % Tramo con nodo inexistente
  if ~isempty(m.tablas_entrada.tramos)
    tr = m.tablas_entrada.tramos{1};
    tr.id = 'TBAD';
    tr.nodo_o = 'NO_EXISTE';
    m.tablas_entrada.tramos{end+1} = tr;
  endif
  % Equipo con nodo_ref invalido
  eq = struct('id', 'EQBAD', 'nodo_ref', 'ZZZ', 'tipo', 'EQUIPO', 'etiqueta', 'x');
  m.tablas_entrada.equipos{end+1} = eq;
  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;

  v2 = aos_cad_validar_topologia(true);
  codigos = {};
  for i = 1:numel(v2.items)
    if isfield(v2.items{i}, 'codigo')
      codigos{end+1} = char(v2.items{i}.codigo); %#ok<AGROW>
    endif
  endfor
  need = {'NODO_HUERFANO', 'TRAMO_NODO_O', 'EQUIPO_NODO_REF'};
  for i = 1:numel(need)
    if ~any(strcmp(codigos, need{i}))
      fprintf(2, 'FALLO: falta codigo %s\n', need{i});
      ok = false;
    else
      fprintf('OK  detectado %s\n', need{i});
    endif
  endfor
  if ~strcmp(v2.estado, 'ERROR')
    fprintf(2, 'FALLO: estado esperado ERROR, got %s\n', v2.estado);
    ok = false;
  else
    fprintf('OK  estado=ERROR\n');
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_validaciones APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_validaciones NO APROBADO\n');
  endif
endfunction
