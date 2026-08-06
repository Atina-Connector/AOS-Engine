function estado = DIAGNOSTICAR_EDITORES_AOSCAD()
% Diagnostica deteccion de LibreCAD y FreeCAD sin abrir sus interfaces.
% Sprint 5: FreeCAD = motor de edicion STEP + verificador cruzado opcional
% (GUI vs CLI; existencia real del binario CLI). occt-draw ausente en Windows
% es esperado por construccion (OCCT viaja dentro de FreeCAD).
  root = fileparts(mfilename('fullpath'));
  if exist(fullfile(root, 'src'), 'dir') == 7
    addpath(fullfile(root, 'src'), '-begin');
    try, iniciar_aos(true); catch, end_try_catch
  endif

  fprintf('\n====================================================\n');
  fprintf(' DIAGNOSTICO DE EDITORES AOSCAD R14 - GNU OCTAVE\n');
  fprintf('====================================================\n');
  fprintf('Sistema          : %s\n', computer());
  fprintf('Octave ejecutable: %s\n', invocacion_local());
  fprintf('PATH sandbox     : %s\n', getenv('PATH'));
  fprintf('FLATPAK_ID       : %s\n', texto_local(getenv('FLATPAK_ID')));
  fprintf('Dentro de Flatpak: %s\n', si_no_local(en_flatpak_local()));
  fprintf('\nRoles:\n');
  fprintf('  LibreCAD  = editor externo DXF\n');
  fprintf('  FreeCAD   = motor de edicion STEP + proveedor CLI del\n');
  fprintf('              verificador cruzado opcional (aos_step_indice_freecad)\n');
  fprintf('  occt-draw = no requerido; ausente en Windows por construccion\n');

  estado = struct();
  estado.librecad = aos_cad_localizar_programa('LibreCAD');
  estado.freecad = aos_cad_localizar_programa('FreeCAD');
  estado.plataforma = aos_verificar_requisitos_plataforma(false);
  estado.opencascade = estado.plataforma.opencascade;
  imprimir_local('LibreCAD (editor DXF)', estado.librecad);
  imprimir_freecad_local(estado.freecad);
  imprimir_occt_local(estado.opencascade);

  if ~ispc()
    fprintf('\n--- SONDEO DEL ENTORNO ACTUAL ---\n');
    comandos = { ...
      'command -v flatpak-spawn 2>/dev/null', ...
      'command -v librecad 2>/dev/null', ...
      'command -v LibreCAD 2>/dev/null', ...
      'command -v freecad 2>/dev/null', ...
      'command -v FreeCAD 2>/dev/null', ...
      'command -v freecadcmd 2>/dev/null', ...
      'command -v FreeCADCmd 2>/dev/null', ...
      'command -v occt-draw 2>/dev/null', ...
      'flatpak list --app --columns=application 2>/dev/null | grep -Ei "freecad|librecad"', ...
      'find "$HOME/Applications" "$HOME/Descargas" "$HOME/Downloads" "$HOME/.local/bin" /opt -maxdepth 3 -type f \( -iname "*freecad*.AppImage" -o -iname "*librecad*.AppImage" \) -print 2>/dev/null'};
    ejecutar_sondeos_local(comandos);

    if en_flatpak_local()
      fprintf('\n--- SONDEO DEL SISTEMA HOST MEDIANTE flatpak-spawn ---\n');
      spawn = comando_local('flatpak-spawn');
      if isempty(spawn)
        fprintf('flatpak-spawn no esta disponible dentro del sandbox.\n');
      else
        host_cmds = { ...
          [spawn ' --host sh -lc ''printf AOS_HOST_OK'''], ...
          [spawn ' --host sh -lc ''command -v librecad || command -v LibreCAD'''], ...
          [spawn ' --host sh -lc ''command -v freecad || command -v FreeCAD'''], ...
          [spawn ' --host sh -lc ''flatpak list --app --columns=application 2>/dev/null | grep -Ei "freecad|librecad"'''], ...
          [spawn ' --host sh -lc ''snap list 2>/dev/null | grep -Ei "freecad|librecad"'''], ...
          [spawn ' --host sh -lc ''command -v occt-draw 2>/dev/null''']};
        ejecutar_sondeos_local(host_cmds);
      endif
    endif
  endif

  fprintf('\nNo se iniciaron aplicaciones graficas durante este diagnostico.\n');
