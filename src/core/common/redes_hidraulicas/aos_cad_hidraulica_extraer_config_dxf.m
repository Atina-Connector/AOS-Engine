function cfg = aos_cad_hidraulica_extraer_config_dxf(modelo, cfg)
% AOS_CAD_HIDRAULICA_EXTRAER_CONFIG_DXF Lee metadatos hidraulicos opcionales.
% Claves admitidas en TEXT/MTEXT AOS_META:
% MODELO/VLP, API, WC, GLR, GAMMA_G, RHO_O, RHO_W, RHO, MU,
% T_K/TEMP_K, QG/QG_SM3D. Los metadatos no reemplazan las tablas editables.
  if nargin < 2 || isempty(cfg), cfg = aos_cad_hidraulica_defaults(struct()); endif
  if nargin < 1 || ~isstruct(modelo) || ~isfield(modelo, 'geometria') || ...
      ~isfield(modelo.geometria, 'entidades_dxf')
    return;
  endif

  entidades = modelo.geometria.entidades_dxf;
  try
    prefs = aos_cad_topo_preferencias('cargar');
  catch
    prefs = struct('meta_tol_m', 2.0);
  end_try_catch
  try
    metas = aos_cad_extraer_metadatos(entidades, prefs);
  catch
    metas = {};
  end_try_catch

  for i = 1:numel(metas)
    if ~isstruct(metas{i}) || ~isfield(metas{i}, 'keys'), continue; endif
    k = metas{i}.keys;
    cfg = aplicar_keys_local(cfg, k);
  endfor
endfunction

function cfg = aplicar_keys_local(cfg, k)
  if ~isstruct(k), return; endif
  modelo = get_text_local(k, {'MODELO','MODEL','VLP'});
  if ~isempty(modelo)
    cfg.modelo = normalizar_modelo_local(modelo);
  endif
  mm = get_text_local(k, {'MODELO_MULTIFASICO','VLP_MULTIFASICO'});
  if ~isempty(mm)
    cfg.modelo_multifasico = normalizar_modelo_local(mm);
  endif

  cfg.fluido.API = get_num_local(k, {'API'}, cfg.fluido.API);
  wc = get_num_local(k, {'WC','WATER_CUT'}, cfg.fluido.WC);
  if wc > 1 && wc <= 100, wc = wc / 100; endif
  cfg.fluido.WC = wc;
  cfg.fluido.GLR = get_num_local(k, {'GLR','GOR'}, cfg.fluido.GLR);
  cfg.fluido.gamma_g = get_num_local(k, {'GAMMA_G','SG_GAS'}, cfg.fluido.gamma_g);
  cfg.fluido.rho_o = get_num_local(k, {'RHO_O','RHO_OIL'}, cfg.fluido.rho_o);
  cfg.fluido.rho_w = get_num_local(k, {'RHO_W','RHO_WATER'}, cfg.fluido.rho_w);
  cfg.fluido.rho_g_std = get_num_local(k, {'RHO_G_STD'}, cfg.fluido.rho_g_std);
  cfg.fluido.mu_l_Pas = get_num_local(k, {'MU','MU_L','MU_L_PAS'}, cfg.fluido.mu_l_Pas);
  cfg.fluido.mu_g_Pas = get_num_local(k, {'MU_G','MU_G_PAS'}, cfg.fluido.mu_g_Pas);
  cfg.fluido.T_sup_K = get_num_local(k, {'T_K','TEMP_K','T_SUP_K'}, cfg.fluido.T_sup_K);
  cfg.fluido.T_fondo_K = get_num_local(k, {'T_FONDO_K'}, cfg.fluido.T_fondo_K);
endfunction

function v = get_num_local(s, nombres, defecto)
  v = defecto;
  for i = 1:numel(nombres)
    if isfield(s, nombres{i})
      x = s.(nombres{i});
      if isnumeric(x)
        y = x(1);
      else
        y = str2double(strrep(strtrim(char(x)), ',', '.'));
      endif
      if ~isnan(y), v = y; return; endif
    endif
  endfor
endfunction

function v = get_text_local(s, nombres)
  v = '';
  for i = 1:numel(nombres)
    if isfield(s, nombres{i}) && ~isempty(s.(nombres{i}))
      v = upper(strtrim(char(s.(nombres{i}))));
      return;
    endif
  endfor
endfunction

function m = normalizar_modelo_local(m)
  m = upper(strrep(strrep(strtrim(char(m)), '-', '_'), ' ', '_'));
  if any(strcmp(m, {'HB','HAGEDORN_BROWN','MULTIFASICO_HB'}))
    m = 'MULTIFASICO_HB';
  elseif any(strcmp(m, {'DR','DUNS_ROS','DUNS&ROS','MULTIFASICO_DR'}))
    m = 'MULTIFASICO_DR';
  elseif any(strcmp(m, {'SIMPLIFICADO','SIMPLE','MULTIFASICO_SIMPLIFICADO'}))
    m = 'MULTIFASICO_SIMPLIFICADO';
  elseif any(strcmp(m, {'DARCY','DARCY_WEISBACH','MONOFASICO','MONOFASICO_DARCY'}))
    m = 'MONOFASICO_DARCY';
  elseif strcmp(m, 'AUTO')
    m = 'AUTOMATICO';
  endif
endfunction
