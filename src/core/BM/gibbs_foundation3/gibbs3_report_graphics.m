function graficos = gibbs3_report_graphics(contexto)
% GIBBS3_REPORT_GRAPHICS Captura las tres ventanas GF3 y contexto del pozo.

  graficos = struct('id', {}, 'titulo', {}, 'seccion', {}, 'estado', {}, 'base64', {});
  res = contexto.resultado;
  carpeta = fileparts(tempname());
  handles = [];
  regenerados = false;

  if isfield(res, 'figuras') && isnumeric(res.figuras)
    handles = res.figuras(:)';
  end
  handles = handles_validos_local(handles);

  if isempty(handles)
    try
      handles = gibbs3_plot(res);
      handles = handles_validos_local(handles);
      regenerados = true;
      for i = 1:numel(handles)
        try, set(handles(i), 'Visible', 'off'); catch, end
      end
    catch err
      graficos(end+1) = entrada_estado_local('gf3_graficas', ...
        'Graficas GF3', 'GF3', ['ERROR_' limpiar_estado_local(err.message)]);
      handles = [];
    end
  end

  ids = {'gf3_cartas_transmision', 'gf3_sarta_espaciamiento', 'gf3_aparato_bombeo'};
  titulos = {'GF3 - cartas, transmision y cargas', ...
    'GF3 - sarta, barras de peso y espaciamiento', ...
    'GF3 - cinematica, torque y potencia del aparato'};
  secciones = {'GF3_CARTAS', 'GF3_DISENO', 'GF3_APARATO'};

  for i = 1:3
    if i <= numel(handles)
      graficos(end+1) = capturar_figura_local(handles(i), ids{i}, ...
        titulos{i}, secciones{i}, carpeta);
    else
      graficos(end+1) = entrada_estado_local(ids{i}, titulos{i}, ...
        secciones{i}, 'NO_DISPONIBLE');
    end
  end

  if regenerados
    for i = 1:numel(handles)
      try
        if ishandle(handles(i)), close(handles(i)); end
      catch
      end
    end
  end

  incluir = true;
  if isfield(contexto.param, 'aosrpt_incluir_contexto_viewer')
    incluir = logical(contexto.param.aosrpt_incluir_contexto_viewer);
  end
  if incluir
    graficos = agregar_contexto_local(graficos, contexto, carpeta);
  else
    graficos(end+1) = entrada_estado_local('survey_2d', ...
      'Survey 2D actual', 'SURVEY', 'EXCLUIDO_POR_USUARIO');
    graficos(end+1) = entrada_estado_local('survey_3d_punzados', ...
      'Survey 3D con punzados', 'SURVEY', 'EXCLUIDO_POR_USUARIO');
    graficos(end+1) = entrada_estado_local('punzados_2d', ...
      'Punzados - intervalos', 'PUNZADOS', 'EXCLUIDO_POR_USUARIO');
  end
end

function graficos = agregar_contexto_local(graficos, contexto, carpeta)
  p = contexto.param;
  [ruta, estado] = generar_seguro_local('aos_generar_imagen_survey', ...
    {p, 'BM', carpeta});
  graficos(end+1) = entrada_archivo_local('survey_2d', 'Survey 2D actual', ...
    'SURVEY', estado, ruta);
  borrar_local(ruta);

  [ruta, estado] = generar_seguro_local('aos_generar_imagen_survey_3d_punzados', ...
    {p, 'BM', carpeta});
  graficos(end+1) = entrada_archivo_local('survey_3d_punzados', ...
    'Survey 3D con punzados', 'SURVEY', estado, ruta);
  borrar_local(ruta);

  [ruta, estado] = generar_seguro_local('aos_generar_imagen_punzados', ...
    {p, 'BM', carpeta});
  graficos(end+1) = entrada_archivo_local('punzados_2d', ...
    'Punzados - intervalos', 'PUNZADOS', estado, ruta);
  borrar_local(ruta);

  [ruta, estado] = generar_seguro_local('aos_generar_imagen_aporte_punzados', ...
    {p, contexto.Ql, carpeta});
  graficos(end+1) = entrada_archivo_local('punzados_aporte', ...
    'Aporte distribuido por punzados', 'PUNZADOS', estado, ruta);
  borrar_local(ruta);
end

function [ruta, estado] = generar_seguro_local(nombre_funcion, args)
  ruta = '';
  estado = 'NO_DISPONIBLE';
  if exist(nombre_funcion, 'file') ~= 2, return; end
  try
    [ruta, estado] = feval(nombre_funcion, args{:});
  catch err
    ruta = '';
    estado = ['ERROR_' limpiar_estado_local(err.message)];
  end
end

function g = capturar_figura_local(h, id, titulo, seccion, carpeta)
  ruta = [tempname(carpeta) '.png'];
  estado = 'NO_DISPONIBLE';
  try
    if ~ishandle(h), error('Figura cerrada.'); end
    print(h, '-dpng', '-r150', ruta);
    if exist(ruta, 'file') ~= 2, error('No se creo el PNG.'); end
    estado = 'OK';
    g = entrada_archivo_local(id, titulo, seccion, estado, ruta);
  catch err
    g = entrada_estado_local(id, titulo, seccion, ...
      ['ERROR_' limpiar_estado_local(err.message)]);
  end
  borrar_local(ruta);
end

function g = entrada_archivo_local(id, titulo, seccion, estado, ruta)
  g = entrada_estado_local(id, titulo, seccion, estado);
  if strcmpi(estado, 'OK') && ischar(ruta) && exist(ruta, 'file') == 2
    g.base64 = archivo_base64_local(ruta);
    if isempty(g.base64), g.estado = 'ERROR_BASE64'; end
  end
end

function g = entrada_estado_local(id, titulo, seccion, estado)
  g = struct('id', id, 'titulo', titulo, 'seccion', seccion, ...
    'estado', estado, 'base64', '');
end

function txt = archivo_base64_local(ruta)
  txt = '';
  fid = fopen(ruta, 'rb');
  if fid < 0, return; end
  bytes = fread(fid, Inf, 'uint8=>uint8');
  fclose(fid);
  try
    txt = base64_encode(bytes);
  catch
    txt = '';
  end
end

function borrar_local(ruta)
  if ischar(ruta) && ~isempty(ruta) && exist(ruta, 'file') == 2
    try, delete(ruta); catch, end
  end
end

function h = handles_validos_local(h)
  salida = [];
  for i = 1:numel(h)
    try
      if ishandle(h(i)), salida(end+1) = h(i); end
    catch
    end
  end
  h = salida;
end

function s = limpiar_estado_local(txt)
  if ~ischar(txt), txt = 'DESCONOCIDO'; end
  s = regexprep(txt, '[^A-Za-z0-9]+', '_');
  s = regexprep(s, '^_+|_+$', '');
  if isempty(s), s = 'DESCONOCIDO'; end
end
