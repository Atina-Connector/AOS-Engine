function m = aos_metricas_energia_sla(e, tipo)
% AOS_METRICAS_ENERGIA_SLA Extrae el contrato canonico de energia.
% Mantiene compatibilidad con estructuras previas sin mezclar indicadores.
  if nargin<1 || ~isstruct(e), e=struct(); endif
  if nargin<2 || isempty(tipo)
    tipo=campo_txt_local(e,'sistema','GENERAL');
  endif
  tipo=upper(strtrim(tipo));
  m=struct('sistema',tipo, ...
    'indice_energetico_bruto_fondo_pct',NaN, ...
    'estado_indice_energetico_bruto','NO_EVALUABLE', ...
    'eficiencia_interna_jet_pct',NaN, ...
    'estado_eficiencia_interna_jet','NO_APLICABLE', ...
    'metodo_indice','', 'metodo_jet','');

  m.indice_energetico_bruto_fondo_pct=campo_num_local(e, ...
    {'indice_energetico_bruto_fondo_pct','indice_energetico_bruto_pct','eficiencia_sistema_fondo_pct'},NaN);
  m.estado_indice_energetico_bruto=campo_txt_local(e, ...
    'estado_indice_energetico_bruto',cond_local(isfinite(m.indice_energetico_bruto_fondo_pct),'OK','NO_EVALUABLE'));
  m.metodo_indice=campo_txt_local(e,'metodo_indice','');

  if strcmp(tipo,'JGL')
    m.eficiencia_interna_jet_pct=campo_num_local(e, ...
      {'eficiencia_interna_jet_pct','eficiencia_dispositivo_pct'},NaN);
    m.estado_eficiencia_interna_jet=campo_txt_local(e, ...
      'estado_eficiencia_interna_jet',cond_local(isfinite(m.eficiencia_interna_jet_pct),'OK','NO_EVALUABLE'));
    m.metodo_jet=campo_txt_local(e,'metodo_eficiencia_dispositivo','');
  endif
endfunction

function v=campo_num_local(s,nombres,def)
  v=def;if ischar(nombres),nombres={nombres};endif
  for i=1:numel(nombres)
    n=nombres{i};
    if isstruct(s)&&isfield(s,n)&&isnumeric(s.(n))&&isscalar(s.(n))&&isfinite(s.(n))
      v=s.(n);return;
    endif
  endfor
endfunction
function v=campo_txt_local(s,n,def)
  v=def;if isstruct(s)&&isfield(s,n)&&ischar(s.(n))&&~isempty(s.(n)),v=s.(n);endif
endfunction
function s=cond_local(c,a,b),if c,s=a;else,s=b;endif,endfunction
