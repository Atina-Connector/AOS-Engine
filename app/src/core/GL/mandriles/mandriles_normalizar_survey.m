function s = mandriles_normalizar_survey(param, Dmax)
% Survey continuo para integrar presiones. Conserva la geometria MD/TVD y
% refina la malla sin reemplazar el survey original del pozo.
  if nargin < 2 || isempty(Dmax)
    Dmax = 3000;
  endif
  p = mandriles_defaults(param);

  md = [];
  tvd = [];
  idt = [];
  idc = [];
  rug = [];
  if isstruct(param) && isfield(param, 'survey') && isstruct(param.survey)
    sv = param.survey;
    if isfield(sv, 'MD'), md = sv.MD(:); endif
    if isfield(sv, 'TVD'), tvd = sv.TVD(:); endif
    if isfield(sv, 'ID_tubing'), idt = sv.ID_tubing(:); endif
    if isfield(sv, 'ID_casing'), idc = sv.ID_casing(:); endif
    if isfield(sv, 'rugosidad'), rug = sv.rugosidad(:); endif
  endif

  n = min(numel(md), numel(tvd));
  if n < 2
    md = [0; Dmax];
    tvd = md;
    idt = p.mand_ID_tubing_m * ones(2,1);
    idc = p.mand_ID_casing_m * ones(2,1);
    rug = p.mand_rugosidad_m * ones(2,1);
  else
    md = md(1:n);
    tvd = tvd(1:n);
    idt = ajustar_aux_local(idt,n,p.mand_ID_tubing_m);
    idc = ajustar_aux_local(idc,n,p.mand_ID_casing_m);
    rug = ajustar_aux_local(rug,n,p.mand_rugosidad_m);

    ok = isfinite(md) & isfinite(tvd);
    md = md(ok);
    tvd = tvd(ok);
    idt = idt(ok);
    idc = idc(ok);
    rug = rug(ok);

    [md, ix] = sort(md);
    tvd = tvd(ix);
    idt = idt(ix);
    idc = idc(ix);
    rug = rug(ix);
    [md, iu] = unique(md, 'stable');
    tvd = tvd(iu);
    idt = idt(iu);
    idc = idc(iu);
    rug = rug(iu);
  endif

  if md(1) > 0
    md = [0; md];
    tvd = [0; tvd];
    idt = [idt(1); idt];
    idc = [idc(1); idc];
    rug = [rug(1); rug];
  endif
  if md(end) < Dmax
    tvdmax = interp1(md,tvd,Dmax,'linear','extrap');
    idtmax = interp1(md,idt,Dmax,'linear','extrap');
    idcmax = interp1(md,idc,Dmax,'linear','extrap');
    rugmax = interp1(md,rug,Dmax,'linear','extrap');
    md = [md; Dmax];
    tvd = [tvd; tvdmax];
    idt = [idt; idtmax];
    idc = [idc; idcmax];
    rug = [rug; rugmax];
  endif

  dentro = md >= 0 & md <= Dmax;
  md_base = md(dentro);
  tvd_base = tvd(dentro);
  idt_base = idt(dentro);
  idc_base = idc(dentro);
  rug_base = rug(dentro);

  paso = max(1,p.mand_paso_integracion_m);
  md_reg = (0:paso:Dmax)';
  if isempty(md_reg) || md_reg(end) < Dmax
    md_reg(end+1,1) = Dmax;
  endif
  md_ref = unique([md_reg; md_base; Dmax]);

  s = struct();
  s.MD = md_ref;
  s.TVD = interp1(md_base,tvd_base,md_ref,'linear','extrap');
  s.ID_tubing = interp1(md_base,idt_base,md_ref,'linear','extrap');
  s.ID_casing = interp1(md_base,idc_base,md_ref,'linear','extrap');
  s.rugosidad = interp1(md_base,rug_base,md_ref,'linear','extrap');
  s.ID_tubing = max(s.ID_tubing,1e-4);
  s.ID_casing = max(s.ID_casing,s.ID_tubing+1e-3);
  s.rugosidad = max(s.rugosidad,1e-8);
endfunction

function v = ajustar_aux_local(x,n,defecto)
  if isempty(x)
    v = defecto*ones(n,1);
  else
    x=x(:);
    if numel(x)==n
      v=x;
    elseif numel(x)==1
      v=x(1)*ones(n,1);
    else
      v=defecto*ones(n,1);
    endif
  endif
  v(~isfinite(v))=defecto;
endfunction
