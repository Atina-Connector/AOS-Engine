function [escena, items] = aos_cad_overlay_resultados(escena, tablas_resultados, opciones)
% AOS_CAD_OVERLAY_RESULTADOS Mapea tablas_resultados a overlay/color sobre escena 3D.
% Solo mapea valores ya calculados. Sin fisica, sin reescala del valor almacenado,
% sin graficos. Objetos sin resultado: overlay.estado='SIN_DATO' (nunca como 0).
%
% [escena, items] = aos_cad_overlay_resultados(escena, tablas_resultados, opciones)
%   escena: struct con .objetos (cell de objetos de aos_cad_escena_3d)
%   tablas_resultados: modelo.tablas_resultados o modelo con ese campo
%   opciones.n_bins: numero fijo de bins (default 8)
%
% Por objeto NODO/TRAMO:
%   overlay.valor, .magnitud {PRESION,CAUDAL}, .unidad (Pa|m3/s),
%   overlay.clase (bin 1..n_bins o []), .estado (OK|SIN_DATO), color_rgb
% Escala de color: min/max de la tabla + bins fijos; clasificacion tipo visor 2D
% (azul->rojo; caudal por |Q|).
  if nargin < 1 || isempty(escena), escena = struct(); endif
  if nargin < 2 || isempty(tablas_resultados), tablas_resultados = struct(); endif
  if nargin < 3 || isempty(opciones), opciones = struct(); endif
  if ~isstruct(escena), escena = struct(); endif
  if ~isstruct(tablas_resultados), tablas_resultados = struct(); endif
  if ~isstruct(opciones), opciones = struct(); endif
  items = {};

  n_bins = 8;
  if isfield(opciones, 'n_bins') && isnumeric(opciones.n_bins) && ...
      ~isempty(opciones.n_bins) && isfinite(opciones.n_bins(1))
    n_bins = max(1, round(opciones.n_bins(1)));
  endif

  tr = resolver_tablas_local(tablas_resultados);
  [mapa_p, vals_p] = mapa_nodos_presion_local(tr);
  [mapa_q, vals_q] = mapa_tramos_caudal_local(tr);
  [vmin_p, vmax_p] = rango_local(vals_p);
  [vmin_q, vmax_q] = rango_local(vals_q);

  objetos = {};
  if isfield(escena, 'objetos') && iscell(escena.objetos)
    objetos = escena.objetos;
  endif

  for i = 1:numel(objetos)
    o = objetos{i};
    if ~isstruct(o), continue; endif
    tipo = '';
    if isfield(o, 'tipo'), tipo = upper(char(o.tipo)); endif
    oid = '';
    if isfield(o, 'id'), oid = char(o.id); endif

    switch tipo
      case 'NODO'
        [o, it] = aplicar_overlay_local(o, oid, mapa_p, 'PRESION', 'Pa', ...
          vmin_p, vmax_p, n_bins, false);
        if ~isempty(it), items{end+1} = it; endif %#ok<AGROW>
      case 'TRAMO'
        [o, it] = aplicar_overlay_local(o, oid, mapa_q, 'CAUDAL', 'm3/s', ...
          vmin_q, vmax_q, n_bins, true);
        if ~isempty(it), items{end+1} = it; endif %#ok<AGROW>
      otherwise
        % POZO / EQUIPO_3D / otros: sin overlay de resultados hidraulicos
    endswitch
    objetos{i} = o;
  endfor

  escena.objetos = objetos;
  if ~isfield(escena, 'n_objetos')
    escena.n_objetos = numel(objetos);
  endif
  escena.overlay_meta = struct( ...
    'n_bins', n_bins, ...
    'presion_Pa', struct('vmin', vmin_p, 'vmax', vmax_p), ...
    'caudal_liquido_m3s', struct('vmin', vmin_q, 'vmax', vmax_q));
endfunction

function tr = resolver_tablas_local(entrada)
  tr = struct('nodos', {{}}, 'tramos', {{}});
  if ~isstruct(entrada), return; endif
  if isfield(entrada, 'tablas_resultados') && isstruct(entrada.tablas_resultados)
    entrada = entrada.tablas_resultados;
  endif
  if isfield(entrada, 'nodos'), tr.nodos = filas_local(entrada.nodos); endif
  if isfield(entrada, 'tramos'), tr.tramos = filas_local(entrada.tramos); endif
endfunction

function filas = filas_local(raw)
  filas = {};
  if isempty(raw), return; endif
  if iscell(raw)
    filas = raw;
  elseif isstruct(raw)
    filas = num2cell(raw);
  endif
endfunction

