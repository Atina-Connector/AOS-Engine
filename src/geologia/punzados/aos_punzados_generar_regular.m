function punzados = aos_punzados_generar_regular(md_inicio, md_fin, cantidad, opciones)
% AOS_PUNZADOS_GENERAR_REGULAR Genera intervalos regulares programaticos.
% opciones puede contener:
%   separacion_m, longitud_m, densidad_tpm, diametro_punzado_m,
%   id_prefijo, nombre_prefijo, activo, origen, fase_deg,
%   penetracion_m, permeabilidad_mD, skin y estado_validacion.

  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif
  [md_inicio, ok1] = aos_numero_seguro(md_inicio, NaN);
  [md_fin, ok2] = aos_numero_seguro(md_fin, NaN);
  [cantidad, ok3] = aos_numero_seguro(cantidad, NaN);
  if ~ok1 || ~ok2 || ~ok3 || ~isfinite(md_inicio) || ~isfinite(md_fin) || ...
     ~isfinite(cantidad) || md_inicio < 0 || md_fin <= md_inicio || ...
     cantidad < 1 || abs(cantidad-round(cantidad)) > 1e-9
    error('AOS Punzados: rango o cantidad invalida para generacion regular.');
  endif
  cantidad = round(cantidad);

  sep = opcion_num_local(opciones, 'separacion_m', 0);
  if ~isfinite(sep) || sep < 0, error('La separacion debe ser finita y no negativa.'); endif
  disponible = md_fin - md_inicio - (cantidad-1)*sep;
  if disponible <= 0, error('La separacion no deja longitud disponible para los tramos.'); endif
  longitud = opcion_num_local(opciones, 'longitud_m', disponible/cantidad);
  if ~isfinite(longitud) || longitud <= 0
    longitud = disponible/cantidad;
  endif
  requerido = cantidad*longitud + (cantidad-1)*sep;
  if requerido > md_fin-md_inicio + 1e-9
    error('La longitud y separacion exceden el rango MD disponible.');
  endif

  dens = opcion_num_local(opciones, 'densidad_tpm', 10);
  diam = opcion_num_local(opciones, 'diametro_punzado_m', 0.010);
  id_pref = opcion_txt_local(opciones, 'id_prefijo', ...
    opcion_txt_local(opciones,'prefijo_id','PUNZ'));
  nom_pref = opcion_txt_local(opciones, 'nombre_prefijo', ...
    opcion_txt_local(opciones,'prefijo_nombre','Tramo'));
  origen = opcion_txt_local(opciones, 'origen', 'GENERACION_REGULAR');
  activo = opcion_log_local(opciones, 'activo', true);
  fase = opcion_num_local(opciones, 'fase_deg', NaN);
  pen = opcion_num_local(opciones, 'penetracion_m', NaN);
  k = opcion_num_local(opciones, 'permeabilidad_mD', NaN);
  skin = opcion_num_local(opciones, 'skin', NaN);
  validacion = opcion_txt_local(opciones, 'estado_validacion', 'NO_VALIDADO');

  tramos = struct([]);
  cursor = md_inicio;
  for i = 1:cantidad
    t = struct('id',sprintf('%s-%03d',id_pref,i), ...
      'nombre',sprintf('%s %d',nom_pref,i), ...
      'MD_desde',cursor,'MD_hasta',cursor+longitud, ...
      'densidad_tpm',dens,'diametro_punzado_m',diam, ...
      'activo',activo,'fase_deg',fase,'penetracion_m',pen, ...
      'tipo_disparo','','formacion','','permeabilidad_mD',k, ...
      'skin',skin,'estado_validacion',validacion, ...
      'observaciones','','origen',origen,'extras',struct());
    if isempty(tramos), tramos=t; else, tramos(end+1)=t; endif
    cursor = cursor + longitud + sep;
  endfor
  [punzados, ~] = aos_punzados_normalizar(struct('tramos',tramos), ...
    struct('origen',origen));
endfunction

function v = opcion_num_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_numero_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
function v = opcion_txt_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_texto_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
function v = opcion_log_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_logico_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
