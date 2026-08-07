function [firma, texto] = sens_firma_config_gl_jgl(p)
% SENS_FIRMA_CONFIG_GL_JGL Firma deterministica del snapshot GL/JGL.
% Qiny y el numero de puntos de las mallas se excluyen deliberadamente:
% Qiny es la variable barrida y la resolucion numerica se audita por separado.
% La firma detecta cambios de fisica, correlaciones, geometria y tolerancias.
% Compatible con GNU Octave.

  if nargin < 1 || ~isstruct(p), p = struct(); endif

  campos = { ...
    'modelo_IPR','modelo_VLP','IP','P_res','P_wh','P_iny_sup','P_b', ...
    'D_iny','D_res','WC','GLR','API','gamma_g','rho_o','rho_w', ...
    'rho_g_std','mu_o','mu_w','mu_g','Z','R_gas','T_sup','T_fondo', ...
    'diam_tbg','ID_tbg','ID_csg','rugosidad','factor_VLP', ...
    'factor_IP_residual','A_n','d_t','eta_n','eta_t','eta_d', ...
    'a_eductor','b_eductor','jgl_geometria_modo','jgl_condicion_motriz_modo', ...
    'jgl_presion_sup_estado','jgl_tol_presion_factibilidad_bar', ...
    'jgl_k_perdida_gas','jgl_eta_transfer', ...
    'jgl_factor_gas_liquido','jgl_alpha','jgl_tol_Q_rel', ...
    'jgl_tol_P_bar','jgl_tol_dP_bar','jgl_min_iter','jgl_max_iter', ...
    'sens_nodal_tol_P','sens_nodal_tol_Q_rel'};

  partes = {};
  for i = 1:numel(campos)
    c = campos{i};
    if isfield(p, c)
      partes{end+1} = [c '=' valor_texto_local(p.(c))]; %#ok<AGROW>
    else
      partes{end+1} = [c '=MISSING']; %#ok<AGROW>
    endif
  endfor

  if isfield(p, 'survey') && isstruct(p.survey)
    partes{end+1} = ['survey=' survey_texto_local(p.survey)]; %#ok<AGROW>
  else
    partes{end+1} = 'survey=NONE'; %#ok<AGROW>
  endif

  texto = partes{1};
  for i = 2:numel(partes)
    texto = [texto '|' partes{i}]; %#ok<AGROW>
  endfor

  try
    firma = hash('sha256', texto);
  catch
    cod = double(texto);
    firma = sprintf('FALLBACK-%08X-%d', ...
      mod(sum(cod .* (1:numel(cod))), 2^32), numel(cod));
  end_try_catch
endfunction

function txt = valor_texto_local(v)
  if ischar(v)
    txt = lower(strtrim(v));
  elseif isnumeric(v) || islogical(v)
    if isempty(v)
      txt = 'EMPTY';
    elseif isscalar(v)
      if isfinite(double(v))
        txt = sprintf('%.17g', double(v));
      elseif isnan(double(v))
        txt = 'NaN';
      elseif double(v) > 0
        txt = 'Inf';
      else
        txt = '-Inf';
      endif
    else
      vv = double(v(:)');
      txt = sprintf('n=%d:', numel(vv));
      for k = 1:numel(vv)
        if isfinite(vv(k))
          txt = [txt sprintf('%.12g,', vv(k))]; %#ok<AGROW>
        elseif isnan(vv(k))
          txt = [txt 'NaN,']; %#ok<AGROW>
        elseif vv(k) > 0
          txt = [txt 'Inf,']; %#ok<AGROW>
        else
          txt = [txt '-Inf,']; %#ok<AGROW>
        endif
      endfor
    endif
  else
    txt = ['CLASS:' class(v)];
  endif
endfunction

function txt = survey_texto_local(s)
  nombres = {'MD','TVD','ID','ID_tubing','diam_tbg','rugosidad', ...
             'inc','inclinacion','azi','azimut'};
  partes = {};
  for i = 1:numel(nombres)
    n = nombres{i};
    if isfield(s, n)
      partes{end+1} = [n ':' valor_texto_local(s.(n))]; %#ok<AGROW>
    endif
  endfor
  if isempty(partes)
    txt = 'STRUCT_WITHOUT_CANONICAL_FIELDS';
    return;
  endif
  txt = partes{1};
  for i = 2:numel(partes)
    txt = [txt ';' partes{i}]; %#ok<AGROW>
  endfor
endfunction
