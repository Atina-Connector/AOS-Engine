function ok = test_aos_cad_dxf()
% TEST_AOS_CAD_DXF Prueba no interactiva del puente CAD-TOP / DXF.
  ok = true;
  root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  % Si el test vive en src/tests: subir 2 niveles a src, 3 a root.
  % Preferir detectar AOS.m
  cand = fileparts(mfilename('fullpath'));
  while ~isempty(cand) && exist(fullfile(cand, 'AOS.m'), 'file') ~= 2
    parent = fileparts(cand);
    if strcmp(parent, cand), break; endif
    cand = parent;
  endwhile
  if exist(fullfile(cand, 'AOS.m'), 'file') == 2
    root = cand;
  endif
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);

  fprintf('\n=== test_aos_cad_dxf ===\n');

  det = aos_cad_localizar_programa('LibreCAD');
  if det.encontrado
    fprintf('OK  LibreCAD detectado [%s]: %s\n', det.metodo, det.gui_cmd);
  else
    fprintf('AVISO  LibreCAD no localizado por PATH, Flatpak, Snap, AppImage ni .desktop.\n');
  endif

  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA DXF de ejemplo: %s\n', dxf);
    ok = false;
    return;
  endif

  modelo = aos_dxf_leer(dxf);
  if modelo.n_capas < 1
    fprintf(2, 'FALLO: se esperaban capas en el DXF.\n');
    ok = false;
  else
    fprintf('OK  capas=%d\n', modelo.n_capas);
  endif
  if modelo.n_entidades < 3
    fprintf(2, 'FALLO: se esperaban >=3 entidades, hay %d.\n', modelo.n_entidades);
    ok = false;
  else
    fprintf('OK  entidades=%d\n', modelo.n_entidades);
  endif
  if ~strcmp(modelo.unidades, 'm')
    fprintf(2, 'FALLO: unidades esperadas m, got %s\n', modelo.unidades);
    ok = false;
  else
    fprintf('OK  unidades=m\n');
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO: aos_cad_importar_dxf\n');
    ok = false;
  else
    fprintf('OK  import a CONFIG_ACTIVA.cad_topologia\n');
    if ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
      fprintf(2, 'FALLO: falta modelo_aoscad tras import\n');
      ok = false;
    else
      inv = CONFIG_ACTIVA.cad_topologia.inventario_tabular;
      fprintf('OK  tablas nodos=%d tramos=%d (sin .aoscad en import)\n', ...
        inv.n_nodos, inv.n_tramos);
    endif
  endif

  aos_cad_registrar_mtime(dxf);
  if ~aos_cad_recargar_si_cambio(true, true)
    fprintf(2, 'FALLO: recarga forzada\n');
    ok = false;
  else
    fprintf('OK  recarga forzada\n');
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_dxf APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_dxf NO APROBADO\n');
  endif
endfunction
