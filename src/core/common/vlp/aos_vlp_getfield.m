function val = aos_vlp_getfield(s, campo, defecto)
  % aos_vlp_getfield.m
  % Lectura robusta de campos simples o anidados para estructuras AOS.
  % Ejemplos:
  %   aos_vlp_getfield(param, 'P_wh', 6e5)
  %   aos_vlp_getfield(param, 'fluidos.WC', 0.5)

  val = defecto;
  if nargin < 3
    defecto = [];
    val = [];
  end
  if ~isstruct(s) || isempty(campo)
    return;
  end

  partes = strsplit(campo, '.');
  tmp = s;
  for i = 1:length(partes)
    p = partes{i};
    if isstruct(tmp) && isfield(tmp, p)
      tmp = tmp.(p);
    else
      return;
    end
  end
  if ~isempty(tmp)
    val = tmp;
  end
end
