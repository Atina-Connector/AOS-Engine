function r = aos_cad_localizar_programa(tipo)
% AOS_CAD_LOCALIZAR_PROGRAMA Localiza editores CAD en Windows y Linux.
% Soporta PATH, rutas absolutas, Flatpak, Snap, AppImage y override JSON.
% Campos principales:
%   encontrado, gui_disponible, cli_disponible, metodo, ruta,
%   comando, gui_cmd, cli_cmds, id_paquete, detalle
  if nargin < 1 || isempty(tipo), tipo = 'LibreCAD'; endif
  tipo = lower(strtrim(char(tipo)));
  r = resultado_vacio_local(tipo);

  override = override_local(tipo);
  if ~isempty(override)
    ro = evaluar_override_local(override, tipo);
    if ro.encontrado
      r = ro;
      return;
    endif
  endif

  if ispc()
    r = buscar_windows_local(tipo);
  else
    r = buscar_linux_local(tipo);
  endif
endfunction

function r = resultado_vacio_local(tipo)
  r = struct();
  r.tipo = tipo;
  r.encontrado = false;
  r.gui_disponible = false;
  r.cli_disponible = false;
  r.metodo = '';
  r.ruta = '';
  r.comando = '';
  r.gui_cmd = '';
  r.cli_cmds = {};
  r.id_paquete = '';
  r.detalle = '';
  r.en_sandbox_flatpak = en_flatpak_local();
  r.puente_host = false;
  r.file_forwarding = false;
  r.comando_fuente = '';
endfunction

function ruta = override_local(tipo)
  ruta = '';
  try
    p = aos_cad_topo_preferencias('cargar');
    if strcmp(tipo, 'librecad') && isfield(p, 'librecad_exe')
      ruta = strtrim(char(p.librecad_exe));
    elseif strcmp(tipo, 'freecad') && isfield(p, 'freecad_exe')
      ruta = strtrim(char(p.freecad_exe));
    endif
  catch
    ruta = '';
  end_try_catch
endfunction

function r = evaluar_override_local(override, tipo)
  r = resultado_vacio_local(tipo);
  if exist(override, 'file') == 2
    r = resultado_directo_local(override, tipo, 'preferencia');
    return;
  endif

  % Permite guardar un comando compuesto, por ejemplo:
  % flatpak run org.freecad.FreeCAD
  primera = primer_token_local(override);
  ruta = buscar_en_path_local(primera);
  if ~isempty(ruta)
    r.encontrado = true;
    r.gui_disponible = true;
    r.cli_disponible = strcmp(tipo, 'freecad');
    r.metodo = 'preferencia_comando';
    r.ruta = ruta;
    r.comando = override;
    r.gui_cmd = override;
    if strcmp(tipo, 'freecad')
      r.cli_cmds = {[override ' -c']};
    endif
    r.detalle = 'Comando definido en preferencias CAD_TOPO.';
  endif
endfunction

function r = buscar_windows_local(tipo)
  r = resultado_vacio_local(tipo);
  if strcmp(tipo, 'freecad')
    nombres = {'FreeCAD.exe', 'freecad.exe'};
    pf = getenv('ProgramFiles');
    pfx86 = getenv('ProgramFiles(x86)');
    local = getenv('LOCALAPPDATA');
    candidatos = { ...
      fullfile(local, 'Programs', 'FreeCAD 1.0', 'bin', 'FreeCAD.exe'), ...
      fullfile(local, 'Programs', 'FreeCAD 0.21', 'bin', 'FreeCAD.exe'), ...
      fullfile(local, 'Programs', 'FreeCAD', 'bin', 'FreeCAD.exe'), ...
      fullfile(pf, 'FreeCAD 1.0', 'bin', 'FreeCAD.exe'), ...
      fullfile(pf, 'FreeCAD 0.21', 'bin', 'FreeCAD.exe'), ...
      fullfile(pf, 'FreeCAD', 'bin', 'FreeCAD.exe'), ...
      fullfile(pfx86, 'FreeCAD', 'bin', 'FreeCAD.exe')};
  else
    nombres = {'LibreCAD.exe', 'librecad.exe'};
    pf = getenv('ProgramFiles');
    pfx86 = getenv('ProgramFiles(x86)');
    local = getenv('LOCALAPPDATA');
    candidatos = {fullfile(pf, 'LibreCAD', 'LibreCAD.exe'), ...
                   fullfile(pfx86, 'LibreCAD', 'LibreCAD.exe'), ...
                   fullfile(local, 'Programs', 'LibreCAD', 'LibreCAD.exe')};
  endif

  for i = 1:numel(candidatos)
    if exist(candidatos{i}, 'file') == 2
      r = resultado_directo_local(candidatos{i}, tipo, 'ruta_windows');
      return;
    endif
  endfor

  for i = 1:numel(nombres)
    ruta = buscar_en_path_local(nombres{i});
    if ~isempty(ruta)
      r = resultado_directo_local(ruta, tipo, 'path_windows');
      return;
    endif
  endfor
