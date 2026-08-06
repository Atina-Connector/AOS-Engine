function survey = obtener_survey(param)
  % obtener_survey.m
  % Devuelve una estructura de survey apta para diagnostico y VLP.
  % Criterio importante:
  %   - Un survey con menos de 3 puntos se considera simplificado.
  %   - Para diagnostico de erosion/carga/Taitel se prioriza un survey completo.
  %   - Si el .aosdat trae solo 2 puntos, se intenta usar config/GL/survey.txt.

  survey = [];

  % 1) Survey heredado desde .aosdat o configuracion activa
  if isfield(param, 'survey') && ~isempty(param.survey) && isstruct(param.survey)
      survey_candidato = completar_survey_basico(param.survey, param);
      n = cantidad_puntos_survey(survey_candidato);
      if n >= 3
          survey = survey_candidato;
          return;
      else
          fprintf('Aviso: el survey activo tiene solo %d punto(s). Se considera simplificado para Taitel/erosion.\n', n);
      end
  end

  % 2) Si hay survey_file explicito, probarlo primero
  if isfield(param, 'survey_file') && ischar(param.survey_file) && exist(param.survey_file, 'file')
      s = load_survey(param.survey_file);
      if cantidad_puntos_survey(s) >= 3
          fprintf('Usando survey completo indicado en survey_file: %s\n', param.survey_file);
          survey = completar_survey_basico(s, param);
          return;
      end
  end

  % 3) Survey estandar del proyecto. Se prueban varias rutas por compatibilidad.
  candidatos = {
      'config/GL/survey.txt'
      'config/survey.txt'
      fullfile('config','GL','survey.txt')
  };
  for k = 1:length(candidatos)
      survey_file = candidatos{k};
      if exist(survey_file, 'file')
          s = load_survey(survey_file);
          if cantidad_puntos_survey(s) >= 3
              fprintf('Usando survey completo del proyecto: %s (%d puntos).\n', survey_file, cantidad_puntos_survey(s));
              survey = completar_survey_basico(s, param);
              survey.origen = survey_file;
              return;
          end
      end
  end

  % 4) Si no hay alternativa, usar el simplificado existente
  if isfield(param, 'survey') && ~isempty(param.survey) && isstruct(param.survey)
      survey = completar_survey_basico(param.survey, param);
      fprintf('Aviso: se usa survey simplificado porque no se encontro survey completo.\n');
      return;
  end

  % 5) Ultimo recurso: crear survey sintetico con dos puntos
  fprintf('Creando survey sintetico (2 puntos) con datos del pozo.\n');
  if isfield(param, 'D_tubing')
      MD_val = param.D_tubing;
  elseif isfield(param, 'D_res')
      MD_val = param.D_res;
  else
      MD_val = 3000;
  end
  if isfield(param, 'D_res')
      TVD_val = param.D_res;
  else
      TVD_val = MD_val;
  end
  if isfield(param, 'diam_tbg')
      diam = param.diam_tbg;
  else
      diam = 0.062;
  end

  survey.MD = [0; MD_val];
  survey.TVD = [0; TVD_val];
  survey.inclinacion = [0; 0];
  survey.azimut = [0; 0];
  survey.ID_tubing = [diam; diam];
  survey.ID_casing = [0.100; 0.100];
  survey.rugosidad = [4.57e-5; 4.57e-5];
  survey.origen = 'sintetico_2_puntos';
  survey.get_TVD = @(md) interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
  survey.get_ID  = @(md) interp1(survey.MD, survey.ID_tubing, md, 'linear', 'extrap');
  if ~isfield(survey, 'origen')
      survey.origen = 'estructura_activa';
  end
  survey.get_inclinacion = @(md) interp1(survey.MD, survey.inclinacion, md, 'linear', 'extrap');
end

function n = cantidad_puntos_survey(s)
  n = 0;
  if isstruct(s) && isfield(s, 'MD') && ~isempty(s.MD)
      n = length(s.MD);
  end
end

function survey = completar_survey_basico(survey, param)
  if ~isfield(survey, 'MD') || isempty(survey.MD)
      return;
  end
  survey.MD = survey.MD(:);
  n = length(survey.MD);
  if ~isfield(survey, 'TVD') || isempty(survey.TVD)
      survey.TVD = survey.MD;
  end
  survey.TVD = survey.TVD(:);
  if ~isfield(survey, 'inclinacion') || isempty(survey.inclinacion)
      survey.inclinacion = zeros(n,1);
  end
  survey.inclinacion = survey.inclinacion(:);
  if ~isfield(survey, 'azimut') || isempty(survey.azimut)
      survey.azimut = zeros(n,1);
  end
  survey.azimut = survey.azimut(:);
  if ~isfield(survey, 'ID_tubing') || isempty(survey.ID_tubing)
      if isfield(param, 'diam_tbg'), diam = param.diam_tbg; else, diam = 0.062; end
      survey.ID_tubing = diam * ones(n,1);
  end
  survey.ID_tubing = survey.ID_tubing(:);
  if ~isfield(survey, 'ID_casing') || isempty(survey.ID_casing)
      survey.ID_casing = 0.100 * ones(n,1);
  end
  survey.ID_casing = survey.ID_casing(:);
  if ~isfield(survey, 'rugosidad') || isempty(survey.rugosidad)
      survey.rugosidad = 4.57e-5 * ones(n,1);
  end
  survey.rugosidad = survey.rugosidad(:);
  survey.get_TVD = @(md) interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
  survey.get_ID  = @(md) interp1(survey.MD, survey.ID_tubing, md, 'linear', 'extrap');
  if ~isfield(survey, 'origen')
      survey.origen = 'estructura_activa';
  end
  survey.get_inclinacion = @(md) interp1(survey.MD, survey.inclinacion, md, 'linear', 'extrap');
end
