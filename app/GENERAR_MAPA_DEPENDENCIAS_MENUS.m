function resultado = GENERAR_MAPA_DEPENDENCIAS_MENUS(varargin)
% GENERAR_MAPA_DEPENDENCIAS_MENUS Genera el manifiesto navegable de menus AOS.
%
% Uso interactivo:
%   GENERAR_MAPA_DEPENDENCIAS_MENUS
%
% Uso no interactivo:
%   GENERAR_MAPA_DEPENDENCIAS_MENUS('ruta/salida')
%   GENERAR_MAPA_DEPENDENCIAS_MENUS('ruta/salida', 'txt')
%   GENERAR_MAPA_DEPENDENCIAS_MENUS('ruta/salida', 'md')
%   GENERAR_MAPA_DEPENDENCIAS_MENUS('ruta/salida', 'both')

  raiz = fileparts(mfilename('fullpath'));
  addpath(fullfile(raiz, 'src', 'tools', 'menu_map'), '-begin');
  addpath(fullfile(raiz, 'src'), '-begin');

  salida_default = fullfile(raiz, 'datos', 'interfaz');

  if nargin >= 1 && ~isempty(varargin{1})
    salida = varargin{1};
  else
    fprintf('\n===== GENERADOR DE MAPA DE MENUS AOS =====\n');
    fprintf('Carpeta predeterminada: %s\n', salida_default);
    fprintf('\nDestino de guardado:\n');
    fprintf('  1 - Usar carpeta predeterminada\n');
    fprintf('  2 - Elegir carpeta con navegador de archivos\n');
    fprintf('  3 - Escribir ruta manualmente\n');
    op_destino = input('Seleccione destino [1]: ');
    if isempty(op_destino), op_destino = 1; endif

    if op_destino == 2
      salida = seleccionar_carpeta_local(salida_default);
    elseif op_destino == 3
      salida = input('Ingrese la ruta de la carpeta de salida: ', 's');
      salida = strtrim(salida);
      if isempty(salida), salida = salida_default; endif
    else
      salida = salida_default;
    endif
  endif

  if nargin >= 2 && ~isempty(varargin{2})
    formato = lower(strtrim(varargin{2}));
  else
    fprintf('\nFormato del informe legible:\n');
    fprintf('  1 - TXT\n');
    fprintf('  2 - Markdown (.md)\n');
    fprintf('  3 - Ambos [predeterminado]\n');
    op = input('Seleccione formato [3]: ');
    if isempty(op), op = 3; endif
    if op == 1
      formato = 'txt';
    elseif op == 2
      formato = 'md';
    else
      formato = 'both';
    endif
  endif

  resultado = aos_generar_mapa_menus(raiz, salida, formato);
endfunction

function carpeta = seleccionar_carpeta_local(carpeta_default)
% Usa el navegador grafico de carpetas cuando esta disponible.
% Si la interfaz grafica no esta disponible, permite escribir la ruta.
  carpeta = '';
  try
    if exist('uigetdir', 'file') == 2 || exist('uigetdir', 'builtin') == 5
      seleccion = uigetdir(carpeta_default, ...
        'Seleccione la carpeta donde guardar el mapa de menus AOS');
      if isnumeric(seleccion) && isequal(seleccion, 0)
        fprintf('Seleccion cancelada. Se usara la carpeta predeterminada.\n');
        carpeta = carpeta_default;
      elseif ischar(seleccion)
        carpeta = seleccion;
      endif
    endif
  catch err
    fprintf('No se pudo abrir el navegador de carpetas: %s\n', err.message);
  end_try_catch

  if isempty(carpeta)
    fprintf('El navegador grafico no esta disponible en esta sesion de Octave.\n');
    carpeta = input(sprintf('Ruta de salida [%s]: ', carpeta_default), 's');
    carpeta = strtrim(carpeta);
    if isempty(carpeta), carpeta = carpeta_default; endif
  endif
endfunction
