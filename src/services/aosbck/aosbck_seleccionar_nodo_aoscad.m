function node_id = aosbck_seleccionar_nodo_aoscad(modo)
% AOSBCK_SELECCIONAR_NODO_AOSCAD Permite tocar un nodo o ingresar su ID.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(modo), modo = 'GRAFICO'; endif
  modo = upper(char(modo));
  if exist('aos_cad_hidraulica_preparar_modelo','file') == 2
    try, aos_cad_hidraulica_preparar_modelo(true); catch, end_try_catch
  endif
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA,'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia,'modelo_aoscad')
    error('AOSBCK: no hay modelo AOSCAD activo.');
  endif
  nodos = CONFIG_ACTIVA.cad_topologia.modelo_aoscad.tablas_entrada.nodos;
  if isempty(nodos), error('AOSBCK: el modelo no contiene nodos.'); endif
  node_id = '';
  if strcmp(modo,'GRAFICO')
    h = [];
    try
      h = aos_cad_hidraulica_dominio_visualizar([], ...
        'Seleccione el nodo que representa la pieza AOSBCK');
      fprintf('Toque el nodo asociado al componente...\n');
      [x,y] = ginput(1);
      node_id = cercano_local(nodos,x,y);
      if ~isempty(h) && ishandle(h), close(h); endif
      fprintf('Nodo seleccionado: %s\n',node_id);
      return;
    catch err
      if ~isempty(h) && ishandle(h), close(h); endif
      fprintf('Seleccion grafica no disponible (%s). Se utilizara ID.\n',err.message);
    end_try_catch
  endif
  fprintf('\nNODOS AOSCAD DISPONIBLES:\n');
  for i=1:numel(nodos)
    n=elem_local(nodos,i);
    fprintf('  %-12s X=%g  Y=%g  Z=%g\n',char(n.id),num_local(n,'x',0),num_local(n,'y',0),num_local(n,'z',0));
  endfor
  node_id=strtrim(input('ID del nodo AOSCAD: ','s'));
  if isempty(buscar_local(nodos,node_id)), error('AOSBCK: nodo no valido.'); endif
endfunction

function id=cercano_local(nodos,x,y)
  dmin=Inf;id='';
  for i=1:numel(nodos)
    n=elem_local(nodos,i);d=hypot(num_local(n,'x',0)-x,num_local(n,'y',0)-y);
    if d<dmin,dmin=d;id=char(n.id);endif
  endfor
endfunction
function n=buscar_local(nodos,id)
  n=[];for i=1:numel(nodos),x=elem_local(nodos,i);if isfield(x,'id')&&strcmp(char(x.id),char(id)),n=x;return;endif;endfor
endfunction
function v=elem_local(c,i),if iscell(c),v=c{i};else,v=c(i);endif;endfunction
function v=num_local(s,f,d),v=d;if isfield(s,f)&&isnumeric(s.(f))&&~isempty(s.(f)),v=double(s.(f)(1));endif;endfunction
