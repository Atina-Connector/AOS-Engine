function info = aos_exportar_contexto_viewer(fid, param, tipo, incluir)
% AOS_EXPORTAR_CONTEXTO_VIEWER Contexto compacto; datos completos en tablas HF3.5.
  if nargin<4||isempty(incluir),incluir=true;endif
  if nargin<3||isempty(tipo),tipo='AOS';endif
  info=struct('incluido',false,'n_survey',0,'n_punzados',0,'tiene_tubing',false,'tiene_equipo',false);
  survey=obtener_survey_local(param);intervalos=obtener_punzados_local(param);equipo=equipo_local(param,tipo);
  ns=0;if ~isempty(survey),ns=numel(survey.MD);endif
  np=size(intervalos,1);te=isfinite(equipo.MD);
  info.n_survey=ns;info.n_punzados=np;info.tiene_equipo=te;info.incluido=incluir&&(ns>0||np>0||te);

  fprintf(fid,'\n[VIEWER_CONTEXT]\n');
  fprintf(fid,'schema=AOS_VIEWER_CONTEXT_1.3\nincluido=%d\nsistema=%s\n',incluir~=0,upper(tipo));
  fprintf(fid,'unidades_profundidad=m\nconvencion_inclinacion=grados_desde_vertical\n');
  fprintf(fid,'convencion_tvd=positiva_hacia_abajo\nrender_preferred=COMPACT\n');
  fprintf(fid,'table_contract=AOS_REPORT_COMPOSITION_1.0\n');

  fprintf(fid,'\n[VIEWER_CONTEXT_SUMMARY]\n');
  fprintf(fid,'schema=AOS_VIEWER_CONTEXT_SUMMARY_1.1\n');
  fprintf(fid,'survey_disponible=%d\nsurvey_n_puntos=%d\n',ns>0,ns);
  fprintf(fid,'punzados_disponibles=%d\npunzados_n_tramos=%d\n',np>0,np);
  fprintf(fid,'equipo_fondo_disponible=%d\nocultar_secciones_vacias=1\n',te);
  if ~incluir,fprintf(fid,'motivo=excluido_por_usuario\n');return;endif

  tablas=struct([]);if isfield(param,'aosrpt_tablas')&&isstruct(param.aosrpt_tablas),tablas=param.aosrpt_tablas;endif
  [ts,~]=aos_report_table_find(tablas,'well_survey');
  fprintf(fid,'\n[SURVEY]\n');
  if ns>0
    fprintf(fid,'estado=cargado\ndisplay_when_empty=0\nn_puntos=%d\n',ns);
    if ~isempty(ts),fprintf(fid,'table_id=%s\nrender_mode=%s\n',ts.id,ts.render_mode);endif
  else,fprintf(fid,'estado=no_disponible\ndisplay_when_empty=0\nn_puntos=0\n');endif

  [tt,~]=aos_report_table_find(tablas,'well_tubing_profile');
  fprintf(fid,'\n[TUBING_PROFILE]\n');
  if ~isempty(tt)&&tt.n_rows>0
    info.tiene_tubing=true;fprintf(fid,'estado=cargado\ndisplay_when_empty=0\nn_puntos=%d\ntable_id=%s\nrender_mode=%s\n',tt.n_rows,tt.id,tt.render_mode);
  else,fprintf(fid,'estado=no_disponible\ndisplay_when_empty=0\nn_puntos=0\n');endif

  [tp,~]=aos_report_table_find(tablas,'well_perforations');
  fprintf(fid,'\n[PERFORATIONS]\ndisplay_when_empty=0\n');
  if np>0
    fprintf(fid,'estado=cargado\nn_tramos=%d\n',np);
    if ~isempty(tp),fprintf(fid,'table_id=%s\nrender_mode=%s\n',tp.id,tp.render_mode);endif
  else,fprintf(fid,'estado=no_disponible\nn_tramos=0\n');endif

  fprintf(fid,'\n[DOWNHOLE_EQUIPMENT]\ndisplay_when_empty=0\ntipo=%s\n',equipo.tipo);
  if te
    fprintf(fid,'estado=definido\nMD_m=%.6f\n',equipo.MD);tvd=interp_tvd_local(survey,equipo.MD);
    if isfinite(tvd),fprintf(fid,'TVD_estado=calculado_desde_survey\nTVD_m=%.6f\n',tvd);else,fprintf(fid,'TVD_estado=no_disponible_por_falta_survey\n');endif
    fprintf(fid,'descripcion=%s\n',limpiar_txt_local(equipo.descripcion));
  else,fprintf(fid,'estado=no_disponible\n');endif
endfunction

function s = num_o_na_local(v)
  if isnumeric(v) && isscalar(v) && isfinite(v), s=sprintf('%.10g',v); else, s='NA'; endif
endfunction

function survey = obtener_survey_local(param)
  survey = [];
  global CONFIG_ACTIVA;
  fuentes = {param, CONFIG_ACTIVA};
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    if isfield(a, 'survey') && isstruct(a.survey)
      x = a.survey;
    else
      x = a;
    endif
    if isfield(x, 'MD') && isfield(x, 'TVD') && ...
       isnumeric(x.MD) && isnumeric(x.TVD)
      n = min(numel(x.MD), numel(x.TVD));
      if n < 2
        continue;
      endif
      survey = x;
      survey.MD = x.MD(1:n)(:);
      survey.TVD = x.TVD(1:n)(:);
      [survey.MD, orden] = sort(survey.MD);
      survey.TVD = survey.TVD(orden);
      nombres = {'inclinacion','INC','inc','azimut','AZI','azi', ...
                 'ID_tubing','id_tubing','diam_tbg','ID_casing','id_casing', ...
                 'rugosidad','roughness'};
      for j = 1:numel(nombres)
        f = nombres{j};
        if isfield(survey, f) && isnumeric(survey.(f))
          v = survey.(f)(:);
          if numel(v) >= n
            survey.(f) = v(1:n)(orden);
          endif
        endif
      endfor
      return;
    endif
  endfor
