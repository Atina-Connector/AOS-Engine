function param = gibbs_lab_defaults(param)
% Defaults defensivos para laboratorio Gibbs v16.
% v17: laboratorio auditado. El modo solver forward no agrega oscilaciones
% hardcodeadas. El benchmark v16 mantiene oscilacion heuristica solo si se activa.
  if nargin < 1 || ~isstruct(param), param = struct(); end
  param = setnum(param, 'S_carrera', 1.5);
  param = setnum(param, 'N_velocidad', 6.0);
  param = setnum(param, 'D_bomba', 1800);
  param = setnum(param, 'D_bomba_mm', 32);
  param = setnum(param, 'eta_vol', 0.80);
  param = setnum(param, 'llenado_bomba', param.eta_vol);
  param = setnum(param, 'rho_o', 850);
  param = setnum(param, 'rho_w', 1000);
  param = setnum(param, 'WC', 0.45);
  param = setnum(param, 'rho_acero', 7850);
  param = setnum(param, 'E_acero', 2.05e11);
  param = setnum(param, 'diam_varilla_mm', 19.05); % 3/4 in
  param = setnum(param, 'relacion_carrera_fondo', 0.85);
  param = setnum(param, 'gibbs_lab_n', 960);
  param = setnum(param, 'gibbs_lab_amort', 0.18);
  param = setnum(param, 'gibbs_lab_retardo_factor', 1.0);

  % Fracciones de carrera superficial usadas para transmitir carga y descarga.
  % Estas NO deforman la carta de fondo: representan la elasticidad de la sarta
  % vista en superficie.
  param = setnum(param, 'gibbs_lab_toma_carga_frac_x', 0.22);
  param = setnum(param, 'gibbs_lab_descarga_frac_x', 0.22);
  param = setnum(param, 'gibbs_lab_fondo_esquina_frac', 0.010);
  param = setnum(param, 'gibbs_lab_osc_frac_Wf', 0.0); % v17: sin oscilacion heuristica por defecto
  param = setnum(param, 'gibbs_lab_friccion_frac', 0.04);

  % Parametros del solver de onda forward v17.
  param = setnum(param, 'gibbs_lab_nx', 36);
  param = setnum(param, 'gibbs_lab_ciclos', 5.0);
  param = setnum(param, 'gibbs_lab_c_damp', 0.12); % 1/s
end

function s = setnum(s, campo, valor)
  if ~isfield(s, campo) || isempty(s.(campo)) || ~isnumeric(s.(campo)) || ~isfinite(s.(campo)(1))
      s.(campo) = valor;
  end
end
