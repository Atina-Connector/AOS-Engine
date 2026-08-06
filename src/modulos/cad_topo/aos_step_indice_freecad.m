function [indice_ext, diag] = aos_step_indice_freecad(archivo_step, opciones)
% AOS_STEP_INDICE_FREECAD Verificador cruzado opcional via FreeCADCmd.
% Solo para tests. Nunca lanza excepcion. Si FreeCAD falta o falla,
% disponible=false con motivo_omision (politica AVISO).
%
% [indice_ext, diag] = aos_step_indice_freecad(archivo_step, opciones)
%   indice_ext.productos: celda con nombre, placement_origen_m, bbox_m
%   diag: disponible, metodo, comando, codigo_salida, motivo_omision
  indice_ext = indice_vacio_local();
  diag = diag_vacio_local();

  try
    if nargin < 1, archivo_step = ''; endif
    if nargin < 2 || isempty(opciones), opciones = struct(); endif

    archivo_step = char(archivo_step);
    if isempty(archivo_step) || exist(archivo_step, 'file') ~= 2
      diag.motivo_omision = 'STEP ausente o ilegible';
      return;
    endif

    script_py = '';
    if isfield(opciones, 'script_py') && ~isempty(opciones.script_py)
      script_py = char(opciones.script_py);
    endif
    if isempty(script_py)
      script_py = localizar_script_local();
    endif
    if isempty(script_py) || exist(script_py, 'file') ~= 2
      diag.motivo_omision = 'Script Python versionado no encontrado';
      return;
    endif

    det = struct();
    try
      det = aos_cad_localizar_programa('FreeCAD');
    catch
      det = struct('encontrado', false, 'cli_disponible', false, ...
        'cli_cmds', {{}}, 'metodo', '', 'gui_cmd', '');
    end_try_catch

    if ~isfield(det, 'encontrado') || ~det.encontrado
      diag.motivo_omision = 'FreeCAD no localizado';
      return;
    endif
    diag.metodo = '';
    if isfield(det, 'metodo'), diag.metodo = char(det.metodo); endif

    if ~isfield(det, 'cli_disponible') || ~det.cli_disponible || ...
        ~isfield(det, 'cli_cmds') || isempty(det.cli_cmds)
      diag.motivo_omision = 'FreeCADCmd no disponible';
      return;
    endif

    % Verificar que algun candidato exista realmente (cli_cmds vienen quoted)
    cmd_ok = '';
    bin_ok = '';
    for i = 1:numel(det.cli_cmds)
      raw = desquote_local(det.cli_cmds{i});
      tok = strtrim(raw);
      % Sufijo opcional " -c" (AppImage); no partir por espacios del path
      cand = tok;
      if length(tok) >= 3 && strcmp(tok(end-2:end), ' -c')
        cand = strtrim(tok(1:end-3));
        cand = desquote_local(cand);
      endif
      if exist(cand, 'file') == 2
        cmd_ok = det.cli_cmds{i};
        bin_ok = cand;
        break;
      endif
      % Flatpak/snap: no es archivo local; aceptar el comando candidato
      low = lower(tok);
      if ~isempty(strfind(low, 'flatpak')) || ...
          ~isempty(strfind(low, 'snap')) || ...
          ~isempty(strfind(low, 'appimage'))
        cmd_ok = det.cli_cmds{i};
        bin_ok = tok;
        break;
      endif
    endfor
    if isempty(cmd_ok)
      diag.motivo_omision = 'Binario FreeCADCmd candidato no existe';
      return;
    endif
    diag.comando = cmd_ok;

    json_out = [tempname() '.json'];
    if isfield(opciones, 'json_out') && ~isempty(opciones.json_out)
      json_out = char(opciones.json_out);
    endif
    if exist(json_out, 'file') == 2
      try, delete(json_out); catch, end_try_catch
    endif

    % Pasar rutas por entorno (robusto en Windows con espacios)
    prev_in = getenv('AOS_STEP_INDICE_IN');
    prev_out = getenv('AOS_STEP_INDICE_OUT');
    setenv('AOS_STEP_INDICE_IN', archivo_step);
    setenv('AOS_STEP_INDICE_OUT', json_out);

    cmdline = construir_cmdline_local(cmd_ok, bin_ok, script_py);
    st = -1;
    out_txt = '';
    try
      [st, out_txt] = system(cmdline);
    catch err
      restaurar_env_local(prev_in, prev_out);
      diag.codigo_salida = -1;
      diag.motivo_omision = sprintf('system() fallo: %s', err.message);
      return;
    end_try_catch
    restaurar_env_local(prev_in, prev_out);
    diag.codigo_salida = st;

    if st ~= 0
      diag.motivo_omision = sprintf( ...
        'FreeCADCmd codigo_salida=%d', st);
      if ~isempty(out_txt)
        diag.motivo_omision = [diag.motivo_omision ' | ' recortar_local(out_txt, 200)];
      endif
      limpiar_tmp_local(json_out);
      return;
    endif

    if exist(json_out, 'file') ~= 2
      diag.motivo_omision = 'JSON de salida no generado';
      return;
    endif

    try
      raw = leer_utf8_local(json_out);
      data = jsondecode(raw);
    catch err
      diag.motivo_omision = sprintf('JSON no parseable: %s', err.message);
      limpiar_tmp_local(json_out);
      return;
    end_try_catch
    limpiar_tmp_local(json_out);

    if ~isstruct(data)
      diag.motivo_omision = 'JSON sin struct raiz';
      return;
    endif
    if isfield(data, 'ok') && ~data.ok
      msg = 'script reporto ok=false';
      if isfield(data, 'error'), msg = char(data.error); endif
      diag.motivo_omision = msg;
      return;
    endif

    indice_ext = parsear_indice_local(data);
    diag.disponible = true;
    diag.motivo_omision = '';
    diag.binario = bin_ok;
  catch err
    diag.disponible = false;
    if isempty(diag.motivo_omision)
      diag.motivo_omision = sprintf('Error interno: %s', err.message);
    endif
  end_try_catch
