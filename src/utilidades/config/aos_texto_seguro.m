function [txt, ok] = aos_texto_seguro(valor, defecto)
% AOS_TEXTO_SEGURO Convierte valores escalares a texto sin romper menus.
% GNU Octave es el motor oficial. Estructuras, celdas complejas y vectores
% no se fuerzan mediante num2str: se inspeccionan o se devuelve el defecto.

  if nargin < 2 || ~ischar(defecto)
    defecto = '';
  endif

  txt = defecto;
  ok = false;

  if isempty(valor)
    return;
  endif

  if ischar(valor)
    if rows(valor) > 1
      valor = valor(1, :);
    endif
    candidato = strtrim(valor);
    if ~isempty(candidato)
      txt = candidato;
      ok = true;
    endif
    return;
  endif

  % Compatibilidad con objetos string si la version de Octave los expone.
  if isa(valor, 'string')
    try
      candidato = strtrim(char(valor));
      if ~isempty(candidato)
        txt = candidato;
        ok = true;
      endif
    catch
    end_try_catch
    return;
  endif

  if islogical(valor) && isscalar(valor)
    if valor
      txt = 'true';
    else
      txt = 'false';
    endif
    ok = true;
    return;
  endif

  if isnumeric(valor) && isscalar(valor)
    if isnan(valor)
      txt = 'NaN';
    elseif isinf(valor)
      if valor > 0
        txt = 'Inf';
      else
        txt = '-Inf';
      endif
    else
      txt = sprintf('%.15g', double(valor));
    endif
    ok = true;
    return;
  endif

  if iscell(valor) && numel(valor) == 1
    [txt, ok] = aos_texto_seguro(valor{1}, defecto);
    return;
  endif

  if isstruct(valor) && isscalar(valor)
    campos = {'nombre_pozo','pozo_nombre','well_name','nombre','name', ...
      'id_pozo','id','descripcion','archivo_aosdat','aosdat_archivo'};
    for i = 1:numel(campos)
      campo = campos{i};
      if isfield(valor, campo) && ~isempty(valor.(campo))
        [candidato, encontrado] = aos_texto_seguro(valor.(campo), '');
        if encontrado
          txt = candidato;
          ok = true;
          return;
        endif
      endif
    endfor
  endif
endfunction
