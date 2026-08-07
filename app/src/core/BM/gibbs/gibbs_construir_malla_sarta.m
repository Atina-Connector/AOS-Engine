function malla = gibbs_construir_malla_sarta(varillas, param, opciones)
  % Construye una malla axial equivalente para la sarta de varillas.
  % La malla respeta secciones taper por propiedades locales E, A y rho.

  if nargin < 3 || ~isstruct(opciones), opciones = struct(); end
  if ~isfield(opciones, 'n_nodos_objetivo'), opciones.n_nodos_objetivo = 31; end

  Ltotal = 0;
  for i = 1:length(varillas.secciones)
      Ltotal = Ltotal + max(varillas.secciones(i).longitud_m, 0);
  end
  if Ltotal <= 0
      Ltotal = leer_campo(param, 'D_bomba', 1500);
  end

  mats = cargar_materiales_seguro(param, varillas);
  Edef = leer_campo(varillas, 'E_Pa', mats.E);
  rhodef = leer_campo(varillas, 'densidad_kg_m3', mats.rho);

  n_obj = max(round(opciones.n_nodos_objetivo), 5);
  n_obj = min(n_obj, 121);
  x = linspace(0, Ltotal, n_obj);
  ne = length(x) - 1;

  A_e = zeros(1, ne);
  E_e = zeros(1, ne);
  rho_e = zeros(1, ne);
  d_e = zeros(1, ne);

  bordes = zeros(1, length(varillas.secciones)+1);
  for i = 1:length(varillas.secciones)
      bordes(i+1) = bordes(i) + max(varillas.secciones(i).longitud_m, 0);
  end
  if bordes(end) <= 0
      bordes(end) = Ltotal;
  end

  for e = 1:ne
      xm = 0.5 * (x(e) + x(e+1));
      isec = length(varillas.secciones);
      for s = 1:length(varillas.secciones)
          if xm >= bordes(s) && xm <= bordes(s+1) + 1e-9
              isec = s;
              break;
          end
      end
      sec = varillas.secciones(isec);
      if isfield(sec, 'area_m2') && sec.area_m2 > 0
          A_e(e) = sec.area_m2;
      else
          Dmm = leer_campo(sec, 'diametro_mm', 22.2);
          A_e(e) = pi * (Dmm / 2000)^2;
      end
      d_e(e) = sqrt(4*A_e(e)/pi);
      E_e(e) = leer_campo(sec, 'E_Pa', Edef);
      rho_e(e) = leer_campo(sec, 'densidad_kg_m3', rhodef);
  end

  dx = diff(x);
  k_e = E_e .* A_e ./ max(dx, 1e-9);
  m_n = zeros(1, length(x));
  for e = 1:ne
      me = rho_e(e) * A_e(e) * dx(e);
      m_n(e) = m_n(e) + 0.5 * me;
      m_n(e+1) = m_n(e+1) + 0.5 * me;
  end

  c_e = sqrt(E_e ./ max(rho_e, 1));
  c_min = min(c_e);
  c_max = max(c_e);

  rho_l = leer_rho_l(param);
  factor_flot = max(0.02, 1 - rho_l / max(mean(rho_e), 1));
  masa_total = sum(m_n);
  peso_flotado_N = masa_total * 9.81 * factor_flot;

  invK = 0;
  for e = 1:ne
      invK = invK + dx(e) / max(E_e(e)*A_e(e), 1e-12);
  end
  K_eq = 1 / max(invK, 1e-20);

  malla = struct();
  malla.x = x;
  malla.dx = dx;
  malla.A_e = A_e;
  malla.E_e = E_e;
  malla.rho_e = rho_e;
  malla.d_e = d_e;
  malla.k_e = k_e;
  malla.m_n = m_n;
  malla.c_e = c_e;
  malla.c_min = c_min;
  malla.c_max = c_max;
  malla.L = Ltotal;
  malla.n_nodos = length(x);
  malla.n_elementos = ne;
  malla.K_eq_N_m = K_eq;
  malla.masa_total_kg = masa_total;
  malla.peso_flotado_N = peso_flotado_N;
  malla.factor_flotacion = factor_flot;
  malla.A_top_m2 = A_e(1);
  malla.E_top_Pa = E_e(1);
  malla.dx_min = min(dx);
  malla.dt_estable = 0.82 * min(dx ./ max(c_e, 1));
end

function mats = cargar_materiales_seguro(param, varillas)
  mats.E = 207e9;
  mats.rho = 7850;
  try
      lista = cargar_materiales_varillas();
      nombre = '';
      if isstruct(varillas) && isfield(varillas, 'material')
          nombre = varillas.material;
      elseif isstruct(param) && isfield(param, 'material_varillas')
          nombre = param.material_varillas;
      end
      for i = 1:length(lista)
          if strcmpi(strtrim(lista(i).nombre), strtrim(nombre))
              mats.E = lista(i).modulo_young_GPa * 1e9;
              mats.rho = lista(i).densidad_kg_m3;
              return;
          end
      end
      if ~isempty(lista)
          mats.E = lista(1).modulo_young_GPa * 1e9;
          mats.rho = lista(1).densidad_kg_m3;
      end
  catch
  end
end

function rho_l = leer_rho_l(param)
  rho_o = leer_campo(param, 'rho_o', 850);
  rho_w = leer_campo(param, 'rho_w', 1000);
  WC = min(max(leer_campo(param, 'WC', 0.5), 0), 1);
  rho_l = rho_o * (1 - WC) + rho_w * WC;
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
