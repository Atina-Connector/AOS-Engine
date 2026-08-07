function ruta = aos_cad_exportar_dxf_rev(archivo_out, silencioso)
% AOS_CAD_EXPORTAR_DXF_REV Exporta *_AOS_REV.dxf con IDs/capas normalizados.
% Sprint1: preserva capas de usuario, BLOCKS e INSERT; escribe AOS UNIDADES=m.
% Nunca sobrescribe el DXF fuente. El DXF sigue siendo entrada, no reporte .aoscad.
  global CONFIG_ACTIVA;
  if nargin < 2, silencioso = false; endif

  if isempty(CONFIG_ACTIVA) || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    error('AOS CAD_TOPO: no hay cad_topologia.');
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'dxf_archivo') || exist(cad.dxf_archivo, 'file') ~= 2
    error('AOS CAD_TOPO: no hay DXF fuente registrado.');
  endif
  fuente = cad.dxf_archivo;

  if nargin < 1 || isempty(archivo_out)
    [~, n, e] = fileparts(fuente);
    outdir = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'enviados');
    if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
    archivo_out = fullfile(outdir, [n '_AOS_REV' e]);
  endif

  % Seguridad: nunca igual a la fuente
  if strcmpi(canon_local(archivo_out), canon_local(fuente))
    [~, n, e] = fileparts(fuente);
    outdir = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'enviados');
    if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
    archivo_out = fullfile(outdir, [n '_AOS_REV' e]);
  endif

  modelo = [];
  if isfield(cad, 'modelo_aoscad')
    modelo = cad.modelo_aoscad;
  endif

  fid = fopen(archivo_out, 'wt');
  if fid < 0
    error('AOS CAD_TOPO: no se pudo crear %s', archivo_out);
  endif

  % DXF ASCII minimo R2000 — modelo ya en metros SI
  fprintf(fid, '  0\nSECTION\n  2\nHEADER\n');
  fprintf(fid, '  9\n$ACADVER\n  1\nAC1015\n');
  fprintf(fid, '  9\n$INSUNITS\n 70\n6\n'); % metros
  fprintf(fid, '  0\nENDSEC\n');

  % Capas: union de originales + capas AOS
  capas_aos = {'0', 'AOS_NODOS', 'AOS_TRAMOS', 'AOS_EQUIPOS', 'AOS_IDS', 'AOS_META'};
  colores_aos = [7, 3, 1, 5, 2, 6];
  capas_out = {};
  colores_out = [];
  capas_src = {};
  if isfield(cad, 'capas'), capas_src = cad.capas; endif
  if isempty(capas_src) && ~isempty(modelo) && isfield(modelo, 'geometria') && ...
      isfield(modelo.geometria, 'capas')
    capas_src = modelo.geometria.capas;
  endif
  capas_src = as_cell_local(capas_src);
  for i = 1:numel(capas_src)
    if isstruct(capas_src{i}) && isfield(capas_src{i}, 'name') && ~isempty(capas_src{i}.name)
      nm = char(capas_src{i}.name);
      if ~any(strcmpi(capas_out, nm))
        capas_out{end+1} = nm; %#ok<AGROW>
        col = 7;
        if isfield(capas_src{i}, 'color') && isfinite(capas_src{i}.color)
          col = capas_src{i}.color;
        endif
        colores_out(end+1) = col; %#ok<AGROW>
      endif
    endif
  endfor
  for i = 1:numel(capas_aos)
    if ~any(strcmpi(capas_out, capas_aos{i}))
      capas_out{end+1} = capas_aos{i}; %#ok<AGROW>
      colores_out(end+1) = colores_aos(i); %#ok<AGROW>
    endif
  endfor

  fprintf(fid, '  0\nSECTION\n  2\nTABLES\n');
  fprintf(fid, '  0\nTABLE\n  2\nLAYER\n 70\n%d\n', numel(capas_out));
  for i = 1:numel(capas_out)
    fprintf(fid, '  0\nLAYER\n  2\n%s\n 70\n0\n 62\n%d\n  6\nCONTINUOUS\n', ...
      capas_out{i}, colores_out(i));
  endfor
  fprintf(fid, '  0\nENDTAB\n  0\nENDSEC\n');

  % BLOCKS: reescribir definiciones conservadas
  bloques = {};
  if isfield(cad, 'bloques'), bloques = cad.bloques; endif
  if isempty(bloques) && ~isempty(modelo) && isfield(modelo, 'geometria') && ...
      isfield(modelo.geometria, 'bloques')
    bloques = modelo.geometria.bloques;
  endif
  bloques = as_cell_local(bloques);
  fprintf(fid, '  0\nSECTION\n  2\nBLOCKS\n');
  handle = 100;
  for b = 1:numel(bloques)
    blk = bloques{b};
    if ~isstruct(blk) || ~isfield(blk, 'name') || isempty(blk.name), continue; endif
    handle = handle + 1;
    bx = 0; by = 0; bz = 0;
    if isfield(blk, 'base_x'), bx = blk.base_x; endif
    if isfield(blk, 'base_y'), by = blk.base_y; endif
    if isfield(blk, 'base_z'), bz = blk.base_z; endif
    fprintf(fid, '  0\nBLOCK\n  5\n%X\n  8\n0\n  2\n%s\n 70\n0\n', handle, blk.name);
    fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n%.6f\n', bx, by, bz);
    if isfield(blk, 'entidades')
      for j = 1:numel(blk.entidades)
        [handle] = escribir_entidad_local(fid, blk.entidades{j}, handle);
      endfor
    endif
    handle = handle + 1;
    fprintf(fid, '  0\nENDBLK\n  5\n%X\n  8\n0\n', handle);
  endfor
  fprintf(fid, '  0\nENDSEC\n');

  fprintf(fid, '  0\nSECTION\n  2\nENTITIES\n');

  % Metadato global de unidades (round-trip explicito)
  handle = handle + 1;
  fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\nAOS_META\n', handle);
  fprintf(fid, ' 10\n0.0\n 20\n-5.0\n 30\n0.0\n 40\n0.8\n  1\nAOS UNIDADES=m\n');

  if ~isempty(modelo) && isfield(modelo, 'tablas_entrada')
    tramos = {};
    nodos = {};
    equipos = {};
    bcs = {};
    if isfield(modelo.tablas_entrada, 'tramos'), tramos = modelo.tablas_entrada.tramos; endif
    if isfield(modelo.tablas_entrada, 'nodos'), nodos = modelo.tablas_entrada.nodos; endif
    if isfield(modelo.tablas_entrada, 'equipos'), equipos = modelo.tablas_entrada.equipos; endif
    if isfield(modelo.tablas_entrada, 'condiciones_borde')
      bcs = modelo.tablas_entrada.condiciones_borde;
    endif

    for i = 1:numel(tramos)
      tr = tramos{i};
      handle = handle + 1;
      capa_tr = 'AOS_TRAMOS';
      if isfield(tr, 'capa') && ~isempty(tr.capa), capa_tr = char(tr.capa); endif
      fprintf(fid, '  0\nLINE\n  5\n%X\n  8\n%s\n', handle, capa_tr);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n', tr.x1, tr.y1);
      fprintf(fid, ' 11\n%.6f\n 21\n%.6f\n 31\n0.0\n', tr.x2, tr.y2);
      handle = handle + 1;
      mx = (tr.x1 + tr.x2) / 2; my = (tr.y1 + tr.y2) / 2;
      fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\nAOS_IDS\n', handle);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n1.0\n  1\n%s\n', ...
        mx, my, tr.id);

      handle = handle + 1;
      meta_txt = meta_texto_tramo_local(tr);
      fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\nAOS_META\n', handle);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n0.8\n  1\n%s\n', ...
        mx, my + 1.2, meta_txt);
    endfor

    for i = 1:numel(nodos)
      n = nodos{i};
      handle = handle + 1;
      capa_n = 'AOS_NODOS';
      if isfield(n, 'capa') && ~isempty(n.capa), capa_n = char(n.capa); endif
      fprintf(fid, '  0\nCIRCLE\n  5\n%X\n  8\n%s\n', handle, capa_n);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n0.5\n', n.x, n.y);
      handle = handle + 1;
      fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\nAOS_IDS\n', handle);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n1.0\n  1\n%s\n', ...
        n.x + 0.6, n.y + 0.6, n.id);
    endfor

    for i = 1:numel(equipos)
      eq = equipos{i};
      nn = [];
      for j = 1:numel(nodos)
        if strcmp(nodos{j}.id, eq.nodo_ref), nn = nodos{j}; break; endif
      endfor
      if isempty(nn), continue; endif
      handle = handle + 1;
      capa_eq = 'AOS_EQUIPOS';
      if isfield(eq, 'capa') && ~isempty(eq.capa), capa_eq = char(eq.capa); endif
      if isfield(eq, 'block_name') && ~isempty(eq.block_name)
        ix = nn.x; iy = nn.y;
        if isfield(eq, 'insert_x'), ix = eq.insert_x; endif
        if isfield(eq, 'insert_y'), iy = eq.insert_y; endif
        fprintf(fid, '  0\nINSERT\n  5\n%X\n  8\n%s\n  2\n%s\n', ...
          handle, capa_eq, char(eq.block_name));
        fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n', ix, iy);
      else
        fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\n%s\n', handle, capa_eq);
        fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n1.2\n  1\n%s\n', ...
          nn.x, nn.y - 1.5, eq.etiqueta);
      endif
    endfor

    for i = 1:numel(bcs)
      bc = bcs{i};
      nn = [];
      for j = 1:numel(nodos)
        if strcmp(nodos{j}.id, bc.nodo_ref), nn = nodos{j}; break; endif
      endfor
      if isempty(nn), continue; endif
      handle = handle + 1;
      v = bc.valor;
      if isstruct(v), v = aos_aoscad_valor(v); endif
      if strcmp(bc.tipo_bc, 'PRESION')
        txt = sprintf('AOS P=%g', v);
      else
        txt = sprintf('AOS Q=%g', v);
      endif
      fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\nAOS_META\n', handle);
      fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n0.0\n 40\n0.8\n  1\n%s\n', ...
        nn.x, nn.y - 2.5, txt);
    endfor
  else
    % Fallback: copiar entidades LINE/CIRCLE/INSERT del inventario
    if isfield(cad, 'entidades')
      for i = 1:numel(cad.entidades)
        handle = escribir_entidad_local(fid, cad.entidades{i}, handle);
      endfor
    endif
  endif

  fprintf(fid, '  0\nENDSEC\n  0\nEOF\n');
  fclose(fid);

  CONFIG_ACTIVA.cad_topologia.dxf_rev_archivo = char(archivo_out);
  ruta = char(archivo_out);

  if ~silencioso
    fprintf('\n--- DXF REVISION EXPORTADO ---\n');
    fprintf('fuente      : %s\n', fuente);
    fprintf('revision    : %s\n', ruta);
    fprintf('capas       : %d | bloques: %d\n', numel(capas_out), numel(bloques));
    fprintf('Fuente NO modificada. DXF != .aoscad. Incluye AOS UNIDADES=m.\n');
  endif
