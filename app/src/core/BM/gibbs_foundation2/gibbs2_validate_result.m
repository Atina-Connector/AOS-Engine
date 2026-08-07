function ok = gibbs2_validate_result(res)
  ok = isfield(res,'promedio') && ~isempty(res.promedio) && ...
       all(isfinite(res.promedio.u_superficie_m));
end
