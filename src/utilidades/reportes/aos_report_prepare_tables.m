function [param, tablas, composicion] = aos_report_prepare_tables(param, tipo, extras, opciones)
% AOS_REPORT_PREPARE_TABLES Inventaria y configura una sola vez las tablas.
  if nargin < 1 || ~isstruct(param), param = struct(); endif
  if nargin < 2 || isempty(tipo), tipo = 'GENERAL'; endif
  if nargin < 3 || isempty(extras), extras = struct([]); endif
  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif

  if isfield(param,'aosrpt_tablas_preparadas') && logical_local(param.aosrpt_tablas_preparadas) && ...
      isfield(param,'aosrpt_tablas') && isstruct(param.aosrpt_tablas) && ...
      isfield(param,'aosrpt_composicion') && isstruct(param.aosrpt_composicion)
    tablas = param.aosrpt_tablas;
    composicion = param.aosrpt_composicion;
    return;
  endif

  tablas = struct([]);
  if isfield(param,'aosrpt_tablas') && isstruct(param.aosrpt_tablas)
    tablas = aos_report_append_tables(tablas, param.aosrpt_tablas);
  endif
  tablas = aos_report_append_tables(tablas, aos_report_collect_standard_tables(param, tipo));
  tablas = aos_report_append_tables(tablas, extras);

  opciones = opciones_desde_param_local(opciones, param);
  [tablas, composicion] = aos_report_configure_tables(tablas, opciones);
  param.aosrpt_tablas = tablas;
  param.aosrpt_composicion = composicion;
  param.aosrpt_tablas_preparadas = true;
  param.aosrpt_table_contract = 'AOS_REPORT_COMPOSITION_1.0';
endfunction

function o = opciones_desde_param_local(o,p)
  if ~isfield(o,'no_interactivo') && isfield(p,'aosrpt_no_interactivo')
    o.no_interactivo = logical_local(p.aosrpt_no_interactivo);
  endif
  if ~isfield(o,'profile') && isfield(p,'aosrpt_report_profile') && ischar(p.aosrpt_report_profile)
    o.profile = p.aosrpt_report_profile;
  endif
  if ~isfield(o,'prompt_each') && isfield(p,'aosrpt_prompt_each')
    o.prompt_each = logical_local(p.aosrpt_prompt_each);
  endif
  if ~isfield(o,'overrides') && isfield(p,'aosrpt_table_overrides') && isstruct(p.aosrpt_table_overrides)
    o.overrides = p.aosrpt_table_overrides;
  endif
endfunction
function tf=logical_local(x)
  tf=false;
  if islogical(x)&&isscalar(x),tf=x;
  elseif isnumeric(x)&&isscalar(x)&&isfinite(x),tf=(x~=0);
  elseif ischar(x),tf=any(strcmpi(strtrim(x),{'1','s','si','true','yes','y'}));endif
endfunction
