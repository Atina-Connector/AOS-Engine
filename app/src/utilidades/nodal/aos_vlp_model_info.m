function info = aos_vlp_model_info(param, profundidad_MD)
% aos_vlp_model_info.m
% Informa el modelo VLP seleccionado y el efectivamente usado por AOS.
% AOS 0.0.11f: rotula DR/HB como versiones AOS simplificadas/estabilizadas.

  if nargin < 1 || isempty(param), param = struct(); end
  if nargin < 2, profundidad_MD = NaN; end

  seleccionado = leer_char_info(param, 'modelo_VLP', 'simplified');
  modelo = lower(strtrim(seleccionado));
  tiene_survey = isstruct(param) && isfield(param, 'survey') && ~isempty(param.survey);

  efectivo = seleccionado;
  funcion = 'vlp_simplified_corregida';
  fallback = false;
  advertencia = '';

  if (strcmp(modelo, 'hb') || strcmp(modelo, 'hagedorn-brown')) && tiene_survey
      efectivo = 'HB_AOS_simplificado_estabilizado';
      funcion = 'vlp_HB_full';
      advertencia = 'No es implementacion canonica completa Hagedorn-Brown.';
  elseif (strcmp(modelo, 'dr') || strcmp(modelo, 'duns_ros') || strcmp(modelo, 'duns&ros')) && tiene_survey
      efectivo = 'DR_AOS_simplificado_estabilizado';
      funcion = 'vlp_duns_ros';
      advertencia = 'No es implementacion canonica completa Duns & Ros original.';
  else
      efectivo = 'simplified';
      funcion = 'vlp_simplified_corregida';
      if ~strcmp(modelo, 'simplified')
          fallback = true;
          advertencia = 'Fallback a VLP simplificada.';
      end
  end

  info = struct();
  info.seleccionado = seleccionado;
  info.efectivo = efectivo;
  info.funcion = funcion;
  info.fallback = fallback;
  info.tiene_survey = tiene_survey;
  info.profundidad_MD = profundidad_MD;
  info.advertencia = advertencia;
end

function v = leer_char_info(s, campo, defecto)
  v = defecto;
  if ~isstruct(s) || ~isfield(s, campo), return; end
  tmp = s.(campo);
  if ischar(tmp)
      v = tmp;
  elseif isnumeric(tmp)
      v = num2str(tmp(1));
  end
end
