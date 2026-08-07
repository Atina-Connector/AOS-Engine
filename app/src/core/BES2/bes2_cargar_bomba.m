function bomba = bes2_cargar_bomba(param)
% Adaptador de catálogo BES V2 y legado.
  param=bes2_defaults(param);
  archivo=param.bes2_bomba_file;
  if ~exist(archivo,'file') && isfield(param,'curva_bomba_file')
    archivo=param.curva_bomba_file;
  endif
  if ~exist(archivo,'file'),error('BES V2: no existe curva de bomba: %s',archivo);endif
  c=load_config(archivo);
  bomba=struct();
  bomba.archivo=archivo;
  bomba.modelo=gettext_local(c,{'modelo'},archivo);
  bomba.origen=gettext_local(c,{'origen'},'CATALOGO_LEGADO');
  bomba.frecuencia_base=getnum_local(c,{'frecuencia_base_Hz','frecuencia_base'},60);
  bomba.rpm_base=getnum_local(c,{'rpm_base'},3600);
  bomba.Q_m3_d=getvec_local(c,{'Q_m3_d','Q_bomba'});
  bomba.head_m_etapa=getvec_local(c,{'head_m_etapa','head_bomba'});
  bomba.eta=getvec_local(c,{'eficiencia','eta_bomba'});
  n=min(numel(bomba.Q_m3_d),numel(bomba.head_m_etapa));
  bomba.Q_m3_d=bomba.Q_m3_d(1:n);
  bomba.head_m_etapa=bomba.head_m_etapa(1:n);
  if isempty(bomba.eta)||numel(bomba.eta)<n
    qb=getnum_local(c,{'Q_BEP_m3_d'},median(bomba.Q_m3_d));
    qspan=max(max(bomba.Q_m3_d)-min(bomba.Q_m3_d),1);
    bomba.eta=0.80-0.62.*((bomba.Q_m3_d-qb)./(0.55.*qspan)).^2;
    bomba.eta=min(max(bomba.eta,0.12),0.82);
    bomba.eta_origen='SINTETICA_SCREENING';
  else
    bomba.eta=bomba.eta(1:n);
    bomba.eta_origen='CATALOGO';
  endif
  bomba.Q_BEP_m3_d=getnum_local(c,{'Q_BEP_m3_d'},NaN);
  if ~isfinite(bomba.Q_BEP_m3_d)
    [~,ib]=max(bomba.eta);bomba.Q_BEP_m3_d=bomba.Q_m3_d(ib);
  endif
  bomba.Q_min_rec_m3_d=getnum_local(c,{'Q_min_recomendado_m3_d'},0.60.*bomba.Q_BEP_m3_d);
  bomba.Q_max_rec_m3_d=getnum_local(c,{'Q_max_recomendado_m3_d'},1.40.*bomba.Q_BEP_m3_d);
  bomba.OD_m=getnum_local(c,{'diametro_exterior_m'},getnum_local(param,{'OD_motor'},0.114));
  [bomba.Q_m3_d,idx]=sort(bomba.Q_m3_d);
  bomba.head_m_etapa=bomba.head_m_etapa(idx);
  bomba.eta=bomba.eta(idx);
endfunction

function v=getvec_local(s,campos)
  v=[];
  for k=1:numel(campos)
    if isfield(s,campos{k})&&isnumeric(s.(campos{k}))&&~isempty(s.(campos{k}))
      v=s.(campos{k})(:);return;
    endif
  endfor
endfunction
function v=getnum_local(s,campos,defecto)
  v=defecto;for k=1:numel(campos),if isfield(s,campos{k})&&isnumeric(s.(campos{k}))&&~isempty(s.(campos{k}))&&isfinite(s.(campos{k})(1)),v=s.(campos{k})(1);return;endif,endfor
endfunction
function t=gettext_local(s,campos,defecto)
  t=defecto;for k=1:numel(campos),if isfield(s,campos{k})&&ischar(s.(campos{k}))&&~isempty(strtrim(s.(campos{k}))),t=strtrim(s.(campos{k}));return;endif,endfor
endfunction
