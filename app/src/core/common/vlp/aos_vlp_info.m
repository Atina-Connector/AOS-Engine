function info = aos_vlp_info(param, profundidad_MD)
% aos_vlp_info.m - Auditoria del modelo VLP seleccionado y efectivo.
% AOS 0.0.11f: deja explicito que DR/HB son versiones AOS simplificadas.

  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(profundidad_MD), profundidad_MD = NaN; end

  try
      p = aos_vlp_parametros(param);
  catch
      p = param;
  end

  seleccionado = 'simplified';
  if isfield(p, 'modelo_VLP') && ischar(p.modelo_VLP) && ~isempty(p.modelo_VLP)
      seleccionado = p.modelo_VLP;
  elseif isfield(param, 'modelo_VLP') && ischar(param.modelo_VLP) && ~isempty(param.modelo_VLP)
      seleccionado = param.modelo_VLP;
  end
  modelo = lower(strtrim(seleccionado));

  tiene_survey = false;
  if isfield(param, 'survey') && ~isempty(param.survey)
      tiene_survey = true;
  elseif isfield(p, 'survey') && ~isempty(p.survey)
      tiene_survey = true;
  end

  efectivo = 'simplified';
  funcion = 'vlp_simplified_corregida';
  fallback = true;
  motivo = '';
  advertencia = '';

  if (strcmp(modelo, 'hb') || strcmp(modelo, 'hagedorn-brown')) && tiene_survey
      efectivo = 'HB_AOS_simplificado_estabilizado';
      funcion = 'vlp_HB_full';
      fallback = false;
      advertencia = 'No es implementacion canonica completa Hagedorn-Brown.';
  elseif (strcmp(modelo, 'dr') || strcmp(modelo, 'duns_ros') || strcmp(modelo, 'duns&ros')) && tiene_survey
      efectivo = 'DR_AOS_simplificado_estabilizado';
      funcion = 'vlp_duns_ros';
      fallback = false;
      advertencia = 'No es implementacion canonica completa Duns & Ros original.';
  else
      efectivo = 'simplified';
      funcion = 'vlp_simplified_corregida';
      fallback = true;
      if strcmp(modelo, 'simplified') || strcmp(modelo, 'simple')
          motivo = 'modelo simplificado seleccionado';
          fallback = false;
      elseif ~tiene_survey
          motivo = 'sin survey disponible';
      else
          motivo = 'modelo VLP no reconocido';
      end
  end

  info = struct();
  info.modelo_solicitado = seleccionado;
  info.modelo_efectivo = efectivo;
  info.funcion = funcion;
  info.fallback = fallback;
  info.motivo_fallback = motivo;
  info.tiene_survey = tiene_survey;
  info.profundidad_MD = profundidad_MD;
  info.advertencia = advertencia;
  info.seleccionado = seleccionado;
  info.efectivo = efectivo;
end
