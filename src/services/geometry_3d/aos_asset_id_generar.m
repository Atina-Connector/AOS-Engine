function [asset_id, clave, adv] = aos_asset_id_generar(asset_type, fila, tabla, opciones)
% AOS_ASSET_ID_GENERAR Identidad determinista AOS-<TIPO>-<hash8>.
%
% [asset_id, clave, adv] = aos_asset_id_generar(asset_type, fila, tabla, opciones)
% Tipos: NODO|TRAMO|EQUIPO|VALVULA|ACCESORIO|BC|CAMARA|RAMAL|ACCESO|STEP_PRODUCT

  asset_id = '';
  clave = '';
  adv = '';

  if nargin < 4 || isempty(opciones), opciones = struct(); endif
  if nargin < 3, tabla = ''; endif
  if nargin < 2, fila = struct(); endif
  if nargin < 1 || isempty(asset_type)
    asset_type = 'NODO';
  endif

  tipo = upper(strtrim(char(asset_type)));
  tipos_ok = {'NODO', 'TRAMO', 'EQUIPO', 'VALVULA', 'ACCESORIO', ...
              'BC', 'CAMARA', 'RAMAL', 'ACCESO', 'STEP_PRODUCT'};
  if ~any(strcmp(tipo, tipos_ok))
    adv = 'ASSET_TIPO_DESCONOCIDO';
    % Se acepta el tipo declarado para no bloquear; queda auditable en adv
  endif

  if isempty(tabla)
    tabla = tabla_desde_tipo_local(tipo);
  endif

  [clave, ~, adv_clave] = aos_asset_clave_estable(fila, tabla, opciones);
  if ~isempty(adv_clave)
    adv = adv_clave;
  endif

  % Hash de tipo + clave (misma entrada => mismo asset_id en cualquier sesion)
  texto = [tipo '|' clave];
  h8 = aos_asset_hash(texto, 8);
  asset_id = sprintf('AOS-%s-%s', tipo, h8);
endfunction

function tabla = tabla_desde_tipo_local(tipo)
  switch tipo
    case 'NODO', tabla = 'nodos';
    case 'TRAMO', tabla = 'tramos';
    case 'EQUIPO', tabla = 'equipos';
    case 'VALVULA', tabla = 'valvulas';
    case 'ACCESORIO', tabla = 'accesorios';
    case 'BC', tabla = 'condiciones_borde';
    case 'CAMARA', tabla = 'camaras';
    case 'RAMAL', tabla = 'ramales';
    case 'ACCESO', tabla = 'accesos';
    case 'STEP_PRODUCT', tabla = 'step_product';
    otherwise, tabla = '';
  endswitch
endfunction
