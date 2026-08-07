function candidatos = gibbs3_rod_design_auto(param, material)
% GIBBS3_ROD_DESIGN_AUTO Genera candidatas uniformes y escalonadas.
% Cada candidata se evalua preliminarmente con cargas estaticas/dinamicas
% aproximadas. La verificacion definitiva puede ejecutarse luego con GF3.

  if nargin < 2 || ~isstruct(material)
    error('gibbs3_rod_design_auto requiere un material valido.');
  end

  diametros = unique(param.rod_allowed_diameters_mm(:)');
  diametros = sort(diametros);
  if isempty(diametros)
    error('No hay diametros permitidos para el diseno automatico.');
  end

  maxc = max(2, round(param.rod_auto_max_candidates));
  maxtr = max(1, min(round(param.rod_max_sections), numel(diametros)));
  idx_uniforme = diametro_uniforme_minimo(param, material, diametros);

  candidatos = candidato_vacio();
  candidatos = candidatos([]);

  % 1) Escalonada recomendada. Cuando hay al menos dos diametros y el
  % usuario permite varios tramos, se arma una configuracion realmente
  % escalonada y luego se verifica. No se oculta la alternativa uniforme.
  if maxtr >= 2 && numel(diametros) >= 2
    ntr = min([maxtr, 3, numel(diametros)]);
    idx_inf = max(1, idx_uniforme - 1);
    idx_sup = min(numel(diametros), max(idx_uniforme + ntr - 1, ntr));
    indices = idx_sup:-1:max(idx_sup-ntr+1,1);
    if numel(indices) < ntr
      indices = [indices, repmat(indices(end), 1, ntr-numel(indices))];
    end
    sec = secciones_patron(param, material, diametros(indices), fracciones_estandar(ntr));
    candidatos(end+1) = crear_candidato('ESCALONADA_RECOMENDADA', sec, ...
      param, material, 'Sarta escalonada equilibrada para verificacion GF3');
  end

  % 2) Escalonada conservadora.
  if maxtr >= 2 && numel(diametros) >= 3
    ntr = min([maxtr, 3, numel(diametros)]);
    idx_sup = min(numel(diametros), max(idx_uniforme + ntr, ntr+1));
    indices = idx_sup:-1:max(idx_sup-ntr+1,1);
    sec = secciones_patron(param, material, diametros(indices), fracciones_estandar(ntr));
    candidatos(end+1) = crear_candidato('ESCALONADA_CONSERVADORA', sec, ...
      param, material, 'Mayor margen de fatiga y carga superficial');
  end

  % 3) Dos tramos, util para comparar contra el diseno de tres tramos.
  if maxtr >= 2 && numel(diametros) >= 2
    idx_top = min(numel(diametros), max(idx_uniforme+1, 2));
    idx_bottom = max(1, idx_top-1);
    sec = secciones_patron(param, material, ...
      [diametros(idx_top), diametros(idx_bottom)], [0.55, 0.45]);
    candidatos(end+1) = crear_candidato('ESCALONADA_DOS_TRAMOS', sec, ...
      param, material, 'Alternativa simple de dos diametros');
  end

  % 4) Minimo peso por celdas. Puede resultar uniforme; se informa como tal.
  sec = construir_minimo_peso(param, material, diametros, ...
    param.rod_auto_target_utilization);
  candidatos(end+1) = crear_candidato('MINIMO_PESO_ESTIMADO', sec, ...
    param, material, 'Minimo peso preliminar sujeto al objetivo de utilizacion');

  % 5) Uniforme de referencia, siempre disponible.
  sec = crear_seccion(param.D_bomba, diametros(idx_uniforme), material);
  candidatos(end+1) = crear_candidato('UNIFORME_REFERENCIA', sec, ...
    param, material, 'Referencia uniforme de menor diametro estimado admisible');

  candidatos = eliminar_duplicados(candidatos);
  if numel(candidatos) > maxc
    candidatos = candidatos(1:maxc);
  end
end

function c = candidato_vacio()
  c = struct('nombre', '', 'secciones', [], 'masa_total_kg', NaN, ...
    'utilizacion_estimada_max', NaN, 'cumple_estimacion', false, ...
    'objetivo_utilizacion', NaN, 'material', '', 'escalonada', false, ...
    'motivo', '', 'verificacion_GF3_ok', false, ...
    'utilizacion_dinamica_max', NaN, 'aprobada_dinamica', false, ...
    'carga_superficie_max_kN', NaN, 'transmision_carrera', NaN, ...
    'score', Inf, 'mensaje_verificacion', 'NO_VERIFICADA');
end

