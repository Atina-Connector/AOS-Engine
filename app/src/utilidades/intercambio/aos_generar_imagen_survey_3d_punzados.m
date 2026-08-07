function [ruta, estado] = aos_generar_imagen_survey_3d_punzados(param, tipo, carpeta)
% Genera una unica vista 3D del pozo con punzados marcados.

  if nargin < 2 || isempty(tipo), tipo = 'AOS'; endif
  if nargin < 3 || isempty(carpeta), carpeta = tempdir(); endif

  ruta = '';
  estado = 'NO_DISPONIBLE';
  survey = survey_local(param);
  if isempty(survey), return; endif

  md = survey.MD(:);
  tvd = survey.TVD(:);
  n = min(numel(md), numel(tvd));
  if n < 2
    estado = 'SURVEY_INSUFICIENTE';
    return;
  endif
  md = md(1:n); tvd = tvd(1:n);
  inc = vector_local(survey, {'inclinacion','INC','inc'}, n, 0);
  azi = vector_local(survey, {'azimut','AZI','azi'}, n, 0);
  [norte, este] = trayectoria_horizontal_local(md, inc, azi);
  intervalos = punzados_local(param);
  equipo_md = equipo_md_local(param, tipo);

  ruta = [tempname(carpeta) '.png'];
  fig = [];
  try
    fig = figure('Visible','off','Position',[90 70 980 760]);
    plot3(este, norte, -tvd, 'k-', 'LineWidth', 2.2); hold on;
    dibujar_punzados_3d_local(md, tvd, este, norte, intervalos);
    if isfinite(equipo_md)
      xe = interp1(md, este, equipo_md, 'linear', 'extrap');
      yn = interp1(md, norte, equipo_md, 'linear', 'extrap');
      zt = interp1(md, tvd, equipo_md, 'linear', 'extrap');
      plot3(xe, yn, -zt, 'ko', 'MarkerFaceColor','k', 'MarkerSize',8);
      text(xe, yn, -zt, ['  ' upper(tipo)], 'Interpreter','none');
    endif
    grid on;
    axis equal;
    view(35,25);
    xlabel('Este (m)');
    ylabel('Norte (m)');
    zlabel('TVD (m)');
    title('Survey 3D con punzados marcados');
    print(fig, '-dpng', '-r160', ruta);
    close(fig); fig = [];
    estado = 'OK';
  catch err
    if ~isempty(fig)
      try, if ishandle(fig), close(fig); endif, catch, end_try_catch
    endif
    if exist(ruta,'file') == 2, delete(ruta); endif
    ruta = '';
    estado = ['ERROR_' limpiar_estado_local(err.message)];
  end_try_catch
endfunction

function [norte, este] = trayectoria_horizontal_local(md, inc, azi)
  n = numel(md); norte = zeros(n,1); este = zeros(n,1);
  for i = 2:n
    dmd = md(i) - md(i-1);
    i1 = inc(i-1) * pi / 180; i2 = inc(i) * pi / 180;
    a1 = azi(i-1) * pi / 180; a2 = azi(i) * pi / 180;
    dogleg = acos(max(-1,min(1,cos(i2-i1) - sin(i1)*sin(i2)*(1-cos(a2-a1)))));
    rf = 1;
    if abs(dogleg) > 1e-10, rf = 2/dogleg * tan(dogleg/2); endif
    dn = 0.5*dmd*(sin(i1)*cos(a1) + sin(i2)*cos(a2))*rf;
    de = 0.5*dmd*(sin(i1)*sin(a1) + sin(i2)*sin(a2))*rf;
    norte(i) = norte(i-1) + dn;
    este(i) = este(i-1) + de;
  endfor
endfunction

function dibujar_punzados_3d_local(md,tvd,este,norte,intervalos)
  for k = 1:size(intervalos,1)
    m1 = max(min(md),intervalos(k,1)); m2 = min(max(md),intervalos(k,2));
    if m2 <= m1, continue; endif
    mm = linspace(m1,m2,12);
    xx = interp1(md,este,mm,'linear','extrap');
    yy = interp1(md,norte,mm,'linear','extrap');
    zz = interp1(md,tvd,mm,'linear','extrap');
    plot3(xx,yy,-zz,'r-','LineWidth',5.0);
  endfor
endfunction

