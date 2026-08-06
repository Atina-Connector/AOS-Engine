function sol=jgl_ejecutar(p,Qiny,modo)
  p=jgl_defaults(p); if nargin<2||isempty(Qiny),if isfield(p,'Q_iny'),Qiny=p.Q_iny;else,Qiny=0;end,end
  if nargin<3||isempty(modo),modo=p.jgl_modo;end; modo=lower(strtrim(modo));
  if strcmp(modo,'iterativo')||strcmp(modo,'preciso'),sol=jgl_solver_iterativo(p,Qiny);
  elseif strcmp(modo,'directo')||strcmp(modo,'rapido'),sol=jgl_solver_directo(p,Qiny);
  else,sol=jgl_solver_automatico(p,Qiny);end
  sol.modo_solicitado=upper(modo); sol.Qiny_MMscfd=Qiny*86400/0.0283168/1e6;
end
