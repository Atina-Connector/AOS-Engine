function [cfg, origen] = aos_config_base(modulo)
% aos_config_base.m - Resuelve la configuracion base para cualquier modulo AOS.
%
% Filosofia de datos AOS:
%   1) config/ aporta defaults y catalogos generales del programa.
%   2) un .aosdat importado representa el caso de pozo y pisa los defaults.
%   3) cada modulo puede ajustar parametros durante la simulacion sin cambiar
%      automaticamente el .aosdat original.
%   4) el .aosrpt debe guardar lo efectivamente usado para reproducibilidad.
%
% Uso:
%   [param, origen] = aos_config_base('JGL');
%
% Compatible con GNU Octave.

  if nargin < 1 || isempty(modulo)
      modulo = 'GENERAL';
  end

  defaults = struct();
  if exist('config/GL/config_jgl.txt', 'file')
      try
          defaults = load_config('config/GL/config_jgl.txt');
      catch
          defaults = struct();
      end
  end

  cfg = defaults;
  origen = 'config/ defaults';

  global CONFIG_ACTIVA AOSDAT_ACTIVO;
  hay_activa = false;
  try
      hay_activa = isstruct(CONFIG_ACTIVA) && ~isempty(fieldnames(CONFIG_ACTIVA));
  catch
      hay_activa = false;
  end

  if hay_activa
      % Normalizar una copia local. Nunca modificar CONFIG_ACTIVA al entrar a
      % un modulo: GL/JGL, BES y BM asignan significados distintos a la
      % profundidad operativa y no deben contaminarse entre si.
      cfg_activa = CONFIG_ACTIVA;
      try
          cfg_activa = aos_normalizar_config(cfg_activa, modulo);
      catch err
          fprintf('ADVERTENCIA AOS: no se pudo normalizar copia de CONFIG_ACTIVA: %s\n', err.message);
      end
      cfg = aos_merge_struct(cfg, cfg_activa);
      if exist('AOSDAT_ACTIVO', 'var') && ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
          origen = ['.aosdat importado: ', AOSDAT_ACTIVO];
      else
          origen = '.aosdat importado';
      end
  end

  cfg = aos_config_defaults(cfg, modulo);
  try
      cfg = aos_normalizar_config(cfg, modulo);
      aos_validar_config_modulo(cfg, modulo, true);
  catch err
      fprintf('ADVERTENCIA AOS: normalizacion final incompleta: %s\n', err.message);
  end
  cfg.aos_config_origen = origen;
  cfg.aos_modulo = modulo;
end

function out = aos_merge_struct(out, src)
  if nargin < 1 || ~isstruct(out), out = struct(); end
  if nargin < 2 || ~isstruct(src), return; end
  campos = fieldnames(src);
  for i = 1:length(campos)
      campo = campos{i};
      out.(campo) = src.(campo);
  end
end

