function [ok, reporte] = aos_cad_sincronizar_2d_3d(opciones)
% AOS_CAD_SINCRONIZAR_2D_3D Orquestador de sincronizacion DXF/STEP 2D-3D.
% Orden fijo:
%   1 detectar mtime
%   2 reimportar fuente cambiada
%   3 invalidar simulacion y derivados
%   4 reconstruir tablas/topologia si cambio DXF
%   5 reconstruir indice/vinculo si cambio STEP
%   6 reconstruir escena
%   7 registrar mtime nuevo
%   8 devolver reporte
%
% [ok, reporte] = aos_cad_sincronizar_2d_3d(opciones)
% opciones.forzar = false
% opciones.reconstruir_topologia = true
% opciones.reconstruir_vinculo = true
% opciones.reconstruir_escena = true
% opciones.incluir_puertos = false
% opciones.silencioso = false
  global CONFIG_ACTIVA;
  ok = false;
  reporte = reporte_vacio_local();

  if nargin < 1 || isempty(opciones) || ~isstruct(opciones)
    opciones = struct();
  endif
  forzar = false;
  if isfield(opciones, 'forzar'), forzar = logical(opciones.forzar); endif
  reconstruir_topologia = true;
  if isfield(opciones, 'reconstruir_topologia')
    reconstruir_topologia = logical(opciones.reconstruir_topologia);
  endif
  reconstruir_vinculo = true;
  if isfield(opciones, 'reconstruir_vinculo')
    reconstruir_vinculo = logical(opciones.reconstruir_vinculo);
  endif
  reconstruir_escena = true;
  if isfield(opciones, 'reconstruir_escena')
    reconstruir_escena = logical(opciones.reconstruir_escena);
  endif
  incluir_puertos = false;
  if isfield(opciones, 'incluir_puertos')
    incluir_puertos = logical(opciones.incluir_puertos);
  endif
  silencioso = false;
  if isfield(opciones, 'silencioso'), silencioso = logical(opciones.silencioso); endif

  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    ok = true;
    if ~silencioso
      fprintf('Sincronizacion 2D/3D: sin CONFIG_ACTIVA.\n');
    endif
    return;
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    ok = true;
    if ~silencioso
      fprintf('Sincronizacion 2D/3D: sin cad_topologia activa.\n');
    endif
    return;
  endif

  ct = CONFIG_ACTIVA.cad_topologia;
  acciones = {};
  items = {};
  fuentes = {};

  % 1) Detectar mtime
  acciones{end+1} = 'DETECTAR_CAMBIOS'; %#ok<AGROW>
  [arch_dxf, mt_dxf_act, mt_dxf_prev, hay_dxf] = resolver_fuente_local(ct, 'dxf');
  [arch_step, mt_step_act, mt_step_prev, hay_step] = resolver_fuente_local(ct, 'step');

  cambio_dxf = false;
  cambio_step = false;
  if hay_dxf
    if forzar
      cambio_dxf = true;
    elseif ~isempty(mt_dxf_prev) && ~isempty(mt_dxf_act) ...
        && abs(mt_dxf_act - mt_dxf_prev) >= 1e-9
      cambio_dxf = true;
    endif
  endif
  if hay_step
    if forzar
      cambio_step = true;
    elseif ~isempty(mt_step_prev) && ~isempty(mt_step_act) ...
        && abs(mt_step_act - mt_step_prev) >= 1e-9
      cambio_step = true;
    endif
  endif

  if ~cambio_dxf && ~cambio_step
    reporte.fuentes_cambiadas = {};
    reporte.acciones = acciones;
    reporte.items = items;
    reporte.requiere_recalculo = false;
    reporte.escena_vigente = escena_vigente_local(CONFIG_ACTIVA.cad_topologia);
    reporte.counts = counts_local(CONFIG_ACTIVA.cad_topologia);
    ok = true;
    if ~silencioso
      fprintf('Sincronizacion 2D/3D: sin cambios de mtime.\n');
    endif
    return;
  endif

  if cambio_dxf, fuentes{end+1} = 'DXF'; endif %#ok<AGROW>
  if cambio_step, fuentes{end+1} = 'STEP'; endif %#ok<AGROW>

  % 2) Reimportar fuentes cambiadas (DXF antes que STEP)
  ok_imp = true;
  if cambio_dxf
    if ~silencioso
      fprintf('DXF modificado. Reimportando: %s\n', arch_dxf);
    endif
    acciones{end+1} = 'REIMPORTAR_DXF'; %#ok<AGROW>
    ok_d = aos_cad_importar_dxf(arch_dxf, true);
    ok_imp = ok_imp && ok_d;
    if ~ok_d
      items{end+1} = item_local('SYNC_REIMPORT_DXF_FALLO', ...
        sprintf('Fallo reimport DXF: %s', arch_dxf), 'ERROR'); %#ok<AGROW>
    endif
  endif
  if cambio_step
    if ~silencioso
      fprintf('STEP modificado. Reimportando: %s\n', arch_step);
    endif
    acciones{end+1} = 'REIMPORTAR_STEP'; %#ok<AGROW>
    ok_s = aos_cad_importar_step(arch_step, true);
    ok_imp = ok_imp && ok_s;
    if ~ok_s
      items{end+1} = item_local('SYNC_REIMPORT_STEP_FALLO', ...
        sprintf('Fallo reimport STEP: %s', arch_step), 'ERROR'); %#ok<AGROW>
    endif
  endif

  % 3) Invalidar simulacion y derivados (atomico; idempotente)
  acciones{end+1} = 'INVALIDAR_SIMULACION_DERIVADOS'; %#ok<AGROW>
  motivo = sprintf('Sincronizacion 2D/3D por cambio de %s', strjoin(fuentes, '+'));
  if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad)
    m = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
    opts_inv = struct( ...
      'codigo', 'INVALIDADA_POR_EDICION', ...
      'invalidar_escena', true, ...
      'limpiar_resultados', true, ...
      'invalidar_recursos', true, ...
      'accion', 'SINCRONIZAR_2D_3D', ...
      'origen', 'SYNC_2D_3D', ...
      'item_codigo', 'SIMULACION_INVALIDADA_POR_SYNC_2D_3D');
    [m, items_inv] = aos_cad_invalidar_simulacion(m, motivo, opts_inv);
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad = m;
    for ii = 1:numel(items_inv)
      items{end+1} = items_inv{ii}; %#ok<AGROW>
    endfor
  else
    aos_cad_invalidar_escena_3d(motivo, 'sync', struct('invalidar_simulacion', true));
  endif
  if isfield(CONFIG_ACTIVA.cad_topologia, 'escena_3d') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.escena_3d)
    CONFIG_ACTIVA.cad_topologia.escena_3d.vigente = false;
  endif
  if isfield(CONFIG_ACTIVA.cad_topologia, 'vinculo_3d') ...
      && isstruct(CONFIG_ACTIVA.cad_topologia.vinculo_3d)
    CONFIG_ACTIVA.cad_topologia.vinculo_3d.vigente = false;
  endif

  % 4) Reconstruir topologia si cambio DXF
  if cambio_dxf && reconstruir_topologia
    acciones{end+1} = 'RECONSTRUIR_TOPOLOGIA'; %#ok<AGROW>
    try
      if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
          && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad)
        aos_cad_construir_topologia(0.05, true);
      endif
    catch err
      items{end+1} = item_local('SYNC_TOPOLOGIA_FALLO', err.message, 'ADVERTENCIA'); %#ok<AGROW>
    end_try_catch
  endif

  % 5) Reconstruir indice/vinculo si cambio STEP
  if cambio_step && reconstruir_vinculo
    acciones{end+1} = 'RECONSTRUIR_INDICE_VINCULO'; %#ok<AGROW>
    try
      ct = CONFIG_ACTIVA.cad_topologia;
      if isfield(ct, 'step_productos') || isfield(ct, 'step_indice_geometrico')
        id_new = aos_cad_build_id_index_step(ct);
        if isfield(ct, 'step_indice_geometrico') && isstruct(ct.step_indice_geometrico)
          id_new = anexar_geometry_simple_local(id_new, ct.step_indice_geometrico);
        endif
        CONFIG_ACTIVA.cad_topologia.id_index_step = id_new;
      endif
      modelo = struct();
      if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
        modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
      endif
      [vin, modelo, items_v] = aos_cad_vincular_asset_3d(modelo, struct( ...
        'cad_topologia', CONFIG_ACTIVA.cad_topologia));
      CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
      CONFIG_ACTIVA.cad_topologia.vinculo_3d = vin;
      for ii = 1:numel(items_v)
        items{end+1} = items_v{ii}; %#ok<AGROW>
      endfor
    catch err
      items{end+1} = item_local('SYNC_VINCULO_FALLO', err.message, 'ADVERTENCIA'); %#ok<AGROW>
    end_try_catch
  endif

  % 6) Reconstruir escena
  escena_ok = false;
  if reconstruir_escena
    acciones{end+1} = 'RECONSTRUIR_ESCENA'; %#ok<AGROW>
    try
      opts_esc = struct( ...
        'incluir_pozo', false, ...
        'incluir_red', true, ...
        'incluir_step', true, ...
        'incluir_puertos', incluir_puertos);
      [esc, items_e] = aos_cad_escena_3d(CONFIG_ACTIVA.cad_topologia, opts_esc);
      CONFIG_ACTIVA.cad_topologia.escena_3d = esc;
      if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad') ...
          && isstruct(CONFIG_ACTIVA.cad_topologia.modelo_aoscad)
        CONFIG_ACTIVA.cad_topologia.modelo_aoscad.escena_3d = esc;
      endif
      escena_ok = isstruct(esc) && isfield(esc, 'vigente') && logical(esc.vigente);
      for ii = 1:numel(items_e)
        items{end+1} = items_e{ii}; %#ok<AGROW>
      endfor
    catch err
      items{end+1} = item_local('SYNC_ESCENA_FALLO', err.message, 'ADVERTENCIA'); %#ok<AGROW>
    end_try_catch
  endif

  % 7) Registrar mtime nuevo
  acciones{end+1} = 'REGISTRAR_MTIME'; %#ok<AGROW>
  if cambio_dxf && ~isempty(arch_dxf)
    aos_cad_registrar_mtime(arch_dxf);
  endif
  if cambio_step && ~isempty(arch_step)
    aos_cad_registrar_mtime(arch_step);
  endif

  % 8) Reporte
  reporte.fuentes_cambiadas = fuentes;
  reporte.acciones = acciones;
  reporte.items = items;
  reporte.requiere_recalculo = true;
  reporte.escena_vigente = escena_ok || escena_vigente_local(CONFIG_ACTIVA.cad_topologia);
  reporte.counts = counts_local(CONFIG_ACTIVA.cad_topologia);
  reporte.counts.n_fuentes_cambiadas = numel(fuentes);
  ok = ok_imp;

  if ~silencioso
    fprintf('Sincronizacion 2D/3D completa. Fuentes: %s | requiere_recalculo=%d | escena_vigente=%d\n', ...
      strjoin(fuentes, '+'), reporte.requiere_recalculo, reporte.escena_vigente);
  endif
