function survey = load_survey(filename, survey_existente)
  % Carga un survey desde archivo o devuelve el existente.
  % Entradas:
  %   filename        : nombre del archivo de survey (opcional si ya hay survey)
  %   survey_existente: estructura de survey ya cargada (opcional)
  % Si se proporciona survey_existente, se devuelve directamente.
  % Si no, se carga desde filename.
  % Si filename no existe, se devuelve [].

  if nargin >= 2 && ~isempty(survey_existente) && isstruct(survey_existente)
      survey = survey_existente;
      return;
  end

  if nargin < 1 || isempty(filename)
      filename = 'config/GL/survey.txt';
  end

  if ~exist(filename, 'file')
      survey = [];
      return;
  end

  fid = fopen(filename, 'r');
  if fid == -1
      survey = [];
      return;
  end

  % Ignorar líneas de comentario hasta encontrar la primera línea de datos
  while ~feof(fid)
      linea = strtrim(fgetl(fid));
      if isempty(linea) || linea(1) == '#'
          continue;
      end
      fseek(fid, -length(linea)-1, 'cof');
      break;
  end

  data_cell = textscan(fid, '%f %f %f %f %f %f %f', 'CommentStyle', '#');
  fclose(fid);

  survey.MD = data_cell{1};
  survey.TVD = data_cell{2};
  survey.inclinacion = data_cell{3};
  survey.azimut = data_cell{4};
  survey.ID_tubing = data_cell{5};
  survey.ID_casing = data_cell{6};
  survey.rugosidad = data_cell{7};

  survey.get_TVD = @(md) interp1(survey.MD, survey.TVD, md, 'linear', 'extrap');
  survey.get_ID = @(md) interp1(survey.MD, survey.ID_tubing, md, 'linear', 'extrap');
  survey.get_inclinacion = @(md) interp1(survey.MD, survey.inclinacion, md, 'linear', 'extrap');
end