endfunction

function handle = escribir_entidad_local(fid, e, handle)
  if ~isstruct(e) || ~isfield(e, 'entity_type'), return; endif
  tipo = upper(char(e.entity_type));
  capa = '0';
  if isfield(e, 'layer') && ~isempty(e.layer), capa = char(e.layer); endif
  handle = handle + 1;
  if strcmp(tipo, 'LINE') && isfield(e, 'geometry') && size(e.geometry, 1) >= 2
    g = e.geometry;
    fprintf(fid, '  0\nLINE\n  5\n%X\n  8\n%s\n', handle, capa);
    fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n%.6f\n', g(1,1), g(1,2), zcol_local(g,1));
    fprintf(fid, ' 11\n%.6f\n 21\n%.6f\n 31\n%.6f\n', g(2,1), g(2,2), zcol_local(g,2));
  elseif strcmp(tipo, 'CIRCLE') && isfield(e, 'geometry')
    g = e.geometry; r = 0.5;
    if isfield(e, 'radius') && ~isnan(e.radius), r = e.radius; endif
    fprintf(fid, '  0\nCIRCLE\n  5\n%X\n  8\n%s\n', handle, capa);
    fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n%.6f\n 40\n%.6f\n', ...
      g(1,1), g(1,2), zcol_local(g,1), r);
  elseif strcmp(tipo, 'INSERT')
    bn = '';
    if isfield(e, 'block_name'), bn = char(e.block_name); endif
    if isempty(bn), return; endif
    x = 0; y = 0; z = 0;
    if isfield(e, 'geometry') && ~isempty(e.geometry)
      x = e.geometry(1,1); y = e.geometry(1,2);
      if size(e.geometry, 2) >= 3, z = e.geometry(1,3); endif
    endif
    fprintf(fid, '  0\nINSERT\n  5\n%X\n  8\n%s\n  2\n%s\n', handle, capa, bn);
    fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n%.6f\n', x, y, z);
  elseif ismember(tipo, {'TEXT', 'MTEXT'}) && isfield(e, 'text')
    x = 0; y = 0; z = 0;
    if isfield(e, 'geometry') && ~isempty(e.geometry)
      x = e.geometry(1,1); y = e.geometry(1,2);
      if size(e.geometry, 2) >= 3, z = e.geometry(1,3); endif
    endif
    fprintf(fid, '  0\nTEXT\n  5\n%X\n  8\n%s\n', handle, capa);
    fprintf(fid, ' 10\n%.6f\n 20\n%.6f\n 30\n%.6f\n 40\n0.8\n  1\n%s\n', ...
      x, y, z, char(e.text));
  endif
