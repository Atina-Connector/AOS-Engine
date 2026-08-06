function idx = aos_cad_build_id_index_step(cad)
% AOS_CAD_BUILD_ID_INDEX_STEP Indice STEP por nombre PRODUCT / id.
% Conserva firma y por_handle (compatibilidad). La identidad se delega al
% servicio aos_asset_id_generar; EQ%03d deja de ser la unica fuente.
  idx = struct('por_handle', struct(), 'items', {{}});
  if nargin < 1 || isempty(cad) || ~isstruct(cad), return; endif
  productos = {};
  if isfield(cad, 'step_productos'), productos = cad.step_productos; endif
  for i = 1:numel(productos)
    p = productos{i};
    nom = '';
    pid = '';
    if isfield(p, 'nombre'), nom = char(p.nombre); endif
    if isfield(p, 'id'), pid = char(p.id); endif
    key = nom;
    if isempty(key), key = pid; endif
    if isempty(key), key = sprintf('STEP_SOLID_%d', i); endif
    raw = ['STEP:' key];
    safe = upper(raw);
    safe = regexprep(safe, '[^A-Z0-9_]', '_');
    if safe(1) >= '0' && safe(1) <= '9', safe = ['H_' safe]; endif

    fila = struct();
    fila.nombre = nom;
    fila.product_name = nom;
    fila.step_product = nom;
    if ~isempty(pid), fila.id = pid; endif
    if isempty(fila.step_product)
      fila.step_product = key;
      fila.nombre = key;
    endif

    [aid, ~, ~] = aos_asset_id_generar('STEP_PRODUCT', fila, 'step_product', struct());

    ent = struct();
    ent.handle = raw;
    % Preferir id de producto STEP; si no hay, asset_id (no EQ posicional)
    if ~isempty(pid)
      ent.id = pid;
    else
      ent.id = aid;
    endif
    ent.id_estable = ent.id;
    ent.asset_id = aid;
    ent.tabla = 'equipos';
    ent.producto = nom;
    idx.por_handle.(safe) = ent;
    idx.items{end+1} = ent; %#ok<AGROW>
  endfor
endfunction
