function sem = bm_semaforo_operacion(param, Ql, varillas, detalle)
  % bm_semaforo_operacion.m - Semaforos rapidos para Bombeo Mecanico.
  %
  % Objetivo: recuperar la lectura rapida de campo. El semaforo no reemplaza
  % al informe; solo resume riesgo operativo preliminar.

  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(Ql), Ql = 0; end
  if nargin < 3, varillas = []; end
  if nargin < 4 || ~isstruct(detalle), detalle = struct(); end

  items = struct([]);
  items(end+1) = item('PRODUCCION', estado_produccion(Ql, detalle), msg_produccion(Ql, detalle));
  items(end+1) = item('LLENADO', estado_llenado(detalle), msg_llenado(detalle));
  items(end+1) = item('CARRERA_FONDO', estado_carrera(detalle), msg_carrera(detalle));
  items(end+1) = item('VARILLAS_FATIGA', estado_fatiga(varillas), msg_fatiga(varillas));
  items(end+1) = item('COMPRESION', estado_compresion(varillas), msg_compresion(varillas));
  items(end+1) = item('GIBBS', estado_gibbs(detalle), msg_gibbs(detalle));

  peor = peor_estado(items);
  sem = struct();
  sem.items = items;
  sem.general = peor;
  sem.descripcion = descripcion_general(peor);
  sem.modelo = 'semaforo_BM_AOS_v13';
end

function it = item(nombre, estado, mensaje)
  it.nombre = nombre;
  it.estado = estado;
  it.mensaje = mensaje;
end

function e = estado_produccion(Ql, d)
  qd = Ql * 86400;
  if qd <= 0
      e = 'ROJO';
  elseif isfield(d, 'Q_ipr_intake_min') && d.Q_ipr_intake_min > 0
      r = Ql / max(d.Q_ipr_intake_min, 1e-12);
      if r > 0.98
          e = 'AMARILLO';
      else
          e = 'VERDE';
      end
  else
      e = 'VERDE';
  end
end

function m = msg_produccion(Ql, d)
  if Ql <= 0
      m = 'Sin produccion calculada o bomba sin condicion de operacion.';
  elseif isfield(d, 'Q_ipr_intake_min') && d.Q_ipr_intake_min > 0 && Ql / max(d.Q_ipr_intake_min,1e-12) > 0.98
      m = 'Produccion cercana al limite IPR/intake. Revisar succion y llenado.';
  else
      m = 'Produccion dentro de capacidad preliminar del sistema.';
  end
end

function e = estado_llenado(d)
  ll = leer_det(d, 'llenado_bomba', leer_det(d, 'llenado_efectivo', NaN));
  if isnan(ll)
      e = 'AMARILLO';
  elseif ll >= 0.75
      e = 'VERDE';
  elseif ll >= 0.50
      e = 'AMARILLO';
  else
      e = 'ROJO';
  end
end

function m = msg_llenado(d)
  ll = leer_det(d, 'llenado_bomba', leer_det(d, 'llenado_efectivo', NaN));
  if isnan(ll)
      m = 'No se pudo estimar llenado de bomba.';
  else
      m = sprintf('Llenado estimado %.0f%%.', ll*100);
  end
end

function e = estado_carrera(d)
  Ss = leer_det(d, 'S_superficie_m', NaN);
  Sf = leer_det(d, 'S_fondo_m', NaN);
  if isnan(Ss) || isnan(Sf) || Ss <= 0
      e = 'AMARILLO';
      return;
  end
  r = Sf / max(Ss, 1e-9);
  if r >= 1.35
      e = 'AMARILLO';
  elseif r >= 0.80
      e = 'VERDE';
  elseif r >= 0.65
      e = 'AMARILLO';
  else
      e = 'ROJO';
  end
end

function m = msg_carrera(d)
  Ss = leer_det(d, 'S_superficie_m', NaN);
  Sf = leer_det(d, 'S_fondo_m', NaN);
  if isnan(Ss) || isnan(Sf) || Ss <= 0
      m = 'No hay carrera fondo/superficie confiable.';
  else
      
      r = Sf/max(Ss,1e-9);
      if r > 1.05
          m = sprintf('Carrera fondo/superficie %.2f: posible amplificacion dinamica.', r);
      else
          m = sprintf('Carrera fondo/superficie %.2f.', r);
      end
  end
end

function e = estado_fatiga(varillas)
  fs = leer_det(varillas, 'fs_fatiga', NaN);
  if isnan(fs)
      e = 'AMARILLO';
  elseif fs >= 1.50
      e = 'VERDE';
  elseif fs >= 1.10
      e = 'AMARILLO';
  else
      e = 'ROJO';
  end
end

function m = msg_fatiga(varillas)
  fs = leer_det(varillas, 'fs_fatiga', NaN);
  if isnan(fs)
      m = 'Sin factor de seguridad de fatiga disponible.';
  else
      m = sprintf('Factor de seguridad fatiga %.2f.', fs);
  end
end

function e = estado_compresion(varillas)
  tmin = leer_det(varillas, 'tension_min_kg', NaN);
  sinker = 0;
  if isstruct(varillas) && isfield(varillas, 'sinker_bars')
      sinker = varillas.sinker_bars;
  end
  if isnan(tmin)
      e = 'AMARILLO';
  elseif tmin > 500 && ~sinker
      e = 'VERDE';
  elseif tmin > 0
      e = 'AMARILLO';
  else
      e = 'ROJO';
  end
end

function m = msg_compresion(varillas)
  tmin = leer_det(varillas, 'tension_min_kg', NaN);
  if isnan(tmin)
      m = 'Sin tension minima de sarta disponible.';
  elseif tmin <= 0
      m = 'Riesgo de compresion/pandeo. Revisar barras de peso y velocidad.';
  else
      m = sprintf('Tension minima superficial %.0f kgf.', tmin);
  end
end

function e = estado_gibbs(d)
  ok = 0;
  if isfield(d, 'gibbs_ok'), ok = d.gibbs_ok; end
  modelo = '';
  if isfield(d, 'modelo') && ischar(d.modelo), modelo = lower(d.modelo); end
  if ok && ~isempty(strfind(modelo, 'estable'))
      e = 'VERDE';
  elseif ok
      e = 'AMARILLO';
  else
      e = 'AMARILLO';
  end
end

function m = msg_gibbs(d)
  modelo = 'sin modelo informado';
  if isfield(d, 'modelo') && ischar(d.modelo), modelo = d.modelo; end
  if isfield(d, 'gibbs_ok') && d.gibbs_ok
      m = ['Gibbs activo: ', modelo, '.'];
  else
      m = ['Gibbs no confirmado o fallback: ', modelo, '.'];
  end
end

function p = peor_estado(items)
  p = 'VERDE';
  for i=1:length(items)
      if strcmp(items(i).estado, 'ROJO')
          p = 'ROJO'; return;
      elseif strcmp(items(i).estado, 'AMARILLO')
          p = 'AMARILLO';
      end
  end
end

function d = descripcion_general(e)
  switch e
    case 'VERDE'
      d = 'Operacion preliminarmente normal.';
    case 'AMARILLO'
      d = 'Operacion posible con precauciones. Revisar detalle antes de ajustar velocidad.';
    otherwise
      d = 'Riesgo operativo alto. Reducir exigencia o revisar diseno.';
  end
end

function v = leer_det(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end
