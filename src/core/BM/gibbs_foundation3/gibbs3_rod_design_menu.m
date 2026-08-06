function [p, ok] = gibbs3_rod_design_menu(p)
% GIBBS3_ROD_DESIGN_MENU Configuracion visible y auditable de sarta.

  p = gibbs3_defaults(p);
  ok = false;

  fprintf('\n====================================================\n');
  fprintf(' GF3 - DISENO Y CONFIGURACION DE SARTA\n');
  fprintf('====================================================\n');
  fprintf('Aparato activo: %s / %s; carrera %.3f m; %.3f spm\n', ...
    p.pumping_unit_type, p.pumping_unit_model, p.S_carrera, p.N_velocidad);
  if p.bomba_lpp
    fprintf('Bomba de fondo: LPP AESIR; se incluye carga hidraulica.\n');
  else
    fprintf('Bomba de fondo: convencional.\n');
  end
  fprintf('  1 - Disenar sarta automaticamente\n');
  fprintf('  2 - Ingresar sarta manual por tramos\n');
  fprintf('  3 - Usar sarta uniforme\n');
  fprintf('  4 - Usar sarta existente del .aosdat/configuracion\n');
  fprintf('  0 - Cancelar\n');
  op = input('Seleccione opcion [1]: ');
  if isempty(op), op = 1; end
  if op == 0, return; end

  switch op
    case 1
      [p, material, okmat] = seleccionar_y_aplicar_material(p);
      if ~okmat, return; end
      [p, ok] = configurar_automatico(p, material);
    case 2
      [p, material, okmat] = seleccionar_y_aplicar_material(p);
      if ~okmat, return; end
      [p, ok] = configurar_manual(p, material);
    case 3
      [p, material, okmat] = seleccionar_y_aplicar_material(p);
      if ~okmat, return; end
      [p, ok] = configurar_uniforme(p, material);
    case 4
      if isempty(p.gibbs3_secciones_varillas)
        fprintf('No existe una sarta por tramos en la configuracion activa.\n');
        return;
      end
      p.gibbs3_secciones_varillas = normalizar_secciones(p.gibbs3_secciones_varillas, p);
      p.gibbs3_secciones_varillas_base = p.gibbs3_secciones_varillas;
      p.rod_design_mode = 'aosdat_existente';
      p.rod_design_candidate_name = 'SARTA_AOSDAT';
      p.rod_design_selection_reason = 'Configuracion leida del archivo o caso activo';
      p.rod_design_configured = 1;
      ok = true;
    otherwise
      fprintf('Opcion no valida.\n');
      return;
  end

  if ok
    p.rod_longitud_comercial_m = leer_numero( ...
      'Longitud comercial de cada varilla (m)', p.rod_longitud_comercial_m);
    p = configurar_barras_peso(p);
    p.gibbs3_secciones_varillas_base = p.gibbs3_secciones_varillas;
    imprimir_sarta(p);
    fprintf('\nLa sarta quedo configurada. GF3 verificara Goodman con las cargas dinamicas.\n');
  end
end

function [p, material, ok] = seleccionar_y_aplicar_material(p)
  catalogo = gibbs3_rod_catalog();
  [material, ok] = seleccionar_material(catalogo, p);
  if ok, p = aplicar_material(p, material); end
end

