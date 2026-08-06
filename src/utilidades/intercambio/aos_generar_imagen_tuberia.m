function [ruta, estado] = aos_generar_imagen_tuberia(param, tipo, Ql, Qiny, carpeta)
% Genera la imagen comun de erosion, Turner y Taitel para el .aosrpt.
% Reutiliza el diagnostico de la corrida cuando existe. Si no existe,
% intenta calcularlo sin abrir figuras ni imprimir tablas.

  if nargin < 2 || isempty(tipo)
    tipo = 'AOS';
  endif
  if nargin < 3 || isempty(Ql)
    Ql = buscar_num_local(param, {'Ql','Q_liq','Qliq'}, 0);
  endif
  if nargin < 4 || isempty(Qiny)
    Qiny = buscar_num_local(param, {'Qiny','Q_iny','Qiny_plot'}, 0);
  endif
  if nargin < 5 || isempty(carpeta)
    carpeta = tempdir();
  endif

  ruta = '';
  estado = 'NO_DISPONIBLE';
  diag = diagnostico_local(param, tipo, Ql, Qiny);
  if isempty(diag) || ~isstruct(diag) || ~isfield(diag, 'perfil')
    return;
  endif

  ruta = [tempname(carpeta) '.png'];
  fig = [];
  try
    fig = plot_erosion_taitel(diag);
    if isempty(fig) || ~ishandle(fig)
      ruta = '';
      estado = 'NO_DISPONIBLE';
      return;
    endif
    set(fig, 'Visible', 'off');
    print(fig, '-dpng', '-r150', ruta);
    close(fig);
    fig = [];
    estado = 'OK';
  catch err
    if ~isempty(fig)
      try
        if ishandle(fig)
          close(fig);
        endif
      catch
      end_try_catch
    endif
    if exist(ruta, 'file') == 2
      delete(ruta);
    endif
    ruta = '';
    estado = ['ERROR_' limpiar_estado_local(err.message)];
  end_try_catch
endfunction

function diag = diagnostico_local(param, tipo, Ql, Qiny)
  diag = [];
  if isstruct(param) && isfield(param, 'diagnostico_tuberia') && ...
     isstruct(param.diagnostico_tuberia) && isfield(param.diagnostico_tuberia, 'perfil')
    diag = param.diagnostico_tuberia;
    return;
  endif

  global ULTIMO_DIAG_TUBERIA;
  if isstruct(ULTIMO_DIAG_TUBERIA) && isfield(ULTIMO_DIAG_TUBERIA, 'perfil')
    coincide = true;
    if isfield(ULTIMO_DIAG_TUBERIA, 'sistema') && ischar(ULTIMO_DIAG_TUBERIA.sistema)
      coincide = strcmpi(ULTIMO_DIAG_TUBERIA.sistema, tipo);
    endif
    if coincide
      diag = ULTIMO_DIAG_TUBERIA;
      return;
    endif
  endif

  if exist('diagnostico_tuberia_produccion', 'file') == 2
    opciones = struct();
    opciones.graficar = false;
    opciones.detalle = false;
    opciones.mostrar_tabla = false;
    try
      evalc('diag = diagnostico_tuberia_produccion(param, tipo, Ql, Qiny, opciones);');
    catch
      diag = [];
    end_try_catch
  endif
endfunction

function v = buscar_num_local(s, campos, defecto)
  v = defecto;
  if ~isstruct(s)
    return;
  endif
  for k = 1:numel(campos)
    if isfield(s, campos{k}) && isnumeric(s.(campos{k})) && ...
       ~isempty(s.(campos{k})) && isfinite(s.(campos{k})(1))
      v = s.(campos{k})(1);
      return;
    endif
  endfor
endfunction

function s = limpiar_estado_local(txt)
  if ~ischar(txt)
    txt = 'DESCONOCIDO';
  endif
  s = regexprep(txt, '[^A-Za-z0-9]+', '_');
  if isempty(s)
    s = 'DESCONOCIDO';
  endif
endfunction
