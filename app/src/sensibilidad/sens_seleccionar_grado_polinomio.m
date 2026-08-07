function grado = sens_seleccionar_grado_polinomio(defecto, maximo, forzado)
% SENS_SELECCIONAR_GRADO_POLINOMIO Seleccion explicita del grado de ajuste.
% SENS-GLJGL-02: el polinomio nunca se activa ni cambia de grado en forma
% oculta. El grado 5 historico de AOS permanece disponible como opcion.

  if nargin < 1 || isempty(defecto), defecto = 0; endif
  if nargin < 2 || isempty(maximo), maximo = 5; endif
  if nargin < 3, forzado = []; endif

  maximo = max(2, min(5, round(maximo)));
  if ~(isnumeric(defecto) && isscalar(defecto) && isfinite(defecto))
    defecto = 0;
  endif
  defecto = round(defecto);
  if defecto ~= 0 && (defecto < 2 || defecto > maximo)
    defecto = 0;
  endif

  fprintf('\n--- GRADO DEL POLINOMIO ---\n');
  fprintf('0 - Automatico controlado [RECOMENDADO]\n');
  fprintf('2 - Cuadratico\n');
  if maximo >= 3, fprintf('3 - Cubico\n'); endif
  if maximo >= 4, fprintf('4 - Cuartico\n'); endif
  if maximo >= 5, fprintf('5 - Quintico [HISTORICO AOS]\n'); endif

  if ~isempty(forzado)
    op = forzado;
  elseif exist('aos_leer_opcion','file') == 2
    op = aos_leer_opcion(sprintf('Seleccione grado [%d]: ', defecto), defecto);
  else
    txt = strtrim(input(sprintf('Seleccione grado [%d]: ', defecto), 's'));
    if isempty(txt), op = defecto; else, op = str2double(txt); endif
  endif

  if ~(isnumeric(op) && isscalar(op) && isfinite(op))
    op = defecto;
  endif
  op = round(op);
  if op ~= 0 && (op < 2 || op > maximo)
    fprintf('Grado no valido; se utiliza automatico controlado.\n');
    op = 0;
  endif
  grado = op;
endfunction