endfunction

function r = buscar_linux_local(tipo)
  r = resultado_vacio_local(tipo);

  if strcmp(tipo, 'freecad')
    nombres_gui = {'FreeCAD', 'freecad'};
    rutas_gui = {'/usr/bin/freecad', '/usr/bin/FreeCAD', ...
                 '/usr/local/bin/freecad', '/usr/local/bin/FreeCAD', ...
                 '/snap/bin/freecad', '/snap/bin/FreeCAD'};
  else
    nombres_gui = {'librecad', 'LibreCAD'};
    rutas_gui = {'/usr/bin/librecad', '/usr/bin/LibreCAD', ...
                 '/usr/local/bin/librecad', '/usr/local/bin/LibreCAD', ...
                 '/snap/bin/librecad'};
  endif

  % 1. PATH real del proceso Octave.
  for i = 1:numel(nombres_gui)
    ruta = buscar_en_path_local(nombres_gui{i});
    if ~isempty(ruta)
      r = resultado_directo_local(ruta, tipo, 'path_linux');
      return;
    endif
  endfor

  % 2. Rutas tipicas, incluyendo Snap.
  for i = 1:numel(rutas_gui)
    if exist(rutas_gui{i}, 'file') == 2
      metodo = 'ruta_linux';
      if ~isempty(strfind(rutas_gui{i}, '/snap/')), metodo = 'snap'; endif
      r = resultado_directo_local(rutas_gui{i}, tipo, metodo);
      return;
    endif
  endfor

  % 3. Si Octave corre dentro de Flatpak, buscar y lanzar en el host.
  % El PATH /app/bin pertenece al sandbox y no ve /usr/bin del sistema.
  if en_flatpak_local()
    r = buscar_host_flatpak_spawn_local(tipo);
    if r.encontrado, return; endif
  endif

  % 4. Flatpak visible dentro del entorno actual.
  r = buscar_flatpak_local(tipo);
  if r.encontrado, return; endif

  % 5. AppImage fuera de PATH.
  r = buscar_appimage_local(tipo);
  if r.encontrado, return; endif

  % 6. Entrada .desktop. Puede descubrir comandos no heredados por Octave.
  r = buscar_desktop_local(tipo);
endfunction

function tf = en_flatpak_local()
  tf = false;
  try
    tf = (exist('/.flatpak-info', 'file') == 2) || ...
         ~isempty(strtrim(getenv('FLATPAK_ID'))) || ...
         strncmp(strtrim(program_invocation_local()), '/app/', 5);
  catch
    tf = false;
  end_try_catch
endfunction

function s = program_invocation_local()
  s = '';
  try
    s = program_invocation_name();
  catch
    try, s = program_name(); catch, s = ''; end_try_catch
  end_try_catch
endfunction

