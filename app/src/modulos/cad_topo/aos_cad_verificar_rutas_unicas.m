function ok = aos_cad_verificar_rutas_unicas(mostrar)
% Verifica que las funciones publicas AOSCAD no esten ocultas por copias legacy.
% Tambien verifica unicidad de servicios geometry_3d y units (anti-sombra).
  if nargin < 1, mostrar = true; endif
  root = aos_cad_raiz();
  ok = true;

  ok = verificar_publica_local(root, 'aos_cad_abrir_externo.m', ...
      'aos_cad_abrir_externo', 'aos_cad_abrir_externo_impl.m', mostrar) && ok;
  ok = verificar_publica_local(root, 'AOS_menu_cad_topologia.m', ...
      'AOS_menu_cad_topologia', 'aos_cad_topologia_menu_impl.m', mostrar) && ok;

  hid_menu = fullfile(root, 'src', 'modulos', 'cad_topo', 'aos_cad_hidraulica_menu.m');
  if exist(hid_menu, 'file') ~= 2
    ok = false;
    if mostrar, fprintf(2, 'FALLO  falta submenu hidraulico: %s\n', hid_menu); endif
  elseif mostrar
    fprintf('OK  submenu hidraulico: %s\n', hid_menu);
  endif

  % Servicios geometry_3d / units (Sprint 2 Linea C)
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_punto_mas_cercano.m', 'aos_geom_punto_mas_cercano', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_fusionar_por_tolerancia.m', 'aos_geom_fusionar_por_tolerancia', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_bbox.m', 'aos_geom_bbox', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_axis2_matriz.m', 'aos_geom_axis2_matriz', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_transformar_bbox.m', 'aos_geom_transformar_bbox', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_geom_bbox_solape.m', 'aos_geom_bbox_solape', mostrar) && ok;
  ok = verificar_servicio_local(root, 'geometry_3d', ...
      'aos_escena_federada.m', 'aos_escena_federada', mostrar) && ok;
  ok = verificar_servicio_local(root, 'units', ...
      'aos_units_factor_a_metros.m', 'aos_units_factor_a_metros', mostrar) && ok;

  % Identidad asset_id (Sprint 2 Linea A) si ya existe en disco
  asset_archivos = {
    'aos_asset_clave_estable.m', 'aos_asset_clave_estable';
    'aos_asset_hash.m', 'aos_asset_hash';
    'aos_asset_id_generar.m', 'aos_asset_id_generar';
    'aos_asset_registro.m', 'aos_asset_registro';
    'aos_asset_identity_validar.m', 'aos_asset_identity_validar'
  };
  for k = 1:size(asset_archivos, 1)
    arch = asset_archivos{k, 1};
    fun = asset_archivos{k, 2};
    ruta = fullfile(root, 'src', 'services', 'geometry_3d', arch);
    if exist(ruta, 'file') == 2
      ok = verificar_servicio_local(root, 'geometry_3d', arch, fun, mostrar) && ok;
    endif
  endfor

  % Funciones HYD_LOOP (Sprint 4): unicidad de archivo bajo src/
  hyd_loop = {
    'aos_cad_hidraulica_lazos_base.m', 'aos_cad_hidraulica_lazos_base';
    'aos_cad_hidraulica_dp_orientado.m', 'aos_cad_hidraulica_dp_orientado';
    'aos_cad_hidraulica_resolver_lazos.m', 'aos_cad_hidraulica_resolver_lazos';
    'aos_cad_hidraulica_lazos_hardy_cross.m', 'aos_cad_hidraulica_lazos_hardy_cross'
  };
  for k = 1:size(hyd_loop, 1)
    arch = hyd_loop{k, 1};
    fun = hyd_loop{k, 2};
    esperado = fullfile(root, 'src', 'core', 'common', 'redes_hidraulicas', arch);
    encontrados = buscar_archivos_local(fullfile(root, 'src'), arch);
    activo = which(fun);
    if exist(esperado, 'file') ~= 2
      ok = false;
      if mostrar, fprintf(2, 'FALLO  falta HYD_LOOP: %s\n', esperado); endif
    elseif numel(encontrados) ~= 1
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  HYD_LOOP %s copias=%d\n', arch, numel(encontrados));
        for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
      endif
    elseif ~rutas_iguales_local(encontrados{1}, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  HYD_LOOP ruta no canonica %s\n', encontrados{1});
      endif
    elseif isempty(activo) || ~rutas_iguales_local(activo, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  which(%s)=%s esperado=%s\n', fun, activo, esperado);
      endif
    elseif mostrar
      fprintf('OK  HYD_LOOP unico %-40s %s\n', fun, activo);
    endif
  endfor

  % Funciones publicas cad_topo Sprint 5 (indice STEP / escena / vinculo)
  sprint5_cad = {
    'aos_step_tabla_entidades.m', 'aos_step_tabla_entidades';
    'aos_step_unidades.m', 'aos_step_unidades';
    'aos_step_indice_geometrico.m', 'aos_step_indice_geometrico';
    'aos_step_indice_freecad.m', 'aos_step_indice_freecad';
    'aos_cad_escena_3d.m', 'aos_cad_escena_3d';
    'aos_cad_visor_3d.m', 'aos_cad_visor_3d';
    'aos_cad_escena_seleccionar.m', 'aos_cad_escena_seleccionar';
    'aos_cad_vincular_asset_3d.m', 'aos_cad_vincular_asset_3d';
    'aos_cad_step_copia_edicion.m', 'aos_cad_step_copia_edicion';
    'aos_cad_traer_step_exportado.m', 'aos_cad_traer_step_exportado';
    'aos_cad_invalidar_escena_3d.m', 'aos_cad_invalidar_escena_3d'
  };
  for k = 1:size(sprint5_cad, 1)
    arch = sprint5_cad{k, 1};
    fun = sprint5_cad{k, 2};
    esperado = fullfile(root, 'src', 'modulos', 'cad_topo', arch);
    encontrados = buscar_archivos_local(fullfile(root, 'src'), arch);
    activo = which(fun);
    if exist(esperado, 'file') ~= 2
      ok = false;
      if mostrar, fprintf(2, 'FALLO  falta Sprint5 cad_topo: %s\n', esperado); endif
    elseif numel(encontrados) ~= 1
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint5 %s copias=%d\n', arch, numel(encontrados));
        for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
      endif
    elseif ~rutas_iguales_local(encontrados{1}, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint5 ruta no canonica %s\n', encontrados{1});
      endif
    elseif isempty(activo) || ~rutas_iguales_local(activo, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  which(%s)=%s esperado=%s\n', fun, activo, esperado);
      endif
    elseif mostrar
      fprintf('OK  Sprint5 unico %-40s %s\n', fun, activo);
    endif
  endfor

  % Funciones publicas cad_topo Sprint 6 (puertos / interferencias / overlay)
  % Cell Nx2: recorrer por filas (k,1)/(k,2); NO aplanar a 1xN (column-major).
  sprint6_cad = {
    'aos_cad_puertos_3d.m', 'aos_cad_puertos_3d';
    'aos_cad_conexiones_3d.m', 'aos_cad_conexiones_3d';
    'aos_cad_validar_conectividad_3d.m', 'aos_cad_validar_conectividad_3d';
    'aos_cad_interferencias.m', 'aos_cad_interferencias';
    'aos_cad_interferencias_mostrar.m', 'aos_cad_interferencias_mostrar';
    'aos_cad_overlay_resultados.m', 'aos_cad_overlay_resultados'
  };
  for k = 1:size(sprint6_cad, 1)
    arch = sprint6_cad{k, 1};
    fun = sprint6_cad{k, 2};
    esperado = fullfile(root, 'src', 'modulos', 'cad_topo', arch);
    encontrados = buscar_archivos_local(fullfile(root, 'src'), arch);
    activo = which(fun);
    if exist(esperado, 'file') ~= 2
      ok = false;
      if mostrar, fprintf(2, 'FALLO  falta Sprint6 cad_topo: %s\n', esperado); endif
    elseif numel(encontrados) ~= 1
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint6 %s copias=%d\n', arch, numel(encontrados));
        for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
      endif
    elseif ~rutas_iguales_local(encontrados{1}, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint6 ruta no canonica %s\n', encontrados{1});
      endif
    elseif isempty(activo) || ~rutas_iguales_local(activo, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  which(%s)=%s esperado=%s\n', fun, activo, esperado);
      endif
    elseif mostrar
      fprintf('OK  Sprint6 unico %-40s %s\n', fun, activo);
    endif
  endfor

  % Funciones publicas cad_topo Sprint 7 (invalidacion / sync / DXF / recursos)
  % Cell Nx2: recorrer por filas (k,1)/(k,2); NO aplanar a 1xN (column-major).
  sprint7_cad = {
    'aos_cad_invalidar_simulacion.m', 'aos_cad_invalidar_simulacion';
    'aos_cad_sincronizar_2d_3d.m', 'aos_cad_sincronizar_2d_3d';
    'aos_cad_dxf_copia_edicion.m', 'aos_cad_dxf_copia_edicion';
    'aos_aoscad_generar_recursos_visuales.m', 'aos_aoscad_generar_recursos_visuales'
  };
  for k = 1:size(sprint7_cad, 1)
    arch = sprint7_cad{k, 1};
    fun = sprint7_cad{k, 2};
    esperado = fullfile(root, 'src', 'modulos', 'cad_topo', arch);
    encontrados = buscar_archivos_local(fullfile(root, 'src'), arch);
    activo = which(fun);
    if exist(esperado, 'file') ~= 2
      ok = false;
      if mostrar, fprintf(2, 'FALLO  falta Sprint7 cad_topo: %s\n', esperado); endif
    elseif numel(encontrados) ~= 1
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint7 %s copias=%d\n', arch, numel(encontrados));
        for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
      endif
    elseif ~rutas_iguales_local(encontrados{1}, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  Sprint7 ruta no canonica %s\n', encontrados{1});
      endif
    elseif isempty(activo) || ~rutas_iguales_local(activo, esperado)
      ok = false;
      if mostrar
        fprintf(2, 'FALLO  which(%s)=%s esperado=%s\n', fun, activo, esperado);
      endif
    elseif mostrar
      fprintf('OK  Sprint7 unico %-40s %s\n', fun, activo);
    endif
  endfor
endfunction

function ok = verificar_publica_local(root, archivo, funcion, implementacion, mostrar)
  encontrados = buscar_archivos_local(fullfile(root, 'src'), archivo);
  esperado = fullfile(root, 'src', 'menu', archivo);
  activo = which(funcion);
  ok = true;

  if numel(encontrados) ~= 1
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  se encontraron %d copias publicas de %s\n', ...
              numel(encontrados), archivo);
      for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
    endif
  elseif ~rutas_iguales_local(encontrados{1}, esperado)
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  la copia publica no esta en la ruta canonica:\n%s\n', ...
              encontrados{1});
    endif
  endif

  if isempty(activo) || ~rutas_iguales_local(activo, esperado)
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  Octave tiene activa una implementacion inesperada de %s:\n%s\n', ...
              funcion, activo);
      fprintf(2, 'Esperada:\n%s\n', esperado);
    endif
  endif

  impl = fullfile(root, 'src', 'modulos', 'cad_topo', implementacion);
  if exist(impl, 'file') ~= 2
    ok = false;
    if mostrar, fprintf(2, 'FALLO  falta implementacion canonica: %s\n', impl); endif
  endif

  if ok && mostrar
    fprintf('OK  funcion publica unica %-28s %s\n', funcion, activo);
    fprintf('OK  implementacion       %-28s %s\n', funcion, impl);
  endif
endfunction

function ok = verificar_servicio_local(root, subdir, archivo, funcion, mostrar)
  encontrados = buscar_archivos_local(fullfile(root, 'src'), archivo);
  esperado = fullfile(root, 'src', 'services', subdir, archivo);
  activo = which(funcion);
  ok = true;

  if numel(encontrados) ~= 1
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  se encontraron %d copias de servicio %s\n', ...
              numel(encontrados), archivo);
      for i = 1:numel(encontrados), fprintf(2, ' - %s\n', encontrados{i}); endfor
    endif
  elseif ~rutas_iguales_local(encontrados{1}, esperado)
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  servicio %s no esta en ruta canonica:\n%s\n', ...
              archivo, encontrados{1});
      fprintf(2, 'Esperada:\n%s\n', esperado);
    endif
  endif

  if exist(esperado, 'file') ~= 2
    ok = false;
    if mostrar, fprintf(2, 'FALLO  falta servicio canonico: %s\n', esperado); endif
  endif

  if isempty(activo) || ~rutas_iguales_local(activo, esperado)
    ok = false;
    if mostrar
      fprintf(2, 'FALLO  Octave tiene activa una implementacion inesperada de %s:\n%s\n', ...
              funcion, activo);
      fprintf(2, 'Esperada:\n%s\n', esperado);
    endif
  endif

  if ok && mostrar
    fprintf('OK  servicio unico %-32s %s\n', funcion, activo);
  endif
endfunction

function lista = buscar_archivos_local(carpeta, nombre)
  lista = {};
  if exist(carpeta, 'dir') ~= 7, return; endif
  d = dir(carpeta);
  for i = 1:numel(d)
    n = d(i).name;
    if strcmp(n, '.') || strcmp(n, '..'), continue; endif
    ruta = fullfile(carpeta, n);
    if d(i).isdir
      sub = buscar_archivos_local(ruta, nombre);
      lista = [lista, sub]; %#ok<AGROW>
    elseif strcmp(n, nombre)
      lista{end+1} = ruta; %#ok<AGROW>
    endif
  endfor
endfunction

function tf = rutas_iguales_local(a, b)
  a0 = char(a); b0 = char(b);
  a = canonicalize_file_name(a0);
  b = canonicalize_file_name(b0);
  if isempty(a), a = a0; endif
  if isempty(b), b = b0; endif
  tf = strcmp(a, b);
endfunction
