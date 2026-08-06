function resultado = aos_generar_mapa_menus(AOS_root, salida_dir, formato_informe)
% AOS_GENERAR_MAPA_MENUS Descubre menus y genera manifiestos para la interfaz.
%
% No ejecuta los menus. Analiza estaticamente los archivos .m para evitar
% efectos secundarios. Salidas:
%   aos_menu_map.json  - contrato principal para la app/interfaz
%   aos_menu_map.csv   - opciones y destinos
%   aos_menu_nodes.csv - inventario de menus
%   aos_menu_map.dot   - grafo Graphviz
%   aos_menu_map.txt   - resumen legible

  if nargin < 1 || isempty(AOS_root)
    aqui = fileparts(mfilename('fullpath'));
    AOS_root = fileparts(fileparts(fileparts(fileparts(aqui))));
  endif
  if nargin < 2 || isempty(salida_dir)
    salida_dir = fullfile(AOS_root, 'datos', 'interfaz');
  endif
  if nargin < 3 || isempty(formato_informe)
    formato_informe = 'both';
  endif
  formato_informe = lower(strtrim(formato_informe));
  if ~any(strcmp(formato_informe, {'txt','md','both'}))
    error('Formato de informe invalido: %s. Use txt, md o both.', formato_informe);
  endif
  if exist(AOS_root, 'dir') ~= 7
    error('AOS_root no existe: %s', AOS_root);
  endif
  if exist(salida_dir, 'dir') ~= 7
    [ok, msg] = mkdir(salida_dir);
    if ~ok, error('No se pudo crear %s: %s', salida_dir, msg); endif
  endif

  src_dir = fullfile(AOS_root, 'src');
  archivos = listar_m_recursivo_local(src_dir);
  indice = construir_indice_local(archivos, AOS_root);

  menus = repmat(menu_vacio_local(), 0, 1);
  for i = 1:numel(indice)
    if indice(i).es_menu
      menus(end+1) = analizar_menu_local(indice(i), indice, AOS_root); %#ok<AGROW>
    endif
  endfor

  if isempty(menus)
    error('No se detectaron menus debajo de %s.', src_dir);
  endif

  [~, orden] = sort(lower({menus.id}));
  menus = menus(orden);
  raiz_menu = detectar_raiz_local(menus);
  generado = datestr(now(), 'yyyy-mm-ddTHH:MM:SS');

  mapa = struct();
  mapa.schema = 'AOS_MENU_MAP';
  mapa.schema_version = 1;
  mapa.aos_version = leer_version_local(AOS_root);
  mapa.generated_at = generado;
  mapa.generator = 'aos_generar_mapa_menus';
  mapa.root_menu = raiz_menu;
  mapa.menus = menus;

  archivo_json = fullfile(salida_dir, 'aos_menu_map.json');
  archivo_csv = fullfile(salida_dir, 'aos_menu_map.csv');
  archivo_nodes = fullfile(salida_dir, 'aos_menu_nodes.csv');
  archivo_dot = fullfile(salida_dir, 'aos_menu_map.dot');
  archivo_txt = fullfile(salida_dir, 'aos_menu_map.txt');
  archivo_md = fullfile(salida_dir, 'aos_menu_map.md');

  escribir_json_local(archivo_json, mapa);
  escribir_csv_local(archivo_csv, menus);
  escribir_nodes_local(archivo_nodes, menus);
  escribir_dot_local(archivo_dot, menus, raiz_menu);
  if strcmp(formato_informe,'txt') || strcmp(formato_informe,'both')
    escribir_resumen_local(archivo_txt, mapa);
  else
    archivo_txt = '';
  endif
  if strcmp(formato_informe,'md') || strcmp(formato_informe,'both')
    escribir_markdown_local(archivo_md, mapa);
  else
    archivo_md = '';
  endif

  total_opciones = 0;
  total_dependencias = 0;
  total_no_resueltas = 0;
  for i = 1:numel(menus)
    total_opciones += numel(menus(i).options);
    for j = 1:numel(menus(i).options)
      total_dependencias += numel(menus(i).options(j).targets);
      total_no_resueltas += numel(menus(i).options(j).unresolved_targets);
    endfor
  endfor

  resultado = struct('total_menus',numel(menus), ...
                     'total_opciones',total_opciones, ...
                     'total_dependencias',total_dependencias, ...
                     'total_no_resueltas',total_no_resueltas, ...
                     'root_menu',raiz_menu, ...
                     'archivo_json',archivo_json, ...
                     'archivo_csv',archivo_csv, ...
                     'archivo_nodes',archivo_nodes, ...
                     'archivo_dot',archivo_dot, ...
                     'archivo_txt',archivo_txt, ...
                     'archivo_md',archivo_md);

  fprintf('\n===== MAPA DE DEPENDENCIAS DE MENUS AOS =====\n');
  fprintf('Menu raiz          : %s\n', raiz_menu);
  fprintf('Menus detectados   : %d\n', resultado.total_menus);
  fprintf('Opciones detectadas: %d\n', resultado.total_opciones);
  fprintf('Dependencias       : %d\n', resultado.total_dependencias);
  fprintf('No resueltas       : %d\n', resultado.total_no_resueltas);
  fprintf('JSON interfaz      : %s\n', archivo_json);
  fprintf('Grafo DOT          : %s\n', archivo_dot);
  if ~isempty(archivo_txt), fprintf('Informe TXT        : %s\n', archivo_txt); endif
  if ~isempty(archivo_md), fprintf('Informe Markdown   : %s\n', archivo_md); endif
  fprintf('=============================================\n');