function r = buscar_host_flatpak_spawn_local(tipo)
% Busca aplicaciones instaladas en el host cuando Octave corre en Flatpak.
% No ejecuta interfaces graficas durante la deteccion.
  r = resultado_vacio_local(tipo);
  spawn = buscar_en_path_local('flatpak-spawn');
  if isempty(spawn) && exist('/usr/bin/flatpak-spawn', 'file') == 2
    spawn = '/usr/bin/flatpak-spawn';
  endif
  if isempty(spawn)
    r.detalle = 'Octave esta en Flatpak pero flatpak-spawn no esta disponible.';
    return;
  endif

  probe = sprintf('%s --host sh -lc %s', shell_quote_local(spawn), ...
                  shell_quote_local('printf AOS_HOST_OK'));
  [st, out] = system(probe);
  if st ~= 0 || isempty(strfind(out, 'AOS_HOST_OK'))
    r.detalle = ['flatpak-spawn existe pero el sandbox no permite ejecutar ' ...
                 'comandos en el host.'];
    return;
  endif

  if strcmp(tipo, 'freecad')
    nombres = {'FreeCAD', 'freecad'};
    rutas = {'/usr/bin/FreeCAD', '/usr/bin/freecad', ...
             '/usr/local/bin/FreeCAD', '/usr/local/bin/freecad', ...
             '/snap/bin/freecad'};
    ids_flatpak = {'org.freecad.FreeCAD'};
  else
    nombres = {'librecad', 'LibreCAD'};
    rutas = {'/usr/bin/librecad', '/usr/bin/LibreCAD', ...
             '/usr/local/bin/librecad', '/usr/local/bin/LibreCAD', ...
             '/snap/bin/librecad'};
    % El ID real publicado por LibreCAD es completamente minusculo.
    ids_flatpak = {'org.librecad.librecad', 'org.librecad.LibreCAD'};
  endif

  % 1. Ejecutable nativo o Snap instalado en el host.
  consulta = 'p=';
  for i = 1:numel(nombres)
    if i == 1
      consulta = ['command -v ' nombres{i} ' 2>/dev/null'];
    else
      consulta = [consulta ' || command -v ' nombres{i} ' 2>/dev/null']; %#ok<AGROW>
    endif
  endfor
  for i = 1:numel(rutas)
    consulta = [consulta ' || { test -x ' shell_single_quote_local(rutas{i}) ...
                ' && printf %s ' shell_single_quote_local(rutas{i}) '; }']; %#ok<AGROW>
  endfor
  cmd = sprintf('%s --host sh -lc %s', shell_quote_local(spawn), ...
                shell_quote_local(consulta));
  [st, out] = system(cmd);
  if st == 0 && ~isempty(strtrim(out))
    host_exe = primera_linea_local(out);
    r.encontrado = true;
    r.gui_disponible = true;
    r.metodo = 'flatpak_spawn_host';
    r.ruta = host_exe;
    r.gui_cmd = sprintf('%s --host %s', shell_quote_local(spawn), ...
                        shell_quote_local(host_exe));
    r.comando = r.gui_cmd;
    r.detalle = ['Ejecutable localizado en el host desde el sandbox: ' host_exe];
    r.puente_host = true;
    r.en_sandbox_flatpak = true;
    if strcmp(tipo, 'freecad')
      r.cli_cmds = comandos_cli_freecad_host_local(spawn, host_exe);
      r.cli_disponible = ~isempty(r.cli_cmds);
    endif
    return;
  endif

  % 2. Aplicacion Flatpak instalada en el host, no dentro del sandbox Octave.
  for iid = 1:numel(ids_flatpak)
    id_flatpak = ids_flatpak{iid};
    verifica = sprintf('flatpak info %s >/dev/null 2>&1', ...
                       shell_single_quote_local(id_flatpak));
    cmd = sprintf('%s --host sh -lc %s', shell_quote_local(spawn), ...
                  shell_quote_local(verifica));
    st = system(cmd);
    if st ~= 0, continue; endif

    r.encontrado = true;
    r.gui_disponible = true;
    r.metodo = 'flatpak_spawn_host_flatpak';
    r.ruta = spawn;
    r.id_paquete = id_flatpak;
    r.file_forwarding = true;
    r.puente_host = true;
    r.en_sandbox_flatpak = true;

    if strcmp(tipo, 'freecad')
      r.gui_cmd = sprintf(['%s --host /usr/bin/flatpak run --branch=stable ' ...
                           '--arch=x86_64 --command=FreeCAD --file-forwarding ' ...
                           '%s --single-instance'], ...
                           shell_quote_local(spawn), shell_quote_local(id_flatpak));
      r.cli_disponible = true;
      r.cli_cmds = { ...
        sprintf('%s --host /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=FreeCADCmd %s', ...
                shell_quote_local(spawn), shell_quote_local(id_flatpak)), ...
        sprintf('%s --host /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=freecadcmd %s', ...
                shell_quote_local(spawn), shell_quote_local(id_flatpak))};
      r.comando_fuente = '/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=FreeCAD --file-forwarding org.freecad.FreeCAD --single-instance @@ %F @@';
    else
      r.gui_cmd = sprintf(['%s --host /usr/bin/flatpak run --branch=stable ' ...
                           '--arch=x86_64 --command=librecad --file-forwarding %s'], ...
                           shell_quote_local(spawn), shell_quote_local(id_flatpak));
      r.cli_disponible = false;
      r.comando_fuente = '/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=librecad --file-forwarding org.librecad.librecad @@ %F @@';
    endif
    r.comando = r.gui_cmd;
    r.detalle = ['Aplicacion Flatpak instalada en el host: ' id_flatpak];
    return;
  endfor

  r.detalle = ['Puente host operativo, pero no se encontro ' tipo ...
               ' por PATH, Snap o Flatpak del host.'];
