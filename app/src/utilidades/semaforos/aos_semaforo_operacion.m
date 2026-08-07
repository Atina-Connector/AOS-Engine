function sem = aos_semaforo_operacion(sistema, param, Ql, Qo, Qiny, detalle)
  % aos_semaforo_operacion.m - Semaforos operativos comunes de AOS.
  if nargin < 1 || isempty(sistema), sistema = 'AOS'; end
  if nargin < 2 || ~isstruct(param), param = struct(); end
  if nargin < 3 || isempty(Ql), Ql = 0; end
  if nargin < 4 || isempty(Qo), Qo = 0; end
  if nargin < 5 || isempty(Qiny), Qiny = 0; end
  if nargin < 6 || ~isstruct(detalle), detalle = struct(); end
  sistema = upper(strtrim(sistema));
  if strcmp(sistema, 'BM') && exist('bm_semaforo_operacion', 'file')
      try
          varillas = [];
          if isfield(param, 'varillas'), varillas = param.varillas; end
          sem = bm_semaforo_operacion(param, Ql, varillas, detalle);
          sem.sistema = 'BM';
          sem.modelo = 'semaforo_global_AOS_v13_BM';
          sem = normalizar_sem(sem);
          if isfield(param, 'diagnostico_tuberia') && isstruct(param.diagnostico_tuberia)
              sem.items = agregar_items_tuberia(sem.items, param.diagnostico_tuberia);
              sem.general = peor_estado(sem.items);
              sem.descripcion = descripcion_general(sem.general);
          end
          return;
      catch
      end
  end
  sem = struct();
  sem.sistema = sistema;
  sem.modelo = 'semaforo_global_AOS_v13';
  sem.items = struct('nombre', {}, 'estado', {}, 'mensaje', {});
  sem.items(end+1) = sem_item('PRODUCCION', estado_produccion(Ql), mensaje_produccion(Ql, Qo));
  [estado_p, msg_p, ok_p] = evaluar_presion_intake(param, Ql, detalle);
  if ok_p, sem.items(end+1) = sem_item('SUCCION_INTAKE', estado_p, msg_p); end
  if strcmp(sistema, 'JGL') || strcmp(sistema, 'GL')
      if Qiny > 0
          sem.items(end+1) = sem_item('GAS_INYECTADO', 'VERDE', ['Gas inyectado ', aos_formato_caudal_gas(Qiny), '.']);
      else
          sem.items(end+1) = sem_item('GAS_INYECTADO', 'AMARILLO', 'Sin caudal de gas inyectado informado o calculado.');
      end
      Pin = leer_num(param, {'P_iny_sup'}, NaN);
      Pwh = leer_num(param, {'P_wh'}, NaN);
      if isfinite(Pin) && isfinite(Pwh)
          if Pin <= Pwh
              sem.items(end+1) = sem_item('PRESION_INY', 'ROJO', 'P_iny <= P_wh. No hay margen evidente de inyeccion.');
          elseif Pin < 1.2*Pwh
              sem.items(end+1) = sem_item('PRESION_INY', 'AMARILLO', sprintf('Margen bajo: P_iny %.1f bar, P_wh %.1f bar.', Pin/1e5, Pwh/1e5));
          else
              sem.items(end+1) = sem_item('PRESION_INY', 'VERDE', sprintf('P_iny %.1f bar > P_wh %.1f bar.', Pin/1e5, Pwh/1e5));
          end
      end
  elseif strcmp(sistema, 'BES')
      [eT, mT, okT] = evaluar_temperatura_bes(param, detalle);
      if okT, sem.items(end+1) = sem_item('TEMPERATURA_MOTOR', eT, mT); end
      [eIR, mIR, okIR] = evaluar_aislacion_bes(detalle);
      if okIR, sem.items(end+1) = sem_item('AISLACION_MOTOR', eIR, mIR); end
  elseif strcmp(sistema, 'BM')
      sem.items = agregar_items_bm_generico(sem.items, param, detalle);
  end
  if isfield(param, 'diagnostico_tuberia') && isstruct(param.diagnostico_tuberia)
      sem.items = agregar_items_tuberia(sem.items, param.diagnostico_tuberia);
  else
      sem.items(end+1) = sem_item('TUBERIA', 'AMARILLO', 'Diagnostico comun de tuberia no disponible.');
  end
  sem.general = peor_estado(sem.items);
  sem.descripcion = descripcion_general(sem.general);
end

function sem = normalizar_sem(sem)
  if ~isfield(sem, 'sistema'), sem.sistema = 'AOS'; end
  if ~isfield(sem, 'items'), sem.items = struct('nombre', {}, 'estado', {}, 'mensaje', {}); end
  if ~isfield(sem, 'general'), sem.general = peor_estado(sem.items); end
  if ~isfield(sem, 'descripcion'), sem.descripcion = descripcion_general(sem.general); end
