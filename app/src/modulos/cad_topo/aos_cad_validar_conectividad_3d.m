function [reporte, items] = aos_cad_validar_conectividad_3d(tabla_conexiones, modelo, opciones)
% AOS_CAD_VALIDAR_CONECTIVIDAD_3D Contrasta conexiones 3D vs topologia.aristas 2D.
% Solo reporta; no modifica la topologia 2D. Determinista, sin graficos.
%
% [reporte, items] = aos_cad_validar_conectividad_3d(tabla_conexiones, modelo, opciones)
%   tabla_conexiones: salida de aos_cad_conexiones_3d
%   modelo: .aoscad con topologia.aristas y tablas_entrada.puertos
%
% Items: CONEXION_3D_INCONSISTENTE_2D, PUERTO_3D_HUERFANO, CONEXION_3D_DUPLICADA.
  if nargin < 1 || isempty(tabla_conexiones), tabla_conexiones = {}; endif
  if nargin < 2 || isempty(modelo), modelo = struct(); endif
  if nargin < 3 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(modelo), modelo = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};

  if ~iscell(tabla_conexiones)
    if isstruct(tabla_conexiones) && isfield(tabla_conexiones, 'conexiones')
      tabla_conexiones = tabla_conexiones.conexiones;
    else
      tabla_conexiones = {tabla_conexiones};
    endif
  endif

  reporte = struct();
  reporte.n_conexiones = numel(tabla_conexiones);
  reporte.n_inconsistentes = 0;
  reporte.n_huerfanos = 0;
  reporte.n_duplicadas = 0;
  reporte.unidades = 'm';
  reporte.vigente = true;

  % --- Duplicadas: mismo par desordenado {puerto_a, puerto_b} ---
  vistos = struct();
  for i = 1:numel(tabla_conexiones)
    c = tabla_conexiones{i};
    if isempty(c) || ~isstruct(c), continue; endif
    pa = ''; pb = '';
    if isfield(c, 'puerto_a'), pa = char(c.puerto_a); endif
    if isfield(c, 'puerto_b'), pb = char(c.puerto_b); endif
    if isempty(pa) || isempty(pb), continue; endif
    pk = clave_par_local(pa, pb);
    if isfield(vistos, pk)
      reporte.n_duplicadas = reporte.n_duplicadas + 1;
      cid = '';
      if isfield(c, 'id'), cid = char(c.id); endif
      items{end+1} = struct( ...
        'codigo', 'CONEXION_3D_DUPLICADA', ...
        'mensaje', sprintf('Conexion duplicada %s (%s-%s)', cid, pa, pb), ...
        'severidad', 'ADVERTENCIA', ...
        'conexion_id', cid, ...
        'puerto_a', pa, ...
        'puerto_b', pb); %#ok<AGROW>
    else
      vistos.(pk) = i;
    endif
  endfor

  % --- Indice 2D: nodos y tramos incidentes por nodo ---
  [nodos_2d, tramos_por_nodo, tramo_nodos] = indice_topologia_local(modelo);

  % Puertos conocidos (contrato o materializados)
  puertos = {};
  if isfield(opciones, 'puertos_3d') && isstruct(opciones.puertos_3d) ...
      && isfield(opciones.puertos_3d, 'lista')
    puertos = opciones.puertos_3d.lista;
  elseif isfield(modelo, 'tablas_entrada') && isstruct(modelo.tablas_entrada) ...
      && isfield(modelo.tablas_entrada, 'puertos')
    puertos = modelo.tablas_entrada.puertos;
    if ~iscell(puertos), puertos = {puertos}; endif
  endif

  % --- Inconsistencias conexion 3D vs aristas 2D ---
  for i = 1:numel(tabla_conexiones)
    c = tabla_conexiones{i};
    if isempty(c) || ~isstruct(c), continue; endif
    est = '';
    if isfield(c, 'estado'), est = char(c.estado); endif
    if strcmp(est, 'ABIERTA'), continue; endif

    pa = ''; pb = '';
    if isfield(c, 'puerto_a'), pa = char(c.puerto_a); endif
    if isfield(c, 'puerto_b'), pb = char(c.puerto_b); endif
    if isempty(pa) || isempty(pb), continue; endif

    nr = '';
    if isfield(c, 'nodo_ref') && ~isempty(c.nodo_ref)
      nr = char(c.nodo_ref);
    endif

    [ok_c, motivo] = conexion_consistente_local(pa, pb, nr, nodos_2d, ...
      tramos_por_nodo, tramo_nodos);
    if ~ok_c
      reporte.n_inconsistentes = reporte.n_inconsistentes + 1;
      cid = '';
      if isfield(c, 'id'), cid = char(c.id); endif
      items{end+1} = struct( ...
        'codigo', 'CONEXION_3D_INCONSISTENTE_2D', ...
        'mensaje', sprintf('Conexion %s inconsistente con topologia 2D: %s', ...
          cid, motivo), ...
        'severidad', 'ADVERTENCIA', ...
        'conexion_id', cid, ...
        'puerto_a', pa, ...
        'puerto_b', pb, ...
        'nodo_ref', nr); %#ok<AGROW>
    endif
  endfor

  % --- Puertos huerfanos: nodo_ref ausente en topologia 2D ---
  refs_en_cnx = struct();
  for i = 1:numel(tabla_conexiones)
    c = tabla_conexiones{i};
    if isempty(c) || ~isstruct(c), continue; endif
    if isfield(c, 'puerto_a') && ~isempty(c.puerto_a)
      refs_en_cnx.(safe_key_local(char(c.puerto_a))) = 1;
    endif
    if isfield(c, 'puerto_b') && ~isempty(c.puerto_b)
      refs_en_cnx.(safe_key_local(char(c.puerto_b))) = 1;
    endif
  endfor

  for i = 1:numel(puertos)
    p = puertos{i};
    if isempty(p) || ~isstruct(p), continue; endif
    pid = '';
    if isfield(p, 'id'), pid = char(p.id); endif
    if isempty(pid), continue; endif

    nr = '';
    if isfield(p, 'nodo_ref') && ~isempty(p.nodo_ref)
      nr = char(p.nodo_ref);
    endif

    huerfano = false;
    motivo = '';
    if ~isempty(nr)
      nk = safe_key_local(nr);
      if ~isfield(nodos_2d, nk)
        huerfano = true;
        motivo = sprintf('nodo_ref %s ausente en topologia 2D', nr);
      endif
    endif
    if ~huerfano && ~isfield(refs_en_cnx, safe_key_local(pid))
      huerfano = true;
      motivo = 'puerto sin conexion 3D asociada';
    endif

    if huerfano
      reporte.n_huerfanos = reporte.n_huerfanos + 1;
      items{end+1} = struct( ...
        'codigo', 'PUERTO_3D_HUERFANO', ...
        'mensaje', sprintf('Puerto %s huerfano: %s', pid, motivo), ...
        'severidad', 'ADVERTENCIA', ...
        'puerto_id', pid, ...
        'nodo_ref', nr); %#ok<AGROW>
    endif
  endfor

  reporte.n_items = numel(items);