endfunction

function archivos = listar_m_recursivo_local(base)
  archivos = {};
  if exist(base, 'dir') ~= 7, return; endif
  d = dir(base);
  for i = 1:numel(d)
    n = d(i).name;
    if strcmp(n,'.') || strcmp(n,'..'), continue; endif
    p = fullfile(base,n);
    if d(i).isdir
      sub = listar_m_recursivo_local(p);
      archivos = [archivos, sub]; %#ok<AGROW>
    else
      [~,~,ext] = fileparts(n);
      if strcmpi(ext,'.m'), archivos{end+1} = p; endif %#ok<AGROW>
    endif
  endfor
endfunction

function indice = construir_indice_local(archivos, root)
  vacio = struct('id','','file','','relative_file','','text','','lines',{{}}, ...
                 'es_menu',false,'title','','line_count',0);
  indice = repmat(vacio, 0, 1);
  for i = 1:numel(archivos)
    txt = leer_texto_local(archivos{i});
    ls = regexp(txt, '\r\n|\n|\r', 'split');
    id = funcion_principal_local(ls, archivos{i});
    rel = ruta_relativa_local(archivos{i}, root);
    es_menu = detectar_menu_local(id, rel, txt);
    titulo = detectar_titulo_local(ls, id);
    indice(end+1) = struct('id',id,'file',archivos{i},'relative_file',rel, ...
                           'text',txt,'lines',{ls},'es_menu',es_menu, ...
                           'title',titulo,'line_count',numel(ls)); %#ok<AGROW>
  endfor
endfunction

function m = analizar_menu_local(item, indice, root)
  m = menu_vacio_local();
  m.id = item.id;
  m.title = item.title;
  m.file = item.relative_file;
  m.absolute_file = item.file;
  m.exists = true;
  m.line_count = item.line_count;
  m.group = inferir_grupo_local(item.id, item.relative_file);

  opciones = extraer_opciones_local(item.lines);
  casos = extraer_casos_local(item.lines, indice, item.id);

  for i = 1:numel(opciones)
    k = opciones(i).key;
    objetivos = {};
    no_resueltos = {};
    for j = 1:numel(casos)
      if any(casos(j).keys == k)
        objetivos = union_estable_local(objetivos, casos(j).targets);
        no_resueltos = union_estable_local(no_resueltos, casos(j).unresolved);
      endif
    endfor
    opciones(i).targets = objetivos;
    opciones(i).unresolved_targets = no_resueltos;
    opciones(i).action = clasificar_accion_local(opciones(i), objetivos);
    opciones(i).navigates = any(cellfun(@(x) es_menu_id_local(x, indice), objetivos));
  endfor

  % Dependencias detectadas sin opcion visible (utiles para auditoria).
  deps = llamadas_proyecto_local(item.lines, indice, item.id);
  m.options = opciones;
  m.dependencies = deps;
