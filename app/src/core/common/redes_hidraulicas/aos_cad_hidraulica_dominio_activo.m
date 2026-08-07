function [dominio, indice] = aos_cad_hidraulica_dominio_activo(modelo)
% Devuelve el dominio hidraulico activo guardado en tablas_entrada.
  dominio = [];
  indice = 0;
  if ~isstruct(modelo) || ~isfield(modelo, 'tablas_entrada') || ...
      ~isfield(modelo.tablas_entrada, 'dominios_hidraulicos') || ...
      isempty(modelo.tablas_entrada.dominios_hidraulicos)
    return;
  endif
  dominios = modelo.tablas_entrada.dominios_hidraulicos;
  if isstruct(dominios)
    dominios = num2cell(dominios);
  endif

  id_activo = '';
  if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion) && ...
      isfield(modelo.simulacion, 'dominio_hidraulico_activo_id') && ...
      ~isempty(modelo.simulacion.dominio_hidraulico_activo_id)
    id_activo = char(modelo.simulacion.dominio_hidraulico_activo_id);
  endif

  if ~isempty(id_activo)
    for i = 1:numel(dominios)
      d = dominios{i};
      if isstruct(d) && isfield(d, 'id') && ...
          strcmp(char(d.id), id_activo)
        dominio = d;
        indice = i;
        return;
      endif
    endfor
  endif

  for i = 1:numel(dominios)
    d = dominios{i};
    activo = false;
    if isstruct(d) && isfield(d, 'activo')
      activo = valor_logico_local(d.activo);
    endif
    if activo
      dominio = d;
      indice = i;
      return;
    endif
  endfor
endfunction

function tf = valor_logico_local(v)
  tf = false;
  if islogical(v) && ~isempty(v)
    tf = v(1);
    return;
  endif
  if isnumeric(v) && ~isempty(v)
    tf = (v(1) ~= 0);
    return;
  endif
  if ischar(v)
    tf = any(strcmpi(strtrim(v), {'SI', 'TRUE', 'ACTIVO', '1'}));
  endif
endfunction
