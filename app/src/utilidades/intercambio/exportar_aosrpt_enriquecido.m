function exportar_aosrpt_enriquecido(param, Ql, Qo, Qiny, tipo, archivo_salida)
% Exporta .aosrpt enriquecido para GNU Octave.
% Orden final de graficos:
% 1) Analisis nodal
% 2) Diagnostico Taitel/Turner/erosion
% 3) Survey 2D actual
% 4) Survey 3D con punzados
% 5) Punzados 2D
% 6) Aporte por punzados (si existe)

  exportacion_interactiva = (nargin < 6 || isempty(archivo_salida));
  carpeta = fullfile('intercambio', 'reportes', 'enviados');
  if exist(carpeta, 'dir') ~= 7
    mkdir(carpeta);
  endif

  global AOSDAT_ACTIVO;
  if exportacion_interactiva
    if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
      defecto = [AOSDAT_ACTIVO '_enriquecido.aosrpt'];
    else
      defecto = 'reporte_enriquecido.aosrpt';
    endif
    archivo_salida = aos_elegir_nombre_reporte(carpeta, defecto);
  else
    [ruta, nombre, ext] = fileparts(archivo_salida);
    if isempty(ext)
      ext = '.aosrpt';
    endif
    if isempty(ruta)
      archivo_salida = fullfile(carpeta, [nombre ext]);
    endif
  endif

  snap = aos_preparar_snapshot_reporte(param, Ql, Qo, Qiny, tipo);
  param = snap.param;
  param.aosrpt_omitir_crypto = true;
  param.aosrpt_omitir_mensaje = true;
  param.aosrpt_es_enriquecido = true;

  graficos = struct('id', {}, 'titulo', {}, 'seccion', {}, 'estado', {}, 'base64', {});

  [ruta_img, estado, id, titulo] = generar_principal_local(param, Ql, Qo, tipo, carpeta);
  graficos(end+1) = entrada_local(id, titulo, 'RESULTADOS', estado, ruta_img);
  borrar_local(ruta_img);

  [ruta_img, estado] = aos_generar_imagen_tuberia(param, tipo, Ql, Qiny, carpeta);
  graficos(end+1) = entrada_local('taitel_tuberia', ...
      'Diagnostico de tuberia: Taitel, Turner y erosion', 'DIAGNOSTICO_TUBERIA', estado, ruta_img);
  borrar_local(ruta_img);

  incluir_viewer = true;
  if isfield(param, 'aosrpt_incluir_contexto_viewer')
    incluir_viewer = logical(param.aosrpt_incluir_contexto_viewer);
  endif

  if incluir_viewer
    [ruta_img, estado] = aos_generar_imagen_survey(param, tipo, carpeta);
  else
    ruta_img = ''; estado = 'EXCLUIDO_POR_USUARIO';
  endif
  graficos(end+1) = entrada_local('survey_2d', 'Survey 2D actual', 'SURVEY', estado, ruta_img);
  borrar_local(ruta_img);

  if incluir_viewer
    [ruta_img, estado] = aos_generar_imagen_survey_3d_punzados(param, tipo, carpeta);
  else
    ruta_img = ''; estado = 'EXCLUIDO_POR_USUARIO';
  endif
  graficos(end+1) = entrada_local('survey_3d_punzados', 'Survey 3D con punzados marcados', 'SURVEY', estado, ruta_img);
  borrar_local(ruta_img);

  if incluir_viewer
    [ruta_img, estado] = aos_generar_imagen_punzados(param, tipo, carpeta);
  else
    ruta_img = ''; estado = 'EXCLUIDO_POR_USUARIO';
  endif
  graficos(end+1) = entrada_local('punzados_2d', 'Punzados - vista 2D de intervalos', 'PUNZADOS', estado, ruta_img);
  borrar_local(ruta_img);

  if incluir_viewer
    [ruta_img, estado] = aos_generar_imagen_aporte_punzados(param, Ql, carpeta);
  else
    ruta_img = ''; estado = 'EXCLUIDO_POR_USUARIO';
  endif
  graficos(end+1) = entrada_local('punzados_aporte', ...
      'Aporte distribuido por punzados', 'PUNZADOS', estado, ruta_img);
  borrar_local(ruta_img);

  if strcmpi(tipo,'GL') && isfield(param,'mandriles_resultado') && isstruct(param.mandriles_resultado)
    [ruta_img, estado] = generar_mandriles_local(param.mandriles_resultado, carpeta);
    graficos(end+1) = entrada_local('diseno_mandriles', ...
      'Diseno y espaciamiento de mandriles', 'MANDRILES', estado, ruta_img);
    borrar_local(ruta_img);
  endif

  estados={graficos.estado};
  param.aosrpt_graficos_count=sum(strcmpi(estados,'OK'));
  exportar_aosrpt(param, Ql, Qo, Qiny, tipo, archivo_salida);

  fid = fopen(archivo_salida, 'a');
  if fid < 0
    error('No se pudo reabrir el reporte enriquecido: %s', archivo_salida);
  endif
  try
    aos_rpt_escribir_graficos(fid, graficos);
    fclose(fid);
  catch err
    fclose(fid);
    rethrow(err);
  end_try_catch

  [codificado, ~] = aos_finalizar_archivo_crypto(archivo_salida, exportacion_interactiva);
  fprintf('\nReporte enriquecido exportado: %s\n', archivo_salida);
  if codificado
    fprintf('Proteccion: CODIFICADO\n');
  else
    fprintf('Proteccion: TEXTO PLANO\n');
  endif
  info = dir(archivo_salida);
  if ~isempty(info)
    fprintf('Tamano final: %.1f KB\n', info.bytes / 1024);
  endif
  imprimir_resumen_graficos_local(graficos);