end
function it = sem_item(nombre, estado, mensaje)
  it = struct(); it.nombre = nombre; it.estado = upper(strtrim(estado)); it.mensaje = mensaje;
end
function e = estado_produccion(Ql)
  qd = Ql * 86400;
  if ~isfinite(qd) || qd <= 0, e = 'ROJO'; elseif qd < 1, e = 'AMARILLO'; else e = 'VERDE'; end
end
function m = mensaje_produccion(Ql, Qo)
  if Ql <= 0, m = 'Sin produccion calculada.'; else m = sprintf('Ql %.2f m3/d, Qo %.2f m3/d.', Ql*86400, Qo*86400); end
end
function [estado, mensaje, ok] = evaluar_presion_intake(param, Ql, detalle)
  ok = false; estado = 'AMARILLO'; mensaje = ''; P = NaN;
  if isstruct(detalle), P = leer_num(detalle, {'P_intake','P_succion','Pwf','P_wf'}, NaN); end
  if isnan(P), P = leer_num(param, {'P_intake','P_succion','Pwf','P_wf'}, NaN); end
  if isnan(P) && exist('calcular_columna_succion', 'file') && Ql >= 0
      try P = calcular_columna_succion(Ql, param); catch, P = NaN; end
  end
  if isnan(P), return; end
  ok = true;
  if P < 2e5, estado = 'ROJO'; mensaje = sprintf('Presion intake/succion %.2f bar: riesgo alto.', P/1e5);
  elseif P < 5e5, estado = 'AMARILLO'; mensaje = sprintf('Presion intake/succion %.2f bar: revisar margen.', P/1e5);
  else, estado = 'VERDE'; mensaje = sprintf('Presion intake/succion %.2f bar.', P/1e5); end
end
function [estado, mensaje, ok] = evaluar_temperatura_bes(param, detalle)
  ok = false; estado = 'AMARILLO'; mensaje = '';
  T = leer_num(detalle, {'T_motor','temperatura_motor'}, NaN); Tmax = leer_num(param, {'T_max_motor'}, NaN);
  if isnan(T) || isnan(Tmax), return; end
  ok = true;
  if T > Tmax, estado = 'ROJO'; mensaje = sprintf('T motor %.1f C supera limite %.1f C.', T, Tmax);
  elseif T > 0.90*Tmax, estado = 'AMARILLO'; mensaje = sprintf('T motor %.1f C cercana al limite %.1f C.', T, Tmax);
  else, estado = 'VERDE'; mensaje = sprintf('T motor %.1f C dentro de limite %.1f C.', T, Tmax); end
end
function [estado, mensaje, ok] = evaluar_aislacion_bes(detalle)
  ok = false; estado = 'AMARILLO'; mensaje = '';
  if ~isstruct(detalle) || ~isfield(detalle, 'IR_estado'), return; end
  ok = true; ir = upper(strtrim(detalle.IR_estado));
  if strcmp(ir, 'MALO') || strcmp(ir, 'CRITICO'), estado = 'ROJO';
  elseif strcmp(ir, 'REGULAR') || strcmp(ir, 'ADVERTENCIA'), estado = 'AMARILLO'; else, estado = 'VERDE'; end
  if isfield(detalle, 'IR_actual'), mensaje = sprintf('IR %.2f Mohm, estado %s.', detalle.IR_actual, detalle.IR_estado);
  else, mensaje = sprintf('Estado de aislacion %s.', detalle.IR_estado); end
end
function items = agregar_items_bm_generico(items, param, d)
  if isstruct(d)
      r = leer_num(d, {'relacion_stroke_fondo','relacion_carrera_fondo','transmision_carrera'}, NaN);
      Ss = leer_num(d, {'S_superficie_m','stroke_superficie_m'}, NaN); Sf = leer_num(d, {'S_fondo_m','stroke_fondo_m'}, NaN);
      if isnan(r) && isfinite(Ss) && isfinite(Sf), r = Sf/max(Ss,1e-9); end
      if isfinite(r)
          if r < 0.55, items(end+1) = sem_item('CARRERA_FONDO', 'ROJO', sprintf('Transmision baja: %.2f.', r));
          elseif r < 0.75 || r > 1.35, items(end+1) = sem_item('CARRERA_FONDO', 'AMARILLO', sprintf('Transmision dinamica %.2f. Puede existir amplificacion/atenuacion.', r));
          else, items(end+1) = sem_item('CARRERA_FONDO', 'VERDE', sprintf('Transmision dinamica %.2f.', r)); end
      end
      ll = leer_num(d, {'llenado_bomba','llenado'}, NaN);
      if isfinite(ll)
          if ll < 0.55, items(end+1) = sem_item('LLENADO_BM', 'ROJO', sprintf('Llenado bajo: %.0f%%.', 100*ll));
          elseif ll < 0.75, items(end+1) = sem_item('LLENADO_BM', 'AMARILLO', sprintf('Llenado parcial: %.0f%%.', 100*ll));
          else, items(end+1) = sem_item('LLENADO_BM', 'VERDE', sprintf('Llenado: %.0f%%.', 100*ll)); end
      end
  end
