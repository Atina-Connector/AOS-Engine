function [survey, punzados, info] = aos_obtener_geometria_activa()
% Obtiene survey y punzados reales de la configuracion activa.
% No usa silenciosamente el survey base de config/GL/survey.txt.
  global CONFIG_ACTIVA geologia AOSDAT_ACTIVO;

  survey = [];
  punzados = [];
  info = struct('pozo', '', 'origen_survey', 'NO_DISPONIBLE', ...
                'origen_punzados', 'NO_DISPONIBLE', 'archivo_aosdat', '');

  if ischar(AOSDAT_ACTIVO)
    info.archivo_aosdat = AOSDAT_ACTIVO;
  endif

  if isstruct(CONFIG_ACTIVA)
    info.pozo = nombre_pozo_local(CONFIG_ACTIVA);

    if isfield(CONFIG_ACTIVA, 'survey')
      survey = normalizar_survey_local(CONFIG_ACTIVA.survey);
      if ~isempty(survey)
        info.origen_survey = 'CONFIG_ACTIVA.survey';
      endif
    endif

    if isempty(survey) && isfield(CONFIG_ACTIVA, 'pozo') && isstruct(CONFIG_ACTIVA.pozo) && ...
       isfield(CONFIG_ACTIVA.pozo, 'survey')
      survey = normalizar_survey_local(CONFIG_ACTIVA.pozo.survey);
      if ~isempty(survey)
        info.origen_survey = 'CONFIG_ACTIVA.pozo.survey';
      endif
    endif

    if isfield(CONFIG_ACTIVA, 'punzados')
      punzados = normalizar_punzados_local(CONFIG_ACTIVA.punzados);
      if tiene_punzados_local(punzados)
        info.origen_punzados = 'CONFIG_ACTIVA.punzados';
      endif
    endif

    if ~tiene_punzados_local(punzados) && isfield(CONFIG_ACTIVA, 'geologia') && ...
       isstruct(CONFIG_ACTIVA.geologia) && isfield(CONFIG_ACTIVA.geologia, 'intervalos')
      punzados = normalizar_punzados_local(CONFIG_ACTIVA.geologia.intervalos);
      if tiene_punzados_local(punzados)
        info.origen_punzados = 'CONFIG_ACTIVA.geologia.intervalos';
      endif
    endif
  endif

  if ~tiene_punzados_local(punzados) && isstruct(geologia) && isfield(geologia, 'intervalos')
    punzados = normalizar_punzados_local(geologia.intervalos);
    if tiene_punzados_local(punzados)
      info.origen_punzados = 'geologia.intervalos';
    endif
  endif
endfunction

function survey = normalizar_survey_local(x)
  survey = [];
  if isempty(x)
    return;
  endif

  if isnumeric(x) && size(x, 2) >= 2
    raw = struct();
    raw.MD = double(x(:, 1));
    raw.TVD = double(x(:, 2));
    if size(x, 2) >= 3, raw.inclinacion = double(x(:, 3)); endif
    if size(x, 2) >= 4, raw.azimut = double(x(:, 4)); endif
    if size(x, 2) >= 5, raw.ID_tubing = double(x(:, 5)); endif
    if size(x, 2) >= 6, raw.ID_casing = double(x(:, 6)); endif
    if size(x, 2) >= 7, raw.rugosidad = double(x(:, 7)); endif
  elseif isstruct(x) && isfield(x, 'MD')
    raw = x;
  else
    return;
  endif

  if ~isfield(raw, 'TVD') || isempty(raw.TVD)
    raw.TVD = raw.MD;
  endif

  n = min(numel(raw.MD), numel(raw.TVD));
  if n < 2
    return;
  endif

  md = double(raw.MD(1:n)(:));
  tvd = double(raw.TVD(1:n)(:));
  inc = completar_vector_local(raw, 'inclinacion', n, 0);
  azi = completar_vector_local(raw, 'azimut', n, 0);
  idt = completar_vector_local(raw, 'ID_tubing', n, 0.062);
  idc = completar_vector_local(raw, 'ID_casing', n, NaN);
  rug = completar_vector_local(raw, 'rugosidad', n, 4.5e-5);

  ok = isfinite(md) & isfinite(tvd);
  md = md(ok); tvd = tvd(ok); inc = inc(ok); azi = azi(ok);
  idt = idt(ok); idc = idc(ok); rug = rug(ok);
  if numel(md) < 2
    return;
  endif

  [md, idx] = sort(md);
  tvd = tvd(idx); inc = inc(idx); azi = azi(idx);
  idt = idt(idx); idc = idc(idx); rug = rug(idx);
  [md, ia] = unique(md, 'stable');
  tvd = tvd(ia); inc = inc(ia); azi = azi(ia);
  idt = idt(ia); idc = idc(ia); rug = rug(ia);

  survey = struct();
  survey.MD = md(:);
  survey.TVD = tvd(:);
  survey.inclinacion = inc(:);
  survey.azimut = azi(:);
  survey.ID_tubing = idt(:);
  survey.ID_casing = idc(:);
  survey.rugosidad = rug(:);

  md_ref = survey.MD;
  tvd_ref = survey.TVD;
  id_ref = survey.ID_tubing;
  inc_ref = survey.inclinacion;
  survey.get_TVD = @(mdq) interp1(md_ref, tvd_ref, mdq, 'linear', 'extrap');
  survey.get_ID = @(mdq) interp1(md_ref, id_ref, mdq, 'linear', 'extrap');
  survey.get_inclinacion = @(mdq) interp1(md_ref, inc_ref, mdq, 'linear', 'extrap');
endfunction

function v = completar_vector_local(s, nombre, n, defecto)
  v = defecto * ones(n, 1);
  if isfield(s, nombre) && isnumeric(s.(nombre)) && ~isempty(s.(nombre))
    raw = double(s.(nombre)(:));
    m = min(numel(raw), n);
    v(1:m) = raw(1:m);
    if m < n && m > 0
      v(m+1:n) = raw(m);
    endif
  endif
endfunction

function p = normalizar_punzados_local(x)
  [p,~]=aos_punzados_normalizar(x);
endfunction

function tf = tiene_punzados_local(p)
  tf = isstruct(p) && isfield(p, 'tramos') && ~isempty(p.tramos);
endfunction

function n = nombre_pozo_local(cfg)
  n = '';
  campos = {'nombre_pozo','pozo_nombre','well_name','nombre','id_pozo','pozo'};
  for i = 1:numel(campos)
    if isfield(cfg, campos{i})
      x = cfg.(campos{i});
      if ischar(x) && ~isempty(strtrim(x))
        n = strtrim(x);
        return;
      elseif isstruct(x)
        sub = {'nombre','id','name'};
        for j = 1:numel(sub)
          if isfield(x, sub{j}) && ischar(x.(sub{j})) && ~isempty(strtrim(x.(sub{j})))
            n = strtrim(x.(sub{j}));
            return;
          endif
        endfor
      endif
    endif
  endfor
endfunction