endfunction

function z = zcol_local(g, row)
  z = 0;
  if size(g, 2) >= 3, z = g(row, 3); endif
endfunction

function txt = meta_texto_tramo_local(tr)
  d = 0.1; mat = 'ACERO'; epsv = 0.045e-3; id = tr.id;
  if isfield(tr, 'diametro_m'), d = aos_aoscad_valor(tr.diametro_m); endif
  if isfield(tr, 'material')
    if isstruct(tr.material), mat = char(aos_aoscad_valor(tr.material));
    else, mat = char(tr.material); endif
  endif
  if isfield(tr, 'rugosidad'), epsv = aos_aoscad_valor(tr.rugosidad); endif
  if isfield(tr, 'id_estable') && ~isempty(tr.id_estable)
    id = char(tr.id_estable);
  elseif isfield(tr, 'etiqueta') && ~isempty(tr.etiqueta)
    id = char(tr.etiqueta);
  endif
  txt = sprintf('AOS D=%g MAT=%s EPS=%g ID=%s', d, mat, epsv, id);
endfunction

function p = canon_local(f)
  p = strrep(lower(char(f)), '\', '/');
endfunction

function c = as_cell_local(x)
  if isempty(x)
    c = {};
  elseif iscell(x)
    c = x;
  elseif isstruct(x)
    c = num2cell(x);
  else
    c = {x};
  endif
endfunction