function survey = survey_local(param)
  survey = [];
  global CONFIG_ACTIVA;
  fuentes = {param, CONFIG_ACTIVA};
  for i = 1:numel(fuentes)
    candidato = fuentes{i};
    if ~isstruct(candidato), continue; endif
    if isfield(candidato,'survey') && isstruct(candidato.survey), candidato = candidato.survey; endif
    if isfield(candidato,'MD') && isfield(candidato,'TVD') && isnumeric(candidato.MD) && isnumeric(candidato.TVD)
      n = min(numel(candidato.MD),numel(candidato.TVD));
      if n >= 2
        survey = candidato;
        md0 = candidato.MD(1:n); tvd0 = candidato.TVD(1:n);
        [mds,orden] = sort(md0(:));
        survey.MD = mds; survey.TVD = tvd0(:)(orden);
        nombres = {'inclinacion','INC','inc','azimut','AZI','azi'};
        for q = 1:numel(nombres), survey = ordenar_campo_local(survey,nombres{q},n,orden); endfor
        return;
      endif
    endif
  endfor
endfunction

function s = ordenar_campo_local(s,nombre,n,orden)
  if isfield(s,nombre) && isnumeric(s.(nombre))
    v = s.(nombre)(:);
    if numel(v) >= n, s.(nombre) = v(1:n)(orden); endif
  endif
endfunction

function v = vector_local(s,nombres,n,defecto)
  v = defecto*ones(n,1);
  for k = 1:numel(nombres)
    if isfield(s,nombres{k}) && isnumeric(s.(nombres{k})) && ~isempty(s.(nombres{k}))
      x = s.(nombres{k})(:); m = min(n,numel(x)); v(1:m)=x(1:m); return;
    endif
  endfor
endfunction

function ints = punzados_local(param)
  ints = [];
  global CONFIG_ACTIVA geologia;
  try
    if exist('aos_obtener_punzados_activos','file') == 2
      x = aos_obtener_punzados_activos(geologia,param);
      ints = normalizar_intervalos_local(x);
      if ~isempty(ints), return; endif
    endif
  catch
  end_try_catch
  fuentes = {param,CONFIG_ACTIVA,geologia};
  nombres = {'punzados','perforaciones','intervalos_punzados','intervalos'};
  for i = 1:numel(fuentes)
    a = fuentes{i}; if ~isstruct(a), continue; endif
    for j = 1:numel(nombres)
      if isfield(a,nombres{j})
        ints = normalizar_intervalos_local(a.(nombres{j}));
        if ~isempty(ints), return; endif
      endif
    endfor
  endfor
endfunction

function a = normalizar_intervalos_local(x)
  a = [];
  if isempty(x), return; endif
  if isnumeric(x) && size(x,2)>=2
    a = double(x(:,1:2));
    a = a(all(isfinite(a),2),:);
    return;
  endif
  if isstruct(x)
    for k=1:numel(x)
      m1=pick_local(x(k),{'MD_desde_m','MD_desde','md_desde','top','tope','MD_top','desde'});
      m2=pick_local(x(k),{'MD_hasta_m','MD_hasta','md_hasta','base','fondo','MD_base','hasta'});
      if isfinite(m1)&&isfinite(m2), a(end+1,:)=[min(m1,m2) max(m1,m2)]; endif
    endfor
  endif
endfunction

function v=pick_local(s,fs)
  v=NaN;
  for k=1:numel(fs)
    if isfield(s,fs{k}) && isnumeric(s.(fs{k})) && isscalar(s.(fs{k})) && isfinite(s.(fs{k}))
      v=s.(fs{k}); return;
    endif
  endfor
endfunction

function md = equipo_md_local(param,tipo)
  md=NaN; global CONFIG_ACTIVA; fuentes={param,CONFIG_ACTIVA};
  if ~isempty(strfind(upper(tipo),'BES')) || ~isempty(strfind(upper(tipo),'BM'))
    campos={'D_bomba','prof_bomba','profundidad_bomba'};
  else
    campos={'D_iny','D_valv','prof_iny','profundidad_inyeccion'};
  endif
  for i=1:numel(fuentes)
    a=fuentes{i}; if ~isstruct(a),continue;endif
    for k=1:numel(campos)
      if isfield(a,campos{k})&&isnumeric(a.(campos{k}))&&isscalar(a.(campos{k}))&&isfinite(a.(campos{k}))
        md=a.(campos{k}); return;
      endif
    endfor
  endfor
endfunction

function s=limpiar_estado_local(txt)
  if ~ischar(txt),txt='DESCONOCIDO';endif
  s=regexprep(txt,'[^A-Za-z0-9]+','_'); if isempty(s),s='DESCONOCIDO';endif
endfunction
