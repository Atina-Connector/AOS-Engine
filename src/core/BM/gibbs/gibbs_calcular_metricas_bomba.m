function [metricas, cartas] = gibbs_calcular_metricas_bomba(param, pos_sup, carga_sup, pos_fondo, carga_fondo, t, valvula, llenado_inst)
  % Calcula carrera efectiva, llenado, desplazamiento y metricas BM.
  pos_sup = pos_sup(:)';
  carga_sup = carga_sup(:)';
  pos_fondo = pos_fondo(:)';
  carga_fondo = carga_fondo(:)';
  t = t(:)';
  if nargin < 7 || isempty(valvula), valvula = double(gradiente_periodico(pos_fondo,t) >= 0); end
  if nargin < 8 || isempty(llenado_inst), llenado_inst = leer_campo(param, 'eta_vol', 0.85) * ones(size(pos_fondo)); end
  valvula = valvula(:)';
  llenado_inst = llenado_inst(:)';

  pos_sup_n = pos_sup - min(pos_sup);
  pos_fondo_n = pos_fondo - min(pos_fondo);
  stroke_sup = max(pos_sup_n) - min(pos_sup_n);
  stroke_fondo = max(pos_fondo_n) - min(pos_fondo_n);

  Dp = leer_campo(param, 'D_bomba_mm', 32) / 1000;
  A_bomba = pi * (Dp/2)^2;
  spm = max(leer_campo(param, 'N_velocidad', 6), 0);
  llenado_base = min(max(leer_campo(param, 'llenado_bomba', leer_campo(param,'eta_vol',0.85)), 0), 1.2);
  slip = min(max(leer_campo(param, 'slip_bomba', 0), 0), 0.95);
  eta_valv = min(max(leer_campo(param, 'eficiencia_valvulas', 1), 0), 1.2);

  % Llenado efectivo: combina parametro de llenado con carrera cargada.
  frac_carga = min(max(mean(valvula > 0.5) * 2, 0), 1.2);
  llenado_efectivo = min(max(llenado_base * eta_valv * max(0.15, min(frac_carga, 1.05)), 0), 1.2);

  Q_teorico_sup = A_bomba * stroke_sup * spm / 60;
  Q_teorico_fondo = A_bomba * stroke_fondo * spm / 60;
  Q_efectivo = Q_teorico_fondo * llenado_efectivo * (1 - slip);

  % Potencia dinamometrica aproximada por integral F dx por ciclo.
  trabajo_sup = abs(integral_periodica(carga_sup, pos_sup_n));
  trabajo_fondo = abs(integral_periodica(carga_fondo, pos_fondo_n));
  potencia_sup = trabajo_sup * spm / 60;
  potencia_fondo = trabajo_fondo * spm / 60;

  metricas = struct();
  metricas.stroke_superficie_m = stroke_sup;
  metricas.stroke_fondo_m = stroke_fondo;
  metricas.relacion_stroke_fondo = stroke_fondo / max(stroke_sup, 1e-9);
  metricas.area_bomba_m2 = A_bomba;
  metricas.llenado_efectivo = llenado_efectivo;
  metricas.slip_bomba = slip;
  metricas.Q_teorico_superficie_m3s = Q_teorico_sup;
  metricas.Q_teorico_fondo_m3s = Q_teorico_fondo;
  metricas.Q_efectivo_m3s = Q_efectivo;
  metricas.Q_efectivo_m3d = Q_efectivo * 86400;
  metricas.carga_sup_max_N = max(carga_sup);
  metricas.carga_sup_min_N = min(carga_sup);
  metricas.carga_fondo_max_N = max(carga_fondo);
  metricas.carga_fondo_min_N = min(carga_fondo);
  metricas.trabajo_sup_J_ciclo = trabajo_sup;
  metricas.trabajo_fondo_J_ciclo = trabajo_fondo;
  metricas.potencia_sup_W = potencia_sup;
  metricas.potencia_fondo_W = potencia_fondo;
  metricas.modelo = 'metricas_bomba_Gibbs_AOS_v10';

  cartas = struct();
  cartas.carta_sup = [pos_sup_n(:), carga_sup(:)];
  cartas.carta_fondo = [pos_fondo_n(:), carga_fondo(:)];
end

function y = gradiente_periodico(x, t)
  x = x(:)'; t = t(:)'; n = length(x); y = zeros(size(x));
  if n < 3, return; end
  dt = median(diff(t));
  if isempty(dt) || ~isfinite(dt) || dt <= 0, dt = 1; end
  for i=1:n
      im=i-1; if im<1, im=n; end
      ip=i+1; if ip>n, ip=1; end
      y(i) = (x(ip)-x(im))/(2*dt);
  end
end

function W = integral_periodica(F, x)
  F = F(:)'; x = x(:)'; n = length(F);
  W = 0;
  for i=1:n
      ip = i+1; if ip>n, ip=1; end
      W = W + 0.5*(F(i)+F(ip))*(x(ip)-x(i));
  end
end

function v = leer_campo(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end