function c = crear_candidato(nombre, sec, p, mat, motivo)
  [masa, umax] = evaluar_estimada(p, mat, sec);
  c = candidato_vacio();
  c.nombre = nombre;
  c.secciones = sec;
  c.masa_total_kg = masa;
  c.utilizacion_estimada_max = umax;
  c.cumple_estimacion = isfinite(umax) && umax <= 1.0;
  c.objetivo_utilizacion = p.rod_auto_target_utilization;
  c.material = mat.nombre;
  c.escalonada = numel(sec) > 1 && numel(unique([sec.diametro_mm])) > 1;
  c.motivo = motivo;
end

function idx = diametro_uniforme_minimo(p, mat, diametros)
  idx = numel(diametros);
  for k = 1:numel(diametros)
    sec = crear_seccion(p.D_bomba, diametros(k), mat);
    [~, u] = evaluar_estimada(p, mat, sec);
    if isfinite(u) && u <= p.rod_auto_target_utilization
      idx = k;
      return;
    end
  end
end

function sec = secciones_patron(p, mat, diametros_top_bottom, fracciones)
  fracciones = fracciones(:)' / sum(fracciones);
  n = numel(diametros_top_bottom);
  sec = crear_seccion(1.0, diametros_top_bottom(1), mat);
  sec = sec([]);
  for i = 1:n
    L = p.D_bomba * fracciones(i);
    if i == n
      L = p.D_bomba - sum([sec.longitud_m]);
    end
    sec(end+1) = crear_seccion(L, diametros_top_bottom(i), mat);
  end
end

function f = fracciones_estandar(n)
  if n <= 1
    f = 1;
  elseif n == 2
    f = [0.55, 0.45];
  elseif n == 3
    f = [0.36, 0.34, 0.30];
  elseif n == 4
    f = [0.29, 0.26, 0.24, 0.21];
  else
    f = ones(1,n) / n;
  end
end

function sec = construir_minimo_peso(p, mat, diametros, objetivo)
  L = p.D_bomba;
  nc = 160;
  dx = L / nc;
  rho_l = p.rho_o * (1-p.WC) + p.rho_w * p.WC;
  bf = max(1-rho_l/mat.rho_kg_m3, 0.05);
  g = p.gibbs3_gravedad_m_s2;
  [Fmean_pump, Falt_pump] = cargas_bomba_estimadas(p, rho_l);
  amax = aceleracion_maxima_aparato(p);

  dcell = zeros(nc,1);
  masa_bajo = 0;
  dmin_inferior = diametros(1);

  for i = nc:-1:1
    elegido = diametros(end);
    for k = 1:numel(diametros)
      d = diametros(k);
      if d < dmin_inferior, continue; end
      A = pi*(d/1000)^2/4;
      mcelda = mat.rho_kg_m3*A*dx;
      Fmean = Fmean_pump + (masa_bajo+0.5*mcelda)*g*bf;
      Falt = Falt_pump + (masa_bajo+0.5*mcelda)*amax;
      sigma_m = max(Fmean/A, 0);
      sigma_a = abs(Falt/A);
      util = p.rod_factor_seguridad * ...
        (sigma_a/(mat.Se_MPa*1e6) + sigma_m/(mat.Sut_MPa*1e6));
      if util <= objetivo
        elegido = d;
        break;
      end
    end
    dcell(i) = elegido;
    dmin_inferior = elegido;
    A = pi*(elegido/1000)^2/4;
    masa_bajo = masa_bajo + mat.rho_kg_m3*A*dx;
  end

  sec = comprimir_celdas(dcell, dx, mat);
  sec = limitar_tramos(sec, p.rod_max_sections, mat);
  sec = corregir_longitud(sec, L);
end

