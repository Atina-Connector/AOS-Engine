function [modelo, items] = aos_cad_invalidar_simulacion(modelo, motivo, opciones)
% AOS_CAD_INVALIDAR_SIMULACION Invalidacion atomica de simulacion y derivados.
% API:
%   [modelo, items] = aos_cad_invalidar_simulacion(modelo, motivo, opciones)
% opciones.codigo = 'INVALIDADA_POR_EDICION'   % estado schema-allowed
% opciones.invalidar_escena = true
% opciones.limpiar_resultados = true
% opciones.invalidar_recursos = true
% opciones.origen = 'AOS_SUITE_OCTAVE'
% opciones.item_codigo = ''   % override del codigo del item trazable
%
% Estado de simulacion siempre schema-allowed (INVALIDADA_POR_EDICION).
% Motivos especificos (p.ej. CONFIGURACION) van en historial/item/advertencias.
  if nargin < 1 || isempty(modelo) || ~isstruct(modelo)
    error('AOS CAD_TOPO: aos_cad_invalidar_simulacion requiere modelo struct.');
  endif
  if nargin < 2 || isempty(motivo)
    motivo = 'Simulacion y derivados invalidados; recalcule.';
  endif
  if nargin < 3 || isempty(opciones) || ~isstruct(opciones)
    opciones = struct();
  endif

  codigo_estado = 'INVALIDADA_POR_EDICION';
  if isfield(opciones, 'codigo') && ~isempty(opciones.codigo)
    codigo_estado = char(opciones.codigo);
  endif
  % Resolver enum incompatible: mapear a schema-allowed y conservar motivo.
  if strcmp(codigo_estado, 'INVALIDADA_POR_CONFIGURACION')
    codigo_estado = 'INVALIDADA_POR_EDICION';
  endif
  estados_ok = {'NO_EJECUTADA', 'EJECUTADA', 'EJECUTADA_CON_ADVERTENCIAS', ...
                'INVALIDADA_POR_EDICION'};
  if ~any(strcmp(codigo_estado, estados_ok))
    codigo_estado = 'INVALIDADA_POR_EDICION';
  endif

  invalidar_escena = true;
  if isfield(opciones, 'invalidar_escena')
    invalidar_escena = logical(opciones.invalidar_escena);
  endif
  limpiar_resultados = true;
  if isfield(opciones, 'limpiar_resultados')
    limpiar_resultados = logical(opciones.limpiar_resultados);
  endif
  invalidar_recursos = true;
  if isfield(opciones, 'invalidar_recursos')
    invalidar_recursos = logical(opciones.invalidar_recursos);
  endif
  origen = 'AOS_SUITE_OCTAVE';
  if isfield(opciones, 'origen') && ~isempty(opciones.origen)
    origen = char(opciones.origen);
  endif
  item_codigo = 'SIMULACION_INVALIDADA_POR_EDICION';
  if isfield(opciones, 'item_codigo') && ~isempty(opciones.item_codigo)
    item_codigo = char(opciones.item_codigo);
  endif

  motivo = char(motivo);
  items = {};

  if ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion)
    modelo.simulacion = struct();
  endif
  sim = modelo.simulacion;

  estado_previo = '';
  if isfield(sim, 'estado'), estado_previo = char(sim.estado); endif
  motor_previo = '';
  if isfield(sim, 'motor'), motor_previo = char(sim.motor); endif
  corrida_previa = '';
  if isfield(sim, 'corrida_id'), corrida_previa = char(sim.corrida_id); endif
  fecha_previa = '';
  if isfield(sim, 'fecha'), fecha_previa = char(sim.fecha); endif

  % Idempotencia: si ya invalidado sin resultados y sin motor vigente,
  % aun asi refresca item/escena/recursos de forma coherente.
  ya_inval = strcmp(estado_previo, 'INVALIDADA_POR_EDICION');

  evento = struct();
  evento.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  evento.proceso = origen;
  evento.accion = 'INVALIDAR_SIMULACION';
  evento.motivo = motivo;
  evento.codigo_estado = codigo_estado;
  evento.resultados_invalidados = true;
  evento.estado_previo = estado_previo;
  evento.motor_previo = motor_previo;
  evento.corrida_id_previo = corrida_previa;
  evento.fecha_previa = fecha_previa;
  if isfield(opciones, 'accion') && ~isempty(opciones.accion)
    evento.accion = char(opciones.accion);
  endif

  if ~isfield(modelo, 'historial_edicion') || isempty(modelo.historial_edicion)
    modelo.historial_edicion = {evento};
  elseif iscell(modelo.historial_edicion)
    % Evitar spam de historial en llamadas idempotentes consecutivas identicas
    if ~(ya_inval && isempty(motor_previo) && resultados_vacios_local(modelo) ...
        && historial_ultimo_igual_local(modelo.historial_edicion, evento))
      modelo.historial_edicion{end+1} = evento;
    endif
  else
    modelo.historial_edicion = {modelo.historial_edicion, evento};
  endif

  % Presentacion vigente: no mostrar motor/corrida/fecha como vigentes.
  sim.estado = codigo_estado;
  sim.motor = '';
  sim.corrida_id = '';
  sim.fecha = '';
  adv = {};
  if isfield(sim, 'advertencias') && ~isempty(sim.advertencias)
    if iscell(sim.advertencias), adv = sim.advertencias; else, adv = {sim.advertencias}; endif
  endif
  if ~tiene_texto_local(adv, 'RESULTADOS_INVALIDADOS')
    adv{end+1} = 'RESULTADOS_INVALIDADOS_POR_EDICION';
  endif
  if isfield(opciones, 'advertencia') && ~isempty(opciones.advertencia)
    if ~tiene_texto_local(adv, char(opciones.advertencia))
      adv{end+1} = char(opciones.advertencia);
    endif
  endif
  sim.advertencias = adv;
  modelo.simulacion = sim;

  if limpiar_resultados
    tr = struct('nodos', {{}}, 'tramos', {{}});
    if isfield(modelo, 'tablas_resultados') && isstruct(modelo.tablas_resultados)
      fn = fieldnames(modelo.tablas_resultados);
      for i = 1:numel(fn)
        tr.(fn{i}) = {};
      endfor
    endif
    if ~isfield(tr, 'resumen'), tr.resumen = {}; endif
    modelo.tablas_resultados = tr;
  endif

  item = struct( ...
    'codigo', item_codigo, ...
    'mensaje', motivo, ...
    'severidad', 'ADVERTENCIA', ...
    'origen', origen);
  items{end+1} = item;

  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones)
    modelo.validaciones = struct('estado', 'ADVERTENCIA', 'items', {{}});
  endif
  if ~isfield(modelo.validaciones, 'items') || isempty(modelo.validaciones.items)
    modelo.validaciones.items = {};
  elseif ~iscell(modelo.validaciones.items)
    modelo.validaciones.items = {modelo.validaciones.items};
  endif
  if ~tiene_codigo_item_local(modelo.validaciones.items, item_codigo)
    modelo.validaciones.items{end+1} = item;
  endif
  if ~isfield(modelo.validaciones, 'estado') ...
      || strcmp(modelo.validaciones.estado, 'PENDIENTE') ...
      || strcmp(modelo.validaciones.estado, 'OK')
    modelo.validaciones.estado = 'ADVERTENCIA';
  endif

  if invalidar_escena
    modelo = marcar_no_vigente_local(modelo, 'escena_3d');
    modelo = marcar_no_vigente_local(modelo, 'vinculo_3d');
    modelo = marcar_no_vigente_local(modelo, 'puertos_3d');
    modelo = marcar_no_vigente_local(modelo, 'conexiones_3d');
    modelo = marcar_no_vigente_local(modelo, 'escena_federada');
    modelo = marcar_no_vigente_local(modelo, 'overlay');
    item_esc = struct( ...
      'codigo', 'ESCENA_3D_INVALIDADA_POR_EDICION', ...
      'mensaje', motivo, ...
      'severidad', 'ADVERTENCIA', ...
      'origen', origen);
    if ~tiene_codigo_item_local(modelo.validaciones.items, item_esc.codigo)
      modelo.validaciones.items{end+1} = item_esc;
    endif
    items{end+1} = item_esc;
  endif

  if invalidar_recursos
    modelo = invalidar_recursos_local(modelo);
  endif

  if isfield(modelo, 'info') && isstruct(modelo.info)
    modelo.info.modificado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  endif
