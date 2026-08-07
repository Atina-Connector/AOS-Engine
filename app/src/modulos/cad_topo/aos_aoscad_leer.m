function modelo = aos_aoscad_leer(archivo, silencioso)
% AOS_AOSCAD_LEER Lee exclusivamente archivos .aoscad JSON UTF-8.
  if nargin < 2, silencioso = false; endif
  if nargin < 1 || isempty(archivo)
    error('AOS CAD_TOPO: aos_aoscad_leer requiere una ruta .aoscad');
  endif
  if ~json_disponible_local('jsondecode')
    error('AOS CAD_TOPO: GNU Octave no dispone de jsondecode.');
  endif

  if exist(archivo, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), archivo);
    if exist(cand, 'file') == 2
      archivo = cand;
    else
      error('AOS CAD_TOPO: no existe %s', archivo);
    endif
  endif

  [~, ~, e] = fileparts(archivo);
  if ~strcmpi(e, '.aoscad')
    error('AOS CAD_TOPO: solo se admiten archivos .aoscad abiertos.');
  endif

  fid = fopen(archivo, 'rt');
  if fid < 0, error('AOS CAD_TOPO: no se pudo abrir %s', archivo); endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
  if isempty(strtrim(raw)), error('AOS CAD_TOPO: archivo vacio: %s', archivo); endif

  try
    modelo = jsondecode(raw);
  catch err
    error('AOS CAD_TOPO: JSON invalido en %s (%s)', archivo, err.message);
  end_try_catch
  modelo = normalizar_json_local(modelo);
  modelo = migrar_dev0_local(modelo);
  validar_modelo_local(modelo);

  if ~silencioso
    fprintf('\n--- AOSCAD LEIDO ---\n');
    fprintf('archivo     : %s\n', archivo);
    fprintf('schema      : %s\n', modelo.info.schema);
    fprintf('perfil      : %s\n', modelo.info.aoscad_perfil);
    fprintf('formato     : %s\n', modelo.info.formato_canonico);
    fprintf('motor       : %s\n', modelo.info.motor_objetivo);
    fprintf('dxf_clase   : %s\n', modelo.info.dxf_clase);
    if isfield(modelo, 'tablas_entrada')
      fprintf('nodos/tramos: %d / %d\n', ...
        numel_safe(modelo.tablas_entrada, 'nodos'), ...
        numel_safe(modelo.tablas_entrada, 'tramos'));
    endif
  endif
endfunction

function modelo = migrar_dev0_local(modelo)
  if ~isstruct(modelo) || ~isfield(modelo, 'info') || ~isstruct(modelo.info)
    return;
  endif
  if isfield(modelo.info, 'schema') && strcmp(char(modelo.info.schema), 'AOSCAD-1.0')
    modelo.info.schema_origen = 'AOSCAD-1.0-MOCKUP';
    modelo.info.schema = 'AOSCAD-0.0.1-DEV1';
    modelo.info.version_modulo = '0.0.1-DEV1';
    modelo.info.estado_desarrollo = 'PROTOTIPO_NO_VALIDADO';
    modelo.info.formato_canonico = 'JSON_UTF8';
    modelo.info.motor_objetivo = 'GNU_OCTAVE';
    modelo.info.migracion_en_memoria = true;
  endif
  if ~isfield(modelo.info, 'formato_canonico'), modelo.info.formato_canonico = 'JSON_UTF8'; endif
  if ~isfield(modelo.info, 'motor_objetivo'), modelo.info.motor_objetivo = 'GNU_OCTAVE'; endif
  if ~isfield(modelo.info, 'estado_desarrollo'), modelo.info.estado_desarrollo = 'PROTOTIPO_NO_VALIDADO'; endif
  if ~isfield(modelo, 'historial_edicion'), modelo.historial_edicion = {}; endif
  if isfield(modelo, 'tablas_entrada') && isstruct(modelo.tablas_entrada) && ...
      ~isfield(modelo.tablas_entrada, 'dominios_hidraulicos')
    modelo.tablas_entrada.dominios_hidraulicos = {};
  endif
  if isfield(modelo, 'tablas_entrada') && isstruct(modelo.tablas_entrada) && ...
      ~isfield(modelo.tablas_entrada, 'puertos')
    modelo.tablas_entrada.puertos = {};
  endif
  if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion) && ...
      ~isfield(modelo.simulacion, 'dominio_hidraulico_activo_id')
    modelo.simulacion.dominio_hidraulico_activo_id = '';
  endif
  if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion)
    estados_ok = {'NO_EJECUTADA', 'EJECUTADA', 'EJECUTADA_CON_ADVERTENCIAS', ...
                  'INVALIDADA_POR_EDICION'};
    if isfield(modelo.simulacion, 'estado') && ~isempty(modelo.simulacion.estado)
      est = char(modelo.simulacion.estado);
      if any(strcmp(est, estados_ok))
        % Respetar estado persistido (incluye INVALIDADA_POR_EDICION).
      elseif strcmp(est, 'INVALIDADA_POR_CONFIGURACION')
        % Compatibilidad legacy: mapear a schema-allowed.
        modelo.simulacion.estado = 'INVALIDADA_POR_EDICION';
      else
        modelo.simulacion.estado = inferir_estado_local(modelo);
      endif
    else
      modelo.simulacion.estado = inferir_estado_local(modelo);
    endif
  endif
  % Legacy sin recursos_visuales: default vacio, sin advertencias nuevas.
  if ~isfield(modelo, 'recursos_visuales')
    modelo.recursos_visuales = {};
  endif
