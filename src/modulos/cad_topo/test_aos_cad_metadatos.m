function ok = test_aos_cad_metadatos()
% TEST_AOS_CAD_METADATOS Verifica lectura de AOS_META desde DXF demo.
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

  fprintf('\n=== test_aos_cad_metadatos ===\n');
  dxf = fullfile(root, 'datos', 'ejemplos', 'cad', 'demo_aos_wells_meta.dxf');
  if exist(dxf, 'file') ~= 2
    fprintf(2, 'FALTA demo metadatos: %s\n', dxf);
    ok = false;
    return;
  endif

  global CONFIG_ACTIVA;
  CONFIG_ACTIVA = struct();
  if ~aos_cad_importar_dxf(dxf, true)
    fprintf(2, 'FALLO import DXF meta\n');
    ok = false;
    return;
  endif

  m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  tramos = m.tablas_entrada.tramos;
  if numel(tramos) < 2
    fprintf(2, 'FALLO: se esperaban >=2 tramos, hay %d\n', numel(tramos));
    ok = false;
    return;
  endif

  % Tramo 1 (0,0)-(100,0) debe tener meta DXF
  t1 = tramos{1};
  d1 = aos_aoscad_valor(t1.diametro_m);
  if abs(d1 - 0.1016) > 1e-6
    fprintf(2, 'FALLO: diametro T1 esperado 0.1016, got %g\n', d1);
    ok = false;
  else
    fprintf('OK  T1 diametro_m=%g origen=%s\n', d1, t1.diametro_m.origen);
  endif
  if ~strcmp(t1.diametro_m.origen, 'TEXTO_AOS_META')
    fprintf(2, 'FALLO: origen diametro T1=%s (esperado TEXTO_AOS_META)\n', t1.diametro_m.origen);
    ok = false;
  endif
  mat1 = aos_aoscad_valor(t1.material);
  if ~strcmpi(char(mat1), 'ACERO')
    fprintf(2, 'FALLO: material T1=%s\n', char(mat1));
    ok = false;
  else
    fprintf('OK  T1 material=%s origen=%s\n', char(mat1), t1.material.origen);
  endif
  eps1 = aos_aoscad_valor(t1.rugosidad);
  if abs(eps1 - 4.5e-5) > 1e-9
    fprintf(2, 'FALLO: rugosidad T1=%g\n', eps1);
    ok = false;
  else
    fprintf('OK  T1 rugosidad=%g origen=%s\n', eps1, t1.rugosidad.origen);
  endif

  % Tramo 2 sin AOS_META de D/MAT/EPS → DEFAULT_MODULO
  t2 = tramos{2};
  if ~strcmp(t2.diametro_m.origen, 'DEFAULT_MODULO')
    fprintf(2, 'FALLO: origen diametro T2=%s (esperado DEFAULT_MODULO)\n', t2.diametro_m.origen);
    ok = false;
  else
    fprintf('OK  T2 diametro origen=DEFAULT_MODULO\n');
  endif

  inv = CONFIG_ACTIVA.cad_topologia.inventario_tabular;
  if ~isfield(inv, 'n_campos_dxf') || inv.n_campos_dxf < 1
    fprintf(2, 'FALLO: n_campos_dxf\n');
    ok = false;
  else
    fprintf('OK  meta DXF campos=%d defaults=%d\n', inv.n_campos_dxf, inv.n_campos_default);
  endif

  % BC / valvulas / accesorios / bombas enriquecidos
  bcs = m.tablas_entrada.condiciones_borde;
  if numel(bcs) < 2
    fprintf(2, 'FALLO: se esperaban >=2 BC explicitos, hay %d\n', numel(bcs));
    ok = false;
  else
    fprintf('OK  BC=%d\n', numel(bcs));
  endif
  % No defaults de BC inventados si hay P/Q: origen de al menos 1 debe ser TEXTO_AOS_META
  n_bc_meta = 0;
  for i = 1:numel(bcs)
    if isstruct(bcs{i}.valor) && isfield(bcs{i}.valor, 'origen') ...
        && strcmp(bcs{i}.valor.origen, 'TEXTO_AOS_META')
      n_bc_meta = n_bc_meta + 1;
    endif
  endfor
  if n_bc_meta < 2
    fprintf(2, 'FALLO: BC desde META=%d (esperado >=2)\n', n_bc_meta);
    ok = false;
  else
    fprintf('OK  BC desde TEXTO_AOS_META=%d\n', n_bc_meta);
  endif

  valvulas = m.tablas_entrada.valvulas;
  if numel(valvulas) < 1
    fprintf(2, 'FALLO: se esperaba >=1 valvula\n');
    ok = false;
  else
    fprintf('OK  valvulas=%d\n', numel(valvulas));
    kv = aos_aoscad_valor(valvulas{1}.Kv);
    if abs(kv - 80) > 1e-9
      fprintf(2, 'FALLO: Kv valvula esperado 80, got %g\n', kv);
      ok = false;
    else
      fprintf('OK  valvula Kv=%g\n', kv);
    endif
  endif

  accesorios = m.tablas_entrada.accesorios;
  if numel(accesorios) < 1
    fprintf(2, 'FALLO: se esperaba >=1 accesorio\n');
    ok = false;
  else
    fprintf('OK  accesorios=%d tipo=%s\n', numel(accesorios), char(accesorios{1}.tipo));
  endif

  n_bombas = 0;
  for i = 1:numel(m.tablas_entrada.equipos)
    if strcmpi(char(m.tablas_entrada.equipos{i}.tipo), 'BOMBA')
      n_bombas = n_bombas + 1;
    endif
  endfor
  if n_bombas < 1
    fprintf(2, 'FALLO: se esperaba >=1 bomba\n');
    ok = false;
  else
    fprintf('OK  bombas=%d\n', n_bombas);
  endif

  % Export REV debe incluir capa AOS_META
  out_rev = fullfile(root, 'intercambio', 'cad', 'enviados', 'test_meta_AOS_REV.dxf');
  outdir = fileparts(out_rev);
  if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
  aos_cad_exportar_dxf_rev(out_rev, true);
  raw = fileread(out_rev);
  if isempty(strfind(raw, 'AOS_META'))
    fprintf(2, 'FALLO: export REV sin capa/texto AOS_META\n');
    ok = false;
  else
    fprintf('OK  export REV incluye AOS_META\n');
  endif
  if isempty(strfind(raw, 'D=0.1016')) && isempty(strfind(raw, 'D=0.101600'))
    % sprintf %g may format differently
    if isempty(strfind(raw, 'MAT=ACERO'))
      fprintf(2, 'FALLO: export REV sin texto meta de tramo\n');
      ok = false;
    else
      fprintf('OK  export REV texto meta presente\n');
    endif
  else
    fprintf('OK  export REV texto D=0.1016 presente\n');
  endif
  if isempty(strfind(raw, 'AOS UNIDADES=m'))
    fprintf(2, 'FALLO: export REV sin AOS UNIDADES=m\n');
    ok = false;
  else
    fprintf('OK  export REV incluye AOS UNIDADES=m\n');
  endif

  % Sprint1: claves de unidad explicitas y heuristica
  app_mm = aos_cad_meta_aplicar(struct('D_MM', '101.6'), 'TEST');
  if abs(app_mm.diametro_m - 0.1016) > 1e-12
    fprintf(2, 'FALLO: D_MM\n'); ok = false;
  else
    fprintf('OK  D_MM explicito\n');
  endif
  app_h = aos_cad_meta_aplicar(struct('D', '101.6'), 'TEST');
  if isempty(strfind(app_h.adv_diametro, 'META_UNIDAD_HEURISTICA'))
    fprintf(2, 'FALLO: falta META_UNIDAD_HEURISTICA\n'); ok = false;
  else
    fprintf('OK  META_UNIDAD_HEURISTICA en D>1\n');
  endif

  if ok
    fprintf('RESULTADO: test_aos_cad_metadatos APROBADO\n');
  else
    fprintf(2, 'RESULTADO: test_aos_cad_metadatos NO APROBADO\n');
  endif
endfunction
