function gibbs3_report_append_sections(archivo, res, formato)
% GIBBS3_REPORT_APPEND_SECTIONS Agrega la auditoria completa GF3 al .aosrpt.

  if nargin < 3 || isempty(formato), formato = 'SIMPLE'; end
  fid = fopen(archivo, 'a');
  if fid < 0
    error('No se pudo abrir el informe GF3 para agregar resultados: %s', archivo);
  end

  try
    p = res.param;
    m = res.metricas;
    prom = res.promedio;

    fprintf(fid, '\n[GF3_META]\n');
    fprintf(fid, 'schema=GF3_REPORT_1.0\n');
    fprintf(fid, 'formato=%s\n', limpiar_txt_local(formato));
    fprintf(fid, 'version=%s\n', limpiar_txt_local(texto_local(res, 'version', 'GF3')));
    fprintf(fid, 'modelo=%s\n', limpiar_txt_local(texto_local(res, 'modelo', 'GIBBS_FOUNDATION_3')));
    fprintf(fid, 'solver=Gibbs_Foundation_3_integral\n');
    fprintf(fid, 'tipo_calculo=simulacion_operativa\n');
    fprintf(fid, 'fecha=%s\n', datestr(now(), 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'convergencia_periodica=%s\n', ...
      estado_bool_local(logico_local(m, 'periodicidad_aprobada', false)));
    fprintf(fid, 'error_periodicidad_rel=%.12g\n', numero_local(m, 'error_periodicidad_rel', NaN));

    fprintf(fid, '\n[GF3_CONFIGURACION]\n');
    fprintf(fid, 'profundidad_bomba_MD_m=%.12g\n', numero_local(p, 'D_bomba', NaN));
    fprintf(fid, 'profundidad_bomba_TVD_m=%.12g\n', numero_local(p, 'D_bomba_TVD', NaN));
    fprintf(fid, 'diametro_bomba_mm=%.12g\n', numero_local(p, 'D_bomba_mm', NaN));
    fprintf(fid, 'carrera_superficial_configurada_m=%.12g\n', numero_local(p, 'S_carrera', NaN));
    fprintf(fid, 'velocidad_spm=%.12g\n', numero_local(p, 'N_velocidad', NaN));
    fprintf(fid, 'water_cut=%.12g\n', numero_local(p, 'WC', NaN));
    fprintf(fid, 'viscosidad_fluido_cP=%.12g\n', numero_local(p, 'viscosidad_fluido_cP', NaN));
    fprintf(fid, 'temperatura_fondo_C=%.12g\n', numero_local(p, 'temperatura_fondo_C', NaN));
    fprintf(fid, 'presion_cabeza_bar=%.12g\n', numero_local(p, 'P_wh', NaN) / 1e5);
    fprintf(fid, 'presion_intake_bar=%.12g\n', presion_intake_local(p) / 1e5);
    fprintf(fid, 'tuberia_anclada=%d\n', logico_local(p, 'tuberia_anclada', true));
    fprintf(fid, 'tuberia_OD_mm=%.12g\n', numero_local(p, 'OD_tuberia_mm', NaN));
    fprintf(fid, 'tuberia_ID_mm=%.12g\n', numero_local(p, 'ID_tuberia_mm', NaN));
    fprintf(fid, 'nodos=%d\n', round(numero_local(p, 'gibbs3_n_nodos', NaN)));
    fprintf(fid, 'ciclos=%d\n', round(numero_local(p, 'gibbs3_n_ciclos', NaN)));
    fprintf(fid, 'ciclos_descartados=%d\n', round(numero_local(p, 'gibbs3_descartar_ciclos', NaN)));
    fprintf(fid, 'puntos_por_ciclo=%d\n', round(numero_local(p, 'gibbs3_puntos_por_ciclo', NaN)));
    fprintf(fid, 'amortiguamiento_delta=%.12g\n', numero_local(p, 'gibbs3_delta_damping', NaN));

    escribir_aparato_local(fid, res);
    escribir_bomba_local(fid, res);
    escribir_resultados_local(fid, res);
    escribir_sarta_local(fid, res);
    escribir_espaciamiento_local(fid, res);
    escribir_validacion_local(fid, res);
    escribir_ciclo_local(fid, res);

    fclose(fid);
  catch err
    fclose(fid);
    rethrow(err);
  end
end

function escribir_aparato_local(fid, res)
  p = res.param;
  fprintf(fid, '\n[GF3_APARATO_BOMBEO]\n');
  fprintf(fid, 'fabricante=%s\n', limpiar_txt_local(texto_local(p, 'pumping_unit_manufacturer', 'NO_ESPECIFICADO')));
  fprintf(fid, 'modelo=%s\n', limpiar_txt_local(texto_local(p, 'pumping_unit_model', 'NO_ESPECIFICADO')));
  fprintf(fid, 'tipo=%s\n', limpiar_txt_local(texto_local(p, 'pumping_unit_type', 'NO_ESPECIFICADO')));
  fprintf(fid, 'modelo_cinematico=%s\n', limpiar_txt_local(texto_local(p, 'pumping_unit_kinematic_model', 'NO_ESPECIFICADO')));
  fprintf(fid, 'carrera_operativa_m=%.12g\n', numero_local(p, 'S_carrera', NaN));
  fprintf(fid, 'spm=%.12g\n', numero_local(p, 'N_velocidad', NaN));
  fprintf(fid, 'capacidad_carga_PR_kN=%.12g\n', numero_local(p, 'pumping_unit_max_pr_load_kN', NaN));
  fprintf(fid, 'capacidad_torque_reductor_kNm=%.12g\n', numero_local(p, 'pumping_unit_gearbox_torque_kNm', NaN));
  fprintf(fid, 'potencia_motor_nominal_kW=%.12g\n', numero_local(p, 'pumping_unit_motor_power_kW', NaN));

  if isfield(res, 'verificacion_aparato') && isstruct(res.verificacion_aparato)
    v = res.verificacion_aparato;
    fprintf(fid, 'estado=%s\n', limpiar_txt_local(texto_local(v, 'estado', 'NO_EVALUADO')));
    fprintf(fid, 'carga_PR_max_kN=%.12g\n', numero_local(v, 'carga_pr_max_kN', NaN));
    fprintf(fid, 'carga_PR_min_kN=%.12g\n', numero_local(v, 'carga_pr_min_kN', NaN));
    fprintf(fid, 'torque_max_abs_kNm=%.12g\n', numero_local(v, 'torque_max_abs_kNm', NaN));
    fprintf(fid, 'torque_RMS_kNm=%.12g\n', numero_local(v, 'torque_rms_kNm', NaN));
    fprintf(fid, 'potencia_motor_max_kW=%.12g\n', numero_local(v, 'potencia_motor_max_kW', NaN));
    fprintf(fid, 'potencia_motor_media_kW=%.12g\n', numero_local(v, 'potencia_motor_media_kW', NaN));
    fprintf(fid, 'contrabalanceo_recomendado_kNm=%.12g\n', numero_local(v, 'contrabalanceo_recomendado_kNm', NaN));
    fprintf(fid, 'utilizacion_carrera=%.12g\n', numero_local(v, 'utilizacion_carrera', NaN));
    fprintf(fid, 'utilizacion_spm=%.12g\n', numero_local(v, 'utilizacion_spm', NaN));
    fprintf(fid, 'utilizacion_carga_PR=%.12g\n', numero_local(v, 'utilizacion_carga_pr', NaN));
    fprintf(fid, 'utilizacion_torque=%.12g\n', numero_local(v, 'utilizacion_torque', NaN));
    fprintf(fid, 'utilizacion_potencia=%.12g\n', numero_local(v, 'utilizacion_potencia', NaN));
  end
end

function escribir_bomba_local(fid, res)
  p = res.param;
  m = res.metricas;
  fprintf(fid, '\n[GF3_BOMBA_FONDO]\n');
  fprintf(fid, 'tipo=%s\n', ternario_local(logico_local(p, 'bomba_lpp', false), 'LPP_AESIR', 'CONVENCIONAL'));
  fprintf(fid, 'diametro_mm=%.12g\n', numero_local(p, 'D_bomba_mm', NaN));
  fprintf(fid, 'llenado=%.12g\n', numero_local(res.bomba, 'llenado', numero_local(p, 'eta_vol', NaN)));
  fprintf(fid, 'longitud_piston_convencional_m=%.12g\n', numero_local(p, 'longitud_piston_m', NaN));
  fprintf(fid, 'holgura_radial_mm=%.12g\n', numero_local(p, 'holgura_radial_mm', NaN));
  fprintf(fid, 'carrera_piston_relativa_m=%.12g\n', numero_local(m, 'carrera_piston_relativa_m', NaN));
  fprintf(fid, 'carga_bomba_max_kN=%.12g\n', numero_local(m, 'carga_bomba_max_N', NaN) / 1000);
  fprintf(fid, 'carga_bomba_min_kN=%.12g\n', numero_local(m, 'carga_bomba_min_N', NaN) / 1000);

  if logico_local(p, 'bomba_lpp', false)
    fprintf(fid, '\n[GF3_LPP_AESIR]\n');
    fprintf(fid, 'longitud_piston_m=%.12g\n', numero_local(p, 'lpp_longitud_piston_m', NaN));
    fprintf(fid, 'ID_interno_piston_mm=%.12g\n', numero_local(p, 'lpp_id_piston_mm', NaN));
    fprintf(fid, 'rugosidad_m=%.12g\n', numero_local(p, 'lpp_rugosidad_m', NaN));
    fprintf(fid, 'coeficiente_perdidas_K=%.12g\n', numero_local(p, 'lpp_coef_perdidas_K', NaN));
    fprintf(fid, 'deltaP_max_bar=%.12g\n', numero_local(m, 'lpp_deltaP_max_Pa', NaN) / 1e5);
    fprintf(fid, 'carga_adicional_max_kN=%.12g\n', numero_local(m, 'lpp_carga_adicional_max_N', NaN) / 1000);
    fprintf(fid, 'velocidad_interna_max_m_s=%.12g\n', numero_local(m, 'lpp_velocidad_interna_max_m_s', NaN));
  end
end

function escribir_resultados_local(fid, res)
  m = res.metricas;
  fprintf(fid, '\n[GF3_RESULTADOS]\n');
  fprintf(fid, 'carrera_superficie_m=%.12g\n', numero_local(m, 'carrera_superficie_m', NaN));
  fprintf(fid, 'carrera_varilla_fondo_m=%.12g\n', numero_local(m, 'carrera_varilla_fondo_m', NaN));
  fprintf(fid, 'movimiento_tuberia_fondo_m=%.12g\n', numero_local(m, 'movimiento_tuberia_fondo_m', NaN));
  fprintf(fid, 'elongacion_tuberia_max_m=%.12g\n', ...
    numero_local(m, 'elongacion_tuberia_max_m', NaN));
  if isfield(res, 'tuberia') && isstruct(res.tuberia)
    fprintf(fid, 'rigidez_axial_tuberia_N_m=%.12g\n', ...
      numero_local(res.tuberia, 'rigidez_axial_N_m', NaN));
    fprintf(fid, 'convencion_signo_tuberia=%s\n', ...
      limpiar_txt_local(texto_local(res.tuberia, 'convencion_signo', ...
      'NO_DECLARADA')));
    fprintf(fid, 'schema_signo_tuberia=%s\n', ...
      limpiar_txt_local(texto_local(res.tuberia, 'schema_signo', ...
      'NO_DECLARADO')));
  endif
  fprintf(fid, 'carrera_piston_relativa_m=%.12g\n', numero_local(m, 'carrera_piston_relativa_m', NaN));
  fprintf(fid, 'transmision_carrera=%.12g\n', numero_local(m, 'transmision_carrera', NaN));
  fprintf(fid, 'perdida_carrera_tuberia_m=%.12g\n', numero_local(m, 'perdida_carrera_tuberia_m', NaN));
  fprintf(fid, 'carga_superficie_max_kN=%.12g\n', numero_local(m, 'carga_superficie_max_N', NaN) / 1000);
  fprintf(fid, 'carga_superficie_min_kN=%.12g\n', numero_local(m, 'carga_superficie_min_N', NaN) / 1000);
  fprintf(fid, 'caudal_teorico_bomba_m3_d=%.12g\n', numero_local(m, 'caudal_teorico_bomba_m3_d', NaN));
  fprintf(fid, 'caudal_estimado_m3_d=%.12g\n', numero_local(m, 'caudal_estimado_m3_d', NaN));
  fprintf(fid, 'velocidad_PR_max_m_s=%.12g\n', numero_local(m, 'velocidad_PR_max_m_s', NaN));
  fprintf(fid, 'aceleracion_PR_max_m_s2=%.12g\n', numero_local(m, 'aceleracion_PR_max_m_s2', NaN));
end

function escribir_sarta_local(fid, res)
  p = res.param;
  fprintf(fid, '\n[GF3_SARTA]\n');
  fprintf(fid, 'modo=%s\n', limpiar_txt_local(texto_local(p, 'rod_design_mode', 'NO_CONFIGURADO')));
  fprintf(fid, 'candidata_seleccionada=%s\n', limpiar_txt_local(texto_local(p, 'rod_design_candidate_name', 'NO_SELECCIONADA')));
  fprintf(fid, 'motivo_seleccion=%s\n', limpiar_txt_local(texto_local(p, 'rod_design_selection_reason', 'NO_DISPONIBLE')));
  fprintf(fid, 'grado_material=%s\n', limpiar_txt_local(texto_local(p, 'rod_grade_name', 'NO_ESPECIFICADO')));
  fprintf(fid, 'factor_seguridad=%.12g\n', numero_local(p, 'rod_factor_seguridad', NaN));
  fprintf(fid, 'longitud_comercial_varilla_m=%.12g\n', numero_local(p, 'rod_longitud_comercial_m', NaN));

  d = struct();
  if isfield(res, 'diseno_sarta_espaciamiento') && isstruct(res.diseno_sarta_espaciamiento)
    d = res.diseno_sarta_espaciamiento;
    fprintf(fid, 'utilizacion_Goodman_max=%.12g\n', numero_local(d, 'utilizacion_max', NaN));
    fprintf(fid, 'fatiga_aprobada=%s\n', estado_bool_local(logico_local(d, 'aprobada_fatiga', false)));
    fprintf(fid, 'elemento_critico=%d\n', round(numero_local(d, 'elemento_critico', NaN)));
    fprintf(fid, 'masa_total_varillas_kg=%.12g\n', numero_local(d, 'masa_total_varillas_kg', NaN));
  end

  fprintf(fid, '\n[GF3_SARTA_TABLAS]\n');
  fprintf(fid, 'schema=GF3_TABLE_REFERENCES_1.0\n');
  fprintf(fid, 'plan_instalacion_table_id=gf3_sarta_instalacion\n');
  fprintf(fid, 'secciones_table_id=gf3_sarta_secciones\n');
  fprintf(fid, 'candidatos_table_id=gf3_sarta_candidatas\n');
  fprintf(fid, 'elementos_table_id=gf3_sarta_elementos\n');
  fprintf(fid, 'nota=La inclusion, resumen, muestreo o archivo completo se define en REPORT_COMPOSITION.\n');

  if isstruct(d) && isfield(d, 'barras_peso')
    b = d.barras_peso;
    cantidad = max(round(numero_local(b, 'cantidad_instalada', 0)), ...
      round(numero_local(b, 'cantidad_recomendada', 0)));
    fprintf(fid, '\n[GF3_BARRAS_PESO]\n');
    fprintf(fid, 'resultado=%s\n', limpiar_txt_local(texto_local(b, 'resultado_operativo', 'NO_EVALUADO')));
    fprintf(fid, 'habilitadas=%d\n', logico_local(b, 'habilitadas', false));
    fprintf(fid, 'instalar=%d\n', logico_local(b, 'instalar', false));
    fprintf(fid, 'cantidad=%d\n', cantidad);
    fprintf(fid, 'longitud_unitaria_m=%.12g\n', numero_local(b, 'longitud_unitaria_m', NaN));
    fprintf(fid, 'longitud_total_instalada_m=%.12g\n', cantidad*numero_local(b, 'longitud_unitaria_m', 0));
    fprintf(fid, 'longitud_teorica_requerida_m=%.12g\n', numero_local(b, 'longitud_teorica_requerida_m', NaN));
    fprintf(fid, 'diametro_mm=%.12g\n', numero_local(b, 'diametro_mm', NaN));
    fprintf(fid, 'masa_total_aire_kg=%.12g\n', cantidad*numero_local(b, 'masa_unitaria_aire_kg', 0));
    fprintf(fid, 'peso_aparente_total_kN=%.12g\n', cantidad*numero_local(b, 'peso_aparente_unitario_N', 0)/1000);
    fprintf(fid, 'ubicacion=%s\n', limpiar_txt_local(texto_local(b, 'ubicacion', 'SOBRE_LA_BOMBA')));
  end
end

function escribir_espaciamiento_local(fid, res)
  if ~isfield(res, 'diseno_sarta_espaciamiento') || ...
      ~isfield(res.diseno_sarta_espaciamiento, 'espaciamiento')
    return;
  end
  e = res.diseno_sarta_espaciamiento.espaciamiento;

  fprintf(fid, '\n[GF3_ESPACIAMIENTO]\n');
  fprintf(fid, 'modelo=%s\n', limpiar_txt_local(texto_local(e, 'modelo', ...
    'NO_ESPECIFICADO')));
  fprintf(fid, 'modo=%s\n', limpiar_txt_local(texto_local(e, 'modo', ...
    'NO_CONFIGURADO')));
  fprintf(fid, 'referencia_geometrica=%s\n', limpiar_txt_local(texto_local(e, ...
    'referencia', 'NO_ESPECIFICADA')));
  fprintf(fid, 'condicion_tubing=%s\n', limpiar_txt_local(texto_local(e, ...
    'condicion_tubing', 'NO_ESPECIFICADA')));
  fprintf(fid, 'condicion_termica_sensado=%s\n', limpiar_txt_local(texto_local(e, ...
    'condicion_termica_sensado', 'NO_ESPECIFICADA')));
  fprintf(fid, 'perfil_termico=%s\n', limpiar_txt_local(texto_local(e, ...
    'perfil_termico', 'NO_ESPECIFICADO')));
  fprintf(fid, 'valido=%s\n', estado_bool_local(logico_local(e, 'valido', false)));
  fprintf(fid, 'estado=%s\n', limpiar_txt_local(texto_local(e, 'estado', ...
    'NO_EVALUADO')));
  fprintf(fid, 'validacion=%s\n', limpiar_txt_local(texto_local(e, ...
    'validacion', 'NO_DISPONIBLE')));

  fprintf(fid, '\n[GF3_ESPACIAMIENTO_INFORMACION_ABSOLUTA]\n');
  fprintf(fid, 'elongacion_absoluta_equilibrio_m=%.12g\n', ...
    numero_local(e, 'elongacion_absoluta_equilibrio_m', NaN));
  fprintf(fid, 'elongacion_absoluta_peso_propio_m=%.12g\n', ...
    numero_local(e, 'elongacion_absoluta_peso_propio_m', NaN));
  fprintf(fid, 'elongacion_estado_sensado_m=%.12g\n', ...
    numero_local(e, 'elongacion_estado_sensado_m', NaN));
  fprintf(fid, 'peso_propio_ya_incluido_al_sensar=%s\n', ...
    estado_bool_local(logico_local(e, 'peso_propio_ya_incluido_al_sensar', false)));
  fprintf(fid, 'contribucion_peso_propio_al_levantamiento_m=%.12g\n', ...
    numero_local(e, 'contribucion_peso_propio_al_levantamiento_m', NaN));

  fprintf(fid, '\n[GF3_ESPACIAMIENTO_COMPONENTES_DIFERENCIALES]\n');
  fprintf(fid, 'compliance_sarta_m_N=%.12g\n', ...
    numero_local(e, 'compliance_sarta_m_N', NaN));
  fprintf(fid, 'carga_referencia_sensado_N=%.12g\n', ...
    numero_local(e, 'carga_referencia_sensado_N', NaN));
  fprintf(fid, 'carga_maxima_bomba_N=%.12g\n', ...
    numero_local(e, 'carga_maxima_bomba_N', NaN));
  fprintf(fid, 'incremento_carga_bomba_N=%.12g\n', ...
    numero_local(e, 'incremento_carga_bomba_N', NaN));
  fprintf(fid, 'elongacion_diferencial_carga_m=%.12g\n', ...
    numero_local(e, 'elongacion_diferencial_carga_m', NaN));
  fprintf(fid, 'movimiento_diferencial_tubing_m=%.12g\n', ...
    numero_local(e, 'movimiento_diferencial_tubing_m', NaN));
  fprintf(fid, 'correccion_cuasistatica_m=%.12g\n', ...
    numero_local(e, 'correccion_cuasistatica_m', NaN));
  fprintf(fid, 'correccion_dinamica_m=%.12g\n', ...
    numero_local(e, 'correccion_dinamica_m', NaN));
  fprintf(fid, 'correccion_mecanica_max_m=%.12g\n', ...
    numero_local(e, 'correccion_mecanica_max_m', NaN));
  fprintf(fid, 'expansion_termica_diferencial_varillas_m=%.12g\n', ...
    numero_local(e, 'expansion_termica_diferencial_varillas_m', NaN));
  fprintf(fid, 'expansion_termica_diferencial_tuberia_m=%.12g\n', ...
    numero_local(e, 'expansion_termica_diferencial_tuberia_m', NaN));
  fprintf(fid, 'correccion_termica_neta_m=%.12g\n', ...
    numero_local(e, 'correccion_termica_neta_m', NaN));
  fprintf(fid, 'correccion_neta_max_m=%.12g\n', ...
    numero_local(e, 'correccion_neta_max_m', NaN));
  fprintf(fid, 'correccion_requerida_m=%.12g\n', ...
    numero_local(e, 'correccion_requerida_m', NaN));
  fprintf(fid, 'clearance_inferior_objetivo_m=%.12g\n', ...
    numero_local(e, 'clearance_inferior_objetivo_m', NaN));
  fprintf(fid, 'clearance_superior_objetivo_m=%.12g\n', ...
    numero_local(e, 'clearance_superior_objetivo_m', NaN));
  fprintf(fid, 'margen_instalacion_m=%.12g\n', ...
    numero_local(e, 'margen_instalacion_m', NaN));

  fprintf(fid, '\n[GF3_ESPACIAMIENTO_RESULTADO_OPERATIVO]\n');
  fprintf(fid, 'recomendado_superficie_m=%.12g\n', ...
    numero_local(e, 'recomendado_superficie_m', NaN));
  fprintf(fid, 'levantamiento_despues_sensar_mm=%.12g\n', ...
    numero_local(e, 'levantamiento_despues_sensar_mm', NaN));
  fprintf(fid, 'tolerancia_ejecucion_mm=%.12g\n', ...
    numero_local(e, 'tolerancia_ejecucion_mm', NaN));
  fprintf(fid, 'clearance_inferior_nominal_m=%.12g\n', ...
    numero_local(e, 'clearance_inferior_estimado_m', NaN));
  fprintf(fid, 'clearance_inferior_peor_caso_m=%.12g\n', ...
    numero_local(e, 'clearance_inferior_peor_caso_m', NaN));
  fprintf(fid, 'clearance_superior_nominal_m=%.12g\n', ...
    numero_local(e, 'clearance_superior_estimado_m', NaN));
  fprintf(fid, 'clearance_superior_peor_caso_m=%.12g\n', ...
    numero_local(e, 'clearance_superior_peor_caso_m', NaN));
  fprintf(fid, 'longitud_util_m=%.12g\n', numero_local(e, 'longitud_util_m', NaN));
  fprintf(fid, 'carrera_relativa_m=%.12g\n', ...
    numero_local(e, 'carrera_relativa_m', NaN));
  fprintf(fid, 'capacidad_ajuste_informada=%s\n', ...
    estado_bool_local(logico_local(e, 'capacidad_ajuste_informada', false)));
  fprintf(fid, 'levantamiento_maximo_disponible_m=%.12g\n', ...
    numero_local(e, 'levantamiento_maximo_disponible_m', NaN));
  fprintf(fid, 'capacidad_ajuste_aprobada=%s\n', ...
    estado_bool_local(logico_local(e, 'capacidad_ajuste_aprobada', false)));

  fprintf(fid, '\n[GF3_ESPACIAMIENTO_INSTRUCCION_CAMPO]\n');
  if logico_local(e, 'valido', false) && ...
      ~strcmpi(texto_local(e, 'estado', 'ROJO'), 'ROJO')
    fprintf(fid, 'resultado=DESPUES_DE_SENSAR_FONDO_LEVANTAR_%.0f_mm_Y_FIJAR_GRAMPA\n', ...
      numero_local(e, 'levantamiento_despues_sensar_mm', NaN));
  else
    fprintf(fid, 'resultado=NO_APLICAR_ESPACIAMIENTO_RESULTADO_NO_APROBADO\n');
  end
  for i = 1:5
    campo = sprintf('instruccion_%d', i);
    fprintf(fid, '%s=%s\n', campo, limpiar_txt_local(texto_local(e, campo, ...
      'NO_DISPONIBLE')));
  end
end

function escribir_validacion_local(fid, res)
  fprintf(fid, '\n[GF3_SEMAFOROS]\n');
  estado_aparato = 'NO_EVALUADO';
  if isfield(res, 'verificacion_aparato')
    estado_aparato = texto_local(res.verificacion_aparato, 'estado', 'NO_EVALUADO');
  end
  fprintf(fid, 'aparato=%s\n', limpiar_txt_local(estado_aparato));

  estado_sarta = 'NO_EVALUADO';
  estado_spacing = 'NO_EVALUADO';
  if isfield(res, 'diseno_sarta_espaciamiento')
    d = res.diseno_sarta_espaciamiento;
    estado_sarta = ternario_local(logico_local(d, 'aprobada_fatiga', false), 'VERDE', 'ROJO');
    if isfield(d, 'espaciamiento')
      estado_spacing = texto_local(d.espaciamiento, 'estado', 'NO_EVALUADO');
    end
  end
  fprintf(fid, 'sarta=%s\n', limpiar_txt_local(estado_sarta));
  fprintf(fid, 'espaciamiento=%s\n', limpiar_txt_local(estado_spacing));
  fprintf(fid, 'periodicidad=%s\n', estado_bool_local(logico_local(res.metricas, 'periodicidad_aprobada', false)));

  fprintf(fid, '\n[GF3_VALIDACION]\n');
  if isfield(res, 'validacion') && isstruct(res.validacion)
    fprintf(fid, 'ok=%d\n', logico_local(res.validacion, 'ok', false));
    if isfield(res.validacion, 'mensajes') && iscell(res.validacion.mensajes)
      fprintf(fid, 'n_mensajes=%d\n', numel(res.validacion.mensajes));
      for i = 1:numel(res.validacion.mensajes)
        fprintf(fid, 'mensaje_%02d=%s\n', i, limpiar_txt_local(res.validacion.mensajes{i}));
      end
    end
  else
    fprintf(fid, 'ok=NO_EVALUADO\n');
  end

  if isfield(res, 'advertencias') && iscell(res.advertencias)
    fprintf(fid, 'n_advertencias=%d\n', numel(res.advertencias));
    for i = 1:numel(res.advertencias)
      fprintf(fid, 'advertencia_%02d=%s\n', i, limpiar_txt_local(res.advertencias{i}));
    end
  else
    fprintf(fid, 'n_advertencias=0\n');
  end
end

function escribir_ciclo_local(fid, res)
  n = 0;
  if isfield(res,'promedio') && isstruct(res.promedio)
    n = minimo_longitudes_local(res.promedio, {'t_s','u_superficie_m','u_varilla_fondo_m', ...
      'u_tuberia_fondo_m','u_piston_relativo_m','F_superficie_N','F_bomba_N'});
  end
  fprintf(fid, '\n[GF3_CICLO_PROMEDIO]\n');
  fprintf(fid, 'puntos=%d\n', n);
  fprintf(fid, 'table_id=gf3_ciclo_promedio\n');
  fprintf(fid, 'datos_completos=TABLA_NATIVA_O_ARCHIVO_INTERNO\n');
  fprintf(fid, 'presentacion_controlada_por=REPORT_COMPOSITION\n');
end

function n = minimo_longitudes_local(s, campos)
  n = Inf;
  if ~isstruct(s), n = 0; return; end
  for i = 1:numel(campos)
    if ~isfield(s, campos{i}) || isempty(s.(campos{i}))
      n = 0;
      return;
    end
    n = min(n, numel(s.(campos{i})));
  end
  if isinf(n), n = 0; end
end

function v = numero_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end

function v = texto_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ischar(s.(campo)) && ...
      ~isempty(strtrim(s.(campo)))
    v = strtrim(s.(campo));
  end
end

function tf = logico_local(s, campo, defecto)
  tf = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if islogical(x) || (isnumeric(x) && ~isempty(x) && isfinite(x(1)))
      tf = logical(x(1));
    end
  end
end

function p = presion_intake_local(s)
  p = numero_local(s, 'P_intake', NaN);
  if ~isfinite(p), p = numero_local(s, 'P_intake_min', NaN); end
end

function s = limpiar_txt_local(valor)
  [s, ok] = aos_texto_seguro(valor, '');
  if ~ok, s = 'VALOR_NO_TEXTO'; endif
  s = regexprep(s, '[\r\n=]', ' ');
  s = strtrim(s);
endfunction

function s = estado_bool_local(tf)
  if tf, s = 'APROBADO'; else, s = 'REVISAR'; end
end

function s = ternario_local(tf, a, b)
  if tf, s = a; else, s = b; end
end
