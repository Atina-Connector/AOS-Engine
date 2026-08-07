function plan = gibbs3_build_installation_plan(param)
% GIBBS3_BUILD_INSTALLATION_PLAN Convierte la sarta GF3 en un plan instalable.
%
% Esta funcion es publica para que resultados GF3 creados con versiones
% anteriores puedan reconstruir la tabla de tramos sin repetir la corrida.

  if nargin < 1 || ~isstruct(param)
    error('Se requiere una estructura de parametros GF3.');
  end

  try
    p = gibbs3_defaults(param);
  catch
    p = param;
  end

  sec = secciones_base_local(p);
  if isempty(sec)
    L = numero_local(p, 'D_bomba', NaN);
    d = numero_local(p, 'gibbs3_diam_varilla_mm', NaN);
    rho = numero_local(p, 'gibbs3_rho_varilla_kg_m3', 7850.0);
    grado = texto_local(p, 'rod_grade_name', 'NO_ESPECIFICADO');
    if ~isfinite(L) || L <= 0 || ~isfinite(d) || d <= 0
      plan = plan_vacio_local();
      return;
    end
    sec = struct('longitud_m', L, 'diametro_mm', d, ...
      'rho_kg_m3', rho, 'grado', grado, 'tipo', 'varilla');
  end

  plan = plan_vacio_local();
  desde = 0.0;
  Lc = numero_local(p, 'rod_longitud_comercial_m', 9.14);
  if ~isfinite(Lc) || Lc <= 0, Lc = 9.14; end
  ajuste_min = numero_local(p, 'rod_ajuste_minimo_m', 0.05);
  if ~isfinite(ajuste_min) || ajuste_min < 0, ajuste_min = 0.05; end

  for i = 1:numel(sec)
    tipo = texto_local(sec(i), 'tipo', 'varilla');
    if strcmpi(tipo, 'barra_peso')
      continue;
    end

    L = numero_local(sec(i), 'longitud_m', NaN);
    d = numero_local(sec(i), 'diametro_mm', NaN);
    if ~isfinite(L) || L <= 0 || ~isfinite(d) || d <= 0
      continue;
    end

    nfull = floor(L/Lc + 1e-10);
    ajuste = L - nfull*Lc;
    if ajuste > 1e-8 && ajuste < ajuste_min && nfull > 0
      nfull = nfull - 1;
      ajuste = L - nfull*Lc;
    end
    if abs(ajuste) < 1e-8, ajuste = 0; end
    nelt = nfull + double(ajuste > 1e-8);

    rho = numero_local(sec(i), 'rho_kg_m3', ...
      numero_local(p, 'gibbs3_rho_varilla_kg_m3', 7850.0));
    grado = texto_local(sec(i), 'grado', ...
      texto_local(p, 'rod_grade_name', 'NO_ESPECIFICADO'));
    A = pi*(d/1000)^2/4;

    item = struct();
    item.indice = numel(plan) + 1;
    item.desde_m = desde;
    item.hasta_m = desde + L;
    item.longitud_m = L;
    item.diametro_mm = d;
    item.grado = grado;
    item.longitud_comercial_m = Lc;
    item.cantidad_varillas_completas = nfull;
    item.ajuste_pony_rod_m = ajuste;
    item.cantidad_elementos = nelt;
    item.masa_kg = rho*A*L;
    plan(end+1) = item;
    desde = item.hasta_m;
  end
end

function plan = plan_vacio_local()
  plan = struct('indice', {}, 'desde_m', {}, 'hasta_m', {}, ...
    'longitud_m', {}, 'diametro_mm', {}, 'grado', {}, ...
    'longitud_comercial_m', {}, 'cantidad_varillas_completas', {}, ...
    'ajuste_pony_rod_m', {}, 'cantidad_elementos', {}, 'masa_kg', {});
end

function sec = secciones_base_local(p)
  sec = [];
  if isfield(p, 'gibbs3_secciones_varillas_base') && ...
      isstruct(p.gibbs3_secciones_varillas_base) && ...
      ~isempty(p.gibbs3_secciones_varillas_base)
    sec = p.gibbs3_secciones_varillas_base;
  elseif isfield(p, 'gibbs3_secciones_varillas') && ...
      isstruct(p.gibbs3_secciones_varillas) && ...
      ~isempty(p.gibbs3_secciones_varillas)
    sec = p.gibbs3_secciones_varillas;
  end
end

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = x(1);
    end
  end
end

function v = texto_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ischar(s.(campo)) && ...
      ~isempty(strtrim(s.(campo)))
    v = strtrim(s.(campo));
  end
end
