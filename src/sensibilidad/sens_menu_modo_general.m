function modo = sens_menu_modo_general(sistema, defecto)
% SENS_MENU_MODO_GENERAL Politica computacional para sensibilidades.
% SENS-GLJGL-01 cambia solo la politica GL: preciso por defecto y los
% modos reducidos quedan identificados como preliminares. Para BES y otros
% consumidores se conservan las opciones y etiquetas heredadas.
  if nargin < 1 || isempty(sistema), sistema = 'SENSIBILIDAD'; endif
  es_gl = strcmpi(strtrim(sistema), 'GL');
  if nargin < 2 || isempty(defecto)
    if es_gl
      defecto = 'preciso';
    else
      defecto = 'abreviado';
    endif
  endif
  opdef = opcion_local(defecto);

  fprintf('\n--- METODO DE CALCULO %s ---\n', upper(sistema));
  if es_gl
    fprintf('1 - Preciso uniforme: malla nodal completa [RESULTADO FINAL]\n');
    fprintf('2 - Simple uniforme: malla reducida [PRELIMINAR]\n');
    fprintf('3 - Hibrido seguro: todos los puntos se recalculan precisos [RESULTADO FINAL]\n');
    fprintf('4 - Abreviado uniforme: exploracion rapida [PRELIMINAR, SIN OPTIMO]\n');
  else
    fprintf('1 - Preciso: malla nodal completa\n');
    fprintf('2 - Simple: malla nodal reducida con refinamiento local\n');
    fprintf('3 - Hibrido: simple y control de extremos/optimo\n');
    fprintf('4 - Abreviado movil: puntos ancla + ajuste grado 4/5\n');
  endif

  op = input(sprintf('Seleccione metodo [%d]: ', opdef));
  if isempty(op), op = opdef; endif
  if op == 1
    modo = 'preciso';
  elseif op == 2
    modo = 'simple';
  elseif op == 3
    modo = 'hibrido';
  else
    modo = 'abreviado';
  endif
endfunction

function op = opcion_local(modo)
  modo = lower(strtrim(modo));
  if strcmp(modo,'preciso')
    op = 1;
  elseif strcmp(modo,'simple')
    op = 2;
  elseif strcmp(modo,'hibrido')
    op = 3;
  else
    op = 4;
  endif
endfunction