endfunction

function tf = resultados_vacios_local(modelo)
  tf = true;
  if ~isfield(modelo, 'tablas_resultados') || ~isstruct(modelo.tablas_resultados)
    return;
  endif
  tr = modelo.tablas_resultados;
  campos = {'nodos', 'tramos', 'resumen'};
  for i = 1:numel(campos)
    if isfield(tr, campos{i}) && ~isempty(tr.(campos{i}))
      tf = false; return;
    endif
  endfor
endfunction

function tf = historial_ultimo_igual_local(hist, evento)
  tf = false;
  if isempty(hist), return; endif
  ev = hist{end};
  if ~isstruct(ev), return; endif
  if isfield(ev, 'accion') && isfield(evento, 'accion') ...
      && strcmp(char(ev.accion), char(evento.accion)) ...
      && isfield(ev, 'motivo') && isfield(evento, 'motivo') ...
      && strcmp(char(ev.motivo), char(evento.motivo))
    tf = true;
  endif
endfunction

function tf = tiene_texto_local(cel, txt)
  tf = false;
  txt = upper(char(txt));
  for i = 1:numel(cel)
    if ~isempty(strfind(upper(char(cel{i})), txt))
      tf = true; return;
    endif
  endfor
endfunction

function tf = tiene_codigo_item_local(items, codigo)
  tf = false;
  if isempty(items), return; endif
  for i = 1:numel(items)
    it = items{i};
    if isstruct(it) && isfield(it, 'codigo') && strcmp(char(it.codigo), char(codigo))
      tf = true; return;
    endif
  endfor
