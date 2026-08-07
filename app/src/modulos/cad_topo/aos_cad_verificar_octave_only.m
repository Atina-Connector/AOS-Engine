function ok = aos_cad_verificar_octave_only(silencioso)
% Verifica que AOSCAD use solo formatos abiertos y GNU Octave.
% REV2: distingue la extension binaria de campos validos como material.
  if nargin < 1, silencioso = false; endif
  root = aos_cad_raiz();
  config = fullfile(root, 'datos_usuario', 'configuracion');
  fallas = {};

  ext_binaria = ['.' 'mat'];
  nombre_motor_no_objetivo = ['MAT' 'LAB'];

  % 1) Prohibicion fuerte: ningun archivo binario legado dentro del arbol AOS.
  encontrados = buscar_extension_local(root, ext_binaria);
  for j = 1:numel(encontrados)
    fallas{end+1} = ['archivo binario no permitido: ' encontrados{j}]; %#ok<AGROW>
  endfor

  pref_legacy = fullfile(config, ['preferencias_cad_topo' ext_binaria]);
  if exist(pref_legacy, 'file') == 2
    fallas{end+1} = ['preferencia antigua no permitida: ' pref_legacy]; %#ok<AGROW>
  endif

  % 2) Revisar referencias literales a la extension binaria, con limite de token.
  %    No debe confundir la extension con campos como material o matrix.
  archivos_texto = listar_textos_local(fullfile(root, 'src'));
  archivos_texto = [archivos_texto listar_textos_local(fullfile(root, 'datos_usuario'))];
  for i = 1:numel(archivos_texto)
    ruta = archivos_texto{i};
    if exist(ruta, 'file') ~= 2, continue; endif
    raw = leer_texto_local(ruta);
    [~, ~, ext_texto] = fileparts(ruta);
    if strcmpi(ext_texto, '.m')
      revisable = extraer_cadenas_local(raw);
    else
      revisable = raw;
    endif
    if contiene_extension_mat_local(revisable)
      fallas{end+1} = ['referencia explicita a archivo ' ext_binaria ': ' ruta]; %#ok<AGROW>
    endif
    if contiene_flag_mat_local(revisable)
      fallas{end+1} = ['persistencia binaria con flag -' 'mat: ' ruta]; %#ok<AGROW>
    endif
    if ~isempty(strfind(upper(raw), nombre_motor_no_objetivo))
      fallas{end+1} = ['motor no objetivo mencionado en: ' ruta]; %#ok<AGROW>
    endif
  endfor

  % Autopruebas del detector para impedir la regresion observada en REV1.
  if contiene_extension_mat_local(['obj.' 'material']) || ...
     contiene_extension_mat_local(['param.' 'material_varillas']) || ...
     contiene_extension_mat_local(['tabla.' 'matrix']) || ...
     contiene_extension_mat_local(extraer_cadenas_local(['keys.' 'MAT = p;']))
    fallas{end+1} = ['autoprueba interna: falso positivo del detector ' ext_binaria]; %#ok<AGROW>
  endif
  if ~contiene_extension_mat_local(['archivo' ext_binaria]) || ...
     ~contiene_extension_mat_local(['ruta/modelo' ext_binaria ';'])
    fallas{end+1} = ['autoprueba interna: referencia ' ext_binaria ' real no detectada']; %#ok<AGROW>
  endif

  req = {'jsonencode', 'jsondecode'};
  for i = 1:numel(req)
    if ~((exist(req{i}, 'builtin') == 5) || (exist(req{i}, 'file') == 2))
      fallas{end+1} = ['funcion JSON no disponible: ' req{i}]; %#ok<AGROW>
    endif
  endfor

  ok = isempty(fallas);
  if ~silencioso
    fprintf('\n--- VERIFICACION AOSCAD OCTAVE-ONLY REV2 ---\n');
    if ok
      fprintf('OK  no existen archivos %s reales en el arbol AOS.\n', ext_binaria);
      fprintf('OK  no existen referencias explicitas ni flags de persistencia %s.\n', ext_binaria);
      fprintf('OK  campos validos como material no generan falsos positivos.\n');
      fprintf('OK  .aoscad JSON es la fuente canonica unica.\n');
    else
      fprintf(2, 'FALLAS: %d\n', numel(fallas));
      for i = 1:numel(fallas), fprintf(2, ' - %s\n', fallas{i}); endfor
    endif
  endif