function [mapa, vals] = mapa_nodos_presion_local(tr)
  mapa = struct();
  vals = [];
  filas = {};
  if isfield(tr, 'nodos'), filas = tr.nodos; endif
  for i = 1:numel(filas)
    r = filas{i};
    if ~isstruct(r), continue; endif
    rid = '';
    if isfield(r, 'id'), rid = char(r.id); endif
    if isempty(rid), continue; endif
    v = num_campo_local(r, 'presion_Pa');
    if ~isfinite(v), continue; endif
    mapa.(safe_key_local(rid)) = v;
    vals(end+1) = v; %#ok<AGROW>
  endfor
endfunction

function [mapa, vals] = mapa_tramos_caudal_local(tr)
  mapa = struct();
  vals = [];
  filas = {};
  if isfield(tr, 'tramos'), filas = tr.tramos; endif
  for i = 1:numel(filas)
    r = filas{i};
    if ~isstruct(r), continue; endif
    rid = '';
    if isfield(r, 'id'), rid = char(r.id); endif
    if isempty(rid), continue; endif
    % Valor almacenado: caudal_liquido_m3s exacto (sin fallback a 0).
    if ~isfield(r, 'caudal_liquido_m3s') || ~isnumeric(r.caudal_liquido_m3s) || ...
        isempty(r.caudal_liquido_m3s)
      continue;
    endif
    v = double(r.caudal_liquido_m3s(1));
    if ~isfinite(v), continue; endif
    mapa.(safe_key_local(rid)) = v;
    % Clasificacion 2D: escala por |Q|
    vals(end+1) = abs(v); %#ok<AGROW>
  endfor
endfunction

function [vmin, vmax] = rango_local(vals)
  vmin = [];
  vmax = [];
  if isempty(vals), return; endif
  vmin = min(vals);
  vmax = max(vals);
  % Misma salvaguarda que aos_cad_visor_2d ante rango nulo
  if abs(vmax - vmin) < 1e-15
    vmax = vmin + 1;
  endif
endfunction

function [o, it] = aplicar_overlay_local(o, oid, mapa, magnitud, unidad, ...
    vmin, vmax, n_bins, usar_abs)
  it = [];
  ov = struct();
  ov.magnitud = char(magnitud);
  ov.unidad = char(unidad);
  ov.valor = [];
  ov.clase = [];
  ov.estado = 'SIN_DATO';

  key = '';
  if ~isempty(oid), key = safe_key_local(oid); endif
  tiene = ~isempty(key) && isfield(mapa, key);
  if ~tiene
    o.overlay = ov;
    o.color_rgb = color_neutro_local();
    it = struct( ...
      'codigo', 'OVERLAY_SIN_DATO', ...
      'mensaje', sprintf('%s %s sin resultado en tablas_resultados', ...
        char(magnitud), oid), ...
      'severidad', 'ADVERTENCIA', ...
      'id', oid, ...
      'tipo', char(o.tipo));
    return;
  endif

  valor = mapa.(key);
  ov.valor = valor; % exacto, sin reescala ni conversion
  ov.estado = 'OK';

  v_esc = valor;
  if usar_abs, v_esc = abs(valor); endif
  [clase, col] = clasificar_color_local(v_esc, vmin, vmax, n_bins);
  ov.clase = clase;
  o.overlay = ov;
  o.color_rgb = col;
endfunction

function [clase, col] = clasificar_color_local(v, vmin, vmax, n_bins)
  % Clasificacion determinista por bins + paleta azul->rojo del visor 2D.
  clase = 1;
  col = [0, 0.15, 1];
  if isempty(vmin) || isempty(vmax) || ~isfinite(v)
    clase = [];
    col = color_neutro_local();
    return;
  endif
  span = vmax - vmin;
  if ~(isfinite(span) && span > 0)
    t = 0;
  else
    t = (v - vmin) / span;
  endif
  if t < 0, t = 0; endif
  if t > 1, t = 1; endif
  clase = floor(t * n_bins) + 1;
  if clase > n_bins, clase = n_bins; endif
  if clase < 1, clase = 1; endif
  if n_bins <= 1
    t_bin = 0;
  else
    t_bin = (clase - 1) / (n_bins - 1);
  endif
  col = [t_bin, 0.15, 1 - t_bin];
endfunction

function col = color_neutro_local()
  % Gris neutro (mismo tono que tramos fuera de dominio en visor 2D)
  col = [0.72, 0.72, 0.72];
endfunction

function v = num_campo_local(s, nom)
  v = NaN;
  if isstruct(s) && isfield(s, nom) && isnumeric(s.(nom)) && ~isempty(s.(nom))
    v = double(s.(nom)(1));
  endif
endfunction

function k = safe_key_local(s)
  s = upper(char(s));
  s = regexprep(s, '[^A-Z0-9_]', '_');
  if isempty(s), s = 'X'; endif
  if s(1) >= '0' && s(1) <= '9', s = ['K_' s]; endif
  k = s;
endfunction
