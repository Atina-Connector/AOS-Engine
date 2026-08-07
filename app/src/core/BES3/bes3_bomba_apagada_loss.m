function r = bes3_bomba_apagada_loss(Ql,fluido,param)
% Perdida pasiva a traves del conjunto BES detenido.
% ideal: equivalente directo a bomba ausente/Qiny=0.
% instalada: perdida localizada K + umbral fijo configurable.
% bloqueada: no permite flujo natural a traves del conjunto.
  p=bes3_defaults(param);modelo=lower(strtrim(p.bes3_bomba_apagada_modelo));
  if isempty(modelo),modelo='ideal';endif
  q=max(Ql,0);dP=0;v=0;rho=max(p.rho_o*(1-p.WC)+p.rho_w*p.WC,1);estado='IDEAL_SIN_PERDIDA_PASIVA';
  if isstruct(fluido)
    if isfield(fluido,'rho_l_kg_m3')&&isfinite(fluido.rho_l_kg_m3),rho=max(fluido.rho_l_kg_m3,1);endif
    qloc=0;
    if isfield(fluido,'Ql_local_m3_s')&&isfinite(fluido.Ql_local_m3_s),qloc=qloc+max(fluido.Ql_local_m3_s,0);endif
    if isfield(fluido,'Qg_free_local_m3_s')&&isfinite(fluido.Qg_free_local_m3_s),qloc=qloc+max(fluido.Qg_free_local_m3_s,0);endif
    q=max(qloc,q);
  endif
  if strcmp(modelo,'bloqueada') || ~logical(p.bes3_bomba_apagada_permite_flujo)
    dP=Inf;estado='FLUJO_BLOQUEADO_POR_COMPLETACION';
  elseif strcmp(modelo,'instalada') || strcmp(modelo,'pasiva')
    A=max(p.bes3_bomba_apagada_area_m2,1e-8);v=q/A;
    dP=max(p.bes3_bomba_apagada_K,0)*0.5*rho*v^2;
    if q>1e-12,dP=dP+max(p.bes3_bomba_apagada_dP_fijo_bar,0)*1e5;endif
    estado='PERDIDA_PASIVA_BES_INSTALADA';
  else
    modelo='ideal';
  endif
  r=struct('modelo',upper(modelo),'estado',estado,'dP_Pa',dP,'dP_bar',dP/1e5, ...
    'K',p.bes3_bomba_apagada_K,'area_m2',p.bes3_bomba_apagada_area_m2, ...
    'velocidad_m_s',v,'rho_kg_m3',rho,'check_valve_estado',p.bes3_check_valve_estado);
endfunction
