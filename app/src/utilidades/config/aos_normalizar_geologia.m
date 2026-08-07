function [geol, avisos] = aos_normalizar_geologia(geol, param)
% Normaliza una seccion [GEOLOGIA] de .aosdat para los modulos AOS.
% Los campos ausentes se completan con valores conservadores y quedan
% registrados en geol.aos_campos_estimados. No reemplaza una petrofisica real.

  if nargin < 1 || ~isstruct(geol), geol = struct(); end
  if nargin < 2 || ~isstruct(param), param = struct(); end
  avisos = {};
  estimados = {};

  geol = alias_num(geol, 'porosidad', {'porosidad_fraccion'});
  geol = alias_num(geol, 'relacion_poisson', {'poisson'});
  geol = alias_num(geol, 'espesor_zona_petrolera', {'espesor_bruto_m'});
  geol = alias_num(geol, 'rho_petroleo', {'rho_o_kg_m3'});
  geol = alias_num(geol, 'rho_agua', {'rho_w_kg_m3'});
  geol = alias_num(geol, 'radio_pozo', {'radio_pozo_m'});
  geol = alias_num(geol, 'radio_drenaje', {'radio_drenaje_m'});
  geol = alias_num(geol, 'B_o', {'Bo'});

  geol = convertir_unidad(geol, 'UCS', {'UCS_MPa'}, 1e6);
  geol = convertir_unidad(geol, 'cohesion', {'cohesion_MPa'}, 1e6);
  geol = convertir_unidad(geol, 'modulo_young', {'modulo_young_GPa'}, 1e9);
  geol = convertir_unidad(geol, 'esfuerzo_vertical', {'esfuerzo_vertical_MPa'}, 1e6);
  geol = convertir_unidad(geol, 'esfuerzo_h_min', {'esfuerzo_h_min_MPa'}, 1e6);
  geol = convertir_unidad(geol, 'esfuerzo_H_max', {'esfuerzo_H_max_MPa'}, 1e6);

  if ~isfield(geol, 'angulo_friccion')
      [v, ok] = primero(geol, {'angulo_friccion_deg'});
      if ok, geol.angulo_friccion = v; end
  end

  % Permeabilidad interna en m2; los aliases *_mD se convierten.
  if ~isfield(geol, 'permeabilidad_h')
      [v, ok] = primero(geol, {'permeabilidad_h_mD','permeabilidad_mD'});
      if ok, geol.permeabilidad_h = v * 9.869233e-16; end
  elseif geol.permeabilidad_h > 1e-8
      geol.permeabilidad_h = geol.permeabilidad_h * 9.869233e-16;
      avisos{end+1} = 'permeabilidad_h interpretada como mD y convertida a m2.';
  end
  if ~isfield(geol, 'permeabilidad_v')
      [v, ok] = primero(geol, {'permeabilidad_v_mD'});
      if ok
          geol.permeabilidad_v = v * 9.869233e-16;
      elseif isfield(geol, 'permeabilidad_h')
          geol.permeabilidad_v = geol.permeabilidad_h * 0.10;
          estimados{end+1} = 'permeabilidad_v';
      end
  elseif geol.permeabilidad_v > 1e-8
      geol.permeabilidad_v = geol.permeabilidad_v * 9.869233e-16;
  end

  % Los punzados conservan su contrato tecnico completo. La altura
  % perforada se calcula solamente con intervalos activos.
  if isfield(geol,'intervalos')
      [geol.intervalos, avisos_pz] = aos_punzados_normalizar(geol.intervalos, ...
        struct('origen','GEOLOGIA'));
      avisos = [avisos, avisos_pz];
  endif
  if (~isfield(geol, 'altura_perforados') || isempty(geol.altura_perforados)) && ...
     isfield(geol, 'intervalos') && isstruct(geol.intervalos) && isfield(geol.intervalos, 'tramos')
      total = 0;
      for i = 1:length(geol.intervalos.tramos)
          if geol.intervalos.tramos(i).activo
              total = total + max(geol.intervalos.tramos(i).MD_hasta - ...
                geol.intervalos.tramos(i).MD_desde, 0);
          endif
      endfor
      geol.altura_perforados = total;
  endif

  % Valores comunes del caso activo.
  if ~isfield(geol, 'P_res') && isfield(param, 'P_res'), geol.P_res = param.P_res; end
  if ~isfield(geol, 'IP') && isfield(param, 'IP'), geol.IP = param.IP; end
  if ~isfield(geol, 'rho_petroleo') && isfield(param, 'rho_o'), geol.rho_petroleo = param.rho_o; end
  if ~isfield(geol, 'rho_agua') && isfield(param, 'rho_w'), geol.rho_agua = param.rho_w; end

  % Defaults conservadores necesarios para que el modulo pueda ejecutarse.
  [geol, estimados] = defecto(geol, estimados, 'tipo_formacion', 3);
  [geol, estimados] = defecto(geol, estimados, 'UCS', 60e6);
  [geol, estimados] = defecto(geol, estimados, 'angulo_friccion', 35);
  [geol, estimados] = defecto(geol, estimados, 'cohesion', 2e6);
  [geol, estimados] = defecto(geol, estimados, 'modulo_young', 30e9);
  [geol, estimados] = defecto(geol, estimados, 'relacion_poisson', 0.22);

  profundidad = 3000;
  if isfield(param, 'D_res') && es_num(param.D_res), profundidad = param.D_res; end
  Sv_def = max(22.5e6 * profundidad / 1000, 20e6);
  [geol, estimados] = defecto(geol, estimados, 'esfuerzo_vertical', Sv_def);
  [geol, estimados] = defecto(geol, estimados, 'esfuerzo_h_min', 0.72 * geol.esfuerzo_vertical);
  [geol, estimados] = defecto(geol, estimados, 'esfuerzo_H_max', 0.85 * geol.esfuerzo_vertical);
  [geol, estimados] = defecto(geol, estimados, 'porosidad', 0.08);
  [geol, estimados] = defecto(geol, estimados, 'permeabilidad_h', 1.0 * 9.869233e-16);
  [geol, estimados] = defecto(geol, estimados, 'permeabilidad_v', 0.10 * geol.permeabilidad_h);
  [geol, estimados] = defecto(geol, estimados, 'radio_poro', 0.02);
  [geol, estimados] = defecto(geol, estimados, 'diametro_grano_medio', 0.20);
  [geol, estimados] = defecto(geol, estimados, 'espesor_zona_petrolera', 20.0);
  [geol, estimados] = defecto(geol, estimados, 'altura_perforados', geol.espesor_zona_petrolera);
  [geol, estimados] = defecto(geol, estimados, 'radio_drenaje', 250.0);
  [geol, estimados] = defecto(geol, estimados, 'radio_pozo', 0.108);
  [geol, estimados] = defecto(geol, estimados, 'skin_factor', 0.0);
  [geol, estimados] = defecto(geol, estimados, 'rho_petroleo', 850.0);
  [geol, estimados] = defecto(geol, estimados, 'rho_agua', 1020.0);
  [geol, estimados] = defecto(geol, estimados, 'mu_petroleo', 1.5e-3);
  [geol, estimados] = defecto(geol, estimados, 'B_o', 1.05);
  [geol, estimados] = defecto(geol, estimados, 'factor_seguridad', 1.20);

  geol.angulo_friccion_rad = geol.angulo_friccion * pi / 180;
  geol.aos_autocargada_desde_aosdat = true;
  geol.aos_campos_estimados = estimados;
  if ~isempty(estimados)
      avisos{end+1} = sprintf('Geologia completada con %d campo(s) estimado(s); revisar antes de decisiones operativas.', length(estimados));
  end
end

function s = alias_num(s, destino, aliases)
  if isfield(s, destino) && es_num(s.(destino)), return; end
  [v, ok] = primero(s, aliases);
  if ok, s.(destino) = v; end
end

function s = convertir_unidad(s, destino, aliases, factor)
  if isfield(s, destino) && es_num(s.(destino)), return; end
  [v, ok] = primero(s, aliases);
  if ok, s.(destino) = v * factor; end
end

function [v, ok] = primero(s, campos)
  v = NaN; ok = false;
  for i = 1:length(campos)
      if isfield(s, campos{i})
          x = s.(campos{i});
          if es_num(x), v = x; ok = true; return; end
          if ischar(x)
              n = str2double(x);
              if ~isnan(n), v = n; ok = true; return; end
          end
      end
  end
end

function [s, lista] = defecto(s, lista, campo, valor)
  if ~isfield(s, campo) || isempty(s.(campo)) || (isnumeric(s.(campo)) && any(~isfinite(s.(campo))))
      s.(campo) = valor;
      lista{end+1} = campo;
  end
end

function tf = es_num(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x);
end
