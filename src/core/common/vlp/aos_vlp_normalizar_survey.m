function survey2 = aos_vlp_normalizar_survey(survey, p, profundidad_MD)
  % aos_vlp_normalizar_survey.m
  % Normaliza survey para VLP.
  % Convención usada en AOS: inclinacion = grados desde la vertical
  %   0° vertical, 90° horizontal.

  if nargin < 2 || ~isstruct(p)
    p = struct();
    p.diam_tbg = 0.062;
    p.eps_abs = 1.5e-5;
  end
  if nargin < 3 || isempty(profundidad_MD)
    profundidad_MD = [];
  end

  if nargin < 1 || isempty(survey) || ~isstruct(survey) || ~isfield(survey, 'MD') || ~isfield(survey, 'TVD')
    if isempty(profundidad_MD)
      profundidad_MD = 3000;
    end
    n = 31;
    survey2.MD = linspace(0, profundidad_MD, n)';
    survey2.TVD = survey2.MD;
    survey2.inclinacion = zeros(n, 1);
    survey2.azimut = zeros(n, 1);
    survey2.ID_tubing = p.diam_tbg * ones(n, 1);
    survey2.ID_casing = NaN * ones(n, 1);
    survey2.rugosidad = p.eps_abs * ones(n, 1);
    return;
  end

  survey2 = survey;
  survey2.MD = survey.MD(:);
  survey2.TVD = survey.TVD(:);
  n = length(survey2.MD);

  if isfield(survey, 'inclinacion')
    survey2.inclinacion = survey.inclinacion(:);
  else
    survey2.inclinacion = zeros(n, 1);
  end

  if isfield(survey, 'azimut')
    survey2.azimut = survey.azimut(:);
  else
    survey2.azimut = zeros(n, 1);
  end

  if isfield(survey, 'ID_tubing')
    survey2.ID_tubing = survey.ID_tubing(:);
  else
    survey2.ID_tubing = p.diam_tbg * ones(n, 1);
  end

  if isfield(survey, 'ID_casing')
    survey2.ID_casing = survey.ID_casing(:);
  else
    survey2.ID_casing = NaN * ones(n, 1);
  end

  if isfield(survey, 'rugosidad')
    survey2.rugosidad = survey.rugosidad(:);
  else
    survey2.rugosidad = p.eps_abs * ones(n, 1);
  end

  % Recortar longitudes si algún vector vino más corto/largo.
  n = min([length(survey2.MD), length(survey2.TVD), length(survey2.inclinacion), length(survey2.ID_tubing), length(survey2.rugosidad)]);
  survey2.MD = survey2.MD(1:n);
  survey2.TVD = survey2.TVD(1:n);
  survey2.inclinacion = survey2.inclinacion(1:n);
  survey2.azimut = survey2.azimut(1:n);
  survey2.ID_tubing = survey2.ID_tubing(1:n);
  survey2.ID_casing = survey2.ID_casing(1:n);
  survey2.rugosidad = survey2.rugosidad(1:n);

  % Ordenar por MD ascendente.
  [survey2.MD, idx] = sort(survey2.MD);
  survey2.TVD = survey2.TVD(idx);
  survey2.inclinacion = survey2.inclinacion(idx);
  survey2.azimut = survey2.azimut(idx);
  survey2.ID_tubing = survey2.ID_tubing(idx);
  survey2.ID_casing = survey2.ID_casing(idx);
  survey2.rugosidad = survey2.rugosidad(idx);

  % Asegurar punto de superficie.
  if survey2.MD(1) > 0
    survey2.MD = [0; survey2.MD];
    survey2.TVD = [0; survey2.TVD];
    survey2.inclinacion = [survey2.inclinacion(1); survey2.inclinacion];
    survey2.azimut = [survey2.azimut(1); survey2.azimut];
    survey2.ID_tubing = [survey2.ID_tubing(1); survey2.ID_tubing];
    survey2.ID_casing = [survey2.ID_casing(1); survey2.ID_casing];
    survey2.rugosidad = [survey2.rugosidad(1); survey2.rugosidad];
  end

  % Si se pidió una profundidad específica y no existe, insertar punto interpolado.
  if ~isempty(profundidad_MD) && profundidad_MD > survey2.MD(1) && profundidad_MD < survey2.MD(end)
    if isempty(find(abs(survey2.MD - profundidad_MD) < 1e-6, 1))
      md_new = profundidad_MD;
      tvd_new = interp1(survey2.MD, survey2.TVD, md_new, 'linear');
      inc_new = interp1(survey2.MD, survey2.inclinacion, md_new, 'linear');
      az_new = interp1(survey2.MD, survey2.azimut, md_new, 'linear');
      id_new = interp1(survey2.MD, survey2.ID_tubing, md_new, 'linear');
      rug_new = interp1(survey2.MD, survey2.rugosidad, md_new, 'linear');
      cas_new = interp1(survey2.MD, survey2.ID_casing, md_new, 'linear');
      survey2.MD = [survey2.MD; md_new];
      survey2.TVD = [survey2.TVD; tvd_new];
      survey2.inclinacion = [survey2.inclinacion; inc_new];
      survey2.azimut = [survey2.azimut; az_new];
      survey2.ID_tubing = [survey2.ID_tubing; id_new];
      survey2.ID_casing = [survey2.ID_casing; cas_new];
      survey2.rugosidad = [survey2.rugosidad; rug_new];
      [survey2.MD, idx] = sort(survey2.MD);
      survey2.TVD = survey2.TVD(idx);
      survey2.inclinacion = survey2.inclinacion(idx);
      survey2.azimut = survey2.azimut(idx);
      survey2.ID_tubing = survey2.ID_tubing(idx);
      survey2.ID_casing = survey2.ID_casing(idx);
      survey2.rugosidad = survey2.rugosidad(idx);
    end
  end

  % Saneos físicos.
  survey2.ID_tubing = max(survey2.ID_tubing, 1e-4);
  survey2.rugosidad = max(survey2.rugosidad, 1e-8);
  survey2.inclinacion = aos_vlp_clamp(survey2.inclinacion, 0, 180);
end