endfunction

function opciones = extraer_opciones_local(lines)
  base = struct('key',0,'label','','status','', 'line',0, ...
                'targets',{{}},'unresolved_targets',{{}}, ...
                'action','UNKNOWN','navigates',false);
  opciones = repmat(base, 0, 1);
  vistos = [];
  for i = 1:numel(lines)
    l = lines{i};
    tok = regexp(l, "fprintf\\s*\\(\\s*'((?:''|[^'])*)'", 'tokens', 'once');
    if isempty(tok), continue; endif
    s = strrep(tok{1}, "''", "'");
    s = strrep(s, '\\n', '');
    t = regexp(s, '^\\s*([0-9]+)\\s*[-:]\\s*(.*?)\\s*$', 'tokens', 'once');
    if isempty(t), continue; endif
    key = str2double(t{1});
    if any(vistos == key), continue; endif
    label = strtrim(t{2});
    est = regexp(label, '\\[([^\\]]+)\\]', 'tokens');
    status = '';
    if ~isempty(est), status = upper(strtrim(est{end}{1})); endif
    opciones(end+1) = struct('key',key,'label',label,'status',status, ...
                             'line',i,'targets',{{}},'unresolved_targets',{{}}, ...
                             'action','UNKNOWN','navigates',false); %#ok<AGROW>
    vistos(end+1) = key; %#ok<AGROW>
  endfor
endfunction

function casos = extraer_casos_local(lines, indice, actual)
  base = struct('keys',[],'targets',{{}},'unresolved',{{}});
  casos = repmat(base, 0, 1);
  activo = 0;
  for i = 1:numel(lines)
    l = strtrim(quitar_comentario_local(lines{i}));
    c = regexp(l, '^case\\s+(.+)$', 'tokens', 'once');
    if ~isempty(c)
      nums = regexp(c{1}, '[0-9]+', 'match');
      keys = cellfun(@str2double, nums);
      casos(end+1) = struct('keys',keys,'targets',{{}},'unresolved',{{}}); %#ok<AGROW>
      activo = numel(casos);
      continue;
    endif
    if ~isempty(regexp(l, '^(otherwise|endswitch|end\\s*switch)', 'once'))
      activo = 0;
      continue;
    endif
    if activo == 0, continue; endif
    llamadas = extraer_llamadas_linea_local(l);
    for j = 1:numel(llamadas)
      fn = llamadas{j};
      if strcmp(fn,actual) || es_builtin_local(fn), continue; endif
      if existe_id_local(fn, indice)
        casos(activo).targets = union_estable_local(casos(activo).targets,{fn});
      elseif parece_accion_aos_local(fn)
        casos(activo).unresolved = union_estable_local(casos(activo).unresolved,{fn});
      endif
    endfor
  endfor
endfunction

function deps = llamadas_proyecto_local(lines, indice, actual)
  deps = {};
  for i = 1:numel(lines)
    l = quitar_comentario_local(lines{i});
    calls = extraer_llamadas_linea_local(l);
    for j = 1:numel(calls)
      fn = calls{j};
      if ~strcmp(fn,actual) && existe_id_local(fn,indice)
        deps = union_estable_local(deps,{fn});
      endif
    endfor
  endfor
endfunction

