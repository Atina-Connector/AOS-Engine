function modo = jgl_modo_condicion_motriz(p)
% JGL_MODO_CONDICION_MOTRIZ Normaliza el contrato de presion motriz JGL.
% SENS-GLJGL-03. No deriva una presion en forma oculta: el modo AUTO es
% estricto y solo usa una presion superficial positiva ya informada.

  modo = 'AUTO_ESTRICTO';
  if nargin >= 1 && isstruct(p) && isfield(p,'jgl_condicion_motriz_modo') && ...
      ischar(p.jgl_condicion_motriz_modo) && ~isempty(strtrim(p.jgl_condicion_motriz_modo))
    modo = upper(strtrim(p.jgl_condicion_motriz_modo));
  endif

  if any(strcmp(modo, {'DERIVADA','DERIVAR','QINY','QINY_FORZADO', ...
                       'DERIVADA_DESDE_QINY','QINY_FORZADO_PRESION_DERIVADA'}))
    modo = 'DERIVADA_DESDE_QINY';
  elseif any(strcmp(modo, {'DISPONIBLE','PRESION','PRESION_INFORMADA', ...
                            'PRESION_DISPONIBLE','QINY_FORZADO_PRESION_VERIFICADA'}))
    modo = 'PRESION_DISPONIBLE';
  elseif any(strcmp(modo, {'SIN_PRESION','CERO_FISICO','NO_MOTRIZ', ...
                            'SIN_PRESION_MOTRIZ'}))
    modo = 'SIN_PRESION_MOTRIZ';
  elseif any(strcmp(modo, {'LEGACY','AUTO_LEGACY','MAXIMO_DISPONIBLE_CINETICO'}))
    modo = 'AUTO_LEGACY';
  else
    modo = 'AUTO_ESTRICTO';
  endif

  if strcmp(modo,'AUTO_ESTRICTO')
    psup = numero_local(p,'P_iny_sup',NaN);
    if isfinite(psup) && psup > 0
      modo = 'PRESION_DISPONIBLE';
    else
      modo = 'SIN_PRESION_MOTRIZ';
    endif
  endif
endfunction

function v = numero_local(s,c,d)
  v = d;
  if isstruct(s) && isfield(s,c)
    x = s.(c);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1))
      v = double(x(1));
    endif
  endif
endfunction
