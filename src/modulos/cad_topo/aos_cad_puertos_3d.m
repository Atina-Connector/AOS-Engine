function [puertos_3d, items] = aos_cad_puertos_3d(modelo, opciones)
% AOS_CAD_PUERTOS_3D Materializa el contrato Sprint 2 con posicion 3D resuelta.
% Hereda z del nodo referido y geometry_id del vinculo 3D cuando exista.
% Solo datos: sin graficos, sin interferencias. Determinista.
%
% [puertos_3d, items] = aos_cad_puertos_3d(modelo, opciones)
%   modelo: .aoscad con tablas_entrada.puertos (contrato Sprint 2)
%   opciones: (opcional) reservado
%
% puertos_3d.lista / .por_id (claves PTO_*) / .n / .unidades='m'
% Item PUERTO_3D_SIN_POSICION (ADVERTENCIA) si la posicion queda indeterminada;
% nunca se fuerza a 0.
  if nargin < 1 || isempty(modelo), modelo = struct(); endif
  if nargin < 2 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(modelo), modelo = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};

  puertos_3d = struct();
  puertos_3d.lista = {};
  puertos_3d.por_id = struct();
  puertos_3d.n = 0;
  puertos_3d.unidades = 'm';
  puertos_3d.vigente = true;

  puertos = {};
  if isfield(modelo, 'tablas_entrada') && isstruct(modelo.tablas_entrada) ...
      && isfield(modelo.tablas_entrada, 'puertos')
    puertos = modelo.tablas_entrada.puertos;
  endif
  if isempty(puertos), return; endif
  if ~iscell(puertos), puertos = {puertos}; endif

  nodos = {};
  if isfield(modelo, 'tablas_entrada') && isfield(modelo.tablas_entrada, 'nodos')
    nodos = modelo.tablas_entrada.nodos;
  endif
  if ~isempty(nodos) && ~iscell(nodos), nodos = {nodos}; endif

  mapa_nodos = mapa_nodos_local(nodos);
  mapa_gid = mapa_geometry_local(modelo);

  lista = {};
  por_id = struct();
  for i = 1:numel(puertos)
    p0 = puertos{i};
    if isempty(p0) || ~isstruct(p0), continue; endif

    pid = '';
    if isfield(p0, 'id') && ~isempty(p0.id)
      pid = char(p0.id);
    else
      pid = sprintf('P%03d', i);
    endif

    tipo = '';
    if isfield(p0, 'tipo'), tipo = char(p0.tipo); endif
    aid = '';
    if isfield(p0, 'asset_id_componente') && ~isempty(p0.asset_id_componente)
      aid = char(p0.asset_id_componente);
    endif
    nodo_ref = '';
    if isfield(p0, 'nodo_ref') && ~isempty(p0.nodo_ref)
      nodo_ref = char(p0.nodo_ref);
    endif
    est = '';
    if isfield(p0, 'estado_conexion') && ~isempty(p0.estado_conexion)
      est = char(p0.estado_conexion);
    endif

    [x, y, z, ok_pos] = resolver_posicion_local(p0, nodo_ref, mapa_nodos);

    gid = '';
    if ~isempty(aid)
      ak = safe_key_local(aid);
      if isfield(mapa_gid, ak)
        gid = mapa_gid.(ak);
      endif
    endif

    p = struct();
    p.id = pid;
    p.tipo = tipo;
    p.asset_id_componente = aid;
    p.asset_id = aid;
    p.nodo_ref = nodo_ref;
    p.estado_conexion = est;
    p.geometry_id = gid;
    p.unidades = 'm';
    p.origen = 'PUERTOS_3D';
    p.indice = i;
    if ok_pos
      p.posicion = struct('x', x, 'y', y, 'z', z);
      p.posicion_resuelta = true;
    else
      % Vacio (no 0, no NaN): preservacion de falla / determinismo isequal
      p.posicion = struct('x', [], 'y', [], 'z', []);
      p.posicion_resuelta = false;
      items{end+1} = struct( ...
        'codigo', 'PUERTO_3D_SIN_POSICION', ...
        'mensaje', sprintf('Puerto %s sin posicion 3D finita', pid), ...
        'severidad', 'ADVERTENCIA', ...
        'puerto_id', pid, ...
        'nodo_ref', nodo_ref); %#ok<AGROW>
    endif

    lista{end+1} = p; %#ok<AGROW>
    por_id.(clave_pto_local(pid)) = p;
  endfor

  puertos_3d.lista = lista;
  puertos_3d.por_id = por_id;
  puertos_3d.n = numel(lista);