endfunction

function ejecutar_sondeos_local(comandos)
  for i = 1:numel(comandos)
    [st, out] = system(comandos{i});
    fprintf('\n$ %s\n', comandos{i});
    if st == 0 && ~isempty(strtrim(out))
      fprintf('%s\n', strtrim(out));
    else
      fprintf('(sin resultado; status=%d)\n', st);
    endif
  endfor
endfunction

function imprimir_local(nombre, r)
  fprintf('\n--- %s ---\n', nombre);
  fprintf('Encontrado       : %s\n', si_no_local(r.encontrado));
  fprintf('GUI disponible   : %s\n', si_no_local(r.gui_disponible));
  fprintf('CLI disponible   : %s\n', si_no_local(r.cli_disponible));
  fprintf('Metodo           : %s\n', texto_local(r.metodo));
  fprintf('Ruta lanzador    : %s\n', texto_local(r.ruta));
  fprintf('Comando GUI      : %s\n', texto_local(r.gui_cmd));
  fprintf('Paquete          : %s\n', texto_local(r.id_paquete));
  if isfield(r, 'en_sandbox_flatpak')
    fprintf('Sandbox Flatpak  : %s\n', si_no_local(r.en_sandbox_flatpak));
  endif
  if isfield(r, 'puente_host')
    fprintf('Puente al host   : %s\n', si_no_local(r.puente_host));
  endif
  if isfield(r, 'comando_fuente')
    fprintf('Lanzador sistema : %s\n', texto_local(r.comando_fuente));
  endif
  fprintf('Detalle          : %s\n', texto_local(r.detalle));
  if ~isempty(r.cli_cmds)
    fprintf('Comandos CLI:\n');
    for i = 1:numel(r.cli_cmds), fprintf('  - %s\n', r.cli_cmds{i}); endfor
  endif
endfunction

function imprimir_freecad_local(r)
  fprintf('\n--- FreeCAD (edicion STEP + CLI cruzado opcional) ---\n');
  fprintf('Rol              : motor de edicion externa STEP; FreeCADCmd\n');
  fprintf('                  alimenta aos_step_indice_freecad (solo tests)\n');
  fprintf('Edicion          : AOS abre copia en intercambio/cad/edicion/\n');
  fprintf('                  FreeCAD NO pisa el .step al guardar: hay que\n');
  fprintf('                  Exportar STEP sobre esa copia, o usar\n');
  fprintf('                  aos_cad_traer_step_exportado (menu sync 3).\n');
  fprintf('Encontrado       : %s\n', si_no_local(r.encontrado));
  fprintf('GUI disponible   : %s\n', si_no_local(r.gui_disponible));
  fprintf('CLI candidatos   : %s (cli_disponible del localizador)\n', ...
          si_no_local(r.cli_disponible));
  fprintf('Metodo           : %s\n', texto_local(r.metodo));
  fprintf('Ruta lanzador    : %s\n', texto_local(r.ruta));
  fprintf('Comando GUI      : %s\n', texto_local(r.gui_cmd));
  if isfield(r, 'gui_cmd') && ~isempty(r.gui_cmd)
    gui_existe = existir_binario_local(r.gui_cmd);
    fprintf('GUI binario existe: %s\n', si_no_local(gui_existe));
  endif
  fprintf('Paquete          : %s\n', texto_local(r.id_paquete));
  fprintf('Detalle          : %s\n', texto_local(r.detalle));
  n_cli = 0;
  n_cli_exist = 0;
  if isfield(r, 'cli_cmds') && ~isempty(r.cli_cmds)
    fprintf('Comandos CLI candidatos (ruta construida):\n');
    for i = 1:numel(r.cli_cmds)
      cmd = r.cli_cmds{i};
      n_cli = n_cli + 1;
      bin = primer_token_local(cmd);
      ex = ~isempty(bin) && (exist(bin, 'file') == 2);
      if ex, n_cli_exist = n_cli_exist + 1; endif
      fprintf('  - %s\n', cmd);
      fprintf('    binario       : %s  existe=%s\n', ...
              texto_local(bin), si_no_local(ex));
    endfor
  else
    fprintf('Comandos CLI     : (ningun candidato)\n');
  endif
  fprintf('CLI real en disco: %d de %d candidato/s\n', n_cli_exist, n_cli);
  fprintf('Nota             : cli_disponible NO prueba ejecutabilidad;\n');
  fprintf('                  aos_step_indice_freecad verifica binario y salida.\n');