function calls = extraer_llamadas_linea_local(line)
  % Analizador deliberadamente simple y compatible con GNU Octave.
  % Evita expresiones regulares PCRE avanzadas, que cambian entre versiones.
  calls = {};
  if isempty(line), return; endif
  n = numel(line);
  i = 1;
  while i <= n
    c = line(i);
    if es_inicio_identificador_local(c)
      j = i + 1;
      while j <= n && es_identificador_local(line(j))
        j += 1;
      endwhile
      nombre = line(i:j-1);
      k = j;
      while k <= n && any(line(k) == [' ' sprintf('\t')])
        k += 1;
      endwhile
      if k <= n && (line(k) == '(' || line(k) == ';')
        calls{end+1} = nombre; %#ok<AGROW>
      endif
      i = j;
    else
      i += 1;
    endif
  endwhile
  calls = unique_estable_local(calls);
endfunction

function tf = es_inicio_identificador_local(c)
  tf = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
endfunction

function tf = es_identificador_local(c)
  tf = es_inicio_identificador_local(c) || (c >= '0' && c <= '9') || c == '_';
endfunction

function titulo = detectar_titulo_local(lines, id)
  titulo = strrep(id,'_',' ');
  for i = 1:min(numel(lines),80)
    tok = regexp(lines{i}, "fprintf\\s*\\(\\s*'((?:''|[^'])*)'", 'tokens', 'once');
    if isempty(tok), continue; endif
    s = strrep(tok{1}, '\\n', '');
    s = regexprep(s, '^=+|=+$', '');
    s = regexprep(s, '^-+|-+$', '');
    s = strtrim(s);
    if numel(s) >= 4 && ( ~isempty(strfind(upper(s),'AOS')) || ...
                         ~isempty(strfind(upper(s),'MENU')) || ...
                         ~isempty(strfind(tok{1},'---')) )
      titulo = s;
      return;
    endif
  endfor
endfunction

function tf = detectar_menu_local(id, rel, txt)
  [~,name] = fileparts(rel);
  n = lower(name);
  tf = false;
  if ~isempty(strfind(lower(rel), [filesep 'menu' filesep])) || ...
     ~isempty(strfind(strrep(lower(rel),'\\','/'), '/menu/'))
    tf = ~isempty(strfind(n,'menu')) || strcmpi(id,'AOS_app') || ...
         ~isempty(strfind(txt,'aos_leer_opcion')) || ...
         ~isempty(strfind(txt,"input('Seleccione"));
  endif
endfunction

function id = funcion_principal_local(lines, file)
  [~,fallback] = fileparts(file);
  id = fallback;
  for i = 1:min(numel(lines),50)
    l = strtrim(lines{i});
    if isempty(regexp(l,'^function\\b','once')), continue; endif
    t = regexp(l, '^function\\s+(?:\\[[^\\]]*\\]|[A-Za-z][A-Za-z0-9_]*)?\\s*=\\s*([A-Za-z][A-Za-z0-9_]*)', 'tokens','once');
    if isempty(t)
      t = regexp(l, '^function\\s+([A-Za-z][A-Za-z0-9_]*)', 'tokens','once');
    endif
    if ~isempty(t), id=t{1}; return; endif
  endfor
endfunction

function root = detectar_raiz_local(menus)
  candidatos = {'AOS_app','AOS','AOS_menu_principal'};
  root = menus(1).id;
  for i = 1:numel(candidatos)
    if any(strcmp({menus.id},candidatos{i})), root=candidatos{i}; return; endif
  endfor
endfunction

function grupo = inferir_grupo_local(id, rel)
  u = upper([id ' ' rel]);
  grupos = {'BM','BES','JGL','GL','PCP','LDL','CGF','EGF','SCADA'};
  grupo = 'GENERAL';
  for i = 1:numel(grupos)
    if ~isempty(strfind(u,grupos{i})), grupo=grupos{i}; return; endif
  endfor
endfunction

function action = clasificar_accion_local(opt, targets)
  if opt.key == 0 || ~isempty(strfind(lower(opt.label),'volver')) || ...
     ~isempty(strfind(lower(opt.label),'salir'))
    action = 'BACK_OR_EXIT';
  elseif isempty(targets)
    if ~isempty(strfind(opt.status,'PLANIFICADO')) || ...
       ~isempty(strfind(opt.status,'DESARROLLO'))
      action = 'PLACEHOLDER';
    else
      action = 'INLINE_OR_UNRESOLVED';
    endif
  else
    action = 'CALL';
  endif
