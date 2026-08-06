function res = gibbs_bm_resolver(param, varillas, opciones)
  % gibbs_bm_resolver.m
  % Motor comun de Bombeo Mecanico basado en la ecuacion de onda de Gibbs.
  %
  % Este modulo es el nucleo fisico BM v10. Tiene dos modos:
  %   - forward: diseno/simulacion desde cinematica superficial y modelo de bomba.
  %   - inverse: diagnostico desde carta dinamometrica de superficie.
  %
  % Unidades internas AOS/SI:
  %   posicion [m], carga [N], tiempo [s], presion [Pa], caudal [m3/s].
  %
  % Nota tecnica:
  %   La implementacion es intencionalmente Octave-compatible y liviana.
  %   No pretende afirmar equivalencia validada con QROD/SROD hasta que se
  %   compare contra casos de referencia, pero deja el camino fisico correcto:
  %   la carrera de fondo y las cartas salen de una ecuacion de onda, no de
  %   una eficiencia fija.

  if nargin < 1 || ~isstruct(param), param = struct(); end
  if nargin < 2 || isempty(varillas), varillas = []; end
  if nargin < 3 || isempty(opciones), opciones = struct(); end

  param = gibbs_param_defaults(param);
  opciones = gibbs_opciones_defaults(opciones);

  if isempty(varillas)
      try
          varillas = diseno_varillas(param, 0);
      catch
          varillas = gibbs_varillas_default(param);
      end
  end

  malla = gibbs_construir_malla_sarta(varillas, param, opciones);

  modo = opciones.modo;
  if isfield(opciones, 'carta_superficie') && ~isempty(opciones.carta_superficie)
      modo = 'inverse';
  elseif isfield(param, 'carta_superficie') && ~isempty(param.carta_superficie)
      modo = 'inverse';
      opciones.carta_superficie = param.carta_superficie;
  end

  switch lower(strtrim(modo))
    case {'forward','diseno','design'}
      res = gibbs_resolver_forward(param, varillas, malla, opciones);
    case {'inverse','inverso','diagnostico'}
      res = gibbs_resolver_inverso(param, varillas, malla, opciones);
    otherwise
      error('Modo Gibbs no reconocido: %s', modo);
  end

  res.parametros = param;
  res.varillas = varillas;
  res.malla = malla;
  res.version = 'AOS_BM_Gibbs_onda_v10';
end

function opciones = gibbs_opciones_defaults(opciones)
  if nargin < 1 || ~isstruct(opciones), opciones = struct(); end
  if ~isfield(opciones, 'modo'), opciones.modo = 'forward'; end
  if ~isfield(opciones, 'n_t'), opciones.n_t = 720; end
  if ~isfield(opciones, 'n_ciclos'), opciones.n_ciclos = 8; end
  if ~isfield(opciones, 'n_nodos_objetivo'), opciones.n_nodos_objetivo = 31; end
  if ~isfield(opciones, 'amortiguamiento'), opciones.amortiguamiento = 0.055; end
  if ~isfield(opciones, 'relajacion_carga'), opciones.relajacion_carga = 0.12; end
  if ~isfield(opciones, 'imprimir'), opciones.imprimir = false; end
  if ~isfield(opciones, 'graficar'), opciones.graficar = false; end
end

function varillas = gibbs_varillas_default(param)
  L = leer_campo(param, 'D_bomba', 1500);
  Dmm = 22.2;
  A = pi * (Dmm / 2000)^2;
  E = 207e9;
  rho = 7850;
  varillas.secciones(1).diametro_mm = Dmm;
  varillas.secciones(1).diametro_pulg = 7/8;
  varillas.secciones(1).longitud_m = L;
  varillas.secciones(1).area_m2 = A;
  varillas.secciones(1).masa_kg = A * L * rho;
  varillas.material = 'Acero Grado D';
  varillas.E_Pa = E;
  varillas.densidad_kg_m3 = rho;
  varillas.vel_onda_m_s = sqrt(E/rho);
  varillas.A_top_m2 = A;
  varillas.masa_total_kg = A * L * rho;
  varillas.peso_flotado_kg = varillas.masa_total_kg * 0.88;
  varillas.peso_fluido_kg = 0;
  varillas.K_rod_N_m = E * A / max(L, 1);
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
