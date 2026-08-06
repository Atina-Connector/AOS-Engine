function t = aos_report_table_from_matrix(id, title, section, data, columns, labels, units, varargin)
% AOS_REPORT_TABLE_FROM_MATRIX Crea una tabla nativa desde una matriz.
% Firma HF3.5:
%   t = aos_report_table_from_matrix(id,title,section,data,columns,labels,units,...)

  if nargin < 5
    error('AOS_REPORT_TABLE_FROM_MATRIX: faltan argumentos.');
  endif
  if nargin < 6 || isempty(labels), labels = columns; endif
  if nargin < 7 || isempty(units), units = repmat({''}, 1, numel(columns)); endif

  if isempty(data), data = zeros(0, numel(columns)); endif
  if ~(isnumeric(data) || islogical(data) || iscell(data))
    error('AOS_REPORT_TABLE_FROM_MATRIX: data debe ser matriz numerica, logica o celda.');
  endif
  if ~iscell(columns) || size(data,2) ~= numel(columns)
    error('AOS_REPORT_TABLE_FROM_MATRIX: columnas incompatibles con data.');
  endif
  if ~iscell(labels) || numel(labels) ~= numel(columns)
    error('AOS_REPORT_TABLE_FROM_MATRIX: labels incompatibles con columns.');
  endif
  if ~iscell(units) || numel(units) ~= numel(columns)
    error('AOS_REPORT_TABLE_FROM_MATRIX: units incompatibles con columns.');
  endif

  if iscell(data)
    rows = data;
  else
    rows = cell(size(data));
    for i = 1:size(data,1)
      for j = 1:size(data,2)
        rows{i,j} = data(i,j);
      endfor
    endfor
  endif

  t = struct('id', id, 'title', title, 'section', section, ...
    'columns', {columns(:)'}, 'labels', {labels(:)'}, ...
    'units', {units(:)'}, 'rows', {rows}, ...
    'role', 'RESULT_TABLE', 'source', 'AOS_CALCULATION', ...
    'category', 'RESULTS', 'priority', 'SECONDARY', ...
    'render_mode', '', 'default_mode', '', 'sample_step', 10, ...
    'archive_full', true, 'mandatory', false);

  if mod(numel(varargin), 2) ~= 0
    error('AOS_REPORT_TABLE_FROM_MATRIX: opciones nombre/valor invalidas.');
  endif
  for k = 1:2:numel(varargin)
    nombre = varargin{k};
    if ~ischar(nombre) || isempty(strtrim(nombre))
      error('AOS_REPORT_TABLE_FROM_MATRIX: nombre de opcion invalido.');
    endif
    t.(nombre) = varargin{k+1};
  endfor
  t = aos_report_table_normalize(t, 1);
endfunction