endfunction

function cmds = comandos_cli_freecad_host_local(spawn, ruta_gui)
  cmds = {};
  consulta = ['d=$(dirname ' shell_single_quote_local(ruta_gui) '); ' ...
              'for n in FreeCADCmd freecadcmd; do ' ...
              'test -x "$d/$n" && { printf "%s\\n" "$d/$n"; exit 0; }; ' ...
              'done; exit 1'];
  cmd = sprintf('%s --host sh -lc %s', shell_quote_local(spawn), ...
                shell_quote_local(consulta));
  [st, out] = system(cmd);
  if st == 0 && ~isempty(strtrim(out))
    cli = primera_linea_local(out);
    cmds{end+1} = sprintf('%s --host %s', shell_quote_local(spawn), ...
                          shell_quote_local(cli)); %#ok<AGROW>
  endif
  if isempty(cmds)
    cmds{end+1} = sprintf('%s --host %s -c', shell_quote_local(spawn), ...
                          shell_quote_local(ruta_gui)); %#ok<AGROW>
  endif
endfunction

function r = buscar_flatpak_local(tipo)
  r = resultado_vacio_local(tipo);
  flatpak = buscar_en_path_local('flatpak');
  if isempty(flatpak) && exist('/usr/bin/flatpak', 'file') == 2
    flatpak = '/usr/bin/flatpak';
  endif
  if isempty(flatpak), return; endif

  if strcmp(tipo, 'freecad')
    ids = {'org.freecad.FreeCAD'};
  else
    ids = {'org.librecad.librecad', 'org.librecad.LibreCAD'};
  endif

  for i = 1:numel(ids)
    id = ids{i};
    cmd_info = sprintf('%s info %s >/dev/null 2>&1', ...
                       shell_quote_local(flatpak), shell_quote_local(id));
    st = system(cmd_info);
    if st == 0
      r.encontrado = true;
      r.gui_disponible = true;
      r.metodo = 'flatpak';
      r.ruta = flatpak;
      r.id_paquete = id;
      r.file_forwarding = true;
      if strcmp(tipo, 'freecad')
        r.gui_cmd = sprintf(['%s run --branch=stable --arch=x86_64 --command=FreeCAD ' ...
                             '--file-forwarding %s --single-instance'], ...
                             shell_quote_local(flatpak), shell_quote_local(id));
        r.cli_disponible = true;
        r.cli_cmds = { ...
          sprintf('%s run --branch=stable --arch=x86_64 --command=FreeCADCmd %s', shell_quote_local(flatpak), shell_quote_local(id)), ...
          sprintf('%s run --branch=stable --arch=x86_64 --command=freecadcmd %s', shell_quote_local(flatpak), shell_quote_local(id))};
        r.comando_fuente = '/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=FreeCAD --file-forwarding org.freecad.FreeCAD --single-instance @@ %F @@';
      else
        r.gui_cmd = sprintf(['%s run --branch=stable --arch=x86_64 --command=librecad ' ...
                             '--file-forwarding %s'], ...
                             shell_quote_local(flatpak), shell_quote_local(id));
        r.cli_disponible = false;
        r.comando_fuente = '/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=librecad --file-forwarding org.librecad.librecad @@ %F @@';
      endif
      r.comando = r.gui_cmd;
      r.detalle = ['Aplicacion Flatpak instalada: ' id];
      return;
    endif
  endfor