function cfg = aos_config_defaults(cfg, modulo)
  % Defaults comunes de pozo/fluidos.
  if ~isfield(cfg, 'T_sup'),        cfg.T_sup = 298.15; end
  if ~isfield(cfg, 'T_fondo'),      cfg.T_fondo = 358.15; end
  if ~isfield(cfg, 'diam_tbg'),     cfg.diam_tbg = 0.062; end
  if ~isfield(cfg, 'rho_o'),        cfg.rho_o = 850; end
  if ~isfield(cfg, 'rho_w'),        cfg.rho_w = 1000; end
  if ~isfield(cfg, 'rho_g_std'),    cfg.rho_g_std = 0.8; end
  if ~isfield(cfg, 'API'),          cfg.API = 35; end
  if ~isfield(cfg, 'gamma_g'),      cfg.gamma_g = 0.7; end
  if ~isfield(cfg, 'R_gas'),        cfg.R_gas = 519.6; end
  if ~isfield(cfg, 'modelo_IPR'),   cfg.modelo_IPR = 'linear'; end
  if ~isfield(cfg, 'modelo_VLP'),   cfg.modelo_VLP = 'HB'; end
  if ~isfield(cfg, 'factor_VLP'),   cfg.factor_VLP = 1.0; end
  if ~isfield(cfg, 'factor_IP_residual'), cfg.factor_IP_residual = 1.0; end

  % Defaults geometricos JGL. Si faltan a_eductor/b_eductor, se calculan
  % desde A_t/A_n. Esto evita volver a los coeficientes historicos bajos.
  if ~isfield(cfg, 'A_n') || isempty(cfg.A_n), cfg.A_n = 12e-6; end
  if ~isfield(cfg, 'd_t') || isempty(cfg.d_t), cfg.d_t = 0.038; end
  if ~isfield(cfg, 'eta_n'), cfg.eta_n = 0.98; end
  if ~isfield(cfg, 'eta_t'), cfg.eta_t = 0.85; end
  if ~isfield(cfg, 'eta_d'), cfg.eta_d = 0.80; end

  necesita_a = ~isfield(cfg, 'a_eductor') || isempty(cfg.a_eductor);
  necesita_b = ~isfield(cfg, 'b_eductor') || isempty(cfg.b_eductor);
  if necesita_a || necesita_b
      A_t = pi * (cfg.d_t/2)^2;
      R_area = A_t / max(cfg.A_n, 1e-12);
      if necesita_a, cfg.a_eductor = 0.0020 * R_area; end
      if necesita_b, cfg.b_eductor = 0.00010 * R_area; end
  end

  % Defaults BES.
  if ~isfield(cfg, 'curva_bomba_file'), cfg.curva_bomba_file = 'config/BES/curva_bomba.txt'; end
  if ~isfield(cfg, 'frecuencia'),       cfg.frecuencia = 60; end
  if ~isfield(cfg, 'frecuencia_base'),  cfg.frecuencia_base = 60; end
  if ~isfield(cfg, 'num_etapas'),       cfg.num_etapas = 100; end
  if ~isfield(cfg, 'T_max_motor'),      cfg.T_max_motor = 120; end
  if ~isfield(cfg, 'eficiencia_motor'), cfg.eficiencia_motor = 0.85; end
  if ~isfield(cfg, 'cp_fluido'),        cfg.cp_fluido = 3500; end
  if ~isfield(cfg, 'velocidad_min_refrig'), cfg.velocidad_min_refrig = 0.3; end
  if ~isfield(cfg, 'voltaje_motor'),    cfg.voltaje_motor = 4000; end
  if ~isfield(cfg, 'IR_base'),          cfg.IR_base = 1000; end
  if ~isfield(cfg, 'factor_envejecimiento'), cfg.factor_envejecimiento = 1.0; end

  % Defaults BM.
  if ~isfield(cfg, 'D_bomba_mm'), cfg.D_bomba_mm = 32; end
  if ~isfield(cfg, 'S_carrera'),  cfg.S_carrera  = 1.5; end
  if ~isfield(cfg, 'N_velocidad'),cfg.N_velocidad = 6; end
  if ~isfield(cfg, 'eta_vol'),    cfg.eta_vol    = 0.80; end
  if ~isfield(cfg, 'eta_mecanica_BM'), cfg.eta_mecanica_BM = 0.75; end
  if ~isfield(cfg, 'P_intake_min'), cfg.P_intake_min = 1e5; end
  if ~isfield(cfg, 'tipo_unidad'), cfg.tipo_unidad = 'Convencional'; end
  if ~isfield(cfg, 'material_varillas'), cfg.material_varillas = 'Acero Grado D'; end
  if ~isfield(cfg, 'tuberia_anclada'), cfg.tuberia_anclada = 1; end
  if ~isfield(cfg, 'usar_gibbs_BM'), cfg.usar_gibbs_BM = 1; end
  if ~isfield(cfg, 'gibbs_n_t'), cfg.gibbs_n_t = 720; end
  if ~isfield(cfg, 'gibbs_n_ciclos'), cfg.gibbs_n_ciclos = 8; end
  if ~isfield(cfg, 'gibbs_n_nodos'), cfg.gibbs_n_nodos = 31; end
  if ~isfield(cfg, 'gibbs_amortiguamiento'), cfg.gibbs_amortiguamiento = 0.055; end
  if ~isfield(cfg, 'gibbs_metodo_forward'), cfg.gibbs_metodo_forward = 'estable'; end
  if ~isfield(cfg, 'slip_bomba'), cfg.slip_bomba = 0.0; end
  if ~isfield(cfg, 'eficiencia_valvulas'), cfg.eficiencia_valvulas = 1.0; end
  if ~isfield(cfg, 'friccion_bomba_N'), cfg.friccion_bomba_N = 0.0; end
end
