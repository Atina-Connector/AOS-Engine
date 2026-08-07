function tvd = aos_tvd_at_md(survey, md)
% aos_tvd_at_md.m - TVD interpolada desde survey. Si no hay survey, TVD=MD.
  if nargin < 2 || isempty(md), md = 0; end
  tvd = md;
  if nargin < 1 || isempty(survey) || ~isstruct(survey), return; end
  try
      if isfield(survey, 'get_TVD') && isa(survey.get_TVD, 'function_handle')
          tvd = survey.get_TVD(md); return;
      end
  catch
  end
  if isfield(survey, 'MD') && isfield(survey, 'TVD') && ~isempty(survey.MD) && ~isempty(survey.TVD)
      try
          tvd = interp1(survey.MD(:), survey.TVD(:), md, 'linear', 'extrap');
      catch
          tvd = md;
      end
  end
end