endfunction

function r = buscar_appimage_local(tipo)
  r = resultado_vacio_local(tipo);
  home = getenv('HOME');
  if isempty(home), home = '~'; endif
  if strcmp(tipo, 'freecad')
    patron = '*freecad*.AppImage';
  else
    patron = '*librecad*.AppImage';
  endif
  dirs = {fullfile(home, 'Applications'), fullfile(home, 'Descargas'), ...
          fullfile(home, 'Downloads'), fullfile(home, '.local', 'bin'), '/opt'};

  for i = 1:numel(dirs)
    if exist(dirs{i}, 'dir') ~= 7, continue; endif
    cmd = sprintf('find %s -maxdepth 3 -type f -iname %s -print -quit 2>/dev/null', ...
                  shell_quote_local(dirs{i}), shell_quote_local(patron));
    [st, out] = system(cmd);
    if st == 0 && ~isempty(strtrim(out))
      ruta = primera_linea_local(out);
      r = resultado_directo_local(ruta, tipo, 'appimage');
      if strcmp(tipo, 'freecad')
        r.cli_disponible = true;
        r.cli_cmds = {[shell_quote_local(ruta) ' -c']};
      endif
      return;
    endif
  endfor
endfunction

function r = buscar_desktop_local(tipo)
  r = resultado_vacio_local(tipo);
  home = getenv('HOME');
  dirs = {fullfile(home, '.local', 'share', 'applications'), ...
          fullfile(home, '.local', 'share', 'flatpak', 'exports', 'share', 'applications'), ...
          '/usr/share/applications', ...
          '/var/lib/flatpak/exports/share/applications'};
  if strcmp(tipo, 'freecad')
    patron = '*freecad*.desktop';
  else
    patron = '*librecad*.desktop';
  endif

  for i = 1:numel(dirs)
    if exist(dirs{i}, 'dir') ~= 7, continue; endif
    lista = dir(fullfile(dirs{i}, patron));
    for j = 1:numel(lista)
      ruta_desktop = fullfile(dirs{i}, lista(j).name);
      exec_line = leer_exec_desktop_local(ruta_desktop);
      if isempty(exec_line), continue; endif
      limpio = limpiar_exec_desktop_local(exec_line);
      if isempty(limpio), continue; endif
      primero = primer_token_local(limpio);
      ruta = buscar_en_path_local(primero);
      if isempty(ruta) && exist(primero, 'file') == 2, ruta = primero; endif
      if isempty(ruta), continue; endif
      r.encontrado = true;
      r.gui_disponible = true;
      r.metodo = 'desktop';
      r.ruta = ruta;
      r.gui_cmd = limpio;
      r.comando = limpio;
      r.detalle = ['Descubierto desde ' ruta_desktop];
      if strcmp(tipo, 'freecad')
        r.cli_disponible = true;
        r.cli_cmds = {[limpio ' -c']};
      endif
      return;
    endfor
  endfor
