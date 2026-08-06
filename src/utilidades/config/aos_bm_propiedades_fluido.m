function [cfg, info] = aos_bm_propiedades_fluido(cfg)
% AOS_BM_PROPIEDADES_FLUIDO Normaliza temperatura y viscosidad para BM.
% La viscosidad explicita siempre tiene prioridad. Si no existe, se estima
% una viscosidad de mezcla agua/petroleo a la temperatura de fondo. La
% correlacion API es preliminar y queda identificada en metadata/reportes.

  if nargin < 1 || ~isstruct(cfg), cfg = struct(); end
  info = struct('avisos', {{}});

  % Temperatura de fondo BM: 60 C cuando el .aosdat no la define.
  if isfield(cfg,'temperatura_fondo_C') && escalar(cfg.temperatura_fondo_C)
      T_C = cfg.temperatura_fondo_C;
      origen_T = origen(cfg,'origen_temperatura_fondo','AOSDAT_O_MANUAL');
  elseif isfield(cfg,'T_fondo_C') && escalar(cfg.T_fondo_C)
      T_C = cfg.T_fondo_C;
      origen_T = 'AOSDAT_ALIAS';
  elseif isfield(cfg,'T_fondo') && escalar(cfg.T_fondo) && ...
         (~isfield(cfg,'aos_T_fondo_original_presente') || cfg.aos_T_fondo_original_presente)
      if cfg.T_fondo > 200
          T_C = cfg.T_fondo - 273.15;
      else
          T_C = cfg.T_fondo;
      end
      origen_T = 'AOSDAT_ALIAS';
  else
      T_C = 60.0;
      origen_T = 'DEFAULT_BM_60C';
      info.avisos{end+1} = 'Temperatura de fondo no informada: se usa 60 C.';
  end
  T_C = min(max(T_C, 0.0), 200.0);
  cfg.temperatura_fondo_C = T_C;
  cfg.T_fondo = T_C + 273.15;
  cfg.origen_temperatura_fondo = origen_T;

  % Agua: Andrade simplificada, valida como estimacion de ingenieria.
  mu_w = 2.414e-5 * 10^(247.8 / (T_C + 133.15)) * 1000.0; % cP

  % Petroleo muerto: correlacion empirica API-temperatura (Beggs-Robinson).
  api = valor(cfg,'API',35.0);
  T_F = T_C * 9/5 + 32;
  z = 3.0324 - 0.02023 * api;
  y = 10^z;
  mu_o = 10^(y * T_F^(-1.163)) - 1.0; % cP
  mu_o = min(max(mu_o, 0.1), 1e5);

  wc = min(max(valor(cfg,'WC',1.0),0.0),1.0);
  cfg.viscosidad_agua_cP = mu_w;
  cfg.viscosidad_petroleo_estimado_cP = mu_o;

  if isfield(cfg,'viscosidad_fluido_cP') && escalar(cfg.viscosidad_fluido_cP) && cfg.viscosidad_fluido_cP > 0
      mu = cfg.viscosidad_fluido_cP;
      metodo = origen(cfg,'metodo_viscosidad','EXPLICITA');
      origen_mu = origen(cfg,'origen_viscosidad','AOSDAT_O_MANUAL');
  elseif isfield(cfg,'viscosidad_cP') && escalar(cfg.viscosidad_cP) && cfg.viscosidad_cP > 0
      mu = cfg.viscosidad_cP;
      metodo = 'EXPLICITA_ALIAS';
      origen_mu = 'AOSDAT_ALIAS';
  else
      % Mezcla logaritmica. Con WC=1 reproduce agua; con WC=0 usa petroleo.
      mu = exp(wc*log(max(mu_w,1e-9)) + (1-wc)*log(max(mu_o,1e-9)));
      metodo = 'MEZCLA_LOG_AGUA_API_PRELIMINAR';
      if wc >= 0.999
          origen_mu = 'DEFAULT_AGUA';
      else
          origen_mu = 'ESTIMADA_API_TEMPERATURA_WC';
          info.avisos{end+1} = 'Viscosidad no informada: estimada con API, temperatura y WC; requiere calibracion.';
      end
  end
  cfg.viscosidad_fluido_cP = mu;
  cfg.viscosidad_fluido_Pa_s = mu / 1000.0;
  cfg.metodo_viscosidad = metodo;
  cfg.origen_viscosidad = origen_mu;

  if ~isfield(cfg,'tipo_fluido_bm') || isempty(cfg.tipo_fluido_bm)
      if wc >= 0.999
          cfg.tipo_fluido_bm = 'AGUA';
      else
          cfg.tipo_fluido_bm = 'MEZCLA_AGUA_PETROLEO';
      end
  end
end

function v=valor(s,c,d)
  v=d;
  if isfield(s,c) && escalar(s.(c)), v=s.(c); end
end
function tf=escalar(x)
  tf=isnumeric(x)&&isscalar(x)&&isfinite(x);
end
function s=origen(cfg,c,d)
  s=d;
  if isfield(cfg,c) && (ischar(cfg.(c)) || isstring(cfg.(c)))
      s=char(cfg.(c));
  end
end
