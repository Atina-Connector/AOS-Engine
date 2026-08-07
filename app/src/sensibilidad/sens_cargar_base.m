function [base, origen] = sens_cargar_base(contexto)
% sens_cargar_base.m - Seleccion explicita de fuente para sensibilidades AOS.
%
% Esta version evita una prioridad automatica oculta. Antes de correr una
% sensibilidad, AOS muestra las fuentes disponibles y el usuario elige con
% cual quiere trabajar:
%   - configuracion importada .aosdat
%   - ultima simulacion ejecutada
%   - configuracion por defecto del proyecto
%
% Compatible con GNU Octave.

  if nargin < 1 || isempty(contexto), contexto = 'GENERAL'; endif
  contexto = upper(strtrim(contexto));

  global CONFIG_ACTIVA ULTIMO_PARAM ULTIMO_TIPO;

  opciones = {};
  etiquetas = {};
  descripciones = {};

  hay_config = exist('CONFIG_ACTIVA', 'var') && isstruct(CONFIG_ACTIVA) && ~isempty(fieldnames(CONFIG_ACTIVA));
  hay_ultimo = exist('ULTIMO_PARAM', 'var') && isstruct(ULTIMO_PARAM) && ~isempty(fieldnames(ULTIMO_PARAM));
  ultimo_compatible = false;
  if hay_ultimo
      if exist('ULTIMO_TIPO', 'var') && ischar(ULTIMO_TIPO) && ~isempty(ULTIMO_TIPO)
          et = ['ultima simulacion ejecutada (', ULTIMO_TIPO, ')'];
          tipo_u = upper(strtrim(ULTIMO_TIPO));
          if strcmp(contexto, 'SENS_GL')
              ultimo_compatible = strcmp(tipo_u, 'GL');
          elseif strcmp(contexto, 'SENS_JGL')
              ultimo_compatible = strcmp(tipo_u, 'JGL');
          elseif strcmp(contexto, 'GL_JGL')
              ultimo_compatible = any(strcmp(tipo_u, {'GL','JGL'}));
          else
              ultimo_compatible = true;
          endif
      else
          et = 'ultima simulacion ejecutada';
          ultimo_compatible = ~any(strcmp(contexto, {'GL_JGL','SENS_GL','SENS_JGL'}));
      endif
  endif

  % SENS-GLJGL-01: para GL/JGL la ultima simulacion compatible es la fuente
  % recomendada y queda primera. Asi el barrido reproduce el punto individual.
  if hay_ultimo && ultimo_compatible
      opciones{end+1} = 'ULTIMO_PARAM';
      etiquetas{end+1} = et;
      descripciones{end+1} = sens_describir_fuente(ULTIMO_PARAM, et);
  endif

  if hay_config
      opciones{end+1} = 'CONFIG_ACTIVA';
      etiquetas{end+1} = 'configuracion importada (.aosdat)';
      descripciones{end+1} = sens_describir_fuente(CONFIG_ACTIVA, etiquetas{end});
  endif

  opciones{end+1} = 'DEFAULT';
  etiquetas{end+1} = 'configuracion por defecto del proyecto';
  descripciones{end+1} = 'config/GL/config_jgl.txt';

  % Una ultima simulacion de otro sistema se conserva como alternativa
  % explicita, pero nunca queda como opcion por defecto del barrido.
  if hay_ultimo && ~ultimo_compatible
      opciones{end+1} = 'ULTIMO_PARAM';
      etiquetas{end+1} = et;
      descripciones{end+1} = [sens_describir_fuente(ULTIMO_PARAM, et), ' | ADVERTENCIA: sistema distinto del contexto solicitado'];
  endif

  fprintf('\n--- FUENTE PARA ANALISIS DE SENSIBILIDAD ---\n');
  for i = 1:length(opciones)
      fprintf(' %d - %s\n', i, etiquetas{i});
      if ~isempty(descripciones{i})
          fprintf('     %s\n', descripciones{i});
      end
  end

  if length(opciones) == 1
      sel = 1;
      fprintf('Solo hay una fuente disponible. Se usara: %s\n', etiquetas{sel});
  else
      sel = input(sprintf('Seleccione fuente (1-%d) [1]: ', length(opciones)));
      if isempty(sel)
          sel = 1;
      end
      if ~isnumeric(sel) || sel < 1 || sel > length(opciones) || floor(sel) ~= sel
          fprintf('Opcion invalida. Se usara la opcion 1: %s\n', etiquetas{1});
          sel = 1;
      end
  end

  switch opciones{sel}
    case 'CONFIG_ACTIVA'
      base = CONFIG_ACTIVA;
      origen = etiquetas{sel};
    case 'ULTIMO_PARAM'
      base = ULTIMO_PARAM;
      origen = etiquetas{sel};
    otherwise
      base = load_config('config/GL/config_jgl.txt');
      origen = etiquetas{sel};
  end

  base = sens_preparar_base(base, contexto);
  base.sens_origen = origen;
  base.sens_contexto = contexto;
  try
    [base.sens_config_firma, base.sens_config_firma_texto] = sens_firma_config_gl_jgl(base);
  catch
  end_try_catch

  fprintf('\nSensibilidad basada en: %s\n', origen);
  sens_imprimir_resumen_base(base);
  fprintf('---------------------------------------------\n');
end

function txt = sens_describir_fuente(cfg, etiqueta)
  txt = '';
  partes = {};
  if isfield(cfg, 'archivo_aosdat') && ~isempty(cfg.archivo_aosdat)
      partes{end+1} = ['archivo: ', char(cfg.archivo_aosdat)];
  elseif isfield(cfg, 'nombre_pozo') && ~isempty(cfg.nombre_pozo)
      partes{end+1} = ['pozo/caso: ', char(cfg.nombre_pozo)];
  end
  if isfield(cfg, 'modelo_VLP') && ~isempty(cfg.modelo_VLP)
      partes{end+1} = ['VLP: ', char(cfg.modelo_VLP)];
  end
  if isfield(cfg, 'modelo_IPR') && ~isempty(cfg.modelo_IPR)
      partes{end+1} = ['IPR: ', char(cfg.modelo_IPR)];
  end
  if isfield(cfg, 'Q_iny') && ~isempty(cfg.Q_iny)
      partes{end+1} = sprintf('Qiny ref: %.0f Sm3/d (%.4g MMscf/d)', aos_m3s_a_sm3d(cfg.Q_iny), aos_m3s_a_mmscfd(cfg.Q_iny));
  elseif isfield(cfg, 'Qiny_plot') && ~isempty(cfg.Qiny_plot)
      partes{end+1} = sprintf('Qiny ref: %.0f Sm3/d (%.4g MMscf/d)', aos_m3s_a_sm3d(cfg.Qiny_plot), aos_m3s_a_mmscfd(cfg.Qiny_plot));
  end
  if isfield(cfg, 'survey') && ~isempty(cfg.survey)
      partes{end+1} = 'survey: cargado';
  end

  if isempty(partes)
      txt = etiqueta;
  else
      txt = partes{1};
      for k = 2:length(partes)
          txt = [txt, ' | ', partes{k}];
      end
  end
end

function sens_imprimir_resumen_base(base)
  if isfield(base, 'archivo_aosdat') && ~isempty(base.archivo_aosdat)
      fprintf('Archivo base      : %s\n', char(base.archivo_aosdat));
  end
  if isfield(base, 'modelo_VLP') && ~isempty(base.modelo_VLP)
      fprintf('Modelo VLP        : %s\n', char(base.modelo_VLP));
  end
  if isfield(base, 'modelo_IPR') && ~isempty(base.modelo_IPR)
      fprintf('Modelo IPR        : %s\n', char(base.modelo_IPR));
  end
  if isfield(base, 'P_wh')
      fprintf('P_wh              : %s\n', aos_formato_presion(base.P_wh, 2));
  end
  if isfield(base, 'P_iny_sup')
      fprintf('P_iny_sup         : %s\n', aos_formato_presion(base.P_iny_sup, 2));
  end
  if isfield(base, 'D_iny')
      fprintf('Prof. levant.     : %s MD\n', aos_formato_longitud(base.D_iny, 1));
  elseif isfield(base, 'D_bomba')
      fprintf('Prof. levant.     : %s MD\n', aos_formato_longitud(base.D_bomba, 1));
  end
  if isfield(base, 'Q_iny') && ~isempty(base.Q_iny)
      fprintf('Qiny referencia   : %s\n', aos_formato_caudal_gas(base.Q_iny));
  elseif isfield(base, 'Qiny_plot') && ~isempty(base.Qiny_plot)
      fprintf('Qiny referencia   : %s\n', aos_formato_caudal_gas(base.Qiny_plot));
  end
  if isfield(base, 'survey') && ~isempty(base.survey)
      try
          fprintf('Survey            : cargado (%d puntos)\n', length(base.survey.MD));
      catch
          fprintf('Survey            : cargado\n');
      end
  else
      fprintf('Survey            : no cargado\n');
  end
end