endfunction

function indice = indice_vacio_local()
  indice = struct();
  indice.productos = {};
  indice.n_productos = 0;
  indice.factor_a_metros = 1e-3;
  indice.origen = 'FreeCADCmd';
endfunction

function diag = diag_vacio_local()
  diag = struct();
  diag.disponible = false;
  diag.metodo = '';
  diag.comando = '';
  diag.codigo_salida = NaN;
  diag.motivo_omision = '';
  diag.binario = '';
endfunction

function cmdline = construir_cmdline_local(cmd_ok, bin_ok, script_py)
  % FreeCADCmd.exe en Windows 1.0 no ejecuta .py por argumento; usar -c exec(open).
  bin_low = lower(char(bin_ok));
  es_cmd_exe = ~isempty(regexp(bin_low, 'freecadcmd(\.exe)?$', 'once'));
  if es_cmd_exe
    py_fwd = strrep(char(script_py), '\', '/');
    py_fwd = strrep(py_fwd, '''', '');
    py_fwd = strrep(py_fwd, '"', '');
    % Comillas simples en Python para no pelear con el quoting del shell Windows
    code = sprintf('exec(open(''%s'', encoding=''utf-8'').read())', py_fwd);
    cmdline = sprintf('%s -c %s', cmd_ok, shell_quote_local(code));
  else
    cmdline = sprintf('%s %s', cmd_ok, shell_quote_local(script_py));
  endif
endfunction

function script_py = localizar_script_local()
  script_py = '';
  aqui = fileparts(mfilename('fullpath'));
  cand = {
    fullfile(aqui, '..', '..', '..', 'herramientas', 'aos_step_indice_freecad_export.py')
    fullfile(aqui, '..', '..', '..', 'datos', 'ejemplos', 'cad', 'aos_step_indice_freecad_export.py')
  };
  try
    raiz = aos_cad_raiz();
    cand{end+1} = fullfile(raiz, 'herramientas', 'aos_step_indice_freecad_export.py');
    cand{end+1} = fullfile(raiz, 'datos', 'ejemplos', 'cad', 'aos_step_indice_freecad_export.py');
  catch
  end_try_catch
  for i = 1:numel(cand)
    p = cand{i};
    if exist(p, 'file') == 2
      script_py = p;
      return;
    endif
  endfor
endfunction

function indice = parsear_indice_local(data)
  indice = indice_vacio_local();
  if isfield(data, 'factor_a_metros') && isnumeric(data.factor_a_metros)
    indice.factor_a_metros = double(data.factor_a_metros);
  endif
  prods = {};
  if isfield(data, 'productos')
    raw = data.productos;
    if iscell(raw)
      prods = raw;
    elseif isstruct(raw)
      for i = 1:numel(raw)
        prods{end+1} = raw(i); %#ok<AGROW>
      endfor
    endif
  endif
  out = {};
  for i = 1:numel(prods)
    p = prods{i};
    if ~isstruct(p), continue; endif
    ent = struct();
    ent.nombre = '';
    if isfield(p, 'nombre'), ent.nombre = char(p.nombre); endif
    ent.placement_origen_m = [NaN, NaN, NaN];
    if isfield(p, 'placement_origen_m')
      ent.placement_origen_m = vec3_local(p.placement_origen_m);
    elseif isfield(p, 'placement_origen')
      f = indice.factor_a_metros;
      ent.placement_origen_m = vec3_local(p.placement_origen) * f;
    endif
    ent.bbox_m = bbox_nan_local();
    if isfield(p, 'bbox_m') && isstruct(p.bbox_m)
      ent.bbox_m = bbox_from_local(p.bbox_m);
    elseif isfield(p, 'bbox') && isstruct(p.bbox)
      f = indice.factor_a_metros;
      b = bbox_from_local(p.bbox);
      campos = fieldnames(b);
      for k = 1:numel(campos)
        b.(campos{k}) = b.(campos{k}) * f;
      endfor
      ent.bbox_m = b;
    endif
    out{end+1} = ent; %#ok<AGROW>
  endfor
  indice.productos = out;
  indice.n_productos = numel(out);
endfunction

function v = vec3_local(x)
  v = [NaN, NaN, NaN];
  if isnumeric(x) && numel(x) >= 3
    v = double(x(1:3)(:)');
  elseif iscell(x) && numel(x) >= 3
    v = [double(x{1}), double(x{2}), double(x{3})];
  endif
endfunction

function bb = bbox_nan_local()
  bb = struct('xmin', NaN, 'xmax', NaN, 'ymin', NaN, 'ymax', NaN, ...
    'zmin', NaN, 'zmax', NaN);
endfunction

function bb = bbox_from_local(s)
  bb = bbox_nan_local();
  campos = {'xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'};
  for i = 1:numel(campos)
    c = campos{i};
    if isfield(s, c) && isnumeric(s.(c)) && isfinite(s.(c))
      bb.(c) = double(s.(c));
    endif
  endfor
endfunction

function raw = leer_utf8_local(ruta)
  fid = fopen(ruta, 'rt');
  if fid < 0
    error('no se pudo abrir %s', ruta);
  endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction

function restaurar_env_local(prev_in, prev_out)
  if isempty(prev_in)
    setenv('AOS_STEP_INDICE_IN', '');
  else
    setenv('AOS_STEP_INDICE_IN', prev_in);
  endif
  if isempty(prev_out)
    setenv('AOS_STEP_INDICE_OUT', '');
  else
    setenv('AOS_STEP_INDICE_OUT', prev_out);
  endif
endfunction

function limpiar_tmp_local(ruta)
  if exist(ruta, 'file') == 2
    try, delete(ruta); catch, end_try_catch
  endif
endfunction

function s = desquote_local(q)
  s = char(q);
  if numel(s) >= 2 && s(1) == '"' && s(end) == '"'
    s = s(2:end-1);
    s = strrep(s, '\"', '"');
    s = strrep(s, '\\', '\');
  endif
endfunction

function q = shell_quote_local(s)
  s = char(s);
  s = strrep(s, '\', '\\');
  s = strrep(s, '"', '\"');
  s = strrep(s, '$', '\$');
  s = strrep(s, '`', '\`');
  q = ['"' s '"'];
endfunction

function s = recortar_local(txt, n)
  s = char(txt);
  s = regexprep(s, '\s+', ' ');
  if numel(s) > n, s = s(1:n); endif
endfunction
