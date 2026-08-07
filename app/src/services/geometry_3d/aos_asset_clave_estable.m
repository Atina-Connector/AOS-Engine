function [clave, origen, adv] = aos_asset_clave_estable(fila, tabla, opciones)
% AOS_ASSET_CLAVE_ESTABLE Clave estable de identidad (sin handle DXF).
% Prioridad: IDEST > INSERT bloque+pos > STEP > geometria canonica cuantizada > id local.
%
% [clave, origen, adv] = aos_asset_clave_estable(fila, tabla, opciones)
%   origen: IDEST|INSERT|STEP|GEOM|ID_LOCAL
%   adv: '' o 'ASSET_CLAVE_NO_ESTABLE' en fallback por id local

  clave = '';
  origen = '';
  adv = '';

  if nargin < 1 || isempty(fila) || ~isstruct(fila)
    clave = 'ID:EMPTY';
    origen = 'ID_LOCAL';
    adv = 'ASSET_CLAVE_NO_ESTABLE';
    return;
  endif
  if nargin < 2 || isempty(tabla), tabla = ''; endif
  if nargin < 3 || isempty(opciones), opciones = struct(); endif
  tabla = lower(strtrim(char(tabla)));

  q = 1e-3;
  if isfield(opciones, 'cuantizacion_m') && isnumeric(opciones.cuantizacion_m) ...
      && ~isempty(opciones.cuantizacion_m)
    q = double(opciones.cuantizacion_m(1));
    if ~(q > 0), q = 1e-3; endif
  endif

  % 1) IDEST:<id_estable>
  id_est = campo_texto_local(fila, 'id_estable');
  if ~isempty(id_est)
    clave = ['IDEST:' id_est];
    origen = 'IDEST';
    return;
  endif

  % 2) INSERT:<block_name>:<x>:<y>
  bn = campo_texto_local(fila, 'block_name');
  if ~isempty(bn)
    x = num_campo_local(fila, 'insert_x', 0);
    y = num_campo_local(fila, 'insert_y', 0);
    clave = sprintf('INSERT:%s:%.6f:%.6f', bn, x, y);
    origen = 'INSERT';
    return;
  endif

  % 3) STEP:<product_name> (step_product; o nombre si la tabla es STEP)
  prod = campo_texto_local(fila, 'step_product');
  es_step = strcmp(tabla, 'step_product') || strcmp(tabla, 'step_products') ...
    || strcmp(tabla, 'productos_step') || strcmp(tabla, 'step');
  if isempty(prod) && es_step
    prod = campo_texto_local(fila, 'nombre');
    if isempty(prod)
      prod = campo_texto_local(fila, 'product_name');
    endif
  endif
  if ~isempty(prod)
    clave = ['STEP:' prod];
    origen = 'STEP';
    return;
  endif

  % 4) Geometria canonica cuantizada (1e-3 m)
  [clave_g, ok_g] = clave_geom_local(fila, tabla, q);
  if ok_g
    clave = clave_g;
    origen = 'GEOM';
    return;
  endif

  % 5) Fallback id local (auditable; no estable ante reorder)
  id_loc = campo_texto_local(fila, 'id');
  if isempty(id_loc)
    id_loc = 'EMPTY';
  endif
  clave = ['ID:' id_loc];
  origen = 'ID_LOCAL';
  adv = 'ASSET_CLAVE_NO_ESTABLE';
endfunction

function [clave, ok] = clave_geom_local(fila, tabla, q)
  clave = '';
  ok = false;

  tiene_tramo = tiene_num_local(fila, 'x1') && tiene_num_local(fila, 'y1') ...
    && tiene_num_local(fila, 'x2') && tiene_num_local(fila, 'y2');
  es_tramo = strcmp(tabla, 'tramos') || strcmp(tabla, 'tramo') || tiene_tramo;
  if es_tramo && tiene_tramo
    x1 = cuantizar_local(num_campo_local(fila, 'x1', 0), q);
    y1 = cuantizar_local(num_campo_local(fila, 'y1', 0), q);
    x2 = cuantizar_local(num_campo_local(fila, 'x2', 0), q);
    y2 = cuantizar_local(num_campo_local(fila, 'y2', 0), q);
    % Extremos ordenados: la direccion del dibujo no cambia la identidad
    if x1 > x2 || (x1 == x2 && y1 > y2)
      xt = x1; yt = y1;
      x1 = x2; y1 = y2;
      x2 = xt; y2 = yt;
    endif
    clave = sprintf('TRAMO:%.3f:%.3f:%.3f:%.3f', x1, y1, x2, y2);
    ok = true;
    return;
  endif

  tiene_xy = tiene_num_local(fila, 'x') || tiene_num_local(fila, 'insert_x');
  es_nodo = strcmp(tabla, 'nodos') || strcmp(tabla, 'nodo') || tiene_xy;
  if es_nodo && tiene_xy
    if tiene_num_local(fila, 'x')
      x = num_campo_local(fila, 'x', 0);
      y = num_campo_local(fila, 'y', 0);
      z = num_campo_local(fila, 'z', 0);
    else
      x = num_campo_local(fila, 'insert_x', 0);
      y = num_campo_local(fila, 'insert_y', 0);
      z = num_campo_local(fila, 'insert_z', 0);
    endif
    x = cuantizar_local(x, q);
    y = cuantizar_local(y, q);
    z = cuantizar_local(z, q);
    clave = sprintf('NODO:%.3f:%.3f:%.3f', x, y, z);
    ok = true;
    return;
  endif
endfunction

function v = cuantizar_local(x, q)
  v = round(double(x) / q) * q;
endfunction

function s = campo_texto_local(fila, nom)
  s = '';
  if ~isfield(fila, nom), return; endif
  v = fila.(nom);
  if isempty(v), return; endif
  if ischar(v) || isstring(v)
    s = strtrim(char(v));
  elseif isnumeric(v)
    s = strtrim(sprintf('%.15g', v(1)));
  endif
endfunction

function tf = tiene_num_local(fila, nom)
  tf = false;
  if ~isfield(fila, nom), return; endif
  v = fila.(nom);
  tf = isnumeric(v) && ~isempty(v) && isfinite(double(v(1)));
endfunction

function x = num_campo_local(fila, nom, def)
  x = def;
  if ~isfield(fila, nom), return; endif
  v = fila.(nom);
  if isnumeric(v) && ~isempty(v)
    x = double(v(1));
  endif
endfunction
