function modelo = aos_cad_hidraulica_aplicar_metadatos(modelo)
% AOS_CAD_HIDRAULICA_APLICAR_METADATOS Asigna modelo por tramo desde AOS_META.
  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada') || ...
      ~isfield(modelo.tablas_entrada, 'tramos') || ...
      ~isfield(modelo, 'geometria') || ~isfield(modelo.geometria, 'entidades_dxf')
    return;
  endif
  try
    prefs = aos_cad_topo_preferencias('cargar');
    tol = 2.0; if isfield(prefs, 'meta_tol_m'), tol = prefs.meta_tol_m; endif
    metas = aos_cad_extraer_metadatos(modelo.geometria.entidades_dxf, prefs);
  catch
    return;
  end_try_catch

  tramos = modelo.tablas_entrada.tramos;
  if isstruct(tramos), tramos = num2cell(tramos); endif
  for i = 1:numel(tramos)
    tr = tramos{i};
    if ~all(isfield(tr, {'x1','y1','x2','y2'})), continue; endif
    mx = (tr.x1 + tr.x2) / 2; my = (tr.y1 + tr.y2) / 2;
    capa = ''; if isfield(tr, 'capa'), capa = char(tr.capa); endif
    [meta, ~] = aos_cad_meta_cercana(metas, mx, my, tol, {'AOS_META', capa});
    if isempty(meta) || ~isfield(meta, 'keys'), continue; endif
    m = key_text_local(meta.keys, {'MODELO','MODEL','VLP'});
    if ~isempty(m), tr.modelo_hidraulico = normalizar_local(m); endif
    fid = key_text_local(meta.keys, {'FLUIDO','FLUID','FLUID_ID'});
    if ~isempty(fid), tr.fluido_id = fid; else tr.fluido_id = 'FLUIDO_001'; endif
    tramos{i} = tr;
  endfor
  modelo.tablas_entrada.tramos = tramos;
endfunction

function v = key_text_local(s, nombres)
  v = '';
  for i = 1:numel(nombres)
    if isfield(s, nombres{i}) && ~isempty(s.(nombres{i}))
      v = upper(strtrim(char(s.(nombres{i})))); return;
    endif
  endfor
endfunction

function m = normalizar_local(m)
  m = upper(strrep(strrep(strtrim(char(m)), '-', '_'), ' ', '_'));
  if any(strcmp(m, {'HB','HAGEDORN_BROWN'})), m = 'MULTIFASICO_HB'; endif
  if any(strcmp(m, {'DR','DUNS_ROS','DUNS&ROS'})), m = 'MULTIFASICO_DR'; endif
  if any(strcmp(m, {'SIMPLIFICADO','SIMPLE'})), m = 'MULTIFASICO_SIMPLIFICADO'; endif
  if any(strcmp(m, {'DARCY','DARCY_WEISBACH','MONOFASICO'})), m = 'MONOFASICO_DARCY'; endif
  if strcmp(m, 'AUTO'), m = 'AUTOMATICO'; endif
endfunction
