function ruta = aos_aoscad_escribir(archivo, perfil, silencioso)
% AOS_AOSCAD_ESCRIBIR Serializa un modelo completo como .aoscad JSON UTF-8.
% No crea ni consulta representaciones binarias paralelas.
% ENRIQUECIDO: regenera recursos_visuales si faltan u obsoletos.
% Escritura atomica (temporal + reemplazo). Fallo de PNG no corrompe .aoscad.
  global CONFIG_ACTIVA;
  if nargin < 3, silencioso = false; endif
  if nargin < 2 || isempty(perfil), perfil = 'SIMPLE'; endif
  perfil = upper(char(perfil));

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: no hay modelo_aoscad para escribir.');
  endif
  if ~json_disponible_local('jsonencode') || ~json_disponible_local('jsondecode')
    error(['AOS CAD_TOPO: esta version de GNU Octave no dispone de jsonencode/jsondecode. ' ...
           'No se generara un archivo parcial.']);
  endif

  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion) || ...
      ~isfield(modelo.simulacion, 'motor') || isempty(modelo.simulacion.motor)
    error(['AOS CAD_TOPO: el modelo no tiene una simulacion vigente. ' ...
           'Ejecute o repita la simulacion antes de guardar.']);
  endif
  if isfield(modelo.simulacion, 'estado') && ...
      strcmpi(char(modelo.simulacion.estado), 'INVALIDADA_POR_EDICION')
    error('AOS CAD_TOPO: los resultados fueron invalidados por una edicion. Recalcule primero.');
  endif

  if ~any(strcmp(perfil, {'SIMPLE', 'ENRIQUECIDO'}))
    error('AOS CAD_TOPO: perfil no valido: %s', perfil);
  endif

  modelo = asegurar_info_local(modelo);
  modelo.info.aoscad_perfil = perfil;
  modelo.info.modificado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  if ~isfield(modelo.info, 'creado_en') || isempty(modelo.info.creado_en)
    modelo.info.creado_en = modelo.info.modificado_en;
  endif

  % AOS 0.2.0 DEV1: inventariar y configurar la presentacion de tablas
  % sin duplicar ni eliminar los datos canonicos del modelo AOSCAD.
  modelo = aos_aoscad_report_composition(modelo, silencioso);

  if nargin < 1 || isempty(archivo)
    root = aos_cad_raiz();
    outdir = fullfile(root, 'intercambio', 'cad', 'aoscad');
    if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
    archivo = fullfile(outdir, sprintf('corrida_%s.aoscad', datestr(now, 'yyyymmdd_HHMMSS')));
  endif

  [p, n, e] = fileparts(archivo);
  if isempty(e)
    archivo = fullfile(p, [n '.aoscad']);
  elseif ~strcmpi(e, '.aoscad')
    error('AOS CAD_TOPO: la salida debe usar extension .aoscad');
  endif
  if ~isempty(p) && exist(p, 'dir') ~= 7, mkdir(p); endif

  if strcmp(perfil, 'ENRIQUECIDO')
    modelo = asegurar_recursos_enriquecido_local(modelo, archivo, silencioso);
  else
    modelo.recursos_visuales = {};
  endif

  try
    texto = jsonencode(modelo);
  catch err
    error('AOS CAD_TOPO: no se pudo serializar el modelo completo (%s)', err.message);
  end_try_catch
  if isempty(texto)
    error('AOS CAD_TOPO: jsonencode devolvio contenido vacio. No se escribio el archivo.');
  endif

  tmp = sprintf('%s.tmp_%s_%06d', archivo, datestr(now, 'yyyymmddHHMMSS'), randi(999999));
  fid = fopen(tmp, 'wt');
  if fid < 0
    error('AOS CAD_TOPO: no se pudo crear archivo temporal %s', tmp);
  endif
  nbytes = fprintf(fid, '%s\n', texto);
  fclose(fid);
  if nbytes <= 2
    if exist(tmp, 'file') == 2, delete(tmp); endif
    error('AOS CAD_TOPO: serializacion vacia; archivo descartado.');
  endif

  % Verificacion de round-trip antes de reemplazar la salida final.
  try
    verificado = leer_json_local(tmp);
    validar_minimo_local(verificado, modelo);
  catch err
    if exist(tmp, 'file') == 2, delete(tmp); endif
    error('AOS CAD_TOPO: round-trip JSON no aprobado (%s)', err.message);
  end_try_catch

  if exist(archivo, 'file') == 2, delete(archivo); endif
  [mov_ok, mov_msg] = movefile(tmp, archivo);
  if ~mov_ok
    if exist(tmp, 'file') == 2, delete(tmp); endif
    error('AOS CAD_TOPO: no se pudo cerrar la escritura atomica (%s)', mov_msg);
  endif

  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.aoscad_archivo = char(archivo);
  if isfield(CONFIG_ACTIVA.cad_topologia, 'aoscad_mat')
    CONFIG_ACTIVA.cad_topologia = rmfield(CONFIG_ACTIVA.cad_topologia, 'aoscad_mat');
  endif
  ruta = char(archivo);

  if ~silencioso
    fprintf('\n--- AOSCAD ESCRITO ---\n');
    fprintf('perfil      : %s\n', perfil);
    fprintf('archivo     : %s\n', ruta);
    fprintf('formato     : JSON UTF-8 (fuente canonica unica)\n');
    fprintf('schema      : %s\n', modelo.info.schema);
    fprintf('motor       : GNU Octave\n');
    if isfield(modelo, 'report_composition') && isstruct(modelo.report_composition)
      rc = modelo.report_composition;
      if isfield(rc, 'table_count_available')
        fprintf('tablas      : %d disponibles', rc.table_count_available);
        if isfield(rc, 'table_count_rendered')
          fprintf(' / %d visibles', rc.table_count_rendered);
        endif
        fprintf('\n');
      endif
    endif
    if strcmp(perfil, 'ENRIQUECIDO') && isstruct(modelo.recursos_visuales)
      n_rec = contar_recursos_local(modelo.recursos_visuales);
      fprintf('recursos    : %d (regenerables)\n', n_rec);
    endif
  endif
