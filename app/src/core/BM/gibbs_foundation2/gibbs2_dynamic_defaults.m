function param = gibbs2_dynamic_defaults(param)
  % Parametros especificos del solver dinamico GF2.
  % Esta funcion centraliza constantes fisicas, limites numericos y
  % parametros de modelo para evitar valores dispersos en el solver.

  if nargin < 1 || ~isstruct(param)
    param = struct();
  end

  % Constantes y control numerico
  param = set_default(param, 'gibbs2_gravedad', 9.80665);          % [m/s2]
  param = set_default(param, 'gibbs2_cfl', 0.35);                 % [-]
  param = set_default(param, 'gibbs2_min_spm', 0.10);             % [spm]
  param = set_default(param, 'gibbs2_min_puntos_por_ciclo', 120); % [-]
  param = set_default(param, 'gibbs2_oversampling', 2);           % [-]

  % Simulacion y postproceso
  param = set_default(param, 'gibbs2_n_ciclos', 5);
  param = set_default(param, 'gibbs2_descartar_ciclos', 1);
  param = set_default(param, 'gibbs2_puntos_por_ciclo', 720);

  % Amortiguamiento axial de Gibbs.
  % gamma = pi * c * delta / (2 L), con unidades [1/s].
  % En el solver se convierte a fuerza nodal: Fd = -m * gamma * v.
  param = set_default(param, 'gibbs2_delta_damping', 0.10);

  % Peso aparente de las varillas
  param = set_default(param, 'gibbs2_buoyancy_factor_rods', 0.87);

  % Bomba y transicion de valvulas
  param = set_default(param, 'gibbs2_llenado_bomba', 0.85);
  param = set_default(param, 'gibbs2_valve_transition_frac', 0.02);
  param = set_default(param, 'gibbs2_valve_vel_threshold', 0.01); % [m/s]

  % Friccion configurable. NaN en fuerza absoluta significa usar la
  % fraccion de la carga hidraulica. Los valores son defaults, no leyes.
  param = set_default(param, 'gibbs2_friccion_ascenso_N', NaN);
  param = set_default(param, 'gibbs2_friccion_descenso_N', NaN);
  param = set_default(param, 'gibbs2_friccion_ascenso_frac', 0.00);
  param = set_default(param, 'gibbs2_friccion_descenso_frac', 0.02);

  % Presion de intake. NaN permite tomar P_intake, P_intake_Pa o
  % P_intake_min si alguno existe en la configuracion del pozo.
  param = set_default(param, 'gibbs2_presion_intake_Pa', NaN);

  % Metadatos
  param = set_default(param, 'gibbs2_integrador', 'semi_implicit_euler');
end

function s = set_default(s, name, value)
  if ~isfield(s, name) || isempty(s.(name))
    s.(name) = value;
  end
end