function [p, ok] = configurar_automatico(p, material)
  ok = false;
  fprintf('\n--- DISENO AUTOMATICO ---\n');
  fprintf('Diametros AOS disponibles: 15.9, 19.1, 22.2, 25.4 y 28.6 mm\n');
  fprintf('  1 - Permitir todos los diametros\n');
  fprintf('  2 - Ingresar diametros permitidos manualmente\n');
  od = input('Seleccione [1]: ');
  if isempty(od), od = 1; end
  if od == 2
    d = input('Vector de diametros en mm, por ejemplo [19.1 22.2 25.4]: ');
    if isempty(d) || any(~isfinite(d(:))) || any(d(:) <= 0)
      fprintf('Lista de diametros invalida.\n');
      return;
    end
    p.rod_allowed_diameters_mm = unique(d(:)');
  end

  p.rod_max_sections = round(leer_numero('Cantidad maxima de tramos', p.rod_max_sections));
  p.rod_max_sections = max(1, p.rod_max_sections);
  p.rod_factor_seguridad = leer_numero('Factor de seguridad Goodman', p.rod_factor_seguridad);
  p.rod_auto_target_utilization = leer_numero( ...
    'Objetivo de utilizacion preliminar', p.rod_auto_target_utilization);
  p.rod_auto_prefer_tapered = preguntar_sn( ...
    'Preferir sarta escalonada cuando resulte aprobada? (s/n) [s]: ', ...
    logical(p.rod_auto_prefer_tapered));
  p.rod_auto_dynamic_verify = preguntar_sn( ...
    'Verificar cada candidata con GF3 antes de elegir? (s/n) [s]: ', ...
    logical(p.rod_auto_dynamic_verify));

  candidatos = gibbs3_rod_design_auto(p, material);
  if isempty(candidatos)
    fprintf('No fue posible generar candidatas.\n');
    return;
  end

  if p.rod_auto_dynamic_verify
    candidatos = gibbs3_rod_design_verify_candidates(p, candidatos);
  end

  fprintf('\n--- ALTERNATIVAS GENERADAS ---\n');
  for k = 1:numel(candidatos)
    c = candidatos(k);
    fprintf('\n%d - %s%s\n', k, c.nombre, texto_escalonada(c.escalonada));
    desde = 0;
    for j = 1:numel(c.secciones)
      s = c.secciones(j);
      hasta = desde + s.longitud_m;
      fprintf('    Tramo %d: MD %.1f a %.1f m | %.1f m x %.1f mm - %s\n', ...
        j, desde, hasta, s.longitud_m, s.diametro_mm, s.grado);
      desde = hasta;
    end
    fprintf('    Masa estimada                : %.1f kg\n', c.masa_total_kg);
    fprintf('    Goodman estimado             : %.3f [%s]\n', ...
      c.utilizacion_estimada_max, texto_estado(c.cumple_estimacion));
    if c.verificacion_GF3_ok
      fprintf('    Goodman dinamico GF3         : %.3f [%s]\n', ...
        c.utilizacion_dinamica_max, texto_estado(c.aprobada_dinamica));
      fprintf('    Carga superficie maxima      : %.2f kN\n', c.carga_superficie_max_kN);
      fprintf('    Transmision de carrera       : %.1f %%\n', 100*c.transmision_carrera);
    else
      fprintf('    Verificacion GF3             : %s\n', c.mensaje_verificacion);
    end
    fprintf('    Criterio                     : %s\n', c.motivo);
  end

  pred = seleccionar_predeterminada(candidatos, p.rod_auto_prefer_tapered);
  sel = input(sprintf('Seleccione la sarta a utilizar [%d]: ', pred));
  if isempty(sel), sel = pred; end
  if sel < 1 || sel > numel(candidatos) || sel ~= round(sel)
    fprintf('Seleccion invalida.\n');
    return;
  end

  p.gibbs3_secciones_varillas = candidatos(sel).secciones;
  p.gibbs3_secciones_varillas_base = candidatos(sel).secciones;
  p.rod_design_mode = 'automatico';
  p.rod_design_configured = 1;
  p.rod_design_candidate_name = candidatos(sel).nombre;
  p.rod_design_estimated_utilization = candidatos(sel).utilizacion_estimada_max;
  p.rod_design_candidates = candidatos;
  if candidatos(sel).escalonada
    p.rod_design_selection_reason = ...
      'Sarta escalonada elegida entre candidatas y verificada por GF3';
  elseif candidatos(sel).verificacion_GF3_ok
    p.rod_design_selection_reason = ...
      'Sarta uniforme elegida por el usuario despues de comparar candidatas GF3';
  else
    p.rod_design_selection_reason = ...
      'Sarta seleccionada por el usuario con verificacion preliminar';
  end
  ok = true;
end

function idx = seleccionar_predeterminada(candidatos, preferir_escalonada)
  idx = 1;
  validos = [];
  for k = 1:numel(candidatos)
    if candidatos(k).verificacion_GF3_ok && candidatos(k).aprobada_dinamica
      if ~preferir_escalonada || candidatos(k).escalonada
        validos(end+1) = k;
      end
    end
  end
  if isempty(validos)
    for k = 1:numel(candidatos)
      if candidatos(k).cumple_estimacion && ...
          (~preferir_escalonada || candidatos(k).escalonada)
        validos(end+1) = k;
      end
    end
  end
  if isempty(validos)
    validos = 1:numel(candidatos);
  end
  scores = Inf(size(validos));
  for j = 1:numel(validos)
    k = validos(j);
    if isfinite(candidatos(k).score)
      scores(j) = candidatos(k).score;
    else
      scores(j) = candidatos(k).masa_total_kg;
    end
  end
  [~, j] = min(scores);
  idx = validos(j);
end

function [p, ok] = configurar_manual(p, material)
  ok = false;
  fprintf('\n--- SARTA MANUAL POR TRAMOS ---\n');
  n = round(leer_numero('Cantidad de tramos', max(1, p.rod_max_sections)));
  if n < 1
    fprintf('La cantidad de tramos debe ser positiva.\n');
    return;
  end

  sec = crear_seccion(1.0, p.gibbs3_diam_varilla_mm, material);
  sec = sec([]);
  for i = 1:n
    fprintf('\nTramo %d de %d (desde superficie hacia fondo)\n', i, n);
    L = input('Longitud (m): ');
    d = input('Diametro (mm): ');
    if isempty(L) || isempty(d) || ~isfinite(L) || ~isfinite(d) || L <= 0 || d <= 0
      fprintf('Datos invalidos. Se cancela la carga manual.\n');
      return;
    end
    sec(end+1) = crear_seccion(L, d, material);
  end

  suma = sum([sec.longitud_m]);
  tol = max(p.gibbs3_tolerancia_longitud_abs_m, ...
    p.gibbs3_tolerancia_longitud_rel*p.D_bomba);
  if abs(suma-p.D_bomba) > tol
    fprintf('\nLa suma de tramos es %.3f m y la profundidad de bomba es %.3f m.\n', ...
      suma, p.D_bomba);
    ajustar = preguntar_sn('Ajustar automaticamente el ultimo tramo? (s/n) [s]: ', true);
    if ~ajustar
      fprintf('La sarta no fue guardada.\n');
      return;
    end
    sec(end).longitud_m = sec(end).longitud_m + (p.D_bomba-suma);
    if sec(end).longitud_m <= 0
      fprintf('El ajuste produciria un ultimo tramo no positivo.\n');
      return;
    end
  end

  p.gibbs3_secciones_varillas = sec;
  p.gibbs3_secciones_varillas_base = sec;
  p.rod_design_mode = 'manual';
  p.rod_design_candidate_name = 'SARTA_MANUAL';
  p.rod_design_selection_reason = 'Configuracion ingresada manualmente';
  p.rod_design_candidates = [];
  p.rod_design_configured = 1;
  ok = true;
end

function [p, ok] = configurar_uniforme(p, material)
  ok = false;
  fprintf('\n--- SARTA UNIFORME ---\n');
  d = leer_numero('Diametro uniforme (mm)', p.gibbs3_diam_varilla_mm);
  if d <= 0
    fprintf('Diametro invalido.\n');
    return;
  end
  p.gibbs3_diam_varilla_mm = d;
  p.gibbs3_E_Pa = material.E_Pa;
  p.gibbs3_rho_varilla_kg_m3 = material.rho_kg_m3;
  p.gibbs3_secciones_varillas = crear_seccion(p.D_bomba, d, material);
  p.gibbs3_secciones_varillas_base = p.gibbs3_secciones_varillas;
  p.rod_design_mode = 'uniforme';
  p.rod_design_candidate_name = 'UNIFORME_USUARIO';
  p.rod_design_selection_reason = 'Diametro uniforme seleccionado por el usuario';
  p.rod_design_candidates = [];
  p.rod_design_configured = 1;
  ok = true;
end

function [material, ok] = seleccionar_material(catalogo, p)
  ok = false;
  material = struct();
  fprintf('\n--- TIPO / MATERIAL DE VARILLA ---\n');
  fprintf('Valores de catalogo para pre-diseno; validar contra fabricante.\n');
  for k = 1:numel(catalogo)
    fprintf('  %d - %s | E %.1f GPa | fatiga %.0f MPa | Sut %.0f MPa\n', ...
      k, catalogo(k).nombre, catalogo(k).E_Pa/1e9, ...
      catalogo(k).Se_MPa, catalogo(k).Sut_MPa);
  end
  fprintf('  %d - Ingresar propiedades manualmente\n', numel(catalogo)+1);
  fprintf('  %d - Mantener propiedades actuales [%s]\n', numel(catalogo)+2, p.rod_grade_name);
  op = input(sprintf('Seleccione [%d]: ', min(2, numel(catalogo))));
  if isempty(op), op = min(2, numel(catalogo)); end

  if op >= 1 && op <= numel(catalogo)
    material = catalogo(op); ok = true;
  elseif op == numel(catalogo)+1
    material.nombre = input('Nombre del material/grado: ', 's');
    if isempty(material.nombre), material.nombre = 'MATERIAL_MANUAL'; end
    material.rho_kg_m3 = input('Densidad (kg/m3): ');
    material.E_Pa = 1e9*input('Modulo de Young (GPa): ');
    material.Se_MPa = input('Limite de fatiga Se (MPa): ');
    material.Sut_MPa = input('Resistencia ultima Sut (MPa): ');
    material.Sy_MPa = input('Limite de fluencia Sy (MPa): ');
    material.origen = 'MANUAL'; material.certificado = 0;
    vals = [material.rho_kg_m3, material.E_Pa, material.Se_MPa, ...
      material.Sut_MPa, material.Sy_MPa];
    if any(~isfinite(vals)) || any(vals <= 0)
      fprintf('Propiedades manuales invalidas.\n'); return;
    end
    ok = true;
  elseif op == numel(catalogo)+2
    material.nombre = p.rod_grade_name;
    material.rho_kg_m3 = p.gibbs3_rho_varilla_kg_m3;
    material.E_Pa = p.gibbs3_E_Pa;
    material.Se_MPa = p.rod_Se_MPa;
    material.Sut_MPa = p.rod_Sut_MPa;
    material.Sy_MPa = p.rod_Sy_MPa;
    material.origen = 'CONFIGURACION_ACTUAL'; material.certificado = 0;
    ok = true;
  else
    fprintf('Seleccion de material invalida.\n');
  end
end

function p = aplicar_material(p, mat)
  p.rod_grade_name = mat.nombre;
  p.rod_catalog_source = mat.origen;
  p.gibbs3_E_Pa = mat.E_Pa;
  p.gibbs3_rho_varilla_kg_m3 = mat.rho_kg_m3;
  p.rod_Se_MPa = mat.Se_MPa;
  p.rod_Sut_MPa = mat.Sut_MPa;
  p.rod_Sy_MPa = mat.Sy_MPa;
end

function p = configurar_barras_peso(p)
  fprintf('\n--- BARRAS DE PESO ---\n');
  p.barras_peso_habilitadas = preguntar_sn( ...
    'Permitir calculo de barras de peso? (s/n) [s]: ', logical(p.barras_peso_habilitadas));
  if p.barras_peso_habilitadas
    p.barras_peso_diametro_mm = leer_numero( ...
      'Diametro de barras de peso (mm)', p.barras_peso_diametro_mm);
    p.barras_peso_longitud_unitaria_m = leer_numero( ...
      'Longitud comercial de cada barra de peso (m)', p.barras_peso_longitud_unitaria_m);
    p.barras_peso_margen = leer_numero( ...
      'Factor de margen para barras de peso', p.barras_peso_margen);
    p.barras_peso_tension_minima_N = leer_numero( ...
      'Tension minima deseada en fondo (N)', p.barras_peso_tension_minima_N);
    p.barras_peso_integrar_en_GF3 = preguntar_sn( ...
      'Integrar las barras calculadas en una segunda corrida GF3? (s/n) [s]: ', ...
      logical(p.barras_peso_integrar_en_GF3));
  end
end

function imprimir_sarta(p)
  fprintf('\n--- SARTA CONFIGURADA ---\n');
  fprintf('Modo / candidata: %s / %s\n', p.rod_design_mode, p.rod_design_candidate_name);
  fprintf('Criterio: %s\n', p.rod_design_selection_reason);
  fprintf('Material base: %s\n', p.rod_grade_name);
  fprintf('Longitud comercial: %.3f m por varilla\n', p.rod_longitud_comercial_m);
  sec = p.gibbs3_secciones_varillas;
  if isempty(sec)
    fprintf('Uniforme: %.1f mm x %.1f m\n', p.gibbs3_diam_varilla_mm, p.D_bomba);
    return;
  end
  desde = 0;
  for i = 1:numel(sec)
    grado = p.rod_grade_name;
    if isfield(sec(i), 'grado'), grado = sec(i).grado; end
    hasta = desde + sec(i).longitud_m;
    nfull = floor(sec(i).longitud_m/p.rod_longitud_comercial_m + 1e-9);
    ajuste = sec(i).longitud_m - nfull*p.rod_longitud_comercial_m;
    fprintf('Tramo %d: MD %.2f-%.2f m | %.2f m x %.1f mm - %s\n', ...
      i, desde, hasta, sec(i).longitud_m, sec(i).diametro_mm, grado);
    fprintf('          %d varillas completas', nfull);
    if ajuste >= p.rod_ajuste_minimo_m
      fprintf(' + ajuste/pony rod %.2f m', ajuste);
    end
    fprintf('\n');
    desde = hasta;
  end
end

function sec = normalizar_secciones(sec, p)
  for i = 1:numel(sec)
    if ~isfield(sec(i),'E_Pa'), sec(i).E_Pa = p.gibbs3_E_Pa; end
    if ~isfield(sec(i),'rho_kg_m3'), sec(i).rho_kg_m3 = p.gibbs3_rho_varilla_kg_m3; end
    if ~isfield(sec(i),'grado'), sec(i).grado = p.rod_grade_name; end
    if ~isfield(sec(i),'Sut_MPa'), sec(i).Sut_MPa = p.rod_Sut_MPa; end
    if ~isfield(sec(i),'Se_MPa'), sec(i).Se_MPa = p.rod_Se_MPa; end
    if ~isfield(sec(i),'Sy_MPa'), sec(i).Sy_MPa = p.rod_Sy_MPa; end
    if ~isfield(sec(i),'tipo'), sec(i).tipo = 'varilla'; end
  end
end

function s = crear_seccion(L, d, mat)
  s = struct('longitud_m', L, 'diametro_mm', d, 'E_Pa', mat.E_Pa, ...
    'rho_kg_m3', mat.rho_kg_m3, 'grado', mat.nombre, ...
    'Sut_MPa', mat.Sut_MPa, 'Se_MPa', mat.Se_MPa, ...
    'Sy_MPa', mat.Sy_MPa, 'tipo', 'varilla');
end

function v = leer_numero(etiqueta, actual)
  x = input(sprintf('%s [%.6g]: ', etiqueta, actual));
  if isempty(x), v = actual; else, v = x; end
end

function tf = preguntar_sn(mensaje, defecto)
  r = lower(strtrim(input(mensaje, 's')));
  if isempty(r), tf = defecto; else, tf = strcmp(r(1), 's'); end
end

function s = texto_estado(ok)
  if ok, s = 'CUMPLE'; else, s = 'REVISAR'; end
end

function s = texto_escalonada(tf)
  if tf, s = ' [ESCALONADA]'; else, s = ' [UNIFORME]'; end
end
