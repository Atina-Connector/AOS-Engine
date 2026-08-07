function ok = aos_aoscad_editar_campo(tabla, id_fila, campo, valor_nuevo, silencioso)
% AOS_AOSCAD_EDITAR_CAMPO Edita un campo y anula resultados dependientes.
  global CONFIG_ACTIVA;
  if nargin < 5, silencioso = false; endif
  ok = false;
  if isempty(CONFIG_ACTIVA) || ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOS CAD_TOPO: no hay modelo_aoscad en memoria.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if ~isfield(modelo, 'tablas_entrada') || ~isfield(modelo.tablas_entrada, tabla)
    error('AOS CAD_TOPO: tabla desconocida: %s', tabla);
  endif
  filas = modelo.tablas_entrada.(tabla);
  found = false;
  valor_anterior = [];
  for i = 1:numel(filas)
    fila = fila_local(filas, i);
    if isfield(fila, 'id') && strcmp(char(fila.id), char(id_fila))
      if isfield(fila, campo), valor_anterior = fila.(campo); endif
      if isfield(fila, campo) && isstruct(fila.(campo)) && ...
          isfield(fila.(campo), 'valor_original')
        fila.(campo).valor_editado = valor_nuevo;
        fila.(campo).fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        fila.(campo).origen = 'USUARIO';
        fila.(campo).usuario_o_proceso = 'AOS_SUITE_OCTAVE';
        fila.(campo).estado_de_validacion = 'PENDIENTE';
      else
        fila.(campo) = valor_nuevo;
      endif
      filas = asignar_fila_local(filas, i, fila);
      found = true;
      break;
    endif
  endfor
  if ~found, error('AOS CAD_TOPO: no se encontro %s id=%s', tabla, id_fila); endif

  modelo.tablas_entrada.(tabla) = filas;

  motivo = sprintf('Edicion de %s.%s.%s; resultados y derivados invalidados.', ...
    char(tabla), char(id_fila), char(campo));
  opts = struct( ...
    'codigo', 'INVALIDADA_POR_EDICION', ...
    'invalidar_escena', true, ...
    'limpiar_resultados', true, ...
    'invalidar_recursos', true, ...
    'accion', 'EDITAR_CAMPO', ...
    'item_codigo', 'RECALCULO_REQUERIDO', ...
    'advertencia', 'RESULTADOS_INVALIDADOS_POR_EDICION');
  [modelo, items_inv] = aos_cad_invalidar_simulacion(modelo, motivo, opts);

  % Enriquecer ultimo evento de historial con detalle de campo
  if isfield(modelo, 'historial_edicion') && ~isempty(modelo.historial_edicion)
    ev = modelo.historial_edicion{end};
    if isstruct(ev)
      ev.tabla = char(tabla);
      ev.id_fila = char(id_fila);
      ev.campo = char(campo);
      ev.valor_anterior = valor_anterior;
      ev.valor_nuevo = valor_nuevo;
      modelo.historial_edicion{end} = ev;
    endif
  endif

  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  if isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.escena_3d)
    CONFIG_ACTIVA.cad_topologia.escena_3d.vigente = false;
  endif
  if isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.vinculo_3d)
    CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente = false;
  endif
  ok = true;
  if ~silencioso
    fprintf('Campo editado: %s.%s.%s\n', tabla, id_fila, campo);
    fprintf('Resultados anteriores: INVALIDADOS. Recalcule antes de guardar.\n');
    if tiene_codigo_local(items_inv, 'ESCENA_3D_INVALIDADA_POR_EDICION')
      fprintf('Escena/vinculo 3D: INVALIDADOS (ESCENA_3D_INVALIDADA_POR_EDICION).\n');
    endif
  endif
endfunction

function fila = fila_local(filas, i)
  if iscell(filas), fila = filas{i}; else, fila = filas(i); endif
endfunction

function filas = asignar_fila_local(filas, i, fila)
  if iscell(filas), filas{i} = fila; else, filas(i) = fila; endif
endfunction

function tf = tiene_codigo_local(items, codigo)
  tf = false;
  if isempty(items), return; endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), char(codigo))
      tf = true; return;
    endif
  endfor
endfunction