endfunction

function [nodos_2d, tramos_por_nodo, tramo_nodos] = indice_topologia_local(modelo)
  nodos_2d = struct();
  tramos_por_nodo = struct();
  tramo_nodos = struct();

  aristas = {};
  if isfield(modelo, 'topologia') && isstruct(modelo.topologia) ...
      && isfield(modelo.topologia, 'aristas')
    aristas = modelo.topologia.aristas;
  endif
  if ~isempty(aristas) && ~iscell(aristas), aristas = {aristas}; endif

  if isempty(aristas) ...
      && isfield(modelo, 'tablas_entrada') && isstruct(modelo.tablas_entrada) ...
      && isfield(modelo.tablas_entrada, 'tramos')
    % Fallback: aristas implicitas desde tramos
    tramos = modelo.tablas_entrada.tramos;
    if ~iscell(tramos), tramos = {tramos}; endif
    for i = 1:numel(tramos)
      tr = tramos{i};
      if isempty(tr) || ~isstruct(tr), continue; endif
      a = struct();
      if isfield(tr, 'id'), a.tramo_ref = char(tr.id); else, a.tramo_ref = ''; endif
      if isfield(tr, 'nodo_o'), a.nodo_o = char(tr.nodo_o); else, a.nodo_o = ''; endif
      if isfield(tr, 'nodo_d'), a.nodo_d = char(tr.nodo_d); else, a.nodo_d = ''; endif
      aristas{end+1} = a; %#ok<AGROW>
    endfor
  endif

  for i = 1:numel(aristas)
    a = aristas{i};
    if isempty(a) || ~isstruct(a), continue; endif
    tid = '';
    if isfield(a, 'tramo_ref') && ~isempty(a.tramo_ref)
      tid = char(a.tramo_ref);
    endif
    no = ''; nd = '';
    if isfield(a, 'nodo_o') && ~isempty(a.nodo_o), no = char(a.nodo_o); endif
    if isfield(a, 'nodo_d') && ~isempty(a.nodo_d), nd = char(a.nodo_d); endif

    if ~isempty(no)
      nodos_2d.(safe_key_local(no)) = no;
      tramos_por_nodo = agregar_tramo_nodo_local(tramos_por_nodo, no, tid);
    endif
    if ~isempty(nd)
      nodos_2d.(safe_key_local(nd)) = nd;
      tramos_por_nodo = agregar_tramo_nodo_local(tramos_por_nodo, nd, tid);
    endif
    if ~isempty(tid)
      tramo_nodos.(safe_key_local(tid)) = struct('nodo_o', no, 'nodo_d', nd);
    endif
  endfor