endfunction

function reporte = reporte_vacio_local()
  reporte = struct();
  reporte.fuentes_cambiadas = {};
  reporte.acciones = {};
  reporte.items = {};
  reporte.requiere_recalculo = false;
  reporte.escena_vigente = false;
  reporte.counts = struct( ...
    'n_nodos', 0, ...
    'n_tramos', 0, ...
    'n_objetos_escena', 0, ...
    'n_fuentes_cambiadas', 0);
endfunction

function [archivo, mt_act, mt_prev, hay] = resolver_fuente_local(ct, prefijo)
  archivo = '';
  mt_act = [];
  mt_prev = [];
  hay = false;
  campo_arch = [prefijo '_archivo'];
  campo_mt = [prefijo '_mtime'];
  if ~isfield(ct, campo_arch) || isempty(ct.(campo_arch))
    return;
  endif
  archivo = char(ct.(campo_arch));
  if exist(archivo, 'file') ~= 2
    cand = fullfile(aos_cad_raiz(), archivo);
    if exist(cand, 'file') == 2
      archivo = cand;
    else
      return;
    endif
  endif
  hay = true;
  mt_act = aos_cad_mtime(archivo);
  if isfield(ct, campo_mt)
    mt_prev = ct.(campo_mt);
  endif
endfunction

