function T = sens_menu_tratamiento_curva(sistema, defecto, forzado)
% SENS_MENU_TRATAMIENTO_CURVA Seleccion visible del tratamiento posterior.
% SENS-GLJGL-02 separa el solver fisico del ajuste polinomico. La opcion
% predeterminada es discreta y no ejecuta polyfit en forma oculta.
%
% forzado (opcional, para selftests):
%   struct('opcion',1|2|3|0,'grado',0|2|3|4|5,'n_grid',201)

  if nargin < 1 || isempty(sistema), sistema = 'SENSIBILIDAD'; endif
  if nargin < 2 || isempty(defecto), defecto = 'DISCRETO'; endif
  if nargin < 3 || ~isstruct(forzado), forzado = struct(); endif

  prefs = struct();
  try
    prefs = aos_preferencias_usuario('cargar');
  catch
    prefs = struct();
  end_try_catch

  if isfield(prefs,'sensibilidades') && isstruct(prefs.sensibilidades)
    ps = prefs.sensibilidades;
  else
    ps = struct();
  endif

  if isfield(ps,'tratamiento_curva_default') && ischar(ps.tratamiento_curva_default)
    defecto = ps.tratamiento_curva_default;
  endif
  opdef = opcion_local(defecto);
  if isfield(forzado,'opcion') && isnumeric(forzado.opcion) && isscalar(forzado.opcion)
    op = forzado.opcion;
  else
    marcas = {'','',''};
    if opdef >= 1 && opdef <= 3, marcas{opdef} = ' [PREDETERMINADO]'; endif
    fprintf('\n--- TRATAMIENTO DE LA CURVA %s ---\n', upper(sistema));
    fprintf('1 - Discreto, sin armonizacion%s\n', marcas{1});
    fprintf('    Usa exclusivamente puntos calculados por el solver.\n');
    fprintf('2 - Armonizacion polinomica informativa%s\n', marcas{2});
    fprintf('    Superpone la curva; no reemplaza el optimo oficial.\n');
    fprintf('3 - Armonizacion polinomica con optimo verificado%s\n', marcas{3});
    fprintf('    Estima por derivada cero y recalcula con el solver fisico.\n');
    fprintf('0 - Cancelar sensibilidad\n');
    if exist('aos_leer_opcion','file') == 2
      op = aos_leer_opcion(sprintf('Seleccione tratamiento [%d]: ', opdef), opdef);
    else
      txt = strtrim(input(sprintf('Seleccione tratamiento [%d]: ', opdef), 's'));
      if isempty(txt), op = opdef; else, op = str2double(txt); endif
    endif
  endif

  if ~(isnumeric(op) && isscalar(op) && isfinite(op)), op = opdef; endif
  op = round(op);
  if ~ismember(op,[0 1 2 3]), op = opdef; endif

  T = struct();
  T.schema = 'AOS_CURVE_TREATMENT_1.0';
  T.hotfix = 'SENS-GLJGL-02';
  T.sistema = upper(strtrim(sistema));
  T.oculto = false;
  T.fuente = 'SELECCION_USUARIO';
  T.cancelado = (op == 0);
  T.habilitado = (op == 2 || op == 3);
  T.usar_polinomio = T.habilitado;
  T.usar_para_recomendacion = (op == 3);
  T.verificar_optimo = (op == 3);
  T.grado_solicitado = NaN;
  T.grado_maximo = 5;
  T.n_grid = 201;
  T.extrapolacion = false;
  T.modo = 'DISCRETO';
  T.descripcion = 'Puntos fisicos del solver; sin polyfit.';

  if T.cancelado
    T.modo = 'CANCELADO';
    T.descripcion = 'Sensibilidad cancelada por el usuario.';
    return;
  elseif op == 2
    T.modo = 'POLINOMICO_INFORMATIVO';
    T.descripcion = 'Curva polinomica derivada; el optimo oficial permanece discreto.';
  elseif op == 3
    T.modo = 'POLINOMICO_VERIFICADO';
    T.descripcion = 'Optimo estimado por derivada cero y verificado con corrida fisica.';
  endif

  if isfield(ps,'grado_polinomio_max') && isnumeric(ps.grado_polinomio_max) && ...
      isscalar(ps.grado_polinomio_max) && isfinite(ps.grado_polinomio_max)
    T.grado_maximo = max(2, min(5, round(ps.grado_polinomio_max)));
  endif
  if isfield(ps,'n_puntos_polinomio') && isnumeric(ps.n_puntos_polinomio) && ...
      isscalar(ps.n_puntos_polinomio) && isfinite(ps.n_puntos_polinomio)
    T.n_grid = max(101, min(2001, round(ps.n_puntos_polinomio)));
  endif
  if mod(T.n_grid,2) == 0, T.n_grid = T.n_grid + 1; endif
  if isfield(forzado,'n_grid') && isnumeric(forzado.n_grid) && isscalar(forzado.n_grid) && isfinite(forzado.n_grid)
    T.n_grid = max(51, min(5001, round(forzado.n_grid)));
    if mod(T.n_grid,2) == 0, T.n_grid = T.n_grid + 1; endif
  endif

  if T.habilitado
    grado_def = 0;
    if isfield(ps,'grado_polinomio_default') && isnumeric(ps.grado_polinomio_default) && ...
        isscalar(ps.grado_polinomio_default) && isfinite(ps.grado_polinomio_default)
      grado_def = round(ps.grado_polinomio_default);
    endif
    grado_forzado = [];
    if isfield(forzado,'grado'), grado_forzado = forzado.grado; endif
    T.grado_solicitado = sens_seleccionar_grado_polinomio(grado_def, T.grado_maximo, grado_forzado);
  endif

  fprintf('Tratamiento seleccionado: %s\n', T.modo);
  if T.habilitado
    if T.grado_solicitado == 0
      fprintf('Grado solicitado: AUTOMATICO CONTROLADO (maximo %d)\n', T.grado_maximo);
    else
      fprintf('Grado solicitado: %d\n', T.grado_solicitado);
    endif
    fprintf('El polinomio es derivado y no modifica los puntos del solver.\n');
  endif
endfunction

function op = opcion_local(modo)
  op = 1;
  if isnumeric(modo) && isscalar(modo) && isfinite(modo)
    op = round(modo);
    if ~ismember(op,[0 1 2 3]), op = 1; endif
    return;
  endif
  if ~ischar(modo), return; endif
  m = upper(strtrim(modo));
  if any(strcmp(m,{'POLINOMICO_INFORMATIVO','INFORMATIVO','POLY_INFO'}))
    op = 2;
  elseif any(strcmp(m,{'POLINOMICO_VERIFICADO','VERIFICADO','POLY_VERIFIED'}))
    op = 3;
  elseif strcmp(m,'CANCELADO')
    op = 0;
  else
    op = 1;
  endif
endfunction