endfunction

function modelo = asegurar_recursos_enriquecido_local(modelo, archivo, silencioso)
% Llama al generador si faltan recursos o estan obsoletos.
% Fallo de PNG: conserva contenedor y no aborta la escritura del .aoscad.
% archivo: destino .aoscad (PNG van a intercambio/cad/recursos).
  if isempty(archivo), archivo = ''; endif
  if ~recursos_necesitan_regen_local(modelo)
    return;
  endif

  root = aos_cad_raiz();
  rec_dir = fullfile(root, 'intercambio', 'cad', 'recursos');
  if exist(rec_dir, 'dir') ~= 7
    try
      mkdir(rec_dir);
    catch
    end_try_catch
  endif

  opts = struct( ...
    'incluir_2d', true, ...
    'incluir_3d', true, ...
    'incluir_overlay', true, ...
    'visible', false, ...
    'directorio', rec_dir);

  items_gen = {};
  rv = [];
  try
    [rv, items_gen] = aos_aoscad_generar_recursos_visuales(modelo, opts);
  catch err
    if ~silencioso
      fprintf(2, 'AOS CAD_TOPO: generacion de recursos fallida (%s); se guarda sin PNG.\n', ...
        err.message);
    endif
    rv = [];
    items_gen = {struct( ...
      'codigo', 'RECURSOS_PNG_FALLO', ...
      'severidad', 'ADVERTENCIA', ...
      'mensaje', sprintf('Generacion de recursos fallida (%s).', err.message), ...
      'origen', 'aos_aoscad_escribir')};
  end_try_catch

  if isstruct(rv) && ~isempty(rv)
    modelo.recursos_visuales = rv;
  else
    modelo.recursos_visuales = contenedor_recursos_vacio_local(items_gen);
  endif

  % Anexar items de generacion a validaciones (trazabilidad; no rompe schema).
  if ~isempty(items_gen)
    modelo = anexar_items_validacion_local(modelo, items_gen);
  endif
endfunction

function tf = recursos_necesitan_regen_local(modelo)
  tf = true;
  if ~isfield(modelo, 'recursos_visuales') || isempty(modelo.recursos_visuales)
    return;
  endif
  rv = modelo.recursos_visuales;
  if ~isstruct(rv), return; endif
  if isfield(rv, 'obsoletos') && logical(rv.obsoletos), return; endif
  if isfield(rv, 'vigente') && ~logical(rv.vigente)
    % Contenedor vacio con vigente=false tambien regenera.
  endif
  n = contar_recursos_local(rv);
  if n < 1, return; endif
  if isfield(rv, 'vigente') && ~logical(rv.vigente), return; endif
  % Algun recurso individual no vigente / obsoleto => regenerar.
  if recursos_individuales_obsoletos_local(rv), return; endif
  tf = false;
