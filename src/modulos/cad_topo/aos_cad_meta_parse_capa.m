function keys = aos_cad_meta_parse_capa(capa)
% AOS_CAD_META_PARSE_CAPA Interpreta sufijos tipo AOS_FLOWLINES_D100_ACERO.
  keys = struct();
  capa = upper(strtrim(char(capa)));
  if isempty(capa), return; endif
  parts = strsplit(capa, '_');
  for i = 1:numel(parts)
    p = parts{i};
    tok = regexp(p, '^D(\d+(?:\.\d+)?)(MM)?$', 'tokens', 'once');
    if ~isempty(tok)
      val = str2double(tok{1});
      if ~isnan(val)
        if numel(tok) >= 2 && ~isempty(tok{2})
          keys.ID_MM = val;
        elseif val > 1
          keys.ID_MM = val;
        else
          keys.D = val;
        endif
      endif
      continue;
    endif
    if ismember(p, {'ACERO','STEEL','CARBON_STEEL','PVC','HDPE','PEAD','COBRE'})
      keys.MAT = p;
    endif
  endfor
endfunction