endfunction

function tf = es_menu_id_local(id, indice)
  tf = false;
  for i=1:numel(indice)
    if strcmp(indice(i).id,id), tf=indice(i).es_menu; return; endif
  endfor
endfunction

function tf = existe_id_local(id, indice)
  tf = any(strcmp({indice.id},id));
endfunction

function tf = parece_accion_aos_local(fn)
  f = lower(fn);
  tf = strncmp(f,'aos_',4) || strncmp(f,'jgl_',4) || ...
       strncmp(f,'gl_',3) || strncmp(f,'bm_',3) || ...
       strncmp(f,'bes_',4) || strncmp(f,'gibbs',5);
endfunction

function tf = es_builtin_local(fn)
  lista = {'if','elseif','for','while','switch','case','catch','try','function', ...
           'fprintf','sprintf','input','disp','error','warning','return','break', ...
           'continue','isempty','isfield','isstruct','isnumeric','ischar','strcmp', ...
           'strcmpi','strtrim','lower','upper','fullfile','fileparts','mfilename', ...
           'addpath','cd','exist','length','numel','max','min','round','floor','ceil', ...
           'struct','cell','true','false','global','clear','clc','close','plot','figure'};
  tf = any(strcmp(fn,lista));
endfunction

function s = quitar_comentario_local(s)
  en = false;
  i = 1;
  while i <= numel(s)
    if s(i) == ''''
      if en && i < numel(s) && s(i+1) == ''''
        i += 2; continue;
      endif
      en = ~en;
    elseif s(i) == '%' && ~en
      s = s(1:i-1); return;
    endif
    i += 1;
  endwhile
endfunction

function txt = leer_texto_local(file)
  fid = fopen(file,'rb');
  if fid < 0, error('No se pudo leer %s',file); endif
  c = fread(fid,Inf,'*char')'; fclose(fid); txt=c;
endfunction

function rel = ruta_relativa_local(path, root)
  p = strrep(path,'\\','/'); r = strrep(root,'\\','/');
  if strncmp(p,[r '/'],numel(r)+1), rel=p(numel(r)+2:end); else rel=p; endif
endfunction

function v = leer_version_local(root)
  v = 'desconocida';
  f = fullfile(root,'VERSION');
  if exist(f,'file') == 2
    v = strtrim(leer_texto_local(f));
  endif
endfunction

function c = unique_estable_local(c)
  out={};
  for i=1:numel(c)
    if ~any(strcmp(out,c{i})), out{end+1}=c{i}; endif %#ok<AGROW>
  endfor
  c=out;
endfunction

function a = union_estable_local(a,b)
  for i=1:numel(b)
    if ~any(strcmp(a,b{i})), a{end+1}=b{i}; endif %#ok<AGROW>
  endfor
endfunction

function m = menu_vacio_local()
  op = struct('key',0,'label','','status','','line',0,'targets',{{}}, ...
              'unresolved_targets',{{}},'action','UNKNOWN','navigates',false);
  m = struct('id','','title','','group','GENERAL','file','','absolute_file','', ...
             'exists',false,'line_count',0,'options',repmat(op,0,1), ...
             'dependencies',{{}});
endfunction

