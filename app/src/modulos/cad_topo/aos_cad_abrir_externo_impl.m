function ok = aos_cad_abrir_externo_impl(tipo, archivo)
% Abre DXF en LibreCAD o STEP en FreeCAD como proceso externo.
% Soporta ejecutables directos, Flatpak, Snap y AppImage.
  ok = false;
  if nargin < 1, tipo = 'DXF'; endif
  tipo = upper(strtrim(tipo));
  if nargin < 2 || isempty(archivo)
    archivo = resolver_archivo_local(tipo);
  endif
  if isempty(archivo)
    fprintf('Operacion cancelada.\n');
    return;
  endif
  if exist(archivo, 'file') ~= 2
    fprintf('No existe el archivo: %s\n', archivo);
    return;
  endif

  if strcmp(tipo, 'DXF')
    det = aos_cad_localizar_programa('LibreCAD');
    etiqueta = 'LibreCAD';
  else
    det = aos_cad_localizar_programa('FreeCAD');
    etiqueta = 'FreeCAD';
  endif

  if ~det.encontrado || ~det.gui_disponible || isempty(det.gui_cmd)
    fprintf('No se encontro un editor grafico utilizable para %s.\n', tipo);
    fprintf('Ejecute DIAGNOSTICAR_EDITORES_AOSCAD para ver el metodo de instalacion.\n');
    aos_verificar_requisitos_plataforma(true);
    return;
  endif

  archivo = char(archivo);
  origen = archivo;
  if strcmp(tipo, 'STEP')
    try
      [archivo, info_c] = aos_cad_step_copia_edicion(origen, struct());
    catch err
      fprintf(2, 'No se pudo preparar copia de edicion STEP: %s\n', err.message);
      return;
    end_try_catch
    if isfield(info_c, 'copiado') && info_c.copiado
      fprintf('Copia de trabajo creada (fixtures/origen intactos):\n  %s\n', archivo);
    elseif isfield(info_c, 'reutilizado') && info_c.reutilizado
      fprintf('Usando copia de trabajo existente:\n  %s\n', archivo);
    endif
  elseif strcmp(tipo, 'DXF')
    try
      [archivo, info_c] = aos_cad_dxf_copia_edicion(origen, struct());
    catch err
      fprintf(2, 'No se pudo preparar copia de edicion DXF: %s\n', err.message);
      return;
    end_try_catch
    if isfield(info_c, 'copiado') && info_c.copiado
      fprintf('Copia de trabajo creada (fixtures/origen intactos):\n  %s\n', archivo);
    elseif isfield(info_c, 'reutilizado') && info_c.reutilizado
      fprintf('Usando copia de trabajo existente:\n  %s\n', archivo);
    endif
  endif

  ok = lanzar_desacoplado_local(det, archivo);
  if ok
    fprintf('Archivo enviado a %s (proceso independiente).\n', etiqueta);
    fprintf('Archivo : %s\n', archivo);
    fprintf('Metodo  : %s\n', det.metodo);
    fprintf('Comando : %s\n', det.gui_cmd);
    if strcmp(tipo, 'STEP')
      registrar_contexto_step_edicion_local(origen, archivo);
      fprintf('\n--- FreeCAD: el .step NO se modifica al guardar el documento ---\n');
      fprintf('1) Edite la geometria en FreeCAD.\n');
      fprintf('2) Archivo -> Exportar -> STEP (File -> Export) y SOBRESCRIBA:\n');
      fprintf('     %s\n', archivo);
      fprintf('3) Vuelva a AOS: menu CAD -> 6 Sincronizacion -> 1 Recargar si cambio.\n');
      fprintf('   Si exporto con OTRO nombre: menu CAD -> 6 -> 3 Traer STEP exportado.\n');
      fprintf('Octave queda libre mientras FreeCAD esta abierto.\n');
    else
      registrar_contexto_dxf_edicion_local(origen, archivo);
      fprintf('\n--- LibreCAD: edite sobre la copia de trabajo (fixture intacto) ---\n');
      fprintf('1) Edite el DXF en LibreCAD y GUARDE sobre:\n');
      fprintf('     %s\n', archivo);
      fprintf('2) Vuelva a AOS: menu CAD -> 6 Sincronizacion -> 1 Recargar si cambio.\n');
      fprintf('Octave queda libre; edite, guarde y vuelva al menu CAD para recargar.\n');
    endif
  else
    fprintf('No fue posible iniciar %s con: %s\n', etiqueta, det.gui_cmd);
  endif
endfunction

function registrar_contexto_dxf_edicion_local(origen, copia)
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  ct = CONFIG_ACTIVA.cad_topologia;
  origen = char(origen);
  copia = char(copia);
  ct.dxf_archivo_edicion = copia;
  if ~strcmpi(origen, copia)
    ct.dxf_archivo_origen = origen;
  elseif ~isfield(ct, 'dxf_archivo_origen') || isempty(ct.dxf_archivo_origen)
    ct.dxf_archivo_origen = origen;
  endif
  CONFIG_ACTIVA.cad_topologia = ct;
  aos_cad_registrar_mtime(copia);
endfunction

