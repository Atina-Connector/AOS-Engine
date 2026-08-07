function modelo_eff = aos_vlp_modelo_efectivo(param, profundidad_MD) %#ok<INUSD>
% aos_vlp_modelo_efectivo.m
% Devuelve el modelo VLP efectivamente usable por compute_P_req.
% AOS 0.0.11f rotula DR/HB como versiones AOS simplificadas.
  modelo_eff = 'simplified';
  if nargin < 1 || ~isstruct(param), return; end
  p = aos_vlp_parametros(param);
  modelo = lower(strtrim(p.modelo_VLP));
  tiene_survey = false;
  if isfield(param, 'survey') && ~isempty(param.survey)
      tiene_survey = true;
  elseif isfield(p, 'survey') && ~isempty(p.survey)
      tiene_survey = true;
  end
  if (strcmp(modelo, 'hb') || strcmp(modelo, 'hagedorn-brown')) && tiene_survey
      modelo_eff = 'HB_AOS_simplificado_estabilizado';
  elseif (strcmp(modelo, 'dr') || strcmp(modelo, 'duns_ros') || strcmp(modelo, 'duns&ros')) && tiene_survey
      modelo_eff = 'DR_AOS_simplificado_estabilizado';
  else
      modelo_eff = 'simplified';
  end
end