endfunction

function [ruta, estado, id, titulo] = generar_principal_local(param, Ql, Qo, tipo, carpeta)
  ruta = [tempname(carpeta) '.png'];
  estado = 'NO_DISPONIBLE';
  id = 'nodal';
  titulo = 'Analisis nodal';
  fig = [];
  try
    if strcmpi(tipo, 'BM') && isfield(param, 'diagnostico_gibbs') && ...
       isstruct(param.diagnostico_gibbs)
      id = 'cartas_gibbs';
      titulo = 'Cartas dinamometricas BM';
      d = param.diagnostico_gibbs;
      fig = figure('Visible', 'off', 'Position', [100 100 1050 720]);
      subplot(2,1,1);
      plot(d.carta_sup(:,1), d.carta_sup(:,2) / 1000, '-');
      grid on;
      xlabel('Posicion superficie (m)');
      ylabel('Carga (kN)');
      title('Carta BM superficie');
      subplot(2,1,2);
      plot(d.carta_fondo(:,1), d.carta_fondo(:,2) / 1000, '-');
      grid on;
      xlabel('Posicion fondo (m)');
      ylabel('Carga (kN)');
      title('Carta BM fondo');
    elseif strcmpi(tipo, 'BES')
      id = 'nodal_bes';
      titulo = 'Analisis nodal BES';
      plot_nodal_BES(param, Ql);
      fig = gcf();
    elseif strcmpi(tipo, 'JGL')
      sol = [];
      if isfield(param, 'sol_jgl')
        sol = param.sol_jgl;
      elseif isfield(param, 'JGL_resultado')
        sol = param.JGL_resultado;
      endif
      id = 'nodal';
      titulo = 'Analisis nodal JGL';
      if (!strcmpi(getenv("AOS_GRAPHICS_MODE"), "off"))
        plot_nodal(param, Ql, 'JGL', sol);
      else
        fprintf("Grafico nodal omitido: modo CLI.\n");
      endif
      fig = gcf();
    elseif strcmpi(tipo, 'GL')
      id = 'nodal';
      titulo = 'Analisis nodal GL';
      if (!strcmpi(getenv("AOS_GRAPHICS_MODE"), "off"))
        plot_nodal(param, Ql, 'GL');
      else
        fprintf("Grafico nodal omitido: modo CLI.\n");
      endif
      fig = gcf();
    else
      id = 'resumen';
      titulo = ['Resumen ' upper(tipo)];
      fig = figure('Visible', 'off');
      bar([Ql, Qo] * 86400);
      set(gca, 'XTickLabel', {'Ql','Qo'});
      ylabel('m3/d');
      title(titulo);
      grid on;
    endif

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

function [ruta, estado] = generar_mandriles_local(R, carpeta)
  ruta=[tempname(carpeta) '.png']; estado='NO_DISPONIBLE'; h=[];
  try
    h=mandriles_plot_v2(R); set(h,'Visible','off'); print(h,'-dpng','-r150',ruta); close(h); estado='OK';
  catch err
    if ~isempty(h), try, close(h); catch, end_try_catch, endif
    if exist(ruta,'file')==2, delete(ruta); endif
    ruta=''; estado=['ERROR_' limpiar_estado_local(err.message)];
  end_try_catch
endfunction

function g = entrada_local(id, titulo, seccion, estado, ruta)
  g = struct();
  g.id = id;
  g.titulo = titulo;
  g.seccion = seccion;
  g.estado = estado;
  g.base64 = '';
  if ischar(ruta) && ~isempty(ruta) && exist(ruta, 'file') == 2 && strcmpi(estado, 'OK')
    g.base64 = archivo_base64_local(ruta);
    if isempty(g.base64)
      g.estado = 'ERROR_BASE64';
    endif
  endif
endfunction

function txt = archivo_base64_local(ruta)
  txt = '';
  fid = fopen(ruta, 'rb');
  if fid < 0
    return;
  endif
  bytes = fread(fid, Inf, 'uint8=>uint8');
  fclose(fid);
  try
    txt = base64_encode(bytes);
  catch
    txt = '';
  end_try_catch
endfunction

function borrar_local(ruta)
  if ischar(ruta) && ~isempty(ruta) && exist(ruta, 'file') == 2
    delete(ruta);
  endif
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

function imprimir_resumen_graficos_local(graficos)
  fprintf('Imagenes enriquecidas:\n');
  for i = 1:numel(graficos)
    fprintf('  %-22s : %s\n', graficos(i).id, graficos(i).estado);
  endfor
endfunction
