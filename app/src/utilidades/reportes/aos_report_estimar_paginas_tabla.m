function paginas = aos_report_estimar_paginas_tabla(tabla)
% AOS_REPORT_ESTIMAR_PAGINAS_TABLA Estimacion conservadora para el PDF.
  filas = 0; columnas = 1;
  if isstruct(tabla)
    if isfield(tabla,'n_rows') && isnumeric(tabla.n_rows), filas=max(0,tabla.n_rows);
    elseif isfield(tabla,'rows') && iscell(tabla.rows), filas=size(tabla.rows,1); endif
    if isfield(tabla,'n_columns') && isnumeric(tabla.n_columns), columnas=max(1,tabla.n_columns);
    elseif isfield(tabla,'columns') && iscell(tabla.columns), columnas=max(1,numel(tabla.columns)); endif
  endif
  filas_pagina = 24;
  if columnas > 8, filas_pagina = 18; endif
  if columnas > 12, filas_pagina = 14; endif
  paginas = max(1, ceil((filas + 3) / filas_pagina));
  if filas == 0, paginas = 0; endif
endfunction
