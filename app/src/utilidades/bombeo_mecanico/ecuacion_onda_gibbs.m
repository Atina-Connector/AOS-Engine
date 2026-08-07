function [carta_sup, carta_fondo, t, u0, info] = ecuacion_onda_gibbs(cinematica, varillas, param, opciones)
  % ecuacion_onda_gibbs.m - Compatibilidad historica.
  % Desde v11 llama al modulo Gibbs BM de ecuacion de onda.
  if nargin < 4 || isempty(opciones), opciones = struct(); end
  if nargin < 3 || isempty(param), param = struct(); end
  if nargin < 2 || isempty(varillas), varillas = diseno_varillas(param, 0); end
  if nargin >= 1 && isstruct(cinematica) && isfield(cinematica, 'pos')
      param.S_carrera = max(cinematica.pos(:)) - min(cinematica.pos(:));
      if isfield(cinematica, 'N'), param.N_velocidad = cinematica.N; end
      if isfield(cinematica, 'tipo'), param.tipo_unidad = cinematica.tipo; end
  end
  res = gibbs_bm_resolver(param, varillas, opciones);
  carta_sup = res.carta_sup;
  carta_fondo = res.carta_fondo;
  t = res.t;
  u0 = res.posicion_superficie_m;
  info = res;
end
