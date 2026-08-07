function archivo = bes3_exportar_reporte(sol,enriquecido,archivo,finalizar_crypto)
% BES3_EXPORTAR_REPORTE Reporte BES3 con composicion transversal HF3.5.
  if nargin<2||isempty(enriquecido),enriquecido=false;endif
  if nargin<4||isempty(finalizar_crypto),finalizar_crypto=true;endif
  carpeta=fullfile('intercambio','reportes','enviados');if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  if nargin<3||isempty(archivo)
    base='BES3_reporte.aosrpt';global AOSDAT_ACTIVO;
    if ischar(AOSDAT_ACTIVO)&&~isempty(AOSDAT_ACTIVO),base=[AOSDAT_ACTIVO '_BES3.aosrpt'];endif
    archivo=aos_elegir_nombre_reporte(carpeta,base);
  endif
  carpeta=fileparts(archivo);if isempty(carpeta),carpeta='.';endif;if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  p=struct();if isfield(sol,'param')&&isstruct(sol.param),p=sol.param;endif
  p.aosrpt_es_enriquecido=enriquecido;
  gg=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  if enriquecido
    figs=bes3_plot_resultado(sol,'off');
    for i=1:numel(figs),tmp=[tempname(carpeta) '.png'];print(figs(i),'-dpng','-r140',tmp);close(figs(i));id=sprintf('bes3_figura_%02d',i);gg(end+1)=entry_local(id,id,'BES3','OK',tmp);delete(tmp);endfor
  endif
  p.aosrpt_graficos_count=numel(gg);
  [p,tablas,comp]=aos_report_prepare_tables(p,'BES3',bes3_report_build_tables(sol),struct());

  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear %s',archivo);endif
  fprintf(fid,'[AOS_REPORT]\nversion=2.0\nviewer_schema=AOS_VIEWER_BES3_1.2\nmodulo=BES3\nfecha=%s\n',datestr(now(),'yyyy-mm-dd HH:MM:SS'));
  [~,rid,~]=fileparts(archivo);mi=struct('report_id',rid,'report_type','BES3_SIMULATION','module','BES3','workbench','AOS_SLA','viewer_schema','AOS_VIEWER_BES3_1.2','graphics_count',numel(gg));aos_report_write_manifest(fid,mi,comp);
  fprintf(fid,'\n[BES3_STATUS]\nversion_solver=%s\nestado_validacion=%s\nestado_solver=%s\npunto_tipo=%s\nmodo_operacion=%s\nestado_bomba=%s\nmodo_frecuencia=%s\nfrecuencia_configurada_Hz=%.10g\nfrecuencia_solicitada_Hz=%.10g\nfrecuencia_efectiva_Hz=%.10g\nfrecuencia_estado=%s\nconvergido=%d\naceptado_preliminar=%d\naceptado_certificado=0\nmodelo_IPR=%s\nmodelo_VLP_seleccionado=%s\nmodelo_VLP_efectivo=%s\n', ...
    clean_local(sol.version),clean_local(sol.estado_validacion),clean_local(sol.estado),clean_local(sol.punto_tipo),clean_local(sol.modo_operacion),clean_local(sol.estado_bomba),clean_local(sol.modo_frecuencia),sol.frecuencia_configurada_Hz,sol.frecuencia_solicitada_Hz,sol.frecuencia_efectiva_Hz,clean_local(sol.frecuencia_estado),sol.convergido,sol.aceptado_preliminar,clean_local(sol.modelo_IPR),clean_local(sol.modelo_VLP),clean_local(sol.vlp_efectivo));
  fprintf(fid,'\n[BES3_SUMMARY]\nmodelo_bomba=%s\norigen_curva=%s\nnum_etapas_total=%.10g\netapa_toma=%.10g\nQ_produccion_superficie_m3_d=%.10g\nQo_m3_d=%.10g\nQ_pump_neto_m3_d=%.10g\nQ_recirc_m3_d=%.10g\nQ_nominal_efectivo_m3_d=%.10g\nQ_recirc_pct_nominal=%.10g\nQ_recirc_max_diseno_m3_d=%.10g\nQ_etapas_inferiores_m3_d=%.10g\nQ_etapas_superiores_m3_d=%.10g\nBEP_inferior_pct=%.10g\nBEP_superior_pct=%.10g\nestado_diseno_recirculacion=%s\nestado_operativo_recirculacion=%s\nrango_inferior=%s\nrango_superior=%s\ngas=%s\nrefrigeracion=%s\n', ...
    clean_local(sol.bomba.modelo),clean_local(sol.bomba.origen),sol.num_etapas_total,sol.etapa_toma,sol.Ql_m3_d,sol.Qo_m3_d,sol.Q_pump_neto_m3_d,sol.Q_recirc_m3_d,sol.Q_nominal_efectivo_m3_d,sol.Q_recirc_pct_nominal,sol.Q_recirc_max_diseno_m3_d,sol.Q_etapas_inferiores_m3_d,sol.Q_etapas_superiores_m3_d,sol.BEP_inferior_pct,sol.BEP_superior_pct,clean_local(sol.estado_diseno_recirculacion),clean_local(sol.estado_operativo_recirculacion),clean_local(sol.rango_inferior_estado),clean_local(sol.rango_superior_estado),clean_local(sol.gas_estado),clean_local(sol.refrigeracion_estado));
  if isfield(sol,'punto')
    e=sol.punto;r=e.recirculacion;g=e.geometria;
    fprintf(fid,'P_wf_bar=%.10g\nP_intake_bar=%.10g\nP_descarga_disponible_bar=%.10g\nP_descarga_requerida_bar=%.10g\nmargen_nodal_bar=%.10g\ndeltaP_bomba_bar=%.10g\nhead_m=%.10g\nP_eje_kW=%.10g\nP_superficie_kW=%.10g\ncorriente_A=%.10g\nT_motor_C=%.10g\nGVF_bomba_pct=%.10g\n',e.Pwf_Pa/1e5,e.Pintake_Pa/1e5,e.Pdesc_disponible_Pa/1e5,e.Pdesc_req_Pa/1e5,e.residuo/1e5,e.dP_bomba_Pa/1e5,e.head_m,e.P_eje_kW,e.electrico.P_superficie_kW,e.electrico.corriente_A,e.electrico.termica.T_motor_C,100*e.fluido.gvf_bomba);
    fprintf(fid,'\n[BES3_COMPLETION]\nposicion_punzados=%s\npunzados_tope_m=%.10g\npunzados_base_m=%.10g\nintake_m=%.10g\nmotor_top_m=%.10g\nmotor_base_m=%.10g\ndescarga_capilar_m=%.10g\nshroud=%d\narea_refrigeracion_m2=%.10g\n',clean_local(g.posicion_estado),g.punzados_tope_m,g.punzados_base_m,g.D_intake_m,g.D_motor_top_m,g.D_motor_base_m,g.D_descarga_capilar_m,g.shroud_habilitado,g.area_refrigeracion_m2);
    d=sol.diagnostico_recirculacion;
    fprintf(fid,'\n[BES3_RECIRCULATION]\nestado=%s\ncumple_refrigeracion=%d\ncumple_diseno=%d\nestado_diseno=%s\nestado_operativo=%s\nQ_natural_m3_d=%.10g\nQ_minimo_m3_d=%.10g\nQ_requerido_m3_d=%.10g\nQ_capilar_m3_d=%.10g\nQ_nominal_efectivo_m3_d=%.10g\nQ_recirc_max_diseno_m3_d=%.10g\nQ_recirc_pct_nominal=%.10g\nlimite_recirc_pct_nominal=%.10g\netapa_toma=%d\nnum_etapas_total=%d\nn_etapas_inferiores=%d\nn_etapas_superiores=%d\nQ_etapas_inferiores_m3_d=%.10g\nQ_etapas_superiores_m3_d=%.10g\nBEP_inferior_pct=%.10g\nBEP_superior_pct=%.10g\nrango_inferior=%s\nrango_superior=%s\nvelocidad_motor_m_s=%.10g\nmargen_presion=%.10g\nRe_capilar=%.10g\nregimen=%s\n',clean_local(r.estado),r.cumple,d.cumple_diseno,clean_local(d.estado_diseno),clean_local(d.estado_operativo),r.Q_natural_m3_d,r.Q_min_refrig_m3_d,r.Q_requerido_m3_d,r.Q_recirc_m3_d,d.Q_nominal_efectivo_m3_d,d.Q_recirc_max_diseno_m3_d,d.Q_recirc_pct_nominal,d.limite_recirc_pct_nominal,d.etapa_toma,d.num_etapas_total,d.n_etapas_inferiores,d.n_etapas_superiores,d.Q_etapas_inferiores_m3_d,d.Q_etapas_superiores_m3_d,d.BEP_inferior_pct,d.BEP_superior_pct,clean_local(d.rango_inferior_estado),clean_local(d.rango_superior_estado),r.velocidad_total_m_s,r.margen_presion,r.Re_capilar,clean_local(r.regimen_capilar));
  endif
  ids={'bes3_semaforos','bes3_nodal','bes3_pump_curve','bes3_tubing_profile'};secs={'BES3_SEMAFOROS','BES3_NODAL_TABLE','BES3_CURVE_TABLE','BES3_DIAGNOSTICO_TUBERIA'};
  for k=1:numel(ids),[t,~]=aos_report_table_find(tablas,ids{k});if ~isempty(t),aos_report_write_reference(fid,secs{k},t,'DISPONIBLE');endif,endfor
  aos_rpt_escribir_tablas(fid,tablas,comp);
  try,aos_exportar_contexto_viewer(fid,p,'BES',true);catch,end_try_catch
  if enriquecido,try,aos_rpt_escribir_graficos(fid,gg);catch,end_try_catch,endif
  fclose(fid);
  if finalizar_crypto&&exist('aos_finalizar_archivo_crypto','file')==2,aos_finalizar_archivo_crypto(archivo,true);endif
  fprintf('Reporte BES3 exportado: %s\n',archivo);
endfunction
function g=entry_local(id,tit,sec,st,ruta),g=struct('id',id,'titulo',tit,'seccion',sec,'estado',st,'base64','');fid=fopen(ruta,'rb');if fid>=0,b=fread(fid,Inf,'uint8=>uint8');fclose(fid);g.base64=base64_encode(b);endif,endfunction
function s=clean_local(x),if ~ischar(x),x='';endif,s=regexprep(x,'[\r\n=,]',' ');endfunction
