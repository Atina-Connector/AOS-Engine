function tablas = aos_report_append_tables(tablas, nuevas)
% AOS_REPORT_APPEND_TABLES Une tablas normalizadas sin depender de campos iguales.
  salida = struct([]);
  indice = 0;
  fuentes = {tablas, nuevas};
  for k = 1:numel(fuentes)
    x = fuentes{k};
    if isempty(x), continue; endif
    if ~isstruct(x), error('Las tablas deben ser estructuras.'); endif
    x = x(:)';
    for i = 1:numel(x)
      indice = indice + 1;
      t = aos_report_table_normalize(x(i), indice);
      if isempty(salida)
        salida = t;
      else
        % Reemplazar por ID para evitar duplicados entre colectores.
        ids = {salida.id};
        j = find(strcmpi(ids, t.id), 1);
        if isempty(j), salida(end+1) = t; else, salida(j) = t; endif
      endif
    endfor
  endfor
  tablas = salida;
endfunction