endfunction

function mapa = agregar_tramo_nodo_local(mapa, nodo_id, tramo_id)
  if isempty(tramo_id), return; endif
  nk = safe_key_local(nodo_id);
  tk = safe_key_local(tramo_id);
  if ~isfield(mapa, nk)
    mapa.(nk) = struct();
  endif
  mapa.(nk).(tk) = tramo_id;
endfunction

function [ok, motivo] = conexion_consistente_local(pa, pb, nr, nodos_2d, ...
    tramos_por_nodo, tramo_nodos)
  ok = true;
  motivo = '';

  ta = tramo_de_puerto_local(pa);
  tb = tramo_de_puerto_local(pb);
  if isempty(ta) || isempty(tb)
    ok = false;
    motivo = 'no se pudo derivar tramo_ref del puerto';
    return;
  endif

  % Si hay nodo_ref, debe existir en 2D y ambos tramos deben ser incidentes
  if ~isempty(nr)
    nk = safe_key_local(nr);
    if ~isfield(nodos_2d, nk)
      ok = false;
      motivo = sprintf('nodo_ref %s no esta en topologia 2D', nr);
      return;
    endif
    if ~isfield(tramos_por_nodo, nk) ...
        || ~isfield(tramos_por_nodo.(nk), safe_key_local(ta)) ...
        || ~isfield(tramos_por_nodo.(nk), safe_key_local(tb))
      ok = false;
      motivo = sprintf('tramos %s/%s no incidentes en nodo %s', ta, tb, nr);
      return;
    endif
    return;
  endif

  % Sin nodo_ref: los dos tramos deben compartir algun nodo en 2D
  na = struct('nodo_o', '', 'nodo_d', '');
  nb = struct('nodo_o', '', 'nodo_d', '');
  if isfield(tramo_nodos, safe_key_local(ta))
    na = tramo_nodos.(safe_key_local(ta));
  endif
  if isfield(tramo_nodos, safe_key_local(tb))
    nb = tramo_nodos.(safe_key_local(tb));
  endif
  compartido = false;
  for ca = {na.nodo_o, na.nodo_d}
    if isempty(ca{1}), continue; endif
    for cb = {nb.nodo_o, nb.nodo_d}
      if strcmp(ca{1}, cb{1})
        compartido = true;
        break;
      endif
    endfor
    if compartido, break; endif
  endfor
  if ~compartido
    ok = false;
    motivo = sprintf('tramos %s y %s no comparten nodo en 2D', ta, tb);
  endif
endfunction

function tid = tramo_de_puerto_local(pid)
  tid = '';
  pid = char(pid);
  if length(pid) > 8 && strcmp(pid(end-7:end), '_ENTRADA')
    tid = pid(1:end-8);
  elseif length(pid) > 7 && strcmp(pid(end-6:end), '_SALIDA')
    tid = pid(1:end-7);
  endif
endfunction

function k = clave_par_local(a, b)
  a = char(a); b = char(b);
  if strcmp(a, b) || sort_str_local(a, b)
    k = safe_key_local([a '__' b]);
  else
    k = safe_key_local([b '__' a]);
  endif
endfunction

function tf = sort_str_local(a, b)
  % true si a <= b lexicografico
  tf = true;
  n = min(length(a), length(b));
  for i = 1:n
    if a(i) < b(i), tf = true; return; endif
    if a(i) > b(i), tf = false; return; endif
  endfor
  tf = length(a) <= length(b);
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction
