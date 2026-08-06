function geol = cargar_geologia(archivo)
  % Carga la configuración de geología desde un archivo de texto.
  % Usa el mismo formato campo = valor que el resto de AOS.
  % Entrada:
  %   archivo : ruta al archivo de configuración (ej. 'config_geologia/config_geologia.txt')
  % Salida:
  %   geol    : estructura con todos los parámetros geomecánicos y petrofísicos.

  % --- Usar la misma función load_config que ya existe en el proyecto ---
  % (Debe estar en el path; se agrega automáticamente desde AOS_app o podemos agregarlo)
  if exist('load_config', 'file') ~= 2
      addpath(fullfile(fileparts(mfilename('fullpath')), '..'), '-begin');
  end
  geol = load_config(archivo);

  % --- Validar que estén los campos mínimos necesarios ---
  campos_obligatorios = {'UCS', 'angulo_friccion', 'esfuerzo_h_min', 'esfuerzo_vertical', ...
                         'permeabilidad_h', 'permeabilidad_v', 'espesor_zona_petrolera', ...
                         'altura_perforados', 'radio_drenaje', 'radio_pozo', ...
                         'rho_petroleo', 'rho_agua', 'mu_petroleo', 'B_o'};
  for i = 1:length(campos_obligatorios)
      if ~isfield(geol, campos_obligatorios{i})
          error('Falta el parámetro obligatorio en la configuración de geología: %s', campos_obligatorios{i});
      end
  end

  % --- Convertir ángulos a radianes para cálculos internos ---
  if isfield(geol, 'angulo_friccion')
      geol.angulo_friccion_rad = deg2rad(geol.angulo_friccion);
  end

  % --- Valores por defecto para campos opcionales ---
  if ~isfield(geol, 'cohesion')
      geol.cohesion = 0;           % Pa (0 para arenas no consolidadas)
  end
  if ~isfield(geol, 'modulo_young')
      geol.modulo_young = 10e9;    % Pa
  end
  if ~isfield(geol, 'relacion_poisson')
      geol.relacion_poisson = 0.25;
  end
  if ~isfield(geol, 'porosidad')
      geol.porosidad = 0.20;
  end
  if ~isfield(geol, 'radio_poro')
      geol.radio_poro = 0.1;       % mm
  end
  if ~isfield(geol, 'diametro_grano_medio')
      geol.diametro_grano_medio = 0.5;  % mm
  end
  if ~isfield(geol, 'skin_factor')
      geol.skin_factor = 0;
  end
  if ~isfield(geol, 'factor_seguridad')
      geol.factor_seguridad = 1.2;
  end
  if ~isfield(geol, 'tipo_formacion')
      geol.tipo_formacion = 2;     % medianamente consolidada por defecto
  end

  fprintf('Configuración de geología cargada correctamente desde %s\n', archivo);
end