function escribir_json_local(file, mapa)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'{\n');
  fprintf(fid,'  "schema":"%s",\n',json_escape_local(mapa.schema));
  fprintf(fid,'  "schema_version":%d,\n',mapa.schema_version);
  fprintf(fid,'  "aos_version":"%s",\n',json_escape_local(mapa.aos_version));
  fprintf(fid,'  "generated_at":"%s",\n',json_escape_local(mapa.generated_at));
  fprintf(fid,'  "generator":"%s",\n',json_escape_local(mapa.generator));
  fprintf(fid,'  "root_menu":"%s",\n',json_escape_local(mapa.root_menu));
  fprintf(fid,'  "menus":[\n');
  for i=1:numel(mapa.menus)
    m=mapa.menus(i);
    fprintf(fid,'    {"id":"%s","title":"%s","group":"%s","file":"%s","exists":%s,"line_count":%d,"dependencies":', ...
      json_escape_local(m.id),json_escape_local(m.title),json_escape_local(m.group), ...
      json_escape_local(m.file),bool_json_local(m.exists),m.line_count);
    escribir_array_strings_local(fid,m.dependencies);
    fprintf(fid,',"options":[');
    for j=1:numel(m.options)
      o=m.options(j);
      if j>1,fprintf(fid,',');endif
      fprintf(fid,'{"key":%d,"label":"%s","status":"%s","line":%d,"action":"%s","navigates":%s,"targets":', ...
        o.key,json_escape_local(o.label),json_escape_local(o.status),o.line, ...
        json_escape_local(o.action),bool_json_local(o.navigates));
      escribir_array_strings_local(fid,o.targets);
      fprintf(fid,',"unresolved_targets":');
      escribir_array_strings_local(fid,o.unresolved_targets);
      fprintf(fid,'}');
    endfor
    fprintf(fid,']}');
    if i<numel(mapa.menus),fprintf(fid,',');endif
    fprintf(fid,'\n');
  endfor
  fprintf(fid,'  ]\n}\n'); fclose(fid);
endfunction

function escribir_array_strings_local(fid,c)
  fprintf(fid,'[');
  for i=1:numel(c)
    if i>1,fprintf(fid,',');endif
    fprintf(fid,'"%s"',json_escape_local(c{i}));
  endfor
  fprintf(fid,']');
endfunction

function s = json_escape_local(s)
  if isempty(s),s='';return;endif
  s=strrep(s,'\\','\\\\'); s=strrep(s,'"','\\"');
  s=strrep(s,sprintf('\r'),'\\r'); s=strrep(s,sprintf('\n'),'\\n');
  s=strrep(s,sprintf('\t'),'\\t');
endfunction

function s = bool_json_local(v)
  if v,s='true';else s='false';endif
endfunction

function escribir_csv_local(file,menus)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'menu_id,menu_title,group,option_key,option_label,status,action,navigates,targets,unresolved_targets,source_file,source_line\n');
  for i=1:numel(menus)
    m=menus(i);
    for j=1:numel(m.options)
      o=m.options(j);
      fprintf(fid,'%s,%s,%s,%d,%s,%s,%s,%d,%s,%s,%s,%d\n', ...
        csv_local(m.id),csv_local(m.title),csv_local(m.group),o.key, ...
        csv_local(o.label),csv_local(o.status),csv_local(o.action),o.navigates, ...
        csv_local(strjoin_local(o.targets,'|')),csv_local(strjoin_local(o.unresolved_targets,'|')), ...
        csv_local(m.file),o.line);
    endfor
  endfor
  fclose(fid);
endfunction

function escribir_nodes_local(file,menus)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'menu_id,title,group,file,line_count,option_count,dependencies\n');
  for i=1:numel(menus)
    fprintf(fid,'%s,%s,%s,%s,%d,%d,%s\n',csv_local(menus(i).id), ...
      csv_local(menus(i).title),csv_local(menus(i).group),csv_local(menus(i).file), ...
      menus(i).line_count,numel(menus(i).options),csv_local(strjoin_local(menus(i).dependencies,'|')));
  endfor
  fclose(fid);
endfunction

