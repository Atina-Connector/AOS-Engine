function exportar_aosrpt(param, Ql, Qo, Qiny, tipo, archivo_salida)
  % Exporta un reporte de simulación en formato .aosrpt
  % Incluye nombre del pozo, semáforo, cuello de botella, choke y
  % la sección [CONFIG_ACTIVA] con los archivos cargados.
  %
  % Por defecto guarda en intercambio/reportes/enviados/
    % Asegurar que las funciones de nodal estén en el path
  % --- Asegurar que las funciones de nodal estén en el path ---
  script_dir = fileparts(mfilename('fullpath'));        % src/utilidades/intercambio/
  nodal_dir = fullfile(script_dir, '..', 'nodal');     % src/utilidades/nodal/
  bm_dir = fullfile(script_dir, '..', 'bombeo_mecanico');
  sem_dir = fullfile(script_dir, '..', 'semaforos');
  addpath(nodal_dir, '-begin');
  addpath(bm_dir, '-begin');
  addpath(sem_dir, '-begin');

  snap=aos_preparar_snapshot_reporte(param,Ql,Qo,Qiny,tipo);
  param=snap.param;

  % --- Carpeta de destino ---
  carpeta_destino = 'intercambio/reportes/enviados';
  if ~exist(carpeta_destino, 'dir')
      mkdir(carpeta_destino);
  end

  % --- Determinar nombre del pozo ---
  global AOSDAT_ACTIVO;
  if isfield(param, 'nombre_pozo') && ~isempty(param.nombre_pozo)
      nombre_pozo = param.nombre_pozo;
  elseif ~isempty(AOSDAT_ACTIVO)
      nombre_pozo = AOSDAT_ACTIVO;
  else
      nombre_pozo = 'Pozo sin nombre';
  end

  if nargin < 6 || isempty(archivo_salida)
      if ~isempty(AOSDAT_ACTIVO), nombre_defecto=[AOSDAT_ACTIVO '.aosrpt']; else, nombre_defecto='reporte.aosrpt'; end
      archivo_salida=aos_elegir_nombre_reporte(carpeta_destino,nombre_defecto);
  else
      [ruta,nombre,~]=fileparts(archivo_salida);
      if isempty(ruta), archivo_salida=fullfile(carpeta_destino,[nombre '.aosrpt']); end
  end

  Ql_d = Ql * 86400;
  Qo_d = Qo * 86400;
  Qiny_Sm3_d = Qiny * 86400;
  Qiny_MMscfd = aos_m3s_a_mmscfd(Qiny);

  % HF3.5: inventario transversal y seleccion de tablas.
  extra_tablas = struct([]);
  if exist('aos_report_build_punzados_distribution_table','file') == 2
    [tabla_dist, resumen_dist] = aos_report_build_punzados_distribution_table(Ql,param);
    extra_tablas = aos_report_append_tables(extra_tablas,tabla_dist);
    param.aosrpt_punzados_resumen = resumen_dist;
  endif
  [param, tablas_reporte, composicion_reporte] = ...
    aos_report_prepare_tables(param,tipo,extra_tablas,struct());

  fid = fopen(archivo_salida, 'w');
  if fid < 0, error('No se pudo abrir el reporte para escritura: %s', archivo_salida); end

  % --- Encabezado ---
  fprintf(fid, '[AOS_REPORT]\n');
  fprintf(fid, 'version=1.2\n');
  fprintf(fid, 'viewer_schema=AOS_VIEWER_CONTEXT_1.0\n');
  fprintf(fid, 'fecha=%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid, 'sistema=%s\n', tipo);
  fprintf(fid, 'nombre_pozo=%s\n', nombre_pozo);
  es_enriquecido = isfield(param,'aosrpt_es_enriquecido') && logical(param.aosrpt_es_enriquecido);
  fprintf(fid, 'contract_revision=AOSRPT_TABLES_1.1\n');
  fprintf(fid, 'formato=%s\n', condicional(es_enriquecido,'ENRIQUECIDO','LIGERO'));
  [~, report_id, ~] = fileparts(archivo_salida);
  report_id = regexprep(report_id,'[^A-Za-z0-9_-]+','_');
  n_graficos=0;
  if isfield(param,'aosrpt_graficos_count') && isnumeric(param.aosrpt_graficos_count) && isscalar(param.aosrpt_graficos_count)
    n_graficos=max(0,round(param.aosrpt_graficos_count));
  elseif es_enriquecido
    n_graficos=1;
  endif
  manifest_info=struct('report_id',report_id, ...
    'report_type',[regexprep(upper(tipo),'[^A-Z0-9_-]+','_') '_SIMULATION'], ...
    'module',regexprep(upper(tipo),'[^A-Z0-9_-]+','_'), ...
    'workbench','AOS_SIM','viewer_schema','AOS_VIEWER_CONTEXT_1.0', ...
    'graphics_count',n_graficos);
  aos_report_write_manifest(fid,manifest_info,composicion_reporte);

  % --- Información de configuración activa ---
  global CONFIG_ACTIVA geologia;
  if ~isempty(CONFIG_ACTIVA)
      fprintf(fid, '\n[CONFIG_ACTIVA]\n');
      if ~isempty(AOSDAT_ACTIVO)
          fprintf(fid, 'archivo_aosdat=%s\n', AOSDAT_ACTIVO);
      end
      if isfield(CONFIG_ACTIVA, 'survey') && ~isempty(CONFIG_ACTIVA.survey)
          if isfield(CONFIG_ACTIVA, 'survey_file')
              fprintf(fid, 'survey=%s\n', CONFIG_ACTIVA.survey_file);
          else
              fprintf(fid, 'survey=cargado\n');
          end
      else
          fprintf(fid, 'survey=no cargado\n');
      end
      if ~isempty(geologia)
          if isfield(geologia, 'archivo')
              fprintf(fid, 'geologia=%s\n', geologia.archivo);
          else
              fprintf(fid, 'geologia=cargada\n');
          end
      else
          fprintf(fid, 'geologia=no cargada\n');
      end
  end

  % --- Parametros clave: snapshot efectivo de la corrida ---
  P_res=snap.P_res; IP=snap.IP; P_wh=snap.P_wh; P_iny=snap.P_iny_sup;
  WC=snap.WC; GLR=snap.GLR; D_valv=snap.D_sla;

  fprintf(fid, '\n[PARAMETROS]\n');
  fprintf(fid, 'P_res_bar=%.2f\n', P_res/1e5);
  fprintf(fid, 'IP_m3_d_bar=%.4f\n', IP*86400*1e5);
  fprintf(fid, 'WC_fraccion=%.2f\n', WC);
  fprintf(fid, 'GLR_Sm3_m3_liquido=%.3f\n', GLR);
  fprintf(fid, 'P_wh_bar=%.2f\n', P_wh/1e5);
  fprintf(fid, 'P_iny_sup_bar=%.2f\n', P_iny/1e5);
  if any(strcmpi(tipo, {'GL','JGL'}))
      fprintf(fid, 'D_iny_m=%.1f\n', D_valv);
      fprintf(fid, 'profundidad_tipo=INYECCION_LEVANTAMIENTO\n');
  else
      fprintf(fid, 'D_bomba_m=%.1f\n', D_valv);
      fprintf(fid, 'profundidad_tipo=BOMBA_INTAKE\n');
  end
  fprintf(fid, 'fuente_parametros=SNAPSHOT_ULTIMA_CORRIDA\n');

  % --- Resultados ---
  fprintf(fid, '\n[RESULTADOS]\n');
  fprintf(fid, 'Ql_m3_d=%.2f\n', Ql_d);
  fprintf(fid, 'Ql_bpd=%.2f\n', Ql_d/0.158987294928);
  fprintf(fid, 'Qo_m3_d=%.2f\n', Qo_d);
  fprintf(fid, 'Qo_bopd=%.2f\n', Qo_d/0.158987294928);
  fprintf(fid, 'Qiny_Sm3_d=%.2f\n', Qiny_Sm3_d);
  fprintf(fid, 'Qiny_MMscfd=%.4f\n', Qiny_MMscfd);

  if strcmpi(tipo,'GL')
      sol=struct();
      if isfield(param,'GL_resultado') && isstruct(param.GL_resultado)
          sol=param.GL_resultado;
      elseif isfield(param,'sol_gl') && isstruct(param.sol_gl)
          sol=param.sol_gl;
      end
      fprintf(fid,'\n[GL_AUDIT]\n');
      if isfield(sol,'estado'), fprintf(fid,'estado=%s\n',sol.estado); end
      if isfield(sol,'D_iny'), fprintf(fid,'D_iny_efectiva_m=%.6f\n',sol.D_iny); end
      if isfield(sol,'audit') && isstruct(sol.audit)
          a=sol.audit;
          escribir_num(fid,'Qiny_solicitado_Sm3_d',a,'Qiny_solicitado',86400);
          escribir_num(fid,'Qiny_efectivo_VLP_Sm3_d',a,'Qiny_efectivo',86400);
          escribir_num(fid,'Qg_formacion_VLP_Sm3_d',a,'Qg_formacion_std',86400);
          escribir_num(fid,'Qg_total_VLP_Sm3_d',a,'Qg_total_std',86400);
          escribir_num(fid,'P_succion_VLP_bar',a,'P_s',1e-5);
          escribir_num(fid,'P_requerida_VLP_bar',a,'P_req',1e-5);
          escribir_num(fid,'residuo_nodal_bar',a,'residuo',1e-5);
          escribir_num(fid,'IP_efectivo_m3_d_bar',a,'IP_efectivo',86400*1e5);
          escribir_num(fid,'P_wh_efectiva_bar',a,'P_wh_efectiva',1e-5);
          escribir_num(fid,'P_iny_sup_efectiva_bar',a,'P_iny_sup_efectiva',1e-5);
      end
  elseif strcmpi(tipo,'JGL')
      sol=struct(); if isfield(param,'sol_jgl')&&isstruct(param.sol_jgl),sol=param.sol_jgl;elseif isfield(param,'JGL_resultado')&&isstruct(param.JGL_resultado),sol=param.JGL_resultado;end
      fprintf(fid,'\n[JGL]\n');
      if isfield(sol,'modo_solicitado'),fprintf(fid,'modo_solicitado=%s\n',sol.modo_solicitado);end
      if isfield(sol,'modo_utilizado'),fprintf(fid,'modo_utilizado=%s\n',sol.modo_utilizado);end
      if isfield(sol,'estado'),fprintf(fid,'estado=%s\n',sol.estado);end
      if isfield(sol,'iteraciones'),fprintf(fid,'iteraciones=%d\n',sol.iteraciones);end
      if isfield(sol,'deltaP'),fprintf(fid,'DeltaP_bar=%.6f\n',sol.deltaP/1e5);end
      if isfield(sol,'Ps'),fprintf(fid,'Ps_bar=%.6f\n',sol.Ps/1e5);end
      if isfield(sol,'Pd'),fprintf(fid,'Pd_bar=%.6f\n',sol.Pd/1e5);end
      if isfield(sol,'Pm'),fprintf(fid,'Pm_bar=%.6f\n',sol.Pm/1e5);end
      if isfield(sol,'potencia_disponible'),fprintf(fid,'potencia_disponible_kW=%.6f\n',sol.potencia_disponible/1000);end
      if isfield(sol,'potencia_transferida'),fprintf(fid,'potencia_transferida_kW=%.6f\n',sol.potencia_transferida/1000);end
      if isfield(sol,'error_directo_iterativo')&&isfinite(sol.error_directo_iterativo),fprintf(fid,'error_directo_iterativo_pct=%.6f\n',100*sol.error_directo_iterativo);end
  elseif strcmpi(tipo,'BES') && isfield(param,'BES_resultado') && isstruct(param.BES_resultado)
      b=param.BES_resultado;fprintf(fid,'\n[BES]\n');
      campos={'P_intake','T_motor','Q_recirc','corriente','IR_actual','run_life'};
      claves={'P_intake_bar','T_motor_C','Q_recirc_m3d','corriente_A','IR_actual_MOhm','run_life_d'};
      factores=[1e-5,1,86400,1,1,1];
      for kk=1:numel(campos),if isfield(b,campos{kk})&&isnumeric(b.(campos{kk})),fprintf(fid,'%s=%.6f\n',claves{kk},b.(campos{kk})*factores(kk));end,end
      if isfield(b,'IR_estado'),fprintf(fid,'IR_estado=%s\n',b.IR_estado);end
  end


  % --- Semaforos operativos comunes para TODOS los modulos ---
  try
      if isfield(param, 'semaforos') && isstruct(param.semaforos)
          sem_global = param.semaforos;
      elseif exist('aos_semaforo_operacion', 'file')
          det_sem = struct();
          if strcmpi(tipo, 'BM') && isfield(param, 'BM_resultado') && isstruct(param.BM_resultado)
              det_sem = param.BM_resultado;
          elseif strcmpi(tipo, 'BES') && isfield(param, 'BES_resultado') && isstruct(param.BES_resultado)
              det_sem = param.BES_resultado;
          end
          sem_global = aos_semaforo_operacion(tipo, param, Ql, Qo, Qiny, det_sem);
      else
          sem_global = [];
      end
      if ~isempty(sem_global) && exist('aos_exportar_semaforos', 'file')
          aos_exportar_semaforos(fid, sem_global, 'SEMAFOROS');
      end
  catch err_sem_global
      fprintf(fid, '\n[SEMAFOROS]\n');
      fprintf(fid, 'estado=no_disponible\n');
      fprintf(fid, 'aviso=%s\n', err_sem_global.message);
  end

  % --- Bombeo Mecanico / Gibbs ---
  if strcmpi(tipo, 'BM')
      fprintf(fid, '\n[BOMBEO_MECANICO]\n');
      if isfield(param, 'D_bomba_mm'), fprintf(fid, 'D_bomba_mm=%.0f\n', param.D_bomba_mm); end
      if isfield(param, 'S_carrera'), fprintf(fid, 'S_carrera_m=%.3f\n', param.S_carrera); end
      if isfield(param, 'N_velocidad'), fprintf(fid, 'N_velocidad_spm=%.2f\n', param.N_velocidad); end
      if isfield(param, 'eta_vol'), fprintf(fid, 'eta_vol=%.3f\n', param.eta_vol); end
      if isfield(param, 'eta_mecanica_BM'), fprintf(fid, 'eta_mecanica_BM=%.3f\n', param.eta_mecanica_BM); end
      if isfield(param, 'P_intake_min'), fprintf(fid, 'P_intake_min_bar=%.2f\n', param.P_intake_min/1e5); end
      if isfield(param, 'tipo_unidad'), fprintf(fid, 'tipo_unidad=%s\n', param.tipo_unidad); end
      if isfield(param, 'modelo_unidad_BM'), fprintf(fid, 'modelo_unidad_BM=%s\n', param.modelo_unidad_BM); end
      if isfield(param, 'material_varillas'), fprintf(fid, 'material_varillas=%s\n', param.material_varillas); end
      if isfield(param, 'tuberia_anclada'), fprintf(fid, 'tuberia_anclada=%d\n', param.tuberia_anclada); end
      fprintf(fid, '\n[BM_CONFIG_FISICA]\n');
      rpt_par(fid,param,'tuberia_anclada','%d');
      rpt_par(fid,param,'OD_tuberia_mm','%.6g');
      rpt_par(fid,param,'ID_tuberia_mm','%.6g');
      rpt_par(fid,param,'E_tuberia_Pa','%.8g');
      rpt_par(fid,param,'longitud_piston_m','%.8g');
      rpt_par(fid,param,'holgura_radial_mm','%.8g');
      rpt_par(fid,param,'temperatura_fondo_C','%.8g');
      rpt_par(fid,param,'viscosidad_fluido_cP','%.8g');
      rpt_par(fid,param,'viscosidad_agua_cP','%.8g');
      rpt_par(fid,param,'viscosidad_petroleo_estimado_cP','%.8g');
      rpt_par(fid,param,'tipo_fluido_bm','%s');
      rpt_par(fid,param,'metodo_viscosidad','%s');
      rpt_par(fid,param,'origen_viscosidad','%s');
      rpt_par(fid,param,'origen_temperatura_fondo','%s');
      fprintf(fid,'estado_modelo_tuberia=PARAMETROS_REGISTRADOS_MODELO_DINAMICO_PENDIENTE\n');
      fprintf(fid,'estado_modelo_fuga=PARAMETROS_REGISTRADOS_CORRELACION_FUGA_PENDIENTE\n');
      if isfield(param, 'BM_resultado') && isstruct(param.BM_resultado)
          det = param.BM_resultado;
          if isfield(det, 'Q_teorico'), fprintf(fid, 'Q_teorico_superficie_m3d=%.2f\n', det.Q_teorico*86400); end
          if isfield(det, 'Q_teorico_fondo'), fprintf(fid, 'Q_teorico_fondo_m3d=%.2f\n', det.Q_teorico_fondo*86400); end
          if isfield(det, 'S_superficie_m'), fprintf(fid, 'stroke_superficie_m=%.4f\n', det.S_superficie_m); end
          if isfield(det, 'S_fondo_m'), fprintf(fid, 'stroke_fondo_m=%.4f\n', det.S_fondo_m); end
          if isfield(det, 'llenado_bomba'), fprintf(fid, 'llenado_bomba=%.4f\n', det.llenado_bomba); end
          if isfield(det, 'espaciamiento') && isstruct(det.espaciamiento), fprintf(fid, 'espaciamiento_recomendado_m=%.3f\n', det.espaciamiento.recomendacion_m); end
          if isfield(det, 'Q_bomba'), fprintf(fid, 'Q_bomba_corr_m3d=%.2f\n', det.Q_bomba*86400); end
          if isfield(det, 'P_intake'), fprintf(fid, 'P_intake_bar=%.2f\n', det.P_intake/1e5); end
          if isfield(det, 'Ql_max_ipr'), fprintf(fid, 'Ql_max_ipr_m3d=%.2f\n', det.Ql_max_ipr*86400); end
      end
      if isfield(param, 'varillas') && isstruct(param.varillas)
          v = param.varillas;
          fprintf(fid, 'varillas_material=%s\n', v.material);
          fprintf(fid, 'varillas_tension_max_kgf=%.0f\n', v.tension_max_kg);
          fprintf(fid, 'varillas_tension_min_kgf=%.0f\n', v.tension_min_kg);
          fprintf(fid, 'varillas_estiramiento_m=%.3f\n', v.estiramiento_m);
          fprintf(fid, 'varillas_fs_fatiga=%.2f\n', v.fs_fatiga);
          fprintf(fid, 'varillas_sinker_bars=%d\n', v.sinker_bars);
      end
      if isfield(param, 'cartas_sup') && isfield(param, 'cartas_fondo')
          [tabla_carta, ~] = aos_report_table_find(tablas_reporte,'bm_carta_gibbs');
          if ~isempty(tabla_carta)
              aos_report_write_reference(fid,'CARTA_GIBBS',tabla_carta,'DISPONIBLE');
              fprintf(fid,'modelo=Gibbs Foundation 3 / contrato vigente\n');
          endif
      end
  end

  % --- Diagnostico SLA-aware ---
  fprintf(fid, '\n[DIAGNOSTICO]\n');
  P_s = snap.P_intake;
  if isfinite(P_s),fprintf(fid, 'P_succion_bar=%.2f\nP_succion_estado=DISPONIBLE\n', P_s/1e5);else,fprintf(fid,'P_succion_bar=NA\nP_succion_estado=NO_DISPONIBLE\n');end
  if ~isfinite(P_s)
      fprintf(fid,'alerta_succion=NO_EVALUABLE\n');
  elseif P_s < 2e5
      fprintf(fid, 'alerta_succion=Presion de entrada por debajo del limite recomendado (2 bar). Riesgo de cavitacion.\n');
  else
      fprintf(fid, 'alerta_succion=OK\n');
  end

  % --- Balance energetico transversal con frontera en el SLA ---
  if any(strcmpi(tipo, {'GL','JGL','BES','BM'}))
      sol_energia = struct();
      if strcmpi(tipo,'JGL')
          if isfield(param,'sol_jgl')&&isstruct(param.sol_jgl),sol_energia=param.sol_jgl;
          elseif isfield(param,'JGL_resultado')&&isstruct(param.JGL_resultado),sol_energia=param.JGL_resultado;endif
      elseif strcmpi(tipo,'GL')
          if isfield(param,'GL_resultado')&&isstruct(param.GL_resultado),sol_energia=param.GL_resultado;
          elseif isfield(param,'sol_gl')&&isstruct(param.sol_gl),sol_energia=param.sol_gl;endif
      elseif strcmpi(tipo,'BES') && isfield(param,'BES_resultado')&&isstruct(param.BES_resultado)
          sol_energia=param.BES_resultado;
      elseif strcmpi(tipo,'BM') && isfield(param,'BM_resultado')&&isstruct(param.BM_resultado)
          sol_energia=param.BM_resultado;
      endif
      try
          en = energia_guardada_o_calcular_local(tipo,param,Ql,Qo,Qiny,sol_energia);
          fprintf(fid, '\n[EFICIENCIA]\n');
          fprintf(fid, 'modelo_energia=%s\n', en.version);
          fprintf(fid, 'frontera_energia=SLA_EN_FONDO\n');
          fprintf(fid, 'metodo_util=%s\n', en.metodo_util);
          fprintf(fid, 'metodo_entrada=%s\n', en.metodo_entrada);
          fprintf(fid, 'profundidad_frontera_MD_m=%.6g\n', en.profundidad_frontera_MD_m);
          fprintf(fid, 'P_succion_SLA_bar=%.8g\n', en.P_succion_Pa / 1e5);
          fprintf(fid, 'P_descarga_SLA_bar=%.8g\n', en.P_descarga_Pa / 1e5);
          fprintf(fid, 'deltaP_util_SLA_bar=%.8g\n', en.deltaP_util_Pa / 1e5);
          fprintf(fid, 'potencia_entrada_kW=%.8g\n', en.potencia_entrada_kW);
          fprintf(fid, 'potencia_util_fondo_kW=%.8g\n', en.potencia_util_fondo_kW);
          met = aos_metricas_energia_sla(en,tipo);
          fprintf(fid, 'indicador_principal=INDICE_ENERGETICO_BRUTO_FONDO\n');
          fprintf(fid, 'indice_energetico_bruto_fondo_pct=%.8g\n', met.indice_energetico_bruto_fondo_pct);
          fprintf(fid, 'estado_indice_energetico_bruto=%s\n', met.estado_indice_energetico_bruto);
          fprintf(fid, 'eficiencia_interna_jet_pct=%.8g\n', met.eficiencia_interna_jet_pct);
          fprintf(fid, 'estado_eficiencia_interna_jet=%s\n', met.estado_eficiencia_interna_jet);
          fprintf(fid, 'metodo_indice=%s\n', met.metodo_indice);
          fprintf(fid, 'metodo_jet=%s\n', met.metodo_jet);
          % Alias historicos para Viewers anteriores. No deben usarse para rotular el indicador.
          fprintf(fid, 'eficiencia_dispositivo_pct=%.8g\n', en.eficiencia_dispositivo_pct);
          fprintf(fid, 'eficiencia_sistema_fondo_pct=%.8g\n', en.eficiencia_sistema_fondo_pct);
          fprintf(fid, 'nivel_confianza=%s\n', en.nivel_confianza);
          if isempty(en.advertencias)
              fprintf(fid, 'advertencias=NINGUNA\n');
          else
              fprintf(fid, 'advertencias=%s\n', strjoin(en.advertencias, ' | '));
          endif
      catch err_energia
          fprintf(fid, '\n[EFICIENCIA]\n');
          fprintf(fid, 'frontera_energia=SLA_EN_FONDO\n');
          fprintf(fid, 'estado=NO_EVALUABLE\n');
          fprintf(fid, 'error=%s\n', err_energia.message);
      end_try_catch
  end

  % --- Geologia: resultados numericos, sin graficos ---
  if ~isempty(geologia)
      criticos = calcular_caudales_criticos(geologia, Ql, param);
      fprintf(fid, '\n[GEOLOGIA]\n');
      fprintf(fid, 'tipo_modelo=%s\n', criticos.confianza_geologica.tipo);
      fprintf(fid, 'confianza=%s\n', criticos.confianza_geologica.nivel);
      fprintf(fid, 'confianza_porcentaje=%d\n', criticos.confianza_geologica.puntaje);
      fprintf(fid, 'Q_arena_m3d=%.6f\n', criticos.Q_arena*86400);
      fprintf(fid, 'Q_erosion_m3d=%.6f\n', criticos.Q_erosion*86400);
      fprintf(fid, 'Q_seguro_provisional_m3d=%.6f\n', criticos.Q_seguro*86400);
      fprintf(fid, 'mecanismo_vinculante=%s\n', criticos.mecanismo_vinculante);
      fprintf(fid, 'Q_seguro_es_provisional=%d\n', criticos.Q_seguro_provisional);
      fprintf(fid, 'conificacion_vinculante=%d\n', criticos.conificacion_vinculante);
      fprintf(fid, 'conificacion_estado=%s\n', criticos.conificacion_estado);
      if criticos.conificacion_vinculante
          fprintf(fid, 'Q_conifica_m3d=%.6f\n', criticos.Q_conifica*86400);
      elseif isfield(criticos,'conificacion_generica')
          g=criticos.conificacion_generica;
          fprintf(fid, 'conificacion_tipo=%s\n',g.tipo);
          fprintf(fid, 'conificacion_conservador_m3d=%.8f\n',g.Q_conservador_m3d);
          fprintf(fid, 'conificacion_probable_m3d=%.8f\n',g.Q_probable_m3d);
          fprintf(fid, 'conificacion_favorable_m3d=%.8f\n',g.Q_favorable_m3d);
          fprintf(fid, 'conificacion_interpretacion=%s\n',g.interpretacion);
      end
      fprintf(fid, 'choke_automatico_habilitado=%d\n',criticos.recomendar_choke);
  end

  % --- Distribucion de punzados: datos nativos con composicion seleccionable ---
  if isfield(param,'aosrpt_punzados_resumen') && isstruct(param.aosrpt_punzados_resumen)
      rp=param.aosrpt_punzados_resumen;
      [tabla_dist,~]=aos_report_table_find(tablas_reporte,'well_perforation_distribution');
      if ~isempty(tabla_dist)
          aos_report_write_reference(fid,'PUNZADOS_DISTRIBUIDOS',tabla_dist,'DISPONIBLE');
          if isfield(rp,'metodo'),fprintf(fid,'metodo=%s\n',rp.metodo);endif
          if isfield(rp,'n_tramos'),fprintf(fid,'n_tramos=%d\n',rp.n_tramos);endif
          if isfield(rp,'n_tiros_total'),fprintf(fid,'n_tiros_total=%d\n',rp.n_tiros_total);endif
      elseif isfield(rp,'aviso') && ischar(rp.aviso) && ~isempty(rp.aviso)
          fprintf(fid,'\n[PUNZADOS_DISTRIBUIDOS]\nestado=no_disponible\naviso=%s\n',rp.aviso);
      endif
  endif

  % --- Diseno de mandriles opcional ---
  if isfield(param,'mandriles_resultado') && isstruct(param.mandriles_resultado)
      aos_rpt_escribir_mandriles(fid,param.mandriles_resultado);
  end

  % --- Diagnostico y tablas nativas opcionales, comunes a todo AOS ---
  if isfield(param,'aosrpt_diagnostico') && isstruct(param.aosrpt_diagnostico) && ...
      exist('aos_rpt_escribir_diagnostico','file') == 2
    aos_rpt_escribir_diagnostico(fid,param.aosrpt_diagnostico);
  end
  if isfield(param,'aosrpt_tablas') && ~isempty(param.aosrpt_tablas) && ...
      exist('aos_rpt_escribir_tablas','file') == 2
    aos_rpt_escribir_tablas(fid,param.aosrpt_tablas,param.aosrpt_composicion);
  end

  % --- Contexto portable para AOS Viewer ---
  incluir_viewer = true;
  if isfield(param,'aosrpt_incluir_contexto_viewer')
      incluir_viewer = logical(param.aosrpt_incluir_contexto_viewer);
  end
  aos_exportar_contexto_viewer(fid,param,tipo,incluir_viewer);

  fclose(fid);
  fprintf('\nReporte exportado: %s\n', archivo_salida);
  fprintf('Tamaño: %.1f KB\n', get_size_kb(archivo_salida));
end

function kb = get_size_kb(archivo)
  info = dir(archivo);
  kb = info.bytes / 1024;
end

function s = condicional(cond, v_true, v_false)
  if cond, s = v_true; else s = v_false; end
end
function escribir_num(fid, clave, s, campo, factor)
  if isstruct(s) && isfield(s,campo) && isnumeric(s.(campo)) && ...
     isscalar(s.(campo)) && isfinite(s.(campo))
      fprintf(fid,'%s=%.10g\n',clave,s.(campo)*factor);
  end
end

function en=energia_guardada_o_calcular_local(tipo,param,Ql,Qo,Qiny,sol)
  en=struct();
  if isstruct(param)&&isfield(param,'energia_sla')&&isstruct(param.energia_sla)
    en=param.energia_sla;
  elseif isstruct(sol)&&isfield(sol,'energia_sla')&&isstruct(sol.energia_sla)
    en=sol.energia_sla;
  else
    en=aos_balance_energia_sla(tipo,param,Ql,Qo,Qiny,sol);
  endif
endfunction


function rpt_par(fid,s,campo,fmt)
  if ~isfield(s,campo) || isempty(s.(campo)), return; end
  v=s.(campo);
  if isnumeric(v) || islogical(v)
      if isscalar(v) && isfinite(double(v)), fprintf(fid,[campo '=' fmt '\n'],v); end
  elseif ischar(v)
      fprintf(fid,[campo '=' fmt '\n'],v);
  elseif isstring(v) && isscalar(v)
      fprintf(fid,[campo '=' fmt '\n'],char(v));
  end
end
