function info = sens_validar_base_gl_jgl(p, sistema)
% SENS_VALIDAR_BASE_GL_JGL Valida el snapshot antes de una sensibilidad.
% Rechaza datos fuera de dominio; no corrige ni recorta silenciosamente.

  if nargin < 1 || ~isstruct(p), p = struct(); endif
  if nargin < 2 || isempty(sistema), sistema = 'GL_JGL'; endif
  sistema = upper(strtrim(sistema));

  info = struct('ok', true, 'errores', {{}}, 'advertencias', {{}}, ...
                'firma', '', 'firma_texto', '');

  wc = numero_local(p, 'WC', NaN);
  if ~isfinite(wc) || wc < 0 || wc > 1
    info.errores{end+1} = sprintf('WC debe ser una fraccion entre 0 y 1. Valor recibido: %.12g.', wc);
  endif

  ip = numero_local(p, 'IP', NaN);
  if ~isfinite(ip) || ip <= 0
    info.errores{end+1} = 'IP debe ser finito y positivo en unidades internas.';
  endif

  pres = numero_local(p, 'P_res', NaN);
  if ~isfinite(pres) || pres <= 0
    info.errores{end+1} = 'P_res debe ser finita y positiva.';
  endif

  pwh = numero_local(p, 'P_wh', NaN);
  if ~isfinite(pwh) || pwh < 0
    info.errores{end+1} = 'P_wh debe ser finita y no negativa.';
  endif

  diny = numero_local(p, 'D_iny', NaN);
  if ~isfinite(diny) || diny < 0
    info.errores{end+1} = 'D_iny debe ser finita y no negativa.';
  endif

  glr = numero_local(p, 'GLR', NaN);
  if ~isfinite(glr) || glr < 0
    info.errores{end+1} = 'GLR debe ser finito y no negativo.';
  endif

  if ~isfield(p, 'modelo_IPR') || ~ischar(p.modelo_IPR) || isempty(strtrim(p.modelo_IPR))
    info.errores{end+1} = 'modelo_IPR no esta definido.';
  endif
  if ~isfield(p, 'modelo_VLP') || ~ischar(p.modelo_VLP) || isempty(strtrim(p.modelo_VLP))
    info.errores{end+1} = 'modelo_VLP no esta definido.';
  endif

  fip = numero_local(p, 'factor_IP_residual', 1);
  if ~isfinite(fip) || fip <= 0
    info.errores{end+1} = 'factor_IP_residual debe ser finito y positivo.';
  endif

  if ~isempty(strfind(sistema, 'JGL'))
    an = numero_local(p, 'A_n', NaN);
    dt = numero_local(p, 'd_t', NaN);
    if ~isfinite(an) || an <= 0
      info.errores{end+1} = 'A_n debe ser finita y positiva para JGL.';
    endif
    if ~isfinite(dt) || dt <= 0
      info.errores{end+1} = 'd_t debe ser finito y positivo para JGL.';
    endif
  endif

  if isfinite(pres) && isfinite(pwh) && pres <= pwh
    info.advertencias{end+1} = 'P_res no supera P_wh; el caso puede no tener cruce nodal.';
  endif

  [info.firma, info.firma_texto] = sens_firma_config_gl_jgl(p);
  info.ok = isempty(info.errores);
endfunction

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = double(x(1));
    elseif ischar(x)
      y = str2double(x);
      if isfinite(y), v = y; endif
    endif
  endif
endfunction
