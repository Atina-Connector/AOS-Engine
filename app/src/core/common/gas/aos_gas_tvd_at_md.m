function tvd = aos_gas_tvd_at_md(param, md)
% Interpola TVD a partir de MD. Fallback: pozo vertical.
  tvd = md;
  if nargin < 2 || ~isfinite(md), return; endif
  s = [];
  if isstruct(param) && isfield(param,'survey') && isstruct(param.survey)
    s = param.survey;
  endif
  if isempty(s) || ~isfield(s,'MD') || ~isfield(s,'TVD')
    return;
  endif
  try
    x = s.MD(:); y = s.TVD(:);
    n = min(numel(x),numel(y));
    x = x(1:n); y = y(1:n);
    [x,idx] = sort(x); y = y(idx);
    [x,ia] = unique(x); y = y(ia);
    if numel(x) >= 2
      tvd = interp1(x,y,md,'linear','extrap');
    endif
  catch
    tvd = md;
  end_try_catch
endfunction
