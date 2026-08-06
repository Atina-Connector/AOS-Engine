function dist = aos_distribuir_produccion_punzados(Ql, geol, intervalos, param)
% Distribuye el caudal entre TODOS los intervalos y tiros activos.
% No usa midperf como punto unico. Para roca uniforme reparte por tiros.
  if nargin<4 || ~isstruct(param), param=struct(); end
  if nargin<2 || ~isstruct(geol), geol=struct(); end
  if nargin<3 || isempty(intervalos)
    intervalos=aos_obtener_punzados_activos(geol,param);
  end
  [intervalos,~]=aos_punzados_normalizar(intervalos);
  if ~isempty(intervalos.tramos)
    intervalos.tramos=intervalos.tramos([intervalos.tramos.activo]);
  endif
  if isempty(intervalos.tramos)
    error('No hay intervalos de punzados activos y validos.');
  endif
  if isempty(Ql) || ~isscalar(Ql) || ~isfinite(Ql), Ql=0; end

  WC = leer_wc(param,geol);
  tr=intervalos.tramos; n=numel(tr);
  tiros=zeros(1,n); largos=zeros(1,n); pesos=zeros(1,n); metodo_trans=true;
  for i=1:n
    md1=num(tr(i),'MD_desde',NaN); md2=num(tr(i),'MD_hasta',NaN);
    dens=num(tr(i),'densidad_tpm',num(tr(i),'tiros_por_m',0));
    h=max(md2-md1,0); N=max(round(h*dens),0);
    largos(i)=h; tiros(i)=N;
    k=num(tr(i),'permeabilidad_mD',num(tr(i),'permeabilidad_h_mD',num(geol,'permeabilidad_mD',NaN)));
    skin=num(tr(i),'skin',num(tr(i),'skin_factor',num(geol,'skin_factor',0)));
    if ~isfinite(k) || k<=0
      metodo_trans=false; pesos(i)=N;
    else
      pesos(i)=k*N/max(1+max(skin,-0.9),0.1);
    end
  end
  if sum(pesos)<=0, pesos=max(tiros,largos); metodo_trans=false; end
  if sum(pesos)<=0, pesos=ones(1,n); metodo_trans=false; end
  f=pesos/sum(pesos); ql=Ql*f;
  survey=obtener_survey_param(param);
  filas=repmat(struct(),1,n);
  for i=1:n
    md1=num(tr(i),'MD_desde',NaN); md2=num(tr(i),'MD_hasta',NaN); mdm=(md1+md2)/2;
    tvd=interp_tvd(survey,mdm);
    filas(i).indice=i; filas(i).MD_desde_m=md1; filas(i).MD_hasta_m=md2;
    filas(i).MD_medio_m=mdm; filas(i).TVD_medio_m=tvd;
    filas(i).longitud_m=largos(i); filas(i).densidad_tpm=num(tr(i),'densidad_tpm',num(tr(i),'tiros_por_m',0));
    filas(i).n_tiros=tiros(i); filas(i).peso_relativo=pesos(i); filas(i).fraccion_aporte=f(i);
    filas(i).Ql_m3s=ql(i); filas(i).Ql_m3d=ql(i)*86400;
    filas(i).Qo_m3d=filas(i).Ql_m3d*(1-WC); filas(i).Qw_m3d=filas(i).Ql_m3d*WC;
    filas(i).Ql_por_tiro_m3d=filas(i).Ql_m3d/max(tiros(i),1);
  end
  dist.tramos=filas; dist.n_tramos=n; dist.n_tiros_total=sum(tiros);
  dist.Ql_total_m3d=Ql*86400; dist.Qo_total_m3d=dist.Ql_total_m3d*(1-WC); dist.Qw_total_m3d=dist.Ql_total_m3d*WC;
  dist.metodo='proporcional_a_tiros'; if metodo_trans, dist.metodo='transmisibilidad_relativa_por_tramo'; end
  dist.nota='Caudal distribuido entre todos los tiros. Midperf solo referencia geometrica.';
end
function v=num(s,c,d), v=d; if isstruct(s)&&isfield(s,c), x=s.(c); if isnumeric(x)&&isscalar(x)&&isfinite(x), v=x; elseif ischar(x), y=str2double(x); if isfinite(y),v=y;end,end,end,end
function WC=leer_wc(p,g)
  WC=0;
  if isstruct(p)
    if isfield(p,'WC'), WC=num(p,'WC',WC); end
    if isfield(p,'fluidos')&&isstruct(p.fluidos), WC=num(p.fluidos,'WC',WC); end
  end
  WC=num(g,'WC',WC); WC=min(max(WC,0),1);
end
function s=obtener_survey_param(p)
  s=[]; global CONFIG_ACTIVA;
  if isstruct(p)&&isfield(p,'survey'), s=p.survey; end
  if isempty(s)&&isstruct(CONFIG_ACTIVA)&&isfield(CONFIG_ACTIVA,'survey'), s=CONFIG_ACTIVA.survey; end
end
function tvd=interp_tvd(s,md)
  tvd=md;
  try
    if isstruct(s)&&isfield(s,'MD')&&isfield(s,'TVD')&&numel(s.MD)>1
      tvd=interp1(s.MD(:),s.TVD(:),md,'linear','extrap');
    elseif isobject(s), tvd=s.get_TVD(md); end
  catch, tvd=md; end
end