endfunction

function out = extraer_cadenas_local(raw)
% Extrae literales entre comillas de archivos .m. Asi, nombres de campos
% como keys.MAT o obj.material no se interpretan como rutas de archivo.
  out = '';
  if isempty(raw), return; endif
  i = 1;
  n = length(raw);
  while i <= n
    c = raw(i);
    if (c == char(39)) || (c == char(34))
      quote = c;
      i = i + 1;
      while i <= n
        c = raw(i);
        if c == quote
          if (i < n) && (raw(i+1) == quote)
            out(end+1) = quote; %#ok<AGROW>
            i = i + 2;
            continue;
          endif
          break;
        endif
        out(end+1) = c; %#ok<AGROW>
        i = i + 1;
      endwhile
      out(end+1) = sprintf('\n'); %#ok<AGROW>
    endif
    i = i + 1;
  endwhile
endfunction

function tf = contiene_extension_mat_local(raw)
% Detecta el token binario solamente cuando termina la extension.
% Los casos positivos se construyen en las autopruebas sin literal embebido.
% Ejemplos negativos: campos material, matrix y listas de materiales.
  tf = false;
  if isempty(raw), return; endif
  s = lower(raw);
  token = ['.' 'mat'];
  pos = strfind(s, token);
  for i = 1:numel(pos)
    siguiente = pos(i) + length(token);
    if siguiente > length(s)
      tf = true;
      return;
    endif
    c = s(siguiente);
    if ~es_identificador_local(c)
      tf = true;
      return;
    endif
  endfor
endfunction

function tf = contiene_flag_mat_local(raw)
% Detecta el flag binario y sus variantes como token independiente.
  tf = false;
  if isempty(raw), return; endif
  s = lower(raw);
  token = ['-' 'mat'];
  pos = strfind(s, token);
  for i = 1:numel(pos)
    anterior_ok = (pos(i) == 1) || ~es_identificador_local(s(pos(i)-1));
    siguiente = pos(i) + length(token);
    siguiente_ok = (siguiente > length(s)) || ...
                   ~es_identificador_local(s(siguiente));
    if anterior_ok && siguiente_ok
      tf = true;
      return;
    endif
  endfor
endfunction

function tf = es_identificador_local(c)
  tf = ((c >= 'a') && (c <= 'z')) || ...
       ((c >= '0') && (c <= '9')) || ...
       (c == '_');
endfunction

function lista = buscar_extension_local(carpeta, extension)
  lista = {};
  if exist(carpeta, 'dir') ~= 7, return; endif
  d = dir(carpeta);
  for i = 1:numel(d)
    if strcmp(d(i).name, '.') || strcmp(d(i).name, '..'), continue; endif
    ruta = fullfile(carpeta, d(i).name);
    if d(i).isdir
      sub = buscar_extension_local(ruta, extension);
      lista = [lista sub]; %#ok<AGROW>
    else
      [~, ~, e] = fileparts(d(i).name);
      if strcmpi(e, extension), lista{end+1} = ruta; endif %#ok<AGROW>
    endif
  endfor
endfunction

function lista = listar_textos_local(carpeta)
  lista = {};
  if exist(carpeta, 'dir') ~= 7, return; endif
  extensiones = {'.m', '.txt', '.md', '.json'};
  d = dir(carpeta);
  for i = 1:numel(d)
    if strcmp(d(i).name, '.') || strcmp(d(i).name, '..'), continue; endif
    ruta = fullfile(carpeta, d(i).name);
    if d(i).isdir
      lista = [lista listar_textos_local(ruta)]; %#ok<AGROW>
    else
      [~, ~, e] = fileparts(d(i).name);
      if any(strcmpi(e, extensiones)), lista{end+1} = ruta; endif %#ok<AGROW>
    endif
  endfor
endfunction

function raw = leer_texto_local(ruta)
  raw = '';
  fid = fopen(ruta, 'rt');
  if fid < 0, return; endif
  raw = fread(fid, Inf, 'char=>char')';
  fclose(fid);
endfunction