end
function items = agregar_items_tuberia(items, diag)
  if ~isfield(diag, 'perfil') || ~isstruct(diag.perfil), return; end
  p = diag.perfil; uso = NaN;
  if isfield(p, 'ratio_erosion') && ~isempty(p.ratio_erosion), uso = max(p.ratio_erosion); end
  alerta_erosion = false; if isfield(p, 'alerta') && isfield(p.alerta, 'erosion') && ~isempty(p.alerta.erosion), alerta_erosion = true; end
  if alerta_erosion, items(end+1) = sem_item('EROSION_TUBERIA', 'ROJO', 'Velocidad erosiva excedida segun API RP 14E simplificado.');
  elseif isfinite(uso) && uso > 0.80, items(end+1) = sem_item('EROSION_TUBERIA', 'AMARILLO', sprintf('Uso erosion %.2f x limite.', uso));
  elseif isfinite(uso), items(end+1) = sem_item('EROSION_TUBERIA', 'VERDE', sprintf('Uso erosion %.2f x limite.', uso)); end
  margen = NaN; if isfield(p, 'ratio_carga') && ~isempty(p.ratio_carga), margen = min(p.ratio_carga); end
  alerta_carga = false; if isfield(p, 'alerta') && isfield(p.alerta, 'carga') && ~isempty(p.alerta.carga), alerta_carga = true; end
  if alerta_carga && isfinite(margen), items(end+1) = sem_item('CARGA_LIQUIDO', 'AMARILLO', sprintf('Turner simplificado: %.2f x critico.', margen));
  elseif alerta_carga, items(end+1) = sem_item('CARGA_LIQUIDO', 'AMARILLO', 'Riesgo de carga segun Turner simplificado.');
  elseif isfinite(margen), items(end+1) = sem_item('CARGA_LIQUIDO', 'VERDE', sprintf('Margen Turner %.2f x critico.', margen)); end
  dom = regimen_dominante_seguro(p);
  if strcmp(dom, 'slug_severo'), items(end+1) = sem_item('REGIMEN_FLUJO', 'ROJO', 'Regimen dominante slug severo segun criterio simplificado.');
  elseif strcmp(dom, 'slug') || strcmp(dom, 'transicion'), items(end+1) = sem_item('REGIMEN_FLUJO', 'AMARILLO', ['Regimen dominante ', dom, ' segun criterio simplificado.']);
  elseif ~strcmp(dom, 'desconocido'), items(end+1) = sem_item('REGIMEN_FLUJO', 'VERDE', ['Regimen dominante ', dom, '.']); end
end
function dom = regimen_dominante_seguro(p)
  dom = 'desconocido'; if ~isfield(p, 'regimenes') || isempty(p.regimenes), return; end
  regs = p.regimenes; candidatos = {'burbuja','slug','slug_severo','transicion','niebla','desconocido'}; conteos = zeros(size(candidatos));
  for i=1:length(candidatos), conteos(i) = sum(strcmp(regs, candidatos{i})); end
  [~, idx] = max(conteos); dom = candidatos{idx};
end
function e = peor_estado(items)
  e = 'VERDE';
  for i=1:length(items)
      est = upper(strtrim(items(i).estado));
      if strcmp(est, 'ROJO'), e = 'ROJO'; return; end
      if strcmp(est, 'AMARILLO'), e = 'AMARILLO'; end
  end
end
function d = descripcion_general(e)
  e = upper(strtrim(e));
  if strcmp(e, 'VERDE'), d = 'Operacion preliminarmente normal.';
  elseif strcmp(e, 'AMARILLO'), d = 'Operacion posible con precauciones. Revisar detalle antes de ajustar.';
  else, d = 'Riesgo operativo alto. Revisar antes de operar o modificar parametros.'; end
end
function v = leer_num(s, nombres, defecto)
  v = defecto; if ~isstruct(s), return; end
  for k=1:length(nombres)
      n = nombres{k};
      if isfield(s, n)
          tmp = s.(n);
          if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1)), v = tmp(1); return; end
      end
  end
end
function y = m3s_a_mmscfd(q)
  y = q * 86400 / 0.0283168 / 1e6;
end