function tf = escena_vigente_local(ct)
  tf = false;
  if ~isstruct(ct), return; endif
  if isfield(ct, 'escena_3d') && isstruct(ct.escena_3d) ...
      && isfield(ct.escena_3d, 'vigente')
    tf = logical(ct.escena_3d.vigente);
    return;
  endif
  if isfield(ct, 'modelo_aoscad') && isstruct(ct.modelo_aoscad) ...
      && isfield(ct.modelo_aoscad, 'escena_3d') ...
      && isstruct(ct.modelo_aoscad.escena_3d) ...
      && isfield(ct.modelo_aoscad.escena_3d, 'vigente')
    tf = logical(ct.modelo_aoscad.escena_3d.vigente);
  endif
endfunction

function c = counts_local(ct)
  c = struct('n_nodos', 0, 'n_tramos', 0, 'n_objetos_escena', 0, ...
    'n_fuentes_cambiadas', 0);
  if ~isstruct(ct), return; endif
  if isfield(ct, 'modelo_aoscad') && isstruct(ct.modelo_aoscad) ...
      && isfield(ct.modelo_aoscad, 'tablas_entrada')
    te = ct.modelo_aoscad.tablas_entrada;
    if isfield(te, 'nodos'), c.n_nodos = numel(te.nodos); endif
    if isfield(te, 'tramos'), c.n_tramos = numel(te.tramos); endif
  endif
  if isfield(ct, 'escena_3d') && isstruct(ct.escena_3d)
    if isfield(ct.escena_3d, 'n_objetos')
      c.n_objetos_escena = ct.escena_3d.n_objetos;
    elseif isfield(ct.escena_3d, 'objetos')
      c.n_objetos_escena = numel(ct.escena_3d.objetos);
    endif
  endif
