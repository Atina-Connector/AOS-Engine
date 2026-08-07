function ok = aos_cad_traer_step_exportado(archivo, silencioso)
% AOS_CAD_TRAER_STEP_EXPORTADO Importa un STEP exportado desde FreeCAD.
% FreeCAD no modifica el .step al guardar el documento: hay que Exportar STEP.
% Si el export uso otro nombre/ruta, esta funcion lo trae a la sesion AOS,
% actualiza step_archivo y invalida escena/vinculo 3D.
%
% ok = aos_cad_traer_step_exportado()
% ok = aos_cad_traer_step_exportado(archivo, silencioso)
  ok = false;
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || isempty(archivo)
    archivo = seleccionar_local();
  endif
  if isempty(archivo)
    if ~silencioso, fprintf('Traer STEP exportado cancelado.\n'); endif
    return;
  endif
  if exist(archivo, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), archivo);
    if exist(cand, 'file') == 2
      archivo = cand;
    else
      fprintf('No existe el STEP exportado: %s\n', archivo);
      return;
    endif
  endif
  archivo = char(archivo);

  % Preferir trabajar sobre copia en edicion (protege origenes/fixtures).
  try
    [copia, info_c] = aos_cad_step_copia_edicion(archivo, struct('forzar_recopia', true));
  catch err
    fprintf(2, 'No se pudo preparar copia de edicion: %s\n', err.message);
    copia = archivo;
    info_c = struct('origen', archivo, 'copiado', false);
  end_try_catch

  if ~silencioso
    fprintf('\n--- TRAER STEP EXPORTADO (FreeCAD) ---\n');
    fprintf('Exportado : %s\n', archivo);
    fprintf('Activo    : %s\n', copia);
    if isfield(info_c, 'copiado') && info_c.copiado
      fprintf('Copia     : regenerada en intercambio/cad/edicion\n');
    endif
  endif

  ok = aos_cad_importar_step(copia, silencioso);
  if ~ok, return; endif

  global CONFIG_ACTIVA;
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) ...
      && isfield(CONFIG_ACTIVA, 'cad_topologia')
    ct = CONFIG_ACTIVA.cad_topologia;
    if ~strcmpi(char(archivo), char(copia))
      ct.step_archivo_export_origen = archivo;
    endif
    ct.step_archivo_edicion = copia;
    if isfield(info_c, 'origen') && ~isempty(info_c.origen) ...
        && ~esta_bajo_edicion_local(info_c.origen)
      ct.step_archivo_origen = char(info_c.origen);
    endif
    CONFIG_ACTIVA.cad_topologia = ct;
  endif

  aos_cad_invalidar_escena_3d( ...
    sprintf(['Escena/vinculo 3D invalidos tras traer STEP exportado: %s'], ...
      copia), 'step', struct('invalidar_simulacion', true));

  if ~silencioso
    fprintf(['STEP traido. Simulacion/escena/vinculo invalidados; ', ...
      'reconstruya (3D Core -> 6) y recalcule.\n']);
  endif
endfunction

function archivo = seleccionar_local()
  archivo = '';
  root = aos_cad_raiz();
  dirs = {
    fullfile(root, 'intercambio', 'cad', 'edicion')
    fullfile(root, 'intercambio', 'cad', 'recibidos')
    fullfile(root, 'intercambio', 'cad', 'enviados')
  };
  candidatos = {};
  for d = 1:numel(dirs)
    if exist(dirs{d}, 'dir') ~= 7, continue; endif
    lista = [dir(fullfile(dirs{d}, '*.step')); dir(fullfile(dirs{d}, '*.stp'))];
    for i = 1:numel(lista)
      if lista(i).isdir, continue; endif
      candidatos{end+1} = fullfile(dirs{d}, lista(i).name); %#ok<AGROW>
    endfor
  endfor
  if ~isempty(candidatos)
    fprintf('STEP candidatos (edicion/recibidos/enviados):\n');
    for i = 1:numel(candidatos)
      fprintf('  %d - %s\n', i, candidatos{i});
    endfor
    fprintf('  0 - Elegir otro archivo\n');
    op = aos_leer_opcion(sprintf('Seleccione [0-%d]: ', numel(candidatos)), []);
    if ~isempty(op) && op >= 1 && op <= numel(candidatos)
      archivo = candidatos{op};
      return;
    endif
  endif
  try
    [f, p] = uigetfile({'*.step;*.stp', 'Archivos STEP'}, ...
      'Seleccionar STEP exportado desde FreeCAD');
    if isnumeric(f) && f == 0, return; endif
    archivo = fullfile(p, f);
  catch
    archivo = strtrim(input('Ruta del STEP exportado: ', 's'));
  end_try_catch
endfunction

function tf = esta_bajo_edicion_local(archivo)
  tf = false;
  dir_ed = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'edicion');
  try
    [pd, ~, ~] = fileparts(char(archivo));
    tf = strcmpi(strrep(pd, '/', filesep), strrep(dir_ed, '/', filesep));
  catch
    tf = false;
  end_try_catch
endfunction
