function rutas_agregadas = iniciar_aos(incluir_pruebas)
% INICIAR_AOS Registra codigo AOS con orden controlado y sin genpath.
% GNU Octave es el motor oficial. Por defecto no agrega tests ni codigo
% legacy al path operativo. Los verificadores pueden invocar iniciar_aos(true).
  if nargin < 1 || isempty(incluir_pruebas), incluir_pruebas = false; endif

  AOS_root = fileparts(fileparts(mfilename('fullpath')));
  src_root = fullfile(AOS_root, 'src');
  if exist(src_root, 'dir') ~= 7
    error('AOS: no se encontro la carpeta src en %s', AOS_root);
  endif

  exclusiones = {fullfile(src_root,'docs')};
  if ~logical(incluir_pruebas)
    exclusiones{end+1} = fullfile(src_root,'tests');
    exclusiones{end+1} = fullfile(src_root,'diagnosticos','legacy');
  endif

  rutas = listar_rutas_codigo_local(src_root, exclusiones);
  rutas = ordenar_rutas_local(rutas, src_root);

  % Limpiar cualquier ruta AOS residual (incluidos tests/legacy agregados
  % por verificadores anteriores) y reconstruir el path de forma determinista.
  partes_path = strsplit(path(), pathsep());
  for i = 1:numel(partes_path)
    ruta_actual = partes_path{i};
    if esta_dentro_local(ruta_actual, src_root)
      try
        rmpath(ruta_actual);
      catch
      end_try_catch
    endif
  endfor

  % El codigo general se agrega al final; las interfaces publicas de menu
  % quedan al principio para impedir que una implementacion interna las sombree.
  for i = 1:numel(rutas)
    addpath(rutas{i}, '-end');
  endfor
  addpath(src_root, '-begin');
  menu_root = fullfile(src_root, 'menu');
  if exist(menu_root,'dir') == 7, addpath(menu_root, '-begin'); endif

  rutas_agregadas = rutas;
endfunction

function rutas = listar_rutas_codigo_local(carpeta, exclusiones)
  rutas = {};
  if esta_excluida_local(carpeta, exclusiones), return; endif
  if contiene_m_local(carpeta), rutas{end+1} = carpeta; endif
  d = dir(carpeta);
  nombres = {d.name};
  nombres_lower = cellfun(@lower, nombres, 'UniformOutput', false);
  [~, orden] = sort(nombres_lower);
  d = d(orden);
  for i = 1:numel(d)
    if ~d(i).isdir || strcmp(d(i).name,'.') || strcmp(d(i).name,'..'), continue; endif
    sub = fullfile(carpeta, d(i).name);
    if esta_excluida_local(sub, exclusiones), continue; endif
    rutas = [rutas, listar_rutas_codigo_local(sub, exclusiones)]; %#ok<AGROW>
  endfor
endfunction

function tf = contiene_m_local(carpeta)
  tf = ~isempty(dir(fullfile(carpeta, '*.m')));
endfunction

function tf = esta_excluida_local(ruta, exclusiones)
  tf = false;
  c = canon_local(ruta);
  for i = 1:numel(exclusiones)
    e = canon_local(exclusiones{i});
    if strcmp(c,e) || (numel(c) > numel(e) && strncmp(c,[e '/'],numel(e)+1))
      tf = true; return;
    endif
  endfor
endfunction

function rutas = ordenar_rutas_local(rutas, src_root)
  if isempty(rutas), return; endif
  pesos = zeros(1,numel(rutas));
  for i = 1:numel(rutas)
    r = canon_local(rutas{i});
    if strcmp(r,canon_local(src_root)), pesos(i)=0;
    elseif ~isempty(strfind(r,'/core/')), pesos(i)=10;
    elseif ~isempty(strfind(r,'/services/')), pesos(i)=20;
    elseif ~isempty(strfind(r,'/solvers/')), pesos(i)=30;
    elseif ~isempty(strfind(r,'/utilidades/')), pesos(i)=40;
    elseif ~isempty(strfind(r,'/geologia/')) || ~isempty(strfind(r,'/sensibilidad/')), pesos(i)=50;
    elseif ~isempty(strfind(r,'/modulos/')), pesos(i)=60;
    elseif ~isempty(strfind(r,'/workbenches/')), pesos(i)=70;
    elseif ~isempty(strfind(r,'/menu')), pesos(i)=100;
    else, pesos(i)=80;
    endif
  endfor
  claves = cell(1,numel(rutas));
  for i=1:numel(rutas), claves{i}=sprintf('%03d_%s',pesos(i),canon_local(rutas{i})); endfor
  [~,idx]=sort(claves); rutas=rutas(idx);
endfunction

function tf = esta_dentro_local(ruta, raiz)
  tf = false;
  if isempty(ruta), return; endif
  c = canon_local(ruta);
  r = canon_local(raiz);
  tf = strcmp(c, r) || (numel(c) > numel(r) && strncmp(c, [r '/'], numel(r)+1));
endfunction

function p = canon_local(p)
  p = strrep(char(p),'\\','/');
  while numel(p)>1 && p(end)=='/', p(end)=[]; endwhile
  if ispc(), p=lower(p); endif
endfunction
