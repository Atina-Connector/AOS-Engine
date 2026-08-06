function [p, ok] = gibbs3_pumping_unit_menu(p)
% GIBBS3_PUMPING_UNIT_MENU Seleccion visible del aparato de bombeo.

  p = gibbs3_defaults(p);
  ok = false;
  fprintf('\n====================================================\n');
  fprintf(' GF3 - APARATO DE BOMBEO\n');
  fprintf('====================================================\n');
  fprintf('  1 - Usar aparato definido en .aosdat/configuracion activa\n');
  fprintf('  2 - Seleccionar aparato desde catalogo AOS\n');
  fprintf('  3 - Ingresar aparato manualmente\n');
  fprintf('  4 - Seleccionar automaticamente desde catalogo\n');
  fprintf('  5 - Aparato generico con movimiento sinusoidal\n');
  fprintf('  0 - Cancelar\n');
  op = input('Seleccione opcion [2]: ');
  if isempty(op), op = 2; end
  if op == 0, return; end

  switch op
    case 1
      if ~datos_aparato_presentes(p)
        fprintf('La configuracion activa no contiene un aparato utilizable.\n');
        return;
      end
      [p, ok] = confirmar_existente(p);
    case 2
      [p, ok] = seleccionar_catalogo(p, false);
    case 3
      [p, ok] = ingresar_manual(p);
    case 4
      [p, ok] = seleccionar_catalogo(p, true);
    case 5
      p = configurar_generico(p);
      ok = true;
    otherwise
      fprintf('Opcion no valida.\n');
      return;
  end

  if ok
    p.gibbs3_movimiento_superficie = 'aparato_bombeo';
    try
      ciclo = gibbs3_pumping_unit_cycle(p, linspace(0,60/p.N_velocidad,181)');
      if max(ciclo.posicion_m)-min(ciclo.posicion_m) <= 0
        error('Carrera cinematica nula.');
      end
    catch err
      fprintf(2, 'Configuracion cinematica invalida: %s\n', err.message);
      p.pumping_unit_configured = 0;
      p.pumping_unit_config_confirmada = 0;
      ok = false;
      return;
    end
    imprimir_resumen(p);
  end
end

function [p, ok] = confirmar_existente(p)
  ok = false;
  fprintf('\nDatos leidos de la configuracion activa:\n');
  fprintf(' %s / %s / %s\n', p.pumping_unit_manufacturer, ...
    p.pumping_unit_model, p.pumping_unit_type);
  p.S_carrera = leer_numero('Carrera operativa (m)', p.S_carrera);
  p.N_velocidad = leer_numero('Velocidad operativa (spm)', p.N_velocidad);
  p.pumping_unit_stroke_max_m = leer_numero( ...
    'Carrera maxima del aparato (m)', max(p.pumping_unit_stroke_max_m,p.S_carrera));
  p.pumping_unit_spm_min = leer_numero('SPM minimo', p.pumping_unit_spm_min);
  p.pumping_unit_spm_max = leer_numero('SPM maximo', ...
    max(p.pumping_unit_spm_max,p.N_velocidad));
  p.pumping_unit_max_pr_load_kN = leer_opcional( ...
    'Capacidad maxima de carga PR (kN; n=desconocida)', ...
    p.pumping_unit_max_pr_load_kN);
  p.pumping_unit_gearbox_torque_kNm = leer_opcional( ...
    'Torque nominal reductor (kN.m; n=desconocido)', ...
    p.pumping_unit_gearbox_torque_kNm);
  p.pumping_unit_motor_power_kW = leer_opcional( ...
    'Potencia nominal motor (kW; n=desconocida)', ...
    p.pumping_unit_motor_power_kW);
  if p.S_carrera > p.pumping_unit_stroke_max_m || ...
      p.N_velocidad < p.pumping_unit_spm_min || ...
      p.N_velocidad > p.pumping_unit_spm_max
    fprintf('La condicion operativa excede el aparato configurado.\n');
    return;
  end
  p.pumping_unit_mode = 'aosdat_existente';
  p.pumping_unit_configured = 1;
  p.pumping_unit_config_confirmada = 1;
  ok = true;
end

function [p, ok] = seleccionar_catalogo(p, automatico)
  ok = false;
  cat = gibbs3_pumping_unit_catalog(p.pumping_unit_catalog_path);
  if automatico
    mask = false(1,numel(cat));
    for k = 1:numel(cat)
      mask(k) = cat(k).carrera_max_m >= p.S_carrera && ...
                cat(k).spm_max >= p.N_velocidad && ...
                cat(k).spm_min <= p.N_velocidad;
    end
    cat = cat(mask);
    if isempty(cat)
      fprintf('No hay aparatos del catalogo que cumplan carrera y SPM.\n');
      return;
    end
    puntaje = zeros(1,numel(cat));
    for k = 1:numel(cat)
      puntaje(k) = (cat(k).carrera_max_m-p.S_carrera) + ...
        0.02*(cat(k).spm_max-p.N_velocidad);
    end
    [~, idx] = sort(puntaje);
    cat = cat(idx);
    fprintf('\nAparatos compatibles ordenados por ajuste de carrera y velocidad:\n');
  else
    fprintf('\nCatalogo de aparatos de bombeo:\n');
  end

  for k = 1:numel(cat)
    fprintf(' %d - %s | %s | carrera max %.2f m | SPM %.1f-%.1f | torque %.1f kN.m\n', ...
      k, cat(k).modelo, cat(k).tipo, cat(k).carrera_max_m, ...
      cat(k).spm_min, cat(k).spm_max, cat(k).torque_max_kNm);
  end
  sel = input('Seleccione aparato [1]: ');
  if isempty(sel), sel = 1; end
  if ~isscalar(sel) || sel ~= round(sel) || sel < 1 || sel > numel(cat)
    fprintf('Seleccion invalida.\n');
    return;
  end
  p = aplicar_item(p, cat(sel));
  p.pumping_unit_mode = ternario(automatico, 'automatico_catalogo', 'catalogo');
  p.S_carrera = leer_numero('Carrera operativa (m)', min(p.S_carrera,p.pumping_unit_stroke_max_m));
  p.N_velocidad = leer_numero('Velocidad operativa (spm)', p.N_velocidad);
  if p.S_carrera > p.pumping_unit_stroke_max_m || p.N_velocidad > p.pumping_unit_spm_max
    fprintf('Carrera o velocidad excede el aparato seleccionado.\n');
    return;
  end
  p.pumping_unit_max_pr_load_kN = leer_opcional( ...
    'Capacidad maxima de carga PR (kN; n=desconocida)', p.pumping_unit_max_pr_load_kN);
  p.pumping_unit_motor_power_kW = leer_opcional( ...
    'Potencia nominal del motor (kW; n=desconocida)', p.pumping_unit_motor_power_kW);
  p.pumping_unit_mechanical_efficiency = leer_numero( ...
    'Eficiencia mecanica global', p.pumping_unit_mechanical_efficiency);
  p.pumping_unit_configured = 1;
  p.pumping_unit_config_confirmada = 1;
  ok = true;
end

function [p, ok] = ingresar_manual(p)
  ok = false;
  fprintf('\n--- TIPO Y CINEMATICA ---\n');
  fprintf(' 1 - Convencional con geometria explicita\n');
  fprintf(' 2 - Convencional, perfil representativo\n');
  fprintf(' 3 - Mark II, perfil representativo\n');
  fprintf(' 4 - Reverse Mark, perfil representativo\n');
  fprintf(' 5 - Balanceada por aire, perfil representativo\n');
  fprintf(' 6 - Hidraulica, perfil suave\n');
  fprintf(' 7 - Carrera larga / Rotaflex, perfil suave\n');
  fprintf(' 8 - Generica sinusoidal\n');
  tipo = input('Seleccione [2]: ');
  if isempty(tipo), tipo = 2; end

  p.pumping_unit_manufacturer = leer_texto('Fabricante', p.pumping_unit_manufacturer);
  p.pumping_unit_model = leer_texto('Modelo', p.pumping_unit_model);
  switch tipo
    case 1
      p.pumping_unit_type = 'Convencional';
      p.pumping_unit_kinematic_model = 'linkage_conventional';
      p = leer_geometria(p);
    case 2
      p.pumping_unit_type = 'Convencional';
      p.pumping_unit_kinematic_model = 'perfil_convencional_representativo';
    case 3
      p.pumping_unit_type = 'MarkII';
      p.pumping_unit_kinematic_model = 'perfil_markii_representativo';
    case 4
      p.pumping_unit_type = 'ReverseMark';
      p.pumping_unit_kinematic_model = 'perfil_reverse_mark_representativo';
    case 5
      p.pumping_unit_type = 'BalanceadaAire';
      p.pumping_unit_kinematic_model = 'perfil_balanceado_aire';
    case 6
      p.pumping_unit_type = 'Hidraulica';
      p.pumping_unit_kinematic_model = 'perfil_hidraulico_suave';
    case 7
      p.pumping_unit_type = 'CarreraLarga';
      p.pumping_unit_kinematic_model = 'perfil_carrera_larga';
    case 8
      p.pumping_unit_type = 'Generica';
      p.pumping_unit_kinematic_model = 'sinusoidal';
    otherwise
      fprintf('Tipo invalido.\n');
      return;
  end

  p.pumping_unit_stroke_max_m = leer_numero('Carrera maxima del aparato (m)', ...
    max(p.pumping_unit_stroke_max_m,p.S_carrera));
  p.S_carrera = leer_numero('Carrera operativa (m)', p.S_carrera);
  p.pumping_unit_spm_min = leer_numero('SPM minimo', p.pumping_unit_spm_min);
  p.pumping_unit_spm_max = leer_numero('SPM maximo', p.pumping_unit_spm_max);
  p.N_velocidad = leer_numero('SPM operativo', p.N_velocidad);
  p.pumping_unit_max_pr_load_kN = leer_opcional( ...
    'Carga maxima PR (kN; n=desconocida)', p.pumping_unit_max_pr_load_kN);
  p.pumping_unit_gearbox_torque_kNm = leer_opcional( ...
    'Torque nominal reductor (kN.m; n=desconocido)', p.pumping_unit_gearbox_torque_kNm);
  p.pumping_unit_motor_power_kW = leer_opcional( ...
    'Potencia nominal motor (kW; n=desconocida)', p.pumping_unit_motor_power_kW);
  p.pumping_unit_mechanical_efficiency = leer_numero( ...
    'Eficiencia mecanica global', p.pumping_unit_mechanical_efficiency);
  p.pumping_unit_counterbalance_torque_kNm = leer_opcional( ...
    'Torque de contrabalanceo instalado (kN.m; n=no modelar)', ...
    p.pumping_unit_counterbalance_torque_kNm);
  p.pumping_unit_counterbalance_phase_rad = leer_numero( ...
    'Fase contrabalanceo (rad)', p.pumping_unit_counterbalance_phase_rad);
  if p.S_carrera > p.pumping_unit_stroke_max_m || ...
      p.N_velocidad < p.pumping_unit_spm_min || p.N_velocidad > p.pumping_unit_spm_max
    fprintf('La condicion operativa excede carrera o rango SPM.\n');
    return;
  end
  p.pumping_unit_mode = 'manual';
  p.pumping_unit_configured = 1;
  p.pumping_unit_config_confirmada = 1;
  ok = true;
end

function p = leer_geometria(p)
  fprintf('\nGeometria simplificada de manivela, biela y balancin.\n');
  p.pumping_unit_crank_radius_m = leer_numero('Radio manivela (m)', p.pumping_unit_crank_radius_m);
  p.pumping_unit_pitman_length_m = leer_numero('Longitud biela/pitman (m)', p.pumping_unit_pitman_length_m);
  p.pumping_unit_beam_rear_arm_m = leer_numero('Brazo trasero balancin (m)', p.pumping_unit_beam_rear_arm_m);
  p.pumping_unit_beam_front_arm_m = leer_numero('Brazo delantero balancin (m)', p.pumping_unit_beam_front_arm_m);
  p.pumping_unit_crank_center_x_m = leer_numero('Centro manivela X respecto pivote (m)', p.pumping_unit_crank_center_x_m);
  p.pumping_unit_crank_center_y_m = leer_numero('Centro manivela Y respecto pivote (m)', p.pumping_unit_crank_center_y_m);
  p.pumping_unit_linkage_branch = round(leer_numero('Rama geometrica (+1 o -1)', p.pumping_unit_linkage_branch));
end

function p = configurar_generico(p)
  p.pumping_unit_manufacturer = 'AOS';
  p.pumping_unit_model = 'GENERICO_SINUSOIDAL';
  p.pumping_unit_type = 'Generica';
  p.pumping_unit_kinematic_model = 'sinusoidal';
  p.pumping_unit_mode = 'generico_sinusoidal';
  p.pumping_unit_stroke_max_m = max(p.pumping_unit_stroke_max_m,p.S_carrera);
  p.pumping_unit_spm_min = 0.1;
  p.pumping_unit_spm_max = max(p.pumping_unit_spm_max,p.N_velocidad);
  p.pumping_unit_configured = 1;
  p.pumping_unit_config_confirmada = 1;
end

function p = aplicar_item(p, item)
  p.pumping_unit_manufacturer = item.fabricante;
  p.pumping_unit_model = item.modelo;
  p.pumping_unit_type = item.tipo;
  p.pumping_unit_kinematic_model = item.modelo_cinematico;
  p.pumping_unit_stroke_max_m = item.carrera_max_m;
  p.pumping_unit_spm_min = item.spm_min;
  p.pumping_unit_spm_max = item.spm_max;
  p.pumping_unit_gearbox_torque_kNm = item.torque_max_kNm;
  p.pumping_unit_max_pr_load_kN = item.carga_pr_max_kN;
  p.pumping_unit_motor_power_kW = item.potencia_motor_kW;
  p.pumping_unit_catalog_source = item.origen;
end

function tf = datos_aparato_presentes(p)
  tf = isfield(p,'pumping_unit_model') && ~isempty(p.pumping_unit_model) && ...
       isfield(p,'pumping_unit_kinematic_model') && ...
       ~isempty(p.pumping_unit_kinematic_model) && ...
       isfinite(p.S_carrera) && p.S_carrera > 0;
end

function imprimir_resumen(p)
  fprintf('\n--- APARATO SELECCIONADO ---\n');
  fprintf('Fabricante / modelo : %s / %s\n', p.pumping_unit_manufacturer, p.pumping_unit_model);
  fprintf('Tipo                : %s\n', p.pumping_unit_type);
  fprintf('Modelo cinematico   : %s\n', p.pumping_unit_kinematic_model);
  fprintf('Carrera / velocidad : %.3f m / %.3f spm\n', p.S_carrera, p.N_velocidad);
  fprintf('Carrera maxima      : %.3f m\n', p.pumping_unit_stroke_max_m);
  imprimir_opcional('Carga PR maxima', p.pumping_unit_max_pr_load_kN, 'kN');
  imprimir_opcional('Torque nominal', p.pumping_unit_gearbox_torque_kNm, 'kN.m');
  imprimir_opcional('Potencia motor', p.pumping_unit_motor_power_kW, 'kW');
end

function imprimir_opcional(nombre, valor, unidad)
  if isfinite(valor)
    fprintf('%-20s: %.3f %s\n', nombre, valor, unidad);
  else
    fprintf('%-20s: NO INFORMADA\n', nombre);
  end
end

function v = leer_numero(etiqueta, actual)
  x = input(sprintf('%s [%.6g]: ', etiqueta, actual));
  if isempty(x), v = actual; else, v = x; end
end

function v = leer_opcional(etiqueta, actual)
  if isfinite(actual)
    def = sprintf('%.6g', actual);
  else
    def = 'n';
  end
  r = input(sprintf('%s [%s]: ', etiqueta, def), 's');
  if isempty(r)
    v = actual;
  elseif lower(strtrim(r(1))) == 'n'
    v = NaN;
  else
    x = str2double(strtrim(r));
    if isfinite(x), v = x; else, v = actual; end
  end
end

function s = leer_texto(etiqueta, actual)
  r = input(sprintf('%s [%s]: ', etiqueta, actual), 's');
  if isempty(r), s = actual; else, s = strtrim(r); end
end

function s = ternario(tf, a, b)
  if tf, s = a; else, s = b; end
end
