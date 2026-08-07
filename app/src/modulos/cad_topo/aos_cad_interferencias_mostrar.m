function aos_cad_interferencias_mostrar(tabla_o_resultado, items)
% AOS_CAD_INTERFERENCIAS_MOSTRAR Tabla primaria de interferencias AABB.
% Patron de aos_cad_hidraulica_mostrar_resultados: fprintf tabular, sin graficos.
% La vista 3D es secundaria (fuera de este modulo).
%
% aos_cad_interferencias_mostrar(tabla_interferencias)
% aos_cad_interferencias_mostrar(tabla_interferencias, items)
% aos_cad_interferencias_mostrar(resultado)  % struct con .tabla_interferencias
  if nargin < 1, tabla_o_resultado = {}; endif
  if nargin < 2, items = {}; endif

  tabla = {};
  if isstruct(tabla_o_resultado) && isfield(tabla_o_resultado, 'tabla_interferencias')
    tabla = tabla_o_resultado.tabla_interferencias;
    if (nargin < 2 || isempty(items)) && isfield(tabla_o_resultado, 'items')
      items = tabla_o_resultado.items;
    endif
  elseif iscell(tabla_o_resultado)
    tabla = tabla_o_resultado;
  elseif isstruct(tabla_o_resultado) && numel(tabla_o_resultado) >= 1 ...
      && isfield(tabla_o_resultado, 'tipo')
    tabla = num2cell(tabla_o_resultado);
  endif
  if ~iscell(tabla), tabla = {}; endif
  if ~iscell(items), items = {items}; endif

  fprintf('\n--- INTERFERENCIAS AABB (%d pares) ---\n', numel(tabla));
  fprintf('(Deteccion conservadora por bounding box; no es colision BRep exacta)\n');
  if isempty(tabla)
    fprintf('Sin pares en conflicto.\n');
  else
    fprintf('%-10s %12s %12s %-18s %-18s %-18s %-18s\n', ...
      'Tipo', 'Vol[m3]', 'Dist[m]', 'Asset_A', 'Geom_A', 'Asset_B', 'Geom_B');
    for i = 1:numel(tabla)
      r = tabla{i};
      if ~isstruct(r), continue; endif
      fprintf('%-10s %12.6g %12.6g %-18s %-18s %-18s %-18s\n', ...
        campo_local(r, 'tipo', ''), ...
        num_local(r, 'volumen_solape_m3', 0), ...
        num_local(r, 'distancia_m', NaN), ...
        trunc_local(campo_local(r, 'asset_a', ''), 18), ...
        trunc_local(campo_local(r, 'geometry_a', ''), 18), ...
        trunc_local(campo_local(r, 'asset_b', ''), 18), ...
        trunc_local(campo_local(r, 'geometry_b', ''), 18));
    endfor
  endif

  if ~isempty(items)
    fprintf('\n--- ITEMS INTERFERENCIAS (%d) ---\n', numel(items));
    for i = 1:numel(items)
      it = items{i};
      if ~isstruct(it), continue; endif
      fprintf('[%s] %s: %s\n', ...
        campo_local(it, 'severidad', 'INFO'), ...
        campo_local(it, 'codigo', ''), ...
        campo_local(it, 'mensaje', ''));
    endfor
  endif
endfunction

function s = campo_local(r, campo, defecto)
  s = defecto;
  if isstruct(r) && isfield(r, campo) && ~isempty(r.(campo))
    try
      s = char(r.(campo));
    catch
      s = defecto;
    end_try_catch
  endif
endfunction

function v = num_local(r, campo, defecto)
  v = defecto;
  if isstruct(r) && isfield(r, campo) && isnumeric(r.(campo)) && ~isempty(r.(campo))
    v = r.(campo)(1);
  endif
endfunction

function s = trunc_local(s, n)
  s = char(s);
  if numel(s) > n
    s = s(1:n);
  endif
endfunction