endfunction

function it = item_local(codigo, mensaje, severidad)
  it = struct( ...
    'codigo', char(codigo), ...
    'mensaje', char(mensaje), ...
    'severidad', char(severidad), ...
    'origen', 'SYNC_2D_3D');
endfunction

function id_new = anexar_geometry_simple_local(id_new, indice)
  if ~isstruct(id_new) || ~isfield(id_new, 'items'), return; endif
  if ~isstruct(indice) || ~isfield(indice, 'ocurrencias'), return; endif
  mapa = struct();
  for i = 1:numel(indice.ocurrencias)
    oc = indice.ocurrencias{i};
    if ~isstruct(oc), continue; endif
    prod = '';
    if isfield(oc, 'producto'), prod = char(oc.producto); endif
    if isempty(prod) && isfield(oc, 'product_name'), prod = char(oc.product_name); endif
    gid = '';
    if isfield(oc, 'geometry_id'), gid = char(oc.geometry_id); endif
    if isempty(prod) || isempty(gid), continue; endif
    sk = safe_key_local(prod);
    if ~isfield(mapa, sk)
      mapa.(sk) = gid;
    endif
  endfor
  for i = 1:numel(id_new.items)
    it = id_new.items{i};
    if ~isstruct(it), continue; endif
    prod = '';
    if isfield(it, 'producto'), prod = char(it.producto); endif
    if isempty(prod) && isfield(it, 'nombre'), prod = char(it.nombre); endif
    if isempty(prod), continue; endif
    sk = safe_key_local(prod);
    if isfield(mapa, sk)
      it.geometry_id = mapa.(sk);
      id_new.items{i} = it;
    endif
  endfor
endfunction

function k = safe_key_local(s)
  k = upper(regexprep(char(s), '[^A-Za-z0-9_]', '_'));
  if isempty(k), k = 'X'; endif
  if isempty(regexp(k, '^[A-Za-z]', 'once'))
    k = ['A_' k];
  endif
endfunction