endfunction

function modelo = marcar_no_vigente_local(modelo, campo)
  if isfield(modelo, campo) && isstruct(modelo.(campo))
    modelo.(campo).vigente = false;
  endif
endfunction

function modelo = invalidar_recursos_local(modelo)
  if ~isfield(modelo, 'recursos_visuales') || isempty(modelo.recursos_visuales)
    return;
  endif
  rv = modelo.recursos_visuales;
  if iscell(rv)
    for i = 1:numel(rv)
      if isstruct(rv{i})
        rv{i}.vigente = false;
        rv{i}.obsoletos = true;
      endif
    endfor
    modelo.recursos_visuales = rv;
    return;
  endif
  if ~isstruct(rv), return; endif
  rv.vigente = false;
  rv.obsoletos = true;
  listas = {'planos', 'graficos', 'recursos', 'items'};
  for L = 1:numel(listas)
    nom = listas{L};
    if ~isfield(rv, nom) || isempty(rv.(nom)), continue; endif
    arr = rv.(nom);
    if ~iscell(arr)
      if isstruct(arr)
        c = cell(1, numel(arr));
        for j = 1:numel(arr), c{j} = arr(j); endfor
        arr = c;
      else
        continue;
      endif
    endif
    for j = 1:numel(arr)
      if isstruct(arr{j})
        arr{j}.vigente = false;
        arr{j}.obsoletos = true;
      endif
    endfor
    rv.(nom) = arr;
  endfor
  modelo.recursos_visuales = rv;
endfunction
