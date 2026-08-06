function [meta, dmin] = aos_cad_meta_cercana(metas, x, y, tol, capas_ok)
% AOS_CAD_META_CERCANA Busca la etiqueta de metadatos mas cercana a (x,y).
% Wrapper CAD: filtra por capa y delega distancia a aos_geom_punto_mas_cercano.
  meta = [];
  dmin = Inf;
  if nargin < 4 || isempty(tol), tol = 2.0; endif
  if nargin < 5, capas_ok = {}; endif

  candidatos = {};
  for i = 1:numel(metas)
    m = metas{i};
    if ~isfield(m, 'x') || ~isfield(m, 'y'), continue; endif
    if isnan(m.x) || isnan(m.y), continue; endif
    if ~isempty(capas_ok)
      cl = upper(char(m.layer));
      okcapa = false;
      for k = 1:numel(capas_ok)
        if strcmp(cl, upper(char(capas_ok{k})))
          okcapa = true; break;
        endif
      endfor
      if ~okcapa, continue; endif
    endif
    candidatos{end+1} = m; %#ok<AGROW>
  endfor

  [idx, dmin] = aos_geom_punto_mas_cercano(candidatos, x, y, tol);
  if ~isempty(idx)
    meta = candidatos{idx};
  endif
endfunction