endfunction

function tf = recursos_individuales_obsoletos_local(rv)
  tf = false;
  recs = [lista_campo_local(rv, 'planos'), lista_campo_local(rv, 'graficos')];
  for i = 1:numel(recs)
    r = recs{i};
    if ~isstruct(r), continue; endif
    if (isfield(r, 'vigente') && ~logical(r.vigente)) ...
        || (isfield(r, 'obsoletos') && logical(r.obsoletos))
      tf = true; return;
    endif
  endfor
endfunction

function arr = lista_campo_local(rv, campo)
  arr = {};
  if ~isstruct(rv) || ~isfield(rv, campo) || isempty(rv.(campo)), return; endif
  v = rv.(campo);
  if iscell(v)
    arr = v;
  elseif isstruct(v)
    arr = cell(1, numel(v));
    for i = 1:numel(v), arr{i} = v(i); endfor
  endif
endfunction

function n = contar_recursos_local(rv)
  n = 0;
  if ~isstruct(rv), return; endif
  n = n + numel(lista_campo_local(rv, 'planos'));
  n = n + numel(lista_campo_local(rv, 'graficos'));
endfunction

function rv = contenedor_recursos_vacio_local(items_gen)
  nota = 'ENRIQUECIDO: recursos visuales no generados (PNG ausente o fallo).';
  if ~isempty(items_gen) && isstruct(items_gen{1}) && isfield(items_gen{1}, 'mensaje')
    nota = char(items_gen{1}.mensaje);
  endif
  rv = struct( ...
    'tipo', 'RECURSOS_VIEWER', ...
    'planos', {{}}, ...
    'graficos', {{}}, ...
    'vigente', false, ...
    'obsoletos', false, ...
    'nota', nota);
endfunction

function modelo = anexar_items_validacion_local(modelo, items_gen)
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'PENDIENTE', 'items', {{}});
  endif
  if ~isfield(modelo.validaciones, 'items') || isempty(modelo.validaciones.items)
    modelo.validaciones.items = {};
  elseif ~iscell(modelo.validaciones.items)
    modelo.validaciones.items = {modelo.validaciones.items};
  endif
  for i = 1:numel(items_gen)
    it = items_gen{i};
    if ~isstruct(it), continue; endif
    modelo.validaciones.items{end+1} = it; %#ok<AGROW>
  endfor
endfunction

function modelo = asegurar_info_local(modelo)
  if ~isfield(modelo, 'info') || ~isstruct(modelo.info), modelo.info = struct(); endif
  modelo.info.schema = 'AOSCAD-0.0.1-DEV1';
  modelo.info.formato_canonico = 'JSON_UTF8';
  modelo.info.motor_objetivo = 'GNU_OCTAVE';
  modelo.info.estado_desarrollo = 'PROTOTIPO_NO_VALIDADO';
  modelo.info.version_modulo = '0.0.1-DEV1';
endfunction

function tf = json_disponible_local(nombre)
  tf = (exist(nombre, 'builtin') == 5) || (exist(nombre, 'file') == 2);
endfunction

function modelo = leer_json_local(archivo)
  fid = fopen(archivo, 'rt');
  if fid < 0, error('no se pudo reabrir el temporal'); endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
  modelo = jsondecode(raw);
endfunction

function validar_minimo_local(leido, original)
  if ~isstruct(leido) || ~isfield(leido, 'info') || ~isfield(leido.info, 'schema')
    error('archivo sin info.schema');
  endif
  if ~strcmp(char(leido.info.schema), 'AOSCAD-0.0.1-DEV1')
    error('schema inesperado');
  endif
  if ~isfield(leido, 'tablas_entrada') || ~isfield(leido, 'simulacion') || ...
      ~isfield(leido, 'tablas_resultados')
    error('faltan secciones obligatorias');
  endif
  if contar_local(leido.tablas_entrada, 'nodos') ~= contar_local(original.tablas_entrada, 'nodos')
    error('cantidad de nodos alterada en round-trip');
  endif
  if contar_local(leido.tablas_entrada, 'tramos') ~= contar_local(original.tablas_entrada, 'tramos')
    error('cantidad de tramos alterada en round-trip');
  endif
endfunction

function n = contar_local(s, f)
  n = 0;
  if isstruct(s) && isfield(s, f), n = numel(s.(f)); endif
endfunction
