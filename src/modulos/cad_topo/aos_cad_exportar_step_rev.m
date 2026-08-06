function ruta = aos_cad_exportar_step_rev(archivo_out, silencioso)
% AOS_CAD_EXPORTAR_STEP_REV Exporta *_AOS_REV.step con Labels/IDs AOS.
% Nunca sobrescribe el STEP fuente. Salida: intercambio/cad/enviados/.
  global CONFIG_ACTIVA;
  if nargin < 2, silencioso = false; endif

  if isempty(CONFIG_ACTIVA) || ~isfield(CONFIG_ACTIVA, 'cad_topologia')
    error('AOS CAD_TOPO: no hay cad_topologia.');
  endif
  cad = CONFIG_ACTIVA.cad_topologia;
  if ~isfield(cad, 'step_archivo') || exist(cad.step_archivo, 'file') ~= 2
    error('AOS CAD_TOPO: no hay STEP fuente registrado.');
  endif
  fuente = char(cad.step_archivo);
  mtime_antes = aos_cad_mtime(fuente);

  if nargin < 1 || isempty(archivo_out)
    [~, n, e] = fileparts(fuente);
    if isempty(e), e = '.step'; endif
    outdir = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'enviados');
    if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
    archivo_out = fullfile(outdir, [n '_AOS_REV' e]);
  endif

  if strcmpi(canon_local(archivo_out), canon_local(fuente))
    [~, n, e] = fileparts(fuente);
    if isempty(e), e = '.step'; endif
    outdir = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'enviados');
    if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
    archivo_out = fullfile(outdir, [n '_AOS_REV' e]);
  endif

  renombres = {};
  if isfield(cad, 'id_index_step') && isfield(cad.id_index_step, 'items')
    for i = 1:numel(cad.id_index_step.items)
      it = cad.id_index_step.items{i};
      nom = '';
      if isfield(it, 'producto'), nom = char(it.producto); endif
      ida = '';
      if isfield(it, 'id'), ida = char(it.id); endif
      if isempty(ida), ida = sprintf('EQ%03d', i); endif
      renombres{end+1} = struct('producto', nom, 'id', ida, 'idx', i); %#ok<AGROW>
    endfor
  elseif isfield(cad, 'step_productos')
    for i = 1:numel(cad.step_productos)
      p = cad.step_productos{i};
      nom = '';
      if isfield(p, 'nombre'), nom = char(p.nombre); endif
      renombres{end+1} = struct('producto', nom, 'id', sprintf('EQ%03d', i), 'idx', i); %#ok<AGROW>
    endfor
  endif

  ok_fc = exportar_via_freecad_local(fuente, archivo_out, renombres);
  if ~ok_fc
    [ok_cp, msg] = copyfile(fuente, archivo_out);
    if ~ok_cp
      error('AOS CAD_TOPO: no se pudo crear REV STEP (%s)', msg);
    endif
    sidecar = [archivo_out '.aos_ids.txt'];
    fid = fopen(sidecar, 'wt');
    if fid >= 0
      fprintf(fid, '# AOS STEP REV id map (FreeCADCmd no disponible)\n');
      for i = 1:numel(renombres)
        fprintf(fid, '%d\t%s\t%s\n', renombres{i}.idx, renombres{i}.id, renombres{i}.producto);
      endfor
      fclose(fid);
    endif
    if ~silencioso
      fprintf(2, 'Aviso: FreeCADCmd no disponible; REV = copia + sidecar ids.\n');
    endif
  endif

  mtime_despues = aos_cad_mtime(fuente);
  if abs(mtime_despues - mtime_antes) > 1e-6
    error('AOS CAD_TOPO: el STEP fuente fue modificado (no permitido).');
  endif

  CONFIG_ACTIVA.cad_topologia.step_rev_archivo = char(archivo_out);
  ruta = char(archivo_out);

  if ~silencioso
    fprintf('\n--- STEP REVISION EXPORTADO ---\n');
    fprintf('fuente      : %s\n', fuente);
    fprintf('revision    : %s\n', ruta);
    fprintf('Fuente NO modificada. STEP != .aoscad.\n');
  endif
endfunction

function ok = exportar_via_freecad_local(fuente, destino, renombres)
  ok = false;
  det = aos_cad_localizar_programa('FreeCAD');
  if ~det.encontrado || ~det.cli_disponible
    return;
  endif

  tmpdir = fullfile(tempdir(), 'aos_cad_step_rev');
  if exist(tmpdir, 'dir') ~= 7, mkdir(tmpdir); endif
  py = fullfile(tmpdir, 'aos_export_step_rev.py');
  mapf = fullfile(tmpdir, 'aos_step_ids.txt');

  fid = fopen(mapf, 'wt');
  if fid < 0, return; endif
  for i = 1:numel(renombres)
    fprintf(fid, '%d\t%s\t%s\n', renombres{i}.idx, renombres{i}.id, renombres{i}.producto);
  endfor
  fclose(fid);

  fid = fopen(py, 'wt');
  if fid < 0, return; endif
  fprintf(fid, 'import FreeCAD\n');
  fprintf(fid, 'import Import\n');
  fprintf(fid, 'src = %s\n', py_str_local(fuente));
  fprintf(fid, 'dst = %s\n', py_str_local(destino));
  fprintf(fid, 'mapf = %s\n', py_str_local(mapf));
  fprintf(fid, 'ids = []\n');
  fprintf(fid, 'with open(mapf, "r") as f:\n');
  fprintf(fid, '    for line in f:\n');
  fprintf(fid, '        parts = line.strip().split("\\t")\n');
  fprintf(fid, '        if len(parts) >= 2:\n');
  fprintf(fid, '            ids.append(parts[1])\n');
  fprintf(fid, 'doc = FreeCAD.newDocument("AOS_REV")\n');
  fprintf(fid, 'Import.insert(src, doc.Name)\n');
  fprintf(fid, 'solids = [o for o in doc.Objects if hasattr(o, "Shape") and (not o.Shape.isNull())]\n');
  fprintf(fid, 'for i, o in enumerate(solids):\n');
  fprintf(fid, '    if i < len(ids):\n');
  fprintf(fid, '        o.Label = ids[i]\n');
  fprintf(fid, '    else:\n');
  fprintf(fid, '        o.Label = "EQ%%03d" %% (i + 1)\n');
  fprintf(fid, 'objs = solids if solids else list(doc.Objects)\n');
  fprintf(fid, 'Import.export(objs, dst)\n');
  fprintf(fid, 'FreeCAD.closeDocument(doc.Name)\n');
  fclose(fid);

  comandos = det.cli_cmds;
  for i = 1:numel(comandos)
    if exist(destino, 'file') == 2
      try, delete(destino); catch, end_try_catch
    endif
    cmdline = sprintf('%s %s', comandos{i}, shell_quote_local(py));
    [st, ~] = system(cmdline);
    if st == 0 && exist(destino, 'file') == 2
      ok = true;
      return;
    endif
  endfor
endfunction

function q = shell_quote_local(s)
  s = char(s);
  s = strrep(s, '\\', '\\\\');
  s = strrep(s, '"', '\\"');
  s = strrep(s, '$', '\\$');
  s = strrep(s, '`', '\\`');
  q = ['"' s '"'];
endfunction

function s = py_str_local(path)
  p = strrep(char(path), '\', '\\');
  p = strrep(p, '"', '\"');
  s = sprintf('"%s"', p);
endfunction

function p = canon_local(f)
  p = strrep(lower(char(f)), '\', '/');
endfunction
