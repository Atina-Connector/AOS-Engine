function carpeta = aos_report_choose_directory(carpeta_defecto)
% AOS_REPORT_CHOOSE_DIRECTORY Seleccion robusta de carpeta para informes.
% DEV5.3: carpeta estandar, navegador grafico o ruta manual.

  if nargin < 1 || ~ischar(carpeta_defecto) || isempty(strtrim(carpeta_defecto))
    carpeta_defecto = fullfile('intercambio', 'reportes', 'enviados');
  endif

  fprintf('\n--- CARPETA DE DESTINO DEL REPORTE ---\n');
  fprintf('  1 - Usar carpeta estandar: %s\n', carpeta_defecto);
  fprintf('  2 - Elegir carpeta con navegador de archivos\n');
  fprintf('  3 - Ingresar ruta manualmente\n');
  op = input('Seleccione una opcion [1]: ');
  if isempty(op), op = 1; endif
  if ~isscalar(op) || ~isfinite(op), op = 1; endif
  op = round(op);

  carpeta = carpeta_defecto;
  if op == 2
    [elegida, metodo] = elegir_graficamente_local(carpeta_defecto);
    if ischar(elegida) && ~isempty(strtrim(elegida)) && ~strcmp(elegida, '0')
      carpeta = strtrim(elegida);
      fprintf('Carpeta elegida mediante %s.\n', metodo);
    else
      fprintf('Seleccion cancelada o navegador no disponible.\n');
      fprintf('Se utilizara la carpeta estandar.\n');
    endif
  elseif op == 3
    entrada = strtrim(input(sprintf('Ruta de destino [%s]: ', carpeta_defecto), 's'));
    if ~isempty(entrada), carpeta = expandir_home_local(entrada); endif
  elseif op ~= 1
    fprintf('Opcion no valida. Se utilizara la carpeta estandar.\n');
  endif

  if exist(carpeta, 'dir') ~= 7
    [ok, msg] = mkdir(carpeta);
    if ~ok
      error('No se pudo crear la carpeta %s: %s', carpeta, msg);
    endif
  endif

  try
    canonica = canonicalize_file_name(carpeta);
    if ischar(canonica) && ~isempty(canonica), carpeta = canonica; endif
  catch
  end_try_catch
  fprintf('Carpeta seleccionada: %s\n', carpeta);
endfunction

function [elegida, metodo] = elegir_graficamente_local(inicial)
  elegida = '';
  metodo = 'navegador';

  % Primera opcion: selector nativo de GNU Octave.
  try
    if exist('uigetdir', 'file') == 2
      r = uigetdir(inicial, 'Seleccione carpeta para informes AOS');
      if ischar(r) && ~isempty(r) && ~strcmp(r, '0')
        elegida = r;
        metodo = 'uigetdir';
        return;
      endif
    endif
  catch err
    fprintf('El selector uigetdir no pudo abrirse: %s\n', err.message);
  end_try_catch

endfunction

function ruta = expandir_home_local(ruta)
  if ~ischar(ruta) || isempty(ruta), return; endif
  if ruta(1) == '~'
    h = getenv('HOME');
    if isempty(h), h = getenv('USERPROFILE'); endif
    if ~isempty(h)
      if numel(ruta) == 1
        ruta = h;
      elseif ruta(2) == '/' || ruta(2) == '\\'
        ruta = fullfile(h, ruta(3:end));
      endif
    endif
  endif
endfunction