endfunction

function r = resultado_directo_local(ruta, tipo, metodo)
  r = resultado_vacio_local(tipo);
  ruta = strtrim(char(ruta));
  if exist(ruta, 'file') ~= 2, return; endif
  r.encontrado = true;
  r.gui_disponible = true;
  r.metodo = metodo;
  r.ruta = ruta;
  r.gui_cmd = shell_quote_local(ruta);
  r.comando = ruta;
  r.detalle = ['Ejecutable directo: ' ruta];

  if strcmp(tipo, 'freecad')
    r.cli_cmds = comandos_cli_freecad_local(ruta);
    r.cli_disponible = ~isempty(r.cli_cmds);
  endif
endfunction

function cmds = comandos_cli_freecad_local(ruta_gui)
  cmds = {};
  [d, ~, ~] = fileparts(ruta_gui);
  candidatos = {fullfile(d, 'FreeCADCmd'), fullfile(d, 'freecadcmd'), ...
                fullfile(d, 'FreeCADCmd.exe'), fullfile(d, 'freecadcmd.exe')};
  for i = 1:numel(candidatos)
    if exist(candidatos{i}, 'file') == 2
      cmds{end+1} = shell_quote_local(candidatos{i}); %#ok<AGROW>
    endif
  endfor
  if isempty(cmds)
    nombre = lower(ruta_gui);
    if ~isempty(strfind(nombre, 'appimage')) || ...
       ~isempty(strfind(nombre, 'freecad'))
      cmds{end+1} = [shell_quote_local(ruta_gui) ' -c']; %#ok<AGROW>
    endif
  endif
endfunction

function ruta = buscar_en_path_local(nombre)
  ruta = '';
  if isempty(nombre), return; endif
  if ispc()
    [st, out] = system(sprintf('where %s 2>NUL', nombre));
  else
    [st, out] = system(sprintf('command -v %s 2>/dev/null', shell_quote_local(nombre)));
  endif
  if st == 0 && ~isempty(strtrim(out))
    ruta = primera_linea_local(out);
  endif
endfunction

function s = leer_exec_desktop_local(ruta)
  s = '';
  fid = fopen(ruta, 'rt');
  if fid < 0, return; endif
  unwind_protect
    while true
      linea = fgetl(fid);
      if ~ischar(linea), break; endif
      if strncmp(linea, 'Exec=', 5)
        s = strtrim(linea(6:end));
        break;
      endif
    endwhile
  unwind_protect_cleanup
    fclose(fid);
  end_unwind_protect
endfunction

function s = limpiar_exec_desktop_local(s)
  marcadores = {'%f', '%F', '%u', '%U', '%i', '%c', '%k'};
  for i = 1:numel(marcadores)
    s = strrep(s, marcadores{i}, '');
  endfor
  s = strtrim(s);
endfunction

function t = primer_token_local(s)
  s = strtrim(char(s));
  t = '';
  if isempty(s), return; endif
  if s(1) == '"'
    idx = find(s(2:end) == '"', 1, 'first');
    if ~isempty(idx), t = s(2:idx); return; endif
  elseif s(1) == ''''
    idx = find(s(2:end) == '''', 1, 'first');
    if ~isempty(idx), t = s(2:idx); return; endif
  endif
  partes = strsplit(s);
  if ~isempty(partes), t = partes{1}; endif
endfunction

function s = primera_linea_local(out)
  out = strtrim(char(out));
  partes = strsplit(out, sprintf('\n'));
  s = strtrim(partes{1});
endfunction

function q = shell_single_quote_local(s)
  sq = char(39);
  s = strrep(char(s), sq, [sq '"' sq '"' sq]);
  q = [sq s sq];
endfunction

function q = shell_quote_local(s)
  s = char(s);
  s = strrep(s, '\', '\\');
  s = strrep(s, '"', '\"');
  s = strrep(s, '$', '\$');
  s = strrep(s, '`', '\`');
  q = ['"' s '"'];
endfunction