endfunction

function [x, y, z, ok] = resolver_posicion_local(p0, nodo_ref, mapa_nodos)
  x = []; y = []; z = [];
  ok = false;

  % 1) Posicion del contrato Sprint 2 (si finita)
  if isfield(p0, 'posicion') && isstruct(p0.posicion)
    pos = p0.posicion;
    if isfield(pos, 'x') && isnumeric(pos.x) && ~isempty(pos.x) && isfinite(pos.x(1))
      x = double(pos.x(1));
    endif
    if isfield(pos, 'y') && isnumeric(pos.y) && ~isempty(pos.y) && isfinite(pos.y(1))
      y = double(pos.y(1));
    endif
    if isfield(pos, 'z') && isnumeric(pos.z) && ~isempty(pos.z) && isfinite(pos.z(1))
      z = double(pos.z(1));
    endif
  endif

  % 2) Heredar / completar desde nodo referido (z prioritario)
  if ~isempty(nodo_ref)
    nk = safe_key_local(nodo_ref);
    if isfield(mapa_nodos, nk)
      n = mapa_nodos.(nk);
      if isempty(x) && isfield(n, 'x') && isnumeric(n.x) && ~isempty(n.x) ...
          && isfinite(n.x(1))
        x = double(n.x(1));
      endif
      if isempty(y) && isfield(n, 'y') && isnumeric(n.y) && ~isempty(n.y) ...
          && isfinite(n.y(1))
        y = double(n.y(1));
      endif
      % z: heredar del nodo si el puerto no trae z finita, o reforzar con nodo
      if isfield(n, 'z') && isnumeric(n.z) && ~isempty(n.z) && isfinite(n.z(1))
        if isempty(z)
          z = double(n.z(1));
        else
          z = double(n.z(1)); % nodo es fuente de cota 3D
        endif
      endif
      if isempty(x) && isfield(n, 'x') && isnumeric(n.x) && ~isempty(n.x) ...
          && isfinite(n.x(1))
        x = double(n.x(1));
      endif
      if isempty(y) && isfield(n, 'y') && isnumeric(n.y) && ~isempty(n.y) ...
          && isfinite(n.y(1))
        y = double(n.y(1));
      endif
    endif
  endif

  if ~isempty(x) && ~isempty(y) && ~isempty(z) ...
      && isfinite(x) && isfinite(y) && isfinite(z)
    ok = true;
  else
    % Indeterminado: no rellenar con 0
    x = []; y = []; z = [];
    ok = false;
  endif
endfunction

function mapa = mapa_nodos_local(nodos)
  mapa = struct();
  for i = 1:numel(nodos)
    n = nodos{i};
    if isempty(n) || ~isstruct(n), continue; endif
    if ~isfield(n, 'id') || isempty(n.id), continue; endif
    mapa.(safe_key_local(char(n.id))) = n;
  endfor
endfunction

function mapa = mapa_geometry_local(modelo)
  mapa = struct();
  if ~isstruct(modelo), return; endif

  if isfield(modelo, 'vinculo_3d') && isstruct(modelo.vinculo_3d) ...
      && isfield(modelo.vinculo_3d, 'por_asset_id') ...
      && isstruct(modelo.vinculo_3d.por_asset_id)
    fn = fieldnames(modelo.vinculo_3d.por_asset_id);
    for i = 1:numel(fn)
      mapa.(fn{i}) = char(modelo.vinculo_3d.por_asset_id.(fn{i}));
    endfor
  endif

  if isfield(modelo, 'activos') && ~isempty(modelo.activos)
    activos = modelo.activos;
    if ~iscell(activos), activos = {activos}; endif
    for i = 1:numel(activos)
      a = activos{i};
      if isempty(a) || ~isstruct(a), continue; endif
      if ~isfield(a, 'asset_id') || isempty(a.asset_id), continue; endif
      if ~isfield(a, 'geometry_id') || isempty(a.geometry_id), continue; endif
      mapa.(safe_key_local(char(a.asset_id))) = char(a.geometry_id);
    endfor
  endif
endfunction

function k = clave_pto_local(id)
  k = ['PTO_' safe_key_local(id)];
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction
