function salida = aos_preferencias_usuario(accion, valor)
% AOS_PREFERENCIAS_USUARIO Preferencias persistentes abiertas en JSON UTF-8.
%   p = aos_preferencias_usuario('cargar')
%   aos_preferencias_usuario('guardar', p)
%   p = aos_preferencias_usuario('restaurar')
  if nargin < 1 || isempty(accion), accion = 'cargar'; endif
  if nargin < 2, valor = []; endif
  ruta = ruta_local();
  switch lower(strtrim(accion))
    case 'ruta'
      salida = ruta;
    case 'defaults'
      salida = defaults_local();
    case 'cargar'
      salida = cargar_local(ruta);
    case 'guardar'
      if ~isstruct(valor), error('AOS: preferencias invalidas.'); endif
      prefs = fusionar_local(defaults_local(), valor);
      prefs.version = 'AOS_PREFS_JSON_1.0';
      prefs.formato = 'JSON_UTF8';
      prefs.fecha_modificacion = datestr(now, 'yyyy-mm-dd HH:MM:SS');
      guardar_json_local(ruta, prefs);
      salida = prefs;
    case 'restaurar'
      prefs = defaults_local();
      prefs.fecha_modificacion = datestr(now, 'yyyy-mm-dd HH:MM:SS');
      guardar_json_local(ruta, prefs);
      salida = prefs;
    otherwise
      error('AOS: accion de preferencias no reconocida: %s', accion);
  endswitch
endfunction

function prefs = cargar_local(ruta)
  base = defaults_local();
  if exist(ruta, 'file') ~= 2
    prefs = base;
    return;
  endif
  try
    s = leer_json_local(ruta);
    if isstruct(s)
      prefs = fusionar_local(base, s);
    else
      prefs = base;
    endif
  catch err
    warning('AOS: no se pudieron cargar preferencias JSON: %s', err.message);
    prefs = base;
  end_try_catch
endfunction

function guardar_json_local(ruta, prefs)
  if ~json_disponible_local('jsonencode') || ~json_disponible_local('jsondecode')
    error('AOS: GNU Octave requiere jsonencode/jsondecode para preferencias.');
  endif
  asegurar_carpeta_local(fileparts(ruta));
  texto = jsonencode(prefs);
  tmp = [ruta '.tmp'];
  fid = fopen(tmp, 'wt');
  if fid < 0, error('AOS: no se pudo crear %s', tmp); endif
  fprintf(fid, '%s\n', texto);
  fclose(fid);
  prueba = leer_json_local(tmp);
  if ~isstruct(prueba) || ~isfield(prueba, 'version')
    delete(tmp);
    error('AOS: preferencias JSON no validas.');
  endif
  if exist(ruta, 'file') == 2, delete(ruta); endif
  [ok, msg] = movefile(tmp, ruta);
  if ~ok, error('AOS: no se pudo guardar preferencias (%s)', msg); endif
endfunction

function s = leer_json_local(ruta)
  if ~json_disponible_local('jsondecode'), error('jsondecode no disponible'); endif
  fid = fopen(ruta, 'rt');
  if fid < 0, error('no se pudo abrir %s', ruta); endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
  s = jsondecode(raw);
endfunction

function tf = json_disponible_local(nombre)
  tf = (exist(nombre, 'builtin') == 5) || (exist(nombre, 'file') == 2);
endfunction

function p = defaults_local()
  p = struct();
  p.version = 'AOS_PREFS_JSON_1.0';
  p.formato = 'JSON_UTF8';
  p.fecha_modificacion = '';
  p.unidades = struct('sistema','METRICO_AOS','presion','bar','profundidad','m', ...
    'liquido','m3/d','gas','Sm3/d','temperatura','C','potencia','kW');
  p.solver = struct('modo_jgl','AUTOMATICO','max_iter_jgl',10, ...
    'tolerancia_relativa',0.01,'registrar_diagnostico',true);
  p.sensibilidades = struct('n_puntos',15,'modo_abreviado',false, ...
    'tratamiento_curva_default','DISCRETO','grado_polinomio_default',0, ...
    'grado_polinomio_max',5,'n_puntos_polinomio',201, ...
    'verificacion_selectiva',true);
  p.reportes = struct('formato_predeterminado','ENRIQUECIDO', ...
    'incluir_contexto_pozo',true,'incluir_survey',true,'codificar_preguntar',true);
  p.seguridad = struct('preguntar_codificacion',true,'aceptar_comandos_scada',false, ...
    'importacion_transaccional',true);
  p.economia = struct('moneda','USD','valor_petroleo_por_m3',0, ...
    'costo_gas_por_1000Sm3',0,'costo_fijo_diario',0, ...
    'costo_electricidad_por_kWh',0);
  p.catalogos = struct('usar_base_aos',true,'usar_usuario',true, ...
    'priorizar_embebidos_aosdat',true);
  p.scada = struct('intervalo_recepcion_s',60,'aplicar_datos_medidos',true, ...
    'aplicar_calibracion',true,'aplicar_comandos',false);
endfunction

function out = fusionar_local(base, extra)
  out = base;
  if ~isstruct(extra), return; endif
  campos = fieldnames(extra);
  for i = 1:numel(campos)
    c = campos{i};
    if isfield(out,c) && isstruct(out.(c)) && isstruct(extra.(c))
      out.(c) = fusionar_local(out.(c), extra.(c));
    else
      out.(c) = extra.(c);
    endif
  endfor
endfunction

function ruta = ruta_local()
  aqui = fileparts(mfilename('fullpath'));
  root = fileparts(fileparts(fileparts(aqui)));
  ruta = fullfile(root, 'datos_usuario', 'configuracion', 'preferencias_aos.json');
endfunction

function asegurar_carpeta_local(carpeta)
  if exist(carpeta,'dir') ~= 7
    [ok,msg] = mkdir(carpeta);
    if ~ok, error('AOS: no se pudo crear %s: %s', carpeta, msg); endif
  endif
endfunction
