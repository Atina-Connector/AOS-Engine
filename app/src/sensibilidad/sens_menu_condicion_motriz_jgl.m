function [p, info] = sens_menu_condicion_motriz_jgl(p, contexto)
% SENS_MENU_CONDICION_MOTRIZ_JGL Seleccion visible de presion motriz.
% SENS-GLJGL-03. Se usa antes de congelar el snapshot de sensibilidad.

  if nargin < 1 || ~isstruct(p), p = struct(); endif
  if nargin < 2 || isempty(contexto), contexto = 'JGL'; endif
  p = jgl_defaults(p);

  psup = numero_local(p,'P_iny_sup',NaN);
  if ~isfield(p,'P_iny_sup_importada_original') || ...
      ~isnumeric(p.P_iny_sup_importada_original) || isempty(p.P_iny_sup_importada_original)
    p.P_iny_sup_importada_original = psup;
  endif
  hay_presion = isfinite(psup) && psup > 0;
  info = struct('cancelado',false,'contexto',contexto,'opcion',NaN, ...
    'modo','NO_DEFINIDO','P_iny_sup_original_Pa',psup, ...
    'P_iny_sup_efectiva_Pa',psup,'mensaje','');

  fprintf('\n--- CONDICION MOTRIZ JGL - SENS-GLJGL-03 ---\n');
  fprintf('Contexto: %s\n', contexto);
  if hay_presion
    fprintf('Presion superficial informada: %.3f bar\n', psup/1e5);
    fprintf(' 1 - Usar la presion disponible y verificar cada Qiny [PREDETERMINADO]\n');
    fprintf(' 2 - Derivar la presion minima desde Qiny y comparar con la disponible\n');
    fprintf(' 3 - Ingresar otra presion superficial disponible\n');
    fprintf(' 0 - Cancelar sensibilidad\n');
    op = input('Seleccione [1]: ');
    if isempty(op), op = 1; endif
  else
    fprintf('El caso no contiene una presion de inyeccion positiva.\n');
    fprintf('Para un barrido con Qiny forzado, el cero no se reemplaza en forma oculta.\n');
    fprintf(' 1 - Derivar la presion minima requerida desde Qiny y la tobera [RECOMENDADO]\n');
    fprintf(' 2 - Ingresar una presion superficial disponible y verificar factibilidad\n');
    fprintf(' 3 - Confirmar que no existe presion motriz (JGL no factible)\n');
    fprintf(' 0 - Cancelar sensibilidad\n');
    op = input('Seleccione [1]: ');
    if isempty(op), op = 1; endif
  endif

  if op == 0
    info.cancelado = true;
    info.opcion = 0;
    info.modo = 'CANCELADO';
    return;
  endif

  if hay_presion
    if op == 2
      p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
      p.jgl_presion_sup_estado = 'INFORMADA_PARA_COMPARACION';
      info.mensaje = 'Se deriva la presion requerida y se compara con la disponible.';
    elseif op == 3
      [p, ok] = ingresar_presion_local(p);
      if ~ok
        info.cancelado = true;
        info.modo = 'CANCELADO';
        return;
      endif
      p.jgl_condicion_motriz_modo = 'PRESION_DISPONIBLE';
      p.jgl_presion_sup_estado = 'INFORMADA_MANUAL';
      info.mensaje = 'Se verifica el Qiny contra la nueva presion disponible.';
    else
      op = 1;
      p.jgl_condicion_motriz_modo = 'PRESION_DISPONIBLE';
      p.jgl_presion_sup_estado = 'INFORMADA_CASO';
      info.mensaje = 'Se usa la presion disponible del caso.';
    endif
  else
    if op == 2
      [p, ok] = ingresar_presion_local(p);
      if ~ok
        info.cancelado = true;
        info.modo = 'CANCELADO';
        return;
      endif
      p.jgl_condicion_motriz_modo = 'PRESION_DISPONIBLE';
      p.jgl_presion_sup_estado = 'INFORMADA_MANUAL';
      info.mensaje = 'Se verifica el Qiny contra la presion ingresada.';
    elseif op == 3
      p.jgl_condicion_motriz_modo = 'SIN_PRESION_MOTRIZ';
      p.jgl_presion_sup_estado = 'CERO_FISICO_CONFIRMADO';
      info.mensaje = 'Se confirmo ausencia de presion motriz; los puntos JGL seran no factibles.';
    else
      op = 1;
      p.jgl_condicion_motriz_modo = 'DERIVADA_DESDE_QINY';
      p.jgl_presion_sup_estado = 'NO_INFORMADA_DERIVAR_DESDE_QINY';
      info.mensaje = 'Se deriva la presion minima requerida para cada Qiny.';
    endif
  endif

  p = jgl_defaults(p);
  info.opcion = op;
  info.modo = jgl_modo_condicion_motriz(p);
  info.P_iny_sup_efectiva_Pa = numero_local(p,'P_iny_sup',NaN);
  fprintf('Modo motriz seleccionado: %s\n', info.modo);
  fprintf('%s\n', info.mensaje);
endfunction

function [p, ok] = ingresar_presion_local(p)
  ok = false;
  actual = numero_local(p,'P_iny_sup',0) / 1e5;
  if ~isfinite(actual) || actual <= 0, actual = 50; endif
  v = input(sprintf('Presion superficial disponible (bar) [%.2f]: ', actual));
  if isempty(v), v = actual; endif
  if ~isnumeric(v) || isempty(v) || ~isfinite(v(1)) || v(1) <= 0
    fprintf(2,'La presion debe ser finita y positiva. Se cancela la seleccion motriz.\n');
    return;
  endif
  p.P_iny_sup = double(v(1)) * 1e5;
  ok = true;
endfunction

function v = numero_local(s,c,d)
  v = d;
  if isstruct(s) && isfield(s,c)
    x = s.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = double(x(1)); endif
  endif
endfunction
