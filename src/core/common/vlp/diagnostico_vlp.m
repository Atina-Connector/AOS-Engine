function diagnostico_vlp(survey, modelo_vlp)
  % Imprime un resumen de los tramos donde se aplica cada modelo VLP
  % según la inclinación del survey y el modelo VLP seleccionado.
  % Entradas:
  %   survey     : estructura del survey
  %   modelo_vlp : 'HB', 'DR', 'simplified' (opcional)

  if nargin < 2
      modelo_vlp = 'HB';   % valor por defecto
  end

  if ~isfield(survey, 'inclinacion') || isempty(survey.inclinacion)
      fprintf('Survey sin datos de inclinación. Se asume pozo vertical.\n');
      return;
  end

  MD = survey.MD;
  incl = survey.inclinacion;

  % Título según modelo
  switch upper(modelo_vlp)
      case 'HB'
          fprintf('\n--- DIAGNÓSTICO DE MODELO VLP (Hagedorn‑Brown) ---\n');
      case 'DR'
          fprintf('\n--- DIAGNÓSTICO DE MODELO VLP (Duns & Ros) ---\n');
      otherwise
          fprintf('\n--- DIAGNÓSTICO DE MODELO VLP (%s) ---\n', modelo_vlp);
  end

  modelo_actual = '';
  tramo_inicio = MD(1);

  for seg = 2:length(MD)
      incl_avg = (incl(seg-1) + incl(seg)) / 2;

      % Asignar nombre del modelo según inclinación y modelo base
      if strcmpi(modelo_vlp, 'HB')
          if incl_avg > 10
              modelo = 'Hagedorn-Brown + Lawson-Brill';
          else
              modelo = 'Hagedorn-Brown (vertical)';
          end
      elseif strcmpi(modelo_vlp, 'DR')
          % Duns & Ros maneja la inclinación internamente, no requiere corrección adicional
          if incl_avg > 10
              modelo = 'Duns & Ros (inclinado)';
          else
              modelo = 'Duns & Ros (vertical)';
          end
      else
          modelo = [modelo_vlp ' (sin corrección por inclinación)'];
      end

      if ~strcmp(modelo, modelo_actual)
          if ~isempty(modelo_actual)
              fprintf('  MD %6.0f - %6.0f m : %s\n', tramo_inicio, MD(seg-1), modelo_actual);
          end
          modelo_actual = modelo;
          tramo_inicio = MD(seg-1);
      end
  end
  % Último tramo
  fprintf('  MD %6.0f - %6.0f m : %s\n', tramo_inicio, MD(end), modelo_actual);
  fprintf('--------------------------------------------------\n');
end