function registrar_contexto_step_edicion_local(origen, copia)
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  ct = CONFIG_ACTIVA.cad_topologia;
  origen = char(origen);
  copia = char(copia);
  ct.step_archivo_edicion = copia;
  if ~strcmpi(origen, copia)
    ct.step_archivo_origen = origen;
  elseif ~isfield(ct, 'step_archivo_origen') || isempty(ct.step_archivo_origen)
    ct.step_archivo_origen = origen;
  endif
  CONFIG_ACTIVA.cad_topologia = ct;
  aos_cad_registrar_mtime(copia);
endfunction

function ok = lanzar_desacoplado_local(det, archivo)
  ok = false;
  archivo = char(archivo);

  if ispc()
    exe = char(det.ruta);
    try
      rt = java.lang.Runtime.getRuntime();
      args = javaArray('java.lang.String', 2);
      args(1) = java.lang.String(exe);
      args(2) = java.lang.String(archivo);
      rt.exec(args);
      ok = true;
      return;
    catch
    end_try_catch

    try
      exe_ps = strrep(exe, '''', '''''');
      arch_ps = strrep(archivo, '''', '''''');
      cmd = sprintf(['powershell -NoProfile -WindowStyle Hidden -Command ' ...
        '"Start-Process -FilePath ''%s'' -ArgumentList ''%s''"'], exe_ps, arch_ps);
      st = system(cmd);
      ok = (st == 0);
      if ok, return; endif
    catch
    end_try_catch

    cmd = sprintf('cmd /c start "" "%s" "%s"', exe, archivo);
    ok = (system(cmd) == 0);
  else
    if isfield(det, 'file_forwarding') && det.file_forwarding
      % Flatpak --file-forwarding exige encerrar la ruta entre @@ ... @@.
      cmd = sprintf('%s @@ %s @@ >/dev/null 2>&1 &', ...
                    det.gui_cmd, shell_quote_local(archivo));
    else
      cmd = sprintf('%s %s >/dev/null 2>&1 &', ...
                    det.gui_cmd, shell_quote_local(archivo));
    endif
    ok = (system(cmd) == 0);
  endif
endfunction

function archivo = resolver_archivo_local(tipo)
  archivo = '';
  global CONFIG_ACTIVA;
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) ...
      && isfield(CONFIG_ACTIVA, 'cad_topologia') && isstruct(CONFIG_ACTIVA.cad_topologia)
    ct = CONFIG_ACTIVA.cad_topologia;
    if strcmp(tipo, 'DXF') && isfield(ct, 'dxf_archivo') && ~isempty(ct.dxf_archivo)
      cand = char(ct.dxf_archivo);
      if exist(cand, 'file') == 2
        fprintf('Usando DXF de CONFIG_ACTIVA.cad_topologia: %s\n', cand);
        archivo = cand;
        return;
      endif
      cand2 = fullfile(aos_cad_raiz(), cand);
      if exist(cand2, 'file') == 2
        fprintf('Usando DXF de CONFIG (relativo): %s\n', cand2);
        archivo = cand2;
        return;
      endif
    elseif strcmp(tipo, 'STEP') && isfield(ct, 'step_archivo') && ~isempty(ct.step_archivo)
      cand = char(ct.step_archivo);
      if exist(cand, 'file') == 2
        fprintf('Usando STEP de CONFIG_ACTIVA.cad_topologia: %s\n', cand);
        archivo = cand;
        return;
      endif
      cand2 = fullfile(aos_cad_raiz(), cand);
      if exist(cand2, 'file') == 2
        fprintf('Usando STEP de CONFIG (relativo): %s\n', cand2);
        archivo = cand2;
        return;
      endif
    endif
  endif

  bandeja = fullfile(aos_cad_raiz(), 'intercambio', 'cad', 'recibidos');
  if exist(bandeja, 'dir') == 7
    if strcmp(tipo, 'STEP')
      lista = [dir(fullfile(bandeja, '*.step')); dir(fullfile(bandeja, '*.stp'))];
    else
      lista = dir(fullfile(bandeja, ['*.', lower(tipo)]));
    endif
    if ~isempty(lista)
      fprintf('Archivos en intercambio/cad/recibidos:\n');
      for i = 1:numel(lista)
        fprintf('  %d - %s\n', i, lista(i).name);
      endfor
      fprintf('  0 - Elegir otro archivo\n');
      op = aos_leer_opcion(sprintf('Seleccione [0-%d]: ', numel(lista)), []);
      if ~isempty(op) && op >= 1 && op <= numel(lista)
        archivo = fullfile(bandeja, lista(op).name);
        return;
      endif
    endif
  endif
  archivo = seleccionar_dialogo_local(tipo);
endfunction

function archivo = seleccionar_dialogo_local(tipo)
  archivo = '';
  if strcmp(tipo, 'STEP')
    filtro = {'*.step;*.stp', 'Archivos STEP'};
  else
    filtro = {['*.', lower(tipo)], ['Archivos ', tipo]};
  endif
  try
    [f, p] = uigetfile(filtro, ['Seleccionar ', tipo]);
    if isnumeric(f) && f == 0, return; endif
    archivo = fullfile(p, f);
  catch
    archivo = strtrim(input(sprintf('Ruta del archivo %s: ', tipo), 's'));
  end_try_catch
endfunction

function q = shell_quote_local(s)
  s = char(s);
  s = strrep(s, '\', '\\');
  s = strrep(s, '"', '\"');
  s = strrep(s, '$', '\$');
  s = strrep(s, '`', '\`');
  q = ['"' s '"'];
endfunction
