function encontrada = aos_mostrar_seccion_activa(alias, titulo)
% Muestra una seccion importada del AOSDAT sin alterar CONFIG_ACTIVA.
  global CONFIG_ACTIVA;
  encontrada = false;
  if nargin < 2 || isempty(titulo), titulo = 'DATOS ACTIVOS'; endif
  if ischar(alias), alias = {alias}; endif
  fprintf('\n--- %s ---\n', titulo);
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('No hay un .aosdat activo.\n');
    return;
  endif
  for i=1:numel(alias)
    c=alias{i};
    if isfield(CONFIG_ACTIVA,c)
      encontrada=true;
      imprimir_local(CONFIG_ACTIVA.(c),c,0);
      return;
    endif
  endfor
  fprintf('El .aosdat activo no contiene ninguna de estas secciones: %s\n', strjoin(alias, ', '));
endfunction

function imprimir_local(v,nombre,nivel)
  sangria=repmat(' ',1,2*nivel);
  if isstruct(v)
    f=fieldnames(v);
    fprintf('%s[%s] (%d campos)\n',sangria,nombre,numel(f));
    limite=min(numel(f),40);
    for j=1:limite
      c=f{j}; x=v.(c);
      if isstruct(x)
        fprintf('%s  %s = <estructura: %d campos>\n',sangria,c,numel(fieldnames(x)));
      elseif isnumeric(x) || islogical(x)
        if isscalar(x), fprintf('%s  %s = %.12g\n',sangria,c,double(x));
        else, fprintf('%s  %s = <%s %s>\n',sangria,c,class(x),mat2str(size(x))); endif
      elseif ischar(x)
        fprintf('%s  %s = %s\n',sangria,c,x);
      elseif iscell(x)
        fprintf('%s  %s = <cell %s>\n',sangria,c,mat2str(size(x)));
      else
        fprintf('%s  %s = <%s>\n',sangria,c,class(x));
      endif
    endfor
    if numel(f)>limite, fprintf('%s  ... %d campos adicionales\n',sangria,numel(f)-limite); endif
  else
    fprintf('%s%s = <%s>\n',sangria,nombre,class(v));
  endif
endfunction