endfunction

function imprimir_occt_local(r)
  fprintf('\n--- Open CASCADE / occt-draw ---\n');
  fprintf('Rol              : motor geometrico futuro de AOS (no adoptado)\n');
  fprintf('Encontrado       : %s\n', si_no_local(r.encontrado));
  fprintf('CLI disponible   : %s\n', si_no_local(r.cli_disponible));
  fprintf('Metodo           : %s\n', texto_local(r.metodo));
  fprintf('Ruta             : %s\n', texto_local(r.ruta));
  fprintf('Comando          : %s\n', texto_local(r.comando));
  if isfield(r, 'detalle')
    fprintf('Detalle          : %s\n', texto_local(r.detalle));
  endif
  if ispc()
    fprintf('Windows          : ausencia de occt-draw ESPERADA por construccion\n');
    fprintf('                  (aos_verificar_requisitos_plataforma corta en ispc).\n');
    fprintf('                  OCCT viaja empaquetado dentro de FreeCAD.\n');
    fprintf('                  No degrada el indice nativo ni la bateria CAD.\n');
  else
    fprintf('Nota             : extractor auxiliar del plan maestro = FreeCADCmd,\n');
    fprintf('                  no occt-draw suelto.\n');
  endif
endfunction

function tf = existir_binario_local(cmd)
  bin = primer_token_local(cmd);
  tf = ~isempty(bin) && (exist(bin, 'file') == 2);
endfunction

function bin = primer_token_local(cmd)
  bin = '';
  s = strtrim(char(cmd));
  if isempty(s), return; endif
  if s(1) == '"'
    p = find(s == '"');
    if numel(p) >= 2
      bin = s(p(1)+1:p(2)-1);
      return;
    endif
  endif
  partes = strsplit(s);
  if ~isempty(partes), bin = partes{1}; endif
endfunction

function tf = en_flatpak_local()
  tf = (exist('/.flatpak-info', 'file') == 2) || ...
       ~isempty(strtrim(getenv('FLATPAK_ID'))) || ...
       strncmp(invocacion_local(), '/app/', 5);
endfunction

function s = invocacion_local()
  s = '';
  try
    s = program_invocation_name();
  catch
    try, s = program_name(); catch, s = ''; end_try_catch
  end_try_catch
  s = strtrim(char(s));
endfunction

function cmd = comando_local(nombre)
  cmd = '';
  [st, out] = system(sprintf('command -v %s 2>/dev/null', nombre));
  if st == 0 && ~isempty(strtrim(out))
    p = strsplit(strtrim(out), sprintf('\n'));
    cmd = p{1};
  endif
endfunction

function s = si_no_local(v)
  if v, s = 'SI'; else, s = 'NO'; endif
endfunction

function s = texto_local(v)
  if isempty(v), s = '(vacio)'; else, s = char(v); endif
endfunction
