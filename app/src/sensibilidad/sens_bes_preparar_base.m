function p = sens_bes_preparar_base(base)
% SENS_BES_PREPARAR_BASE Defaults y sincronizacion comunes para BES.
% GNU Octave es el entorno objetivo; evitar sintaxis compacta dependiente
% del parser y preservar siempre los campos runtime de la sensibilidad.

  if nargin < 1 || ~isstruct(base), base = struct(); end
  p = sens_preparar_base(base, 'BES');

  if ~isfield(p,'curva_bomba_file') || isempty(p.curva_bomba_file)
      p.curva_bomba_file = 'config/BES/curva_bomba.txt';
  end
  if ~isfield(p,'frecuencia') || isempty(p.frecuencia), p.frecuencia = 60; end
  if ~isfield(p,'frecuencia_base') || isempty(p.frecuencia_base), p.frecuencia_base = 60; end

  if ~isfield(p,'num_etapas') || isempty(p.num_etapas)
      p.num_etapas = 100;
      if exist(p.curva_bomba_file,'file') == 2
          try
              c = load_config(p.curva_bomba_file);
              if isstruct(c) && isfield(c,'num_etapas') && isnumeric(c.num_etapas) && ...
                 isscalar(c.num_etapas) && isfinite(c.num_etapas)
                  p.num_etapas = c.num_etapas;
              end
          catch
              % Mantener el default; la evaluacion BES informara otros errores.
          end
      end
  end

  if ~isfield(p,'T_max_motor') || isempty(p.T_max_motor), p.T_max_motor = 120; end
  if ~isfield(p,'eficiencia_motor') || isempty(p.eficiencia_motor), p.eficiencia_motor = 0.85; end
  if ~isfield(p,'cp_fluido') || isempty(p.cp_fluido), p.cp_fluido = 3500; end
  if ~isfield(p,'velocidad_min_refrig') || isempty(p.velocidad_min_refrig), p.velocidad_min_refrig = 0.3; end
  if ~isfield(p,'voltaje_motor') || isempty(p.voltaje_motor), p.voltaje_motor = 4000; end
  if ~isfield(p,'IR_base') || isempty(p.IR_base), p.IR_base = 1000; end
  if ~isfield(p,'factor_envejecimiento') || isempty(p.factor_envejecimiento), p.factor_envejecimiento = 1.0; end

  if ~isfield(p,'mu_o') || isempty(p.mu_o)
      try
          pvt = pvt_calcular(p.P_res, p.T_fondo - 273.15, p.API, p.gamma_g);
          p.mu_o = pvt.mu_o;
      catch
          p.mu_o = 0.01;
      end
  end

  p = aos_sincronizar_config(p, 'BES');
end
