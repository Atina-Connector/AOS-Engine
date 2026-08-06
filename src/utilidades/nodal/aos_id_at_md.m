function id = aos_id_at_md(param, md, defecto)
% aos_id_at_md.m - ID hidráulico en una profundidad MD.
  if nargin < 3 || isempty(defecto), defecto = 0.062; end
  id = defecto;
  if nargin < 1 || ~isstruct(param), return; end
  if isfield(param, 'survey') && isstruct(param.survey)
      try
          if isfield(param.survey, 'get_ID') && isa(param.survey.get_ID, 'function_handle')
              id = param.survey.get_ID(md); return;
          end
      catch
      end
      if isfield(param.survey, 'MD') && isfield(param.survey, 'ID_tubing') && ~isempty(param.survey.MD)
          try
              id = interp1(param.survey.MD(:), param.survey.ID_tubing(:), md, 'linear', 'extrap'); return;
          catch
          end
      end
  end
  if isfield(param, 'diam_tbg') && isnumeric(param.diam_tbg) && ~isempty(param.diam_tbg)
      id = param.diam_tbg(1);
  elseif isfield(param, 'tubing') && isstruct(param.tubing) && isfield(param.tubing, 'ID') && isnumeric(param.tubing.ID)
      id = param.tubing.ID(1);
  end
  id = max(id, 1e-4);
end
