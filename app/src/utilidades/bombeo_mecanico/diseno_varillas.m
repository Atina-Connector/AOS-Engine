function varillas = diseno_varillas(param, Ql)
  % diseno_varillas.m - Dimensionamiento preliminar del tren de varillas.
  % Modelo orientativo para BM. Calcula cargas, fatiga y datos necesarios
  % para las cartas Gibbs simplificadas.

  if nargin < 2, Ql = 0; end
  param = bm_defaults_diseno(param);

  D_bomba = param.D_bomba;
  D_bomba_mm = param.D_bomba_mm;
  S_carrera = param.S_carrera;
  N_velocidad = param.N_velocidad;
  rho_l = param.rho_o * (1 - param.WC) + param.rho_w * param.WC;

  % Material seleccionado.
  mats = cargar_materiales_varillas();
  mat = mats(1);
  for k = 1:length(mats)
      if strcmpi(strtrim(mats(k).nombre), strtrim(param.material_varillas))
          mat = mats(k);
          break;
      end
  end
  densidad = mat.densidad_kg_m3;
  E = mat.modulo_young_GPa * 1e9;
  limite_fatiga = mat.limite_fatiga_MPa * 1e6;
  Sut = mat.resistencia_ultima_MPa * 1e6;

  % Tren inicial tipico. Se conserva simple para no sobrediseniar el modulo.
  diam_mm = [25.4, 22.2, 19.1];
  diam_pulg = [1, 7/8, 3/4];
  area = pi * (diam_mm / 2000).^2;
  if D_bomba > 2000
      pct = [0.35, 0.35, 0.30];
  else
      pct = [0.30, 0.40, 0.30];
  end
  longitudes = D_bomba * pct;
  longitudes(end) = D_bomba - sum(longitudes(1:end-1));

  masa_secciones = longitudes .* area .* densidad;
  masa_total = sum(masa_secciones);
  factor_flot = max(0.05, 1 - rho_l / max(densidad, 1));
  peso_flotado_kgf = masa_total * factor_flot;

  A_bomba = pi * ((D_bomba_mm/1000)/2)^2;
  peso_fluido_kgf = A_bomba * D_bomba * rho_l;

  g = 9.81;
  omega = 2 * pi * max(N_velocidad, 0) / 60;
  S_piston_est = 0.85 * S_carrera;
  a_max = (S_piston_est / 2) * omega^2;
  factor_inercial = a_max / g;

  tension_max_kgf = peso_flotado_kgf + peso_fluido_kgf + masa_total * factor_inercial;
  tension_min_kgf = peso_flotado_kgf - masa_total * factor_inercial;

  sinker_bars = 0;
  peso_sinker_kg = 0;
  tension_min_obj = leer_campo(param, 'tension_min_obj_kg', 250);
  if tension_min_kgf < tension_min_obj
      peso_sinker_kg = (tension_min_obj - tension_min_kgf) * 1.10;
      sinker_bars = 1;
      tension_min_kgf = tension_min_kgf + peso_sinker_kg;
  end

  % Rigidez por secciones en serie.
  invK = 0;
  for i = 1:length(longitudes)
      invK = invK + longitudes(i) / max(E * area(i), 1e-9);
  end
  K_rod = 1 / max(invK, 1e-20);
  estiramiento_m = (peso_fluido_kgf * g) / max(K_rod, 1e-9);

  % Goodman conservador usando la seccion superior.
  sigma_max = tension_max_kgf * g / area(1);
  sigma_min = max(tension_min_kgf, 0) * g / area(1);
  sigma_a = max((sigma_max - sigma_min) / 2, 0);
  sigma_m = max((sigma_max + sigma_min) / 2, 0);
  denom = sigma_a / max(limite_fatiga, 1) + sigma_m / max(Sut, 1);
  fs_fatiga = 1 / max(denom, 1e-12);

  varillas = struct();
  for i = 1:length(diam_mm)
      varillas.secciones(i).diametro_mm = diam_mm(i);
      varillas.secciones(i).diametro_pulg = diam_pulg(i);
      varillas.secciones(i).longitud_m = longitudes(i);
      varillas.secciones(i).area_m2 = area(i);
      varillas.secciones(i).masa_kg = masa_secciones(i);
  end

  varillas.tension_max_kg = tension_max_kgf;
  varillas.tension_min_kg = tension_min_kgf;
  varillas.estiramiento_m = estiramiento_m;
  varillas.fs_fatiga = fs_fatiga;
  varillas.sinker_bars = sinker_bars;
  varillas.peso_sinker_kg = peso_sinker_kg;
  varillas.material = mat.nombre;
  varillas.masa_total_kg = masa_total;
  varillas.peso_flotado_kg = peso_flotado_kgf;
  varillas.peso_fluido_kg = peso_fluido_kgf;
  varillas.K_rod_N_m = K_rod;
  varillas.E_Pa = E;
  varillas.densidad_kg_m3 = densidad;
  varillas.vel_onda_m_s = sqrt(E / densidad);
  varillas.A_top_m2 = area(1);
  varillas.a_max_m_s2 = a_max;
  varillas.Ql_m3s = Ql;
  varillas.modelo = 'diseno_varillas_AOS_v09_orientativo';
end

function param = bm_defaults_diseno(param)
  if nargin < 1 || ~isstruct(param), param = struct(); end
  if ~isfield(param, 'D_bomba'), param.D_bomba = 1500; end
  if ~isfield(param, 'D_bomba_mm'), param.D_bomba_mm = 32; end
  if ~isfield(param, 'S_carrera'), param.S_carrera = 1.5; end
  if ~isfield(param, 'N_velocidad'), param.N_velocidad = 6; end
  if ~isfield(param, 'rho_o'), param.rho_o = 850; end
  if ~isfield(param, 'rho_w'), param.rho_w = 1000; end
  if ~isfield(param, 'WC'), param.WC = 0.5; end
  if ~isfield(param, 'material_varillas'), param.material_varillas = 'Acero Grado D'; end
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
