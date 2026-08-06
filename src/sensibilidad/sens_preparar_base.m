function base = sens_preparar_base(base, modulo)
% SENS_PREPARAR_BASE Defaults comunes y sincronizacion para sensibilidades.
% Los valores canonicos editados o barridos tienen prioridad sobre aliases del
% .aosdat. GNU Octave es el entorno objetivo.

  if nargin < 1 || isempty(base) || ~isstruct(base), base = struct(); end
  if nargin < 2 || isempty(modulo), modulo = 'GENERAL'; end

  try
    base = aos_sincronizar_config(base, modulo);
  catch
    try, base = aos_normalizar_config(base, modulo); catch, end
  end

  if ~isfield(base, 'T_sup'),        base.T_sup = 298.15; end
  if ~isfield(base, 'T_fondo'),      base.T_fondo = 358.15; end
  if ~isfield(base, 'diam_tbg'),     base.diam_tbg = 0.062; end
  if ~isfield(base, 'rho_o'),        base.rho_o = 850; end
  if ~isfield(base, 'rho_w'),        base.rho_w = 1000; end
  if ~isfield(base, 'rho_g_std'),    base.rho_g_std = 0.8; end
  if ~isfield(base, 'API'),          base.API = 35; end
  if ~isfield(base, 'gamma_g'),      base.gamma_g = 0.7; end
  if ~isfield(base, 'R_gas'),        base.R_gas = 519.6; end
  if ~isfield(base, 'modelo_IPR') || isempty(base.modelo_IPR), base.modelo_IPR = 'linear'; end
  if ~isfield(base, 'P_b'),          base.P_b = 100e5; end
  base.P_b = aos_presion_bar_a_pa(base.P_b, 100);

  if ~isfield(base, 'A_n') || isempty(base.A_n), base.A_n = 12e-6; end
  if ~isfield(base, 'd_t') || isempty(base.d_t), base.d_t = 0.038; end
  if ~isfield(base, 'eta_n'), base.eta_n = 0.98; end
  if ~isfield(base, 'eta_t'), base.eta_t = 0.85; end
  if ~isfield(base, 'eta_d'), base.eta_d = 0.80; end
  % No recalcular coeficientes JGL silenciosamente durante un barrido.
  % Si a_eductor y b_eductor ya existen, se consideran la calibracion efectiva
  % del caso; las sensibilidades geometricas fuerzan 'derivada' explicitamente.
  if ~isfield(base, 'jgl_geometria_modo') || isempty(base.jgl_geometria_modo)
    if isfield(base, 'a_eductor') && isnumeric(base.a_eductor) && ~isempty(base.a_eductor) && isfinite(base.a_eductor(1)) && ...
       isfield(base, 'b_eductor') && isnumeric(base.b_eductor) && ~isempty(base.b_eductor) && isfinite(base.b_eductor(1))
      base.jgl_geometria_modo = 'calibrada';
    else
      base.jgl_geometria_modo = 'derivada';
    endif
  endif
  base = jgl_actualizar_geometria(base, base.jgl_geometria_modo);

  if ~isfield(base, 'curva_bomba_file'), base.curva_bomba_file = 'config/BES/curva_bomba.txt'; end
  if ~isfield(base, 'frecuencia'),       base.frecuencia = 60; end
  if ~isfield(base, 'frecuencia_base'),  base.frecuencia_base = 60; end
  if ~isfield(base, 'num_etapas'),       base.num_etapas = 100; end
  if ~isfield(base, 'T_max_motor'),      base.T_max_motor = 120; end
  if ~isfield(base, 'eficiencia_motor'), base.eficiencia_motor = 0.85; end
  if ~isfield(base, 'cp_fluido'),        base.cp_fluido = 3500; end
  if ~isfield(base, 'velocidad_min_refrig'), base.velocidad_min_refrig = 0.3; end
  if ~isfield(base, 'voltaje_motor'),    base.voltaje_motor = 4000; end
  if ~isfield(base, 'IR_base'),          base.IR_base = 1000; end
  if ~isfield(base, 'factor_envejecimiento'), base.factor_envejecimiento = 1.0; end

  try
    base.survey = obtener_survey(base);
  catch
    if ~isfield(base, 'survey'), base.survey = []; end
  end

  profundidad = NaN;
  m = upper(strtrim(modulo));
  if any(strcmp(m, {'BES','BM','SENS_BES','SENSIBILIDAD_BES'}))
    if isfield(base,'D_bomba'), profundidad = base.D_bomba; end
  else
    if isfield(base,'D_iny'), profundidad = base.D_iny; end
  end
  if isfield(base, 'survey') && ~isempty(base.survey) && isfinite(profundidad)
    try, base.diam_tbg = base.survey.get_ID(profundidad); catch, end
  end

  try, base = aos_sincronizar_aliases_canonicos(base); catch, end
end