endfunction

function v = campo_vector_local(s, nombres, n, defecto)
  v = defecto * ones(n,1);
  for j = 1:numel(nombres)
    f = nombres{j};
    if isfield(s, f) && isnumeric(s.(f)) && ~isempty(s.(f))
      x = s.(f)(:);
      m = min(n, numel(x));
      v(1:m) = x(1:m);
      return;
    endif
  endfor
endfunction

function intervalos = obtener_punzados_local(param)
  intervalos = [];
  global geologia CONFIG_ACTIVA;

  if exist('aos_obtener_punzados_activos', 'file') == 2
    try
      x = aos_obtener_punzados_activos(geologia, param);
      intervalos = normalizar_local(x);
      if ~isempty(intervalos)
        return;
      endif
    catch
    end_try_catch
  endif

  fuentes = {param, CONFIG_ACTIVA, geologia};
  nombres = {'punzados','perforaciones','intervalos_punzados','intervalos'};
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    for j = 1:numel(nombres)
      if isfield(a, nombres{j})
        intervalos = normalizar_local(a.(nombres{j}));
        if ~isempty(intervalos)
          return;
        endif
      endif
    endfor
  endfor
endfunction

function a = normalizar_local(x)
  a = [];
  if isempty(x)
    return;
  endif
  if isnumeric(x) && size(x,2) >= 2
    a = double(x(:,1:2));
    a = a(all(isfinite(a),2),:);
    return;
  endif
  if isstruct(x)
    for k = 1:numel(x)
      md1 = primer_local(x(k), {'MD_desde_m','MD_desde','md_desde','top','tope','MD_top','desde'});
      md2 = primer_local(x(k), {'MD_hasta_m','MD_hasta','md_hasta','base','fondo','MD_base','hasta'});
      if isfinite(md1) && isfinite(md2)
        a(end+1,:) = [min(md1,md2) max(md1,md2)];
      endif
    endfor
  endif
endfunction

function v = primer_local(s, campos)
  v = NaN;
  for k = 1:numel(campos)
    if isfield(s, campos{k}) && isnumeric(s.(campos{k})) && ...
       isscalar(s.(campos{k})) && isfinite(s.(campos{k}))
      v = s.(campos{k});
      return;
    endif
  endfor
endfunction

function tvd = interp_tvd_local(survey, md)
  tvd = NaN;
  if isempty(survey) || ~isfinite(md)
    return;
  endif
  try
    tvd = interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
  catch
    tvd = NaN;
  end_try_catch
endfunction

function equipo = equipo_local(param, tipo)
  tipo_u = upper(tipo);
  equipo = struct('tipo', tipo_u, 'MD', NaN, 'descripcion', '');
  if ~isempty(strfind(tipo_u, 'CGF'))
    equipo.tipo = 'COMPRESOR_CGF';
    equipo.MD = buscar_local(param, {'D_cgf','D_cgf_m'});
    equipo.descripcion = 'Compresor axial de gas en fondo';
  elseif ~isempty(strfind(tipo_u, 'EGF'))
    equipo.tipo = 'EDUCTOR_GAS_GAS';
    equipo.MD = buscar_local(param, {'D_egf','D_egf_m'});
    equipo.descripcion = 'Eyector gas-gas de fondo';
  elseif ~isempty(strfind(tipo_u, 'JGL'))
    equipo.tipo = 'EDUCTOR_JGL';
    equipo.MD = buscar_local(param, {'D_iny','D_valv','prof_iny','profundidad_inyeccion'});
    equipo.descripcion = 'Eductor / punto de mezcla JGL';
  elseif ~isempty(strfind(tipo_u, 'GL'))
    equipo.tipo = 'PUNTO_INYECCION_GL';
    equipo.MD = buscar_local(param, {'D_iny','D_valv','prof_iny','profundidad_inyeccion'});
    equipo.descripcion = 'Punto efectivo de inyeccion GL';
  elseif strcmp(tipo_u, 'BES')
    equipo.tipo = 'BOMBA_BES';
    equipo.MD = buscar_local(param, {'D_bomba','prof_bomba','profundidad_bomba'});
    equipo.descripcion = 'Bomba / intake BES';
  elseif strcmp(tipo_u, 'BM')
    equipo.tipo = 'BOMBA_MECANICA';
    equipo.MD = buscar_local(param, {'D_bomba','prof_bomba','profundidad_bomba'});
    equipo.descripcion = 'Bomba de fondo BM';
  endif
endfunction

function v = buscar_local(param, campos)
  v = NaN;
  global CONFIG_ACTIVA;
  fuentes = {param, CONFIG_ACTIVA};
  for i = 1:numel(fuentes)
    a = fuentes{i};
    if ~isstruct(a)
      continue;
    endif
    for k = 1:numel(campos)
      if isfield(a, campos{k}) && isnumeric(a.(campos{k})) && ...
         isscalar(a.(campos{k})) && isfinite(a.(campos{k}))
        v = a.(campos{k});
        return;
      endif
    endfor
  endfor
endfunction

function s = limpiar_txt_local(txt)
  if ~ischar(txt)
    txt = '';
  endif
  s = regexprep(txt, '[\r\n=]', ' ');
endfunction