function escribir_dot_local(file,menus,root)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'digraph AOS_MENUS {\n  rankdir=LR;\n  node [shape=box];\n');
  for i=1:numel(menus)
    forma='box'; if strcmp(menus(i).id,root),forma='doubleoctagon';endif
    fprintf(fid,'  "%s" [label="%s",shape=%s];\n',dot_escape_local(menus(i).id),dot_escape_local(menus(i).title),forma);
  endfor
  for i=1:numel(menus)
    for j=1:numel(menus(i).options)
      o=menus(i).options(j);
      for k=1:numel(o.targets)
        if any(strcmp({menus.id},o.targets{k}))
          fprintf(fid,'  "%s" -> "%s" [label="%d - %s"];\n', ...
            dot_escape_local(menus(i).id),dot_escape_local(o.targets{k}),o.key,dot_escape_local(o.label));
        endif
      endfor
    endfor
  endfor
  fprintf(fid,'}\n'); fclose(fid);
endfunction

function s=dot_escape_local(s)
  s=strrep(s,'\\','\\\\'); s=strrep(s,'"','\\"');
endfunction

function escribir_resumen_local(file,mapa)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'AOS MENU MAP\nVersion: %s\nGenerado: %s\nRaiz: %s\n\n', ...
    mapa.aos_version,mapa.generated_at,mapa.root_menu);
  for i=1:numel(mapa.menus)
    m=mapa.menus(i);
    fprintf(fid,'[%s] %s\n  Archivo: %s\n',m.id,m.title,m.file);
    for j=1:numel(m.options)
      o=m.options(j);
      fprintf(fid,'  %d - %s',o.key,o.label);
      if ~isempty(o.targets),fprintf(fid,' -> %s',strjoin_local(o.targets,', '));endif
      fprintf(fid,'\n');
    endfor
    fprintf(fid,'\n');
  endfor
  fclose(fid);
endfunction


function escribir_markdown_local(file,mapa)
  fid=fopen(file,'w'); if fid<0,error('No se pudo escribir %s',file);endif
  fprintf(fid,'# Mapa de dependencias de menus AOS\n\n');
  fprintf(fid,'- **Version AOS:** %s\n',mapa.aos_version);
  fprintf(fid,'- **Generado:** %s\n',mapa.generated_at);
  fprintf(fid,'- **Menu raiz:** `%s`\n',mapa.root_menu);
  fprintf(fid,'- **Menus detectados:** %d\n\n',numel(mapa.menus));
  for i=1:numel(mapa.menus)
    m=mapa.menus(i);
    fprintf(fid,'## %s (`%s`)\n\n',m.title,m.id);
    fprintf(fid,'**Archivo:** `%s`  \n',m.file);
    fprintf(fid,'**Grupo:** %s  \n',m.group);
    fprintf(fid,'**Opciones:** %d\n\n',numel(m.options));
    if isempty(m.options)
      fprintf(fid,'_No se detectaron opciones visibles._\n\n');
    else
      fprintf(fid,'| Opcion | Etiqueta | Destino | Accion | Estado | Linea |\n');
      fprintf(fid,'|---:|---|---|---|---|---:|\n');
      for j=1:numel(m.options)
        o=m.options(j);
        destino=strjoin_local(o.targets,', ');
        if isempty(destino), destino='-'; endif
        estado=o.status; if isempty(estado), estado='-'; endif
        fprintf(fid,'| %d | %s | %s | %s | %s | %d |\n',o.key,md_escape_local(o.label), ...
          md_escape_local(destino),md_escape_local(o.action),md_escape_local(estado),o.line);
      endfor
      fprintf(fid,'\n');
    endif
    if ~isempty(m.dependencies)
      fprintf(fid,'**Dependencias detectadas:** %s\n\n',md_escape_local(strjoin_local(m.dependencies,', ')));
    endif
  endfor
  fclose(fid);
endfunction

function s=md_escape_local(s)
  s=strrep(s,'|','\|');
  s=strrep(s,sprintf('\r'),' ');
  s=strrep(s,sprintf('\n'),' ');
endfunction

function s=csv_local(valor)
  [s,ok]=aos_texto_seguro(valor,'');if ~ok,s='';endif
  s=strrep(s,'"','""'); s=['"' s '"'];
endfunction

function s=strjoin_local(c,sep)
  if isempty(c),s='';return;endif
  s=c{1}; for i=2:numel(c),s=[s sep c{i}];endfor
endfunction
