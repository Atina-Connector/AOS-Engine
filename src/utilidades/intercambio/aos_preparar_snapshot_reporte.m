function s = aos_preparar_snapshot_reporte(param,Ql,Qo,Qiny,tipo)
% Prepara un snapshot inmutable de la ultima corrida para serializar.
% No relee valores desde CONFIG_ACTIVA ni desde aliases de importacion.
  if nargin<5||isempty(tipo),tipo='GENERAL';end
  p=aos_sincronizar_config(param,tipo);
  s=struct();s.param=p;s.tipo=upper(tipo);s.Ql=Ql;s.Qo=Qo;s.Qiny=Qiny;
  s.P_res=leer(p,'P_res',NaN);s.IP=leer(p,'IP',NaN);s.WC=leer(p,'WC',NaN);s.GLR=leer(p,'GLR',NaN);
  s.P_wh=leer(p,'P_wh',NaN);s.P_iny_sup=leer(p,'P_iny_sup',NaN);
  if any(strcmpi(s.tipo,{'GL','JGL'})),s.D_sla=leer(p,'D_iny',leer(p,'D_bomba',NaN));else,s.D_sla=leer(p,'D_bomba',NaN);end
  s.P_intake=NaN;
  if strcmpi(s.tipo,'JGL')
    sol=struct();if isfield(p,'sol_jgl')&&isstruct(p.sol_jgl),sol=p.sol_jgl;elseif isfield(p,'JGL_resultado')&&isstruct(p.JGL_resultado),sol=p.JGL_resultado;end
    if isfield(sol,'Ps'),s.P_intake=sol.Ps;end
  elseif strcmpi(s.tipo,'BES')&&isfield(p,'BES_resultado')&&isstruct(p.BES_resultado)&&isfield(p.BES_resultado,'P_intake')
    s.P_intake=p.BES_resultado.P_intake;
  elseif strcmpi(s.tipo,'BM')&&isfield(p,'BM_resultado')&&isstruct(p.BM_resultado)&&isfield(p.BM_resultado,'P_intake')
    s.P_intake=p.BM_resultado.P_intake;
  end
  if ~isfinite(s.P_intake)
    try,s.P_intake=calcular_columna_succion(Ql,p);catch,s.P_intake=NaN;end
  end
end
function v=leer(p,c,d)
  v=d;if isstruct(p)&&isfield(p,c),x=p.(c);if isnumeric(x)&&~isempty(x)&&isfinite(x(1)),v=x(1);end,end
end