function [Fmean, Falt] = cargas_bomba_estimadas(p, rho_l)
  Ap = pi*(p.D_bomba_mm/1000)^2/4;
  if isfinite(p.D_bomba_TVD), tvd = p.D_bomba_TVD; else, tvd = p.D_bomba; end
  if isfinite(p.P_intake), Pintake = p.P_intake; else, Pintake = p.P_intake_min; end
  Pdesc = p.P_wh + rho_l*p.gibbs3_gravedad_m_s2*tvd;
  dP = max(Pdesc-Pintake, 0);
  llenado = p.eta_vol;
  if isfinite(p.gibbs3_llenado_bomba), llenado = p.gibbs3_llenado_bomba; end
  Fup = dP*Ap*llenado + p.gibbs3_friccion_ascenso_N;
  Fdown = p.gibbs3_friccion_descenso_N;
  Fmean = 0.5*(Fup+Fdown);
  Falt = 0.5*abs(Fup-Fdown);

  if p.bomba_lpp
    pp = p;
    if ~isfinite(pp.viscosidad_fluido_cP) || pp.viscosidad_fluido_cP <= 0
      pp.viscosidad_fluido_cP = 10.0;
    end
    bomba = struct('area_piston_m2', Ap, 'rho_liquido_kg_m3', rho_l);
    try
      ciclo = gibbs3_pumping_unit_cycle(p, linspace(0,60/p.N_velocidad,361)');
      vmax = max(abs(ciclo.velocidad_m_s));
    catch
      vmax = 0.5*p.S_carrera*(2*pi*p.N_velocidad/60);
    end
    lpp = gibbs3_lpp_hydraulics(pp, bomba, vmax);
    Falt = Falt + abs(lpp.F_firmada_N);
  end
end

function sec = comprimir_celdas(dcell, dx, mat)
  sec = crear_seccion(1.0, dcell(1), mat);
  sec = sec([]);
  inicio = 1;
  for i = 2:numel(dcell)+1
    if i > numel(dcell) || dcell(i) ~= dcell(inicio)
      sec(end+1) = crear_seccion((i-inicio)*dx, dcell(inicio), mat);
      inicio = i;
    end
  end
end

function sec = limitar_tramos(sec, maxtramos, mat)
  maxtramos = max(1, round(maxtramos));
  while numel(sec) > maxtramos
    longitudes = [sec.longitud_m];
    [~, idx] = min(longitudes);
    if idx == 1
      vecino = 2;
    elseif idx == numel(sec)
      vecino = idx-1;
    elseif sec(idx-1).diametro_mm >= sec(idx+1).diametro_mm
      vecino = idx-1;
    else
      vecino = idx+1;
    end
    dmerge = max(sec(idx).diametro_mm, sec(vecino).diametro_mm);
    Lmerge = sec(idx).longitud_m + sec(vecino).longitud_m;
    nuevo = crear_seccion(Lmerge, dmerge, mat);
    a = min(idx, vecino); b = max(idx, vecino);
    sec(a) = nuevo; sec(b) = [];
  end
end

function sec = corregir_longitud(sec, L)
  sec(end).longitud_m = sec(end).longitud_m + (L-sum([sec.longitud_m]));
end

function [masa, umax] = evaluar_estimada(p, mat, sec)
  rho_l = p.rho_o*(1-p.WC) + p.rho_w*p.WC;
  bf = max(1-rho_l/mat.rho_kg_m3, 0.05);
  [Fmean_pump, Falt_pump] = cargas_bomba_estimadas(p, rho_l);
  amax = aceleracion_maxima_aparato(p);
  masa = 0; masa_bajo = 0; umax = 0;
  for i = numel(sec):-1:1
    A = pi*(sec(i).diametro_mm/1000)^2/4;
    msec = sec(i).rho_kg_m3*A*sec(i).longitud_m;
    Fmean = Fmean_pump + (masa_bajo+0.5*msec)*p.gibbs3_gravedad_m_s2*bf;
    Falt = Falt_pump + (masa_bajo+0.5*msec)*amax;
    util = p.rod_factor_seguridad * ...
      (abs(Falt/A)/(sec(i).Se_MPa*1e6) + ...
       max(Fmean/A,0)/(sec(i).Sut_MPa*1e6));
    umax = max(umax, util);
    masa_bajo = masa_bajo + msec;
    masa = masa + msec;
  end
end

function amax = aceleracion_maxima_aparato(p)
  try
    t = linspace(0,60/p.N_velocidad,721)';
    ciclo = gibbs3_pumping_unit_cycle(p,t);
    amax = max(abs(ciclo.aceleracion_m_s2));
  catch
    omega = 2*pi*p.N_velocidad/60;
    amax = 0.5*p.S_carrera*omega^2;
  end
end

function s = crear_seccion(L, d, mat)
  s = struct('longitud_m', L, 'diametro_mm', d, 'E_Pa', mat.E_Pa, ...
    'rho_kg_m3', mat.rho_kg_m3, 'grado', mat.nombre, ...
    'Sut_MPa', mat.Sut_MPa, 'Se_MPa', mat.Se_MPa, ...
    'Sy_MPa', mat.Sy_MPa, 'tipo', 'varilla');
end

function out = eliminar_duplicados(in)
  keep = true(1,numel(in));
  for i = 2:numel(in)
    for j = 1:i-1
      if keep(j) && mismas_secciones(in(i).secciones, in(j).secciones)
        keep(i) = false;
        break;
      end
    end
  end
  out = in(keep);
end

function tf = mismas_secciones(a, b)
  tf = numel(a) == numel(b);
  if ~tf, return; end
  for i = 1:numel(a)
    if abs(a(i).longitud_m-b(i).longitud_m) > 1e-5 || ...
       abs(a(i).diametro_mm-b(i).diametro_mm) > 1e-6
      tf = false;
      return;
    end
  end
end