endfunction

function est = inferir_estado_local(modelo)
% No forzar EJECUTADA solo porque exista motor: exige resultados vigentes.
  est = 'NO_EJECUTADA';
  tiene_motor = isfield(modelo.simulacion, 'motor') && ~isempty(modelo.simulacion.motor);
  tiene_res = false;
  if isfield(modelo, 'tablas_resultados') && isstruct(modelo.tablas_resultados)
    tr = modelo.tablas_resultados;
    if (isfield(tr, 'nodos') && ~isempty(tr.nodos)) ...
        || (isfield(tr, 'tramos') && ~isempty(tr.tramos))
      tiene_res = true;
    endif
  endif
  if tiene_motor && tiene_res
    est = 'EJECUTADA';
  elseif tiene_motor && ~tiene_res
    % Motor residual sin resultados: no presentar como EJECUTADA.
    est = 'NO_EJECUTADA';
  endif
endfunction

function validar_modelo_local(modelo)
  if ~isstruct(modelo) || ~isfield(modelo, 'info') || ~isfield(modelo.info, 'schema')
    error('AOS CAD_TOPO: archivo sin info.schema');
  endif
  if ~strcmp(char(modelo.info.schema), 'AOSCAD-0.0.1-DEV1')
    error('AOS CAD_TOPO: schema no soportado: %s', char(modelo.info.schema));
  endif
  % recursos_visuales es aditivo: legacy sin la seccion ya fue defaultado en migrar.
  oblig = {'tablas_entrada', 'geometria', 'topologia', 'simulacion', ...
           'tablas_resultados', 'validaciones'};
  for i = 1:numel(oblig)
    if ~isfield(modelo, oblig{i})
      error('AOS CAD_TOPO: falta seccion obligatoria %s', oblig{i});
    endif
  endfor
endfunction

function n = numel_safe(s, f)
  n = 0;
  if isstruct(s) && isfield(s, f), n = numel(s.(f)); endif
endfunction

function modelo = normalizar_json_local(modelo)
  if ~isstruct(modelo), return; endif

  % Colecciones tabulares: siempre celdas, incluso con una sola fila.
  secs = {'tablas_entrada', 'tablas_resultados'};
  for i = 1:numel(secs)
    if ~isfield(modelo, secs{i}) || ~isstruct(modelo.(secs{i})), continue; endif
    s = modelo.(secs{i});
    fn = fieldnames(s);
    for k = 1:numel(fn), s.(fn{k}) = a_celdas_local(s.(fn{k})); endfor
    modelo.(secs{i}) = s;
  endfor

  if isfield(modelo, 'topologia') && isstruct(modelo.topologia)
    if isfield(modelo.topologia, 'aristas')
      modelo.topologia.aristas = a_celdas_local(modelo.topologia.aristas);
    endif
    if isfield(modelo.topologia, 'nodos_grafo')
      modelo.topologia.nodos_grafo = a_celdas_local(modelo.topologia.nodos_grafo);
    endif
  endif

  if isfield(modelo, 'validaciones') && isstruct(modelo.validaciones) && ...
      isfield(modelo.validaciones, 'items')
    modelo.validaciones.items = a_celdas_local(modelo.validaciones.items);
  endif
  if isfield(modelo, 'historial_edicion')
    modelo.historial_edicion = a_celdas_local(modelo.historial_edicion);
  endif
  % activos: opcional; normalizar a celdas si existe (paquetes legacy sin activos OK)
  if isfield(modelo, 'activos')
    modelo.activos = a_celdas_local(modelo.activos);
  endif
  % recursos_visuales: normalizar planos/graficos; respetar vigente/obsoletos
  if isfield(modelo, 'recursos_visuales') && isstruct(modelo.recursos_visuales)
    rv = modelo.recursos_visuales;
    if isfield(rv, 'planos'), rv.planos = a_celdas_local(rv.planos); endif
    if isfield(rv, 'graficos'), rv.graficos = a_celdas_local(rv.graficos); endif
    modelo.recursos_visuales = rv;
  endif
endfunction

function c = a_celdas_local(v)
  if iscell(v)
    c = v;
  elseif isempty(v)
    c = {};
  elseif isstruct(v)
    c = cell(1, numel(v));
    for j = 1:numel(v), c{j} = v(j); endfor
  else
    c = {v};
  endif
endfunction

function tf = json_disponible_local(nombre)
  tf = (exist(nombre, 'builtin') == 5) || (exist(nombre, 'file') == 2);
endfunction
