function [P_req, detalle] = compute_P_req(param, Ql, Qg_total_std, profundidad_MD)
  % compute_P_req.m - Entrada VLP corregida para AOS / GNU Octave.
  % AOS 0.0.11: devuelve detalle opcional del modelo VLP efectivo.

  if nargin < 4
    error('compute_P_req requiere: param, Ql, Qg_total_std, profundidad_MD');
  end

  p = aos_vlp_parametros(param);

  if isfield(param, 'survey') && ~isempty(param.survey)
    survey = param.survey;
  elseif isfield(p, 'survey') && ~isempty(p.survey)
    survey = p.survey;
  else
    survey = [];
  end

  detalle = aos_vlp_info(param, profundidad_MD);
  modelo = lower(strtrim(p.modelo_VLP));

  if strcmp(modelo, 'hb') && ~isempty(survey)
    survey = aos_vlp_normalizar_survey(survey, p, profundidad_MD);
    [~, MD_out, P_out] = vlp_HB_full(p, survey, Ql, Qg_total_std);
    P_req = interp1(MD_out, P_out, profundidad_MD, 'linear', 'extrap');
  elseif (strcmp(modelo, 'dr') || strcmp(modelo, 'duns_ros') || strcmp(modelo, 'duns&ros')) && ~isempty(survey)
    survey = aos_vlp_normalizar_survey(survey, p, profundidad_MD);
    [~, MD_out, P_out] = vlp_duns_ros(p, survey, Ql, Qg_total_std);
    P_req = interp1(MD_out, P_out, profundidad_MD, 'linear', 'extrap');
  else
    [P_req, ~, ~] = vlp_simplified_corregida(p, Ql, Qg_total_std, profundidad_MD, survey);
  end

  if isfield(p, 'factor_VLP') && ~isempty(p.factor_VLP)
    P_req = p.P_wh + p.factor_VLP * (P_req - p.P_wh);
  end
end
