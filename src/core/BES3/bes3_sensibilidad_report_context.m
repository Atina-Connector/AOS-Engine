function contexto = bes3_sensibilidad_report_context(param, R)
% BES3_SENSIBILIDAD_REPORT_CONTEXT Adaptador DEV5.4 al flujo transversal.
  if nargin<1||~isstruct(param),param=struct();endif
  if nargin<2||~isstruct(R),error('Falta resultado de sensibilidad BES3.');endif
  contexto=aos_sensibilidad_report_context('BES3',param,R);
  contexto.exportador_simple='bes3_exportar_sensibilidad_simple';
  contexto.exportador_enriquecido='bes3_exportar_sensibilidad_enriquecido';
  contexto.diagnostico=aos_sensibilidad_diagnosticar(R,'BES3',param);
  contexto.effective_inputs=entradas_local(param,R);
endfunction
function e=entradas_local(p,R)
  e=struct();
  e.schema='AOS_EFFECTIVE_INPUTS_1.1';
  e.num_etapas_total=num_local(p,'num_etapas',NaN);e.num_etapas_total_unidad='etapas';e.num_etapas_total_origen=origen_local(p,'num_etapas','CONFIGURACION_EFECTIVA');e.num_etapas_total_validacion='INFORMADO';
  e.frecuencia_base_Hz=num_local(p,'frecuencia',NaN);e.frecuencia_base_Hz_unidad='Hz';e.frecuencia_base_Hz_origen=origen_local(p,'frecuencia','CONFIGURACION_EFECTIVA');e.frecuencia_base_Hz_validacion='INFORMADO';
  e.limite_recirculacion_pct_nominal=num_local(p,'bes3_limite_recirculacion_pct_nominal',10);e.limite_recirculacion_pct_nominal_unidad='%';e.limite_recirculacion_pct_nominal_origen=origen_local(p,'bes3_limite_recirculacion_pct_nominal','DEFAULT_BES3');e.limite_recirculacion_pct_nominal_validacion='INFORMADO';
  e.tolerancia_produccion_m3_d=num_local(p,'bes3_tol_produccion_m3_d',0.01);e.tolerancia_produccion_m3_d_unidad='m3/d';e.tolerancia_produccion_m3_d_origen=origen_local(p,'bes3_tol_produccion_m3_d','DEFAULT_BES3');e.tolerancia_produccion_m3_d_validacion='INFORMADO';
  e.capilar_ID_mm=1000*num_local(p,'bes3_capilar_ID_m',NaN);e.capilar_ID_mm_unidad='mm';e.capilar_ID_mm_origen=origen_local(p,'bes3_capilar_ID_m','CONFIGURACION_EFECTIVA');e.capilar_ID_mm_validacion='INFORMADO';
  e.capilar_OD_mm=1000*num_local(p,'bes3_capilar_OD_m',NaN);e.capilar_OD_mm_unidad='mm';e.capilar_OD_mm_origen=origen_local(p,'bes3_capilar_OD_m','CONFIGURACION_EFECTIVA');e.capilar_OD_mm_validacion='INFORMADO';
  e.profundidad_intake_m=num_local(p,'D_bomba',NaN);e.profundidad_intake_m_unidad='m';e.profundidad_intake_m_origen=origen_local(p,'D_bomba','CONFIGURACION_EFECTIVA');e.profundidad_intake_m_validacion='INFORMADO';
  e.archivo_bomba=texto_local(p,'bes3_bomba_file','NO_INFORMADO');e.archivo_bomba_origen=origen_local(p,'bes3_bomba_file','CATALOGO');e.archivo_bomba_validacion='INFORMADO';
  e.modelo_IPR=texto_local(p,'modelo_IPR','NO_INFORMADO');e.modelo_IPR_origen=origen_local(p,'modelo_IPR','CONFIGURACION_EFECTIVA');e.modelo_IPR_validacion='INFORMADO';
  e.modelo_VLP=texto_local(p,'modelo_VLP','NO_INFORMADO');e.modelo_VLP_origen=origen_local(p,'modelo_VLP','CONFIGURACION_EFECTIVA');e.modelo_VLP_validacion='INFORMADO';
  e.variable_sensibilizada=texto_local(R,'campo','parametro');e.variable_sensibilizada_origen='SENSIBILIDAD_MANUAL';
endfunction
function o=origen_local(p,c,def)
  o=def;campos={[c '_origen'],['origen_' c]};
  for i=1:numel(campos)
    if isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i})))
      o=normalizar_origen_local(p.(campos{i}),def);return;
    endif
  endfor
  if isfield(p,'aos_config_origen')&&ischar(p.aos_config_origen)&&~isempty(strtrim(p.aos_config_origen))
    o=normalizar_origen_local(p.aos_config_origen,def);
  endif
endfunction
function o=normalizar_origen_local(o,def)
  if ~ischar(o)||isempty(strtrim(o)),o=def;return;endif
  o=upper(strtrim(o));
  if ~isempty(strfind(o,'/'))||~isempty(strfind(o,'|'))||~isempty(strfind(o,','))
    o='CONFIGURACION_EFECTIVA_NO_TRAZADA';
  endif
  o=regexprep(o,'[^A-Z0-9_-]+','_');
endfunction
function v=num_local(s,c,d),v=d;if isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=double(s.(c)(1));endif,endfunction
function t=texto_local(s,c,d),t=d;if isfield(s,c)&&ischar(s.(c))&&~isempty(strtrim(s.(c))),t=s.(c);endif,endfunction
