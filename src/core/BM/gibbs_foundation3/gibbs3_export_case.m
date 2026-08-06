function archivos = gibbs3_export_case(res, directorio)
% GIBBS3_EXPORT_CASE Exporta ciclo, aparato, sarta e instrucciones.

  res = gibbs3_upgrade_result_schema(res);

  if exist(directorio, 'dir') ~= 7, mkdir(directorio); end
  sello = datestr(now(), 'yyyymmdd_HHMMSS');
  base = fullfile(directorio, ['GF3_' sello]);
  csvfile = [base '_ciclo_promedio.csv'];
  rodfile = [base '_sarta_elementos.csv'];
  installfile = [base '_sarta_instalacion.csv'];
  unitfile = [base '_aparato.csv'];
  txtfile = [base '_resumen.txt'];
  jsonfile = [base '_resultado.json'];

  p = res.promedio;
  a = p.aparato;
  v = res.verificacion_aparato;
  M = [p.t_s, p.u_superficie_m, p.u_varilla_fondo_m, ...
       p.u_tuberia_fondo_m, p.u_piston_relativo_m, ...
       p.F_superficie_N, p.F_bomba_N, p.apertura_valvula, ...
       p.F_LPP_N, p.deltaP_LPP_Pa, p.Q_LPP_m3_s, ...
       a.velocidad_m_s, a.aceleracion_m_s2, a.angulo_rad, ...
       v.torque_neto_kNm, v.potencia_motor_kW];
  fid = fopen(csvfile, 'w');
  if fid < 0, error('No se pudo crear %s.', csvfile); end
  fprintf(fid, ['t_s,u_superficie_m,u_varilla_fondo_m,u_tuberia_fondo_m,' ...
    'u_piston_relativo_m,F_superficie_N,F_bomba_N,apertura_valvula,' ...
    'F_LPP_N,deltaP_LPP_Pa,Q_LPP_m3_s,velocidad_PR_m_s,' ...
    'aceleracion_PR_m_s2,angulo_manivela_rad,torque_neto_kNm,' ...
    'potencia_motor_kW\n']);
  fclose(fid);
  dlmwrite(csvfile, M, '-append', 'delimiter', ',', 'precision', '%.12g');

  d = res.diseno_sarta_espaciamiento;
  R = [d.elementos.x_m, d.elementos.diametro_mm, ...
       d.elementos.Fmax_N, d.elementos.Fmin_N, ...
       d.elementos.sigma_max_MPa, d.elementos.sigma_min_MPa, ...
       d.elementos.sigma_alternante_MPa, d.elementos.sigma_media_MPa, ...
       d.elementos.utilizacion];
  fid = fopen(rodfile, 'w');
  if fid < 0, error('No se pudo crear %s.', rodfile); end
  fprintf(fid, ['x_m,diametro_mm,Fmax_N,Fmin_N,sigma_max_MPa,' ...
    'sigma_min_MPa,sigma_alternante_MPa,sigma_media_MPa,utilizacion\n']);
  fclose(fid);
  dlmwrite(rodfile, R, '-append', 'delimiter', ',', 'precision', '%.12g');

  fid = fopen(installfile, 'w');
  if fid < 0, error('No se pudo crear %s.', installfile); end
  fprintf(fid, ['tramo,desde_m,hasta_m,longitud_m,diametro_mm,grado,' ...
    'longitud_comercial_m,varillas_completas,pony_rod_m,elementos,masa_kg\n']);
  plan = d.plan_instalacion_sarta;
  for i = 1:numel(plan)
    s = plan(i);
    fprintf(fid, '%d,%.12g,%.12g,%.12g,%.12g,%s,%.12g,%d,%.12g,%d,%.12g\n', ...
      s.indice, s.desde_m, s.hasta_m, s.longitud_m, s.diametro_mm, ...
      limpiar_csv(s.grado), s.longitud_comercial_m, ...
      s.cantidad_varillas_completas, s.ajuste_pony_rod_m, ...
      s.cantidad_elementos, s.masa_kg);
  end
  fclose(fid);

  A = [a.t_s, a.posicion_m, a.velocidad_m_s, a.aceleracion_m_s2, ...
       a.angulo_rad, v.torque_carga_kNm, v.torque_contrabalanceo_kNm, ...
       v.torque_neto_kNm, v.potencia_pr_kW, v.potencia_motor_kW];
  fid = fopen(unitfile, 'w');
  if fid < 0, error('No se pudo crear %s.', unitfile); end
  fprintf(fid, ['t_s,posicion_m,velocidad_m_s,aceleracion_m_s2,angulo_rad,' ...
    'torque_carga_kNm,torque_contrabalanceo_kNm,torque_neto_kNm,' ...
    'potencia_PR_kW,potencia_motor_kW\n']);
  fclose(fid);
  dlmwrite(unitfile, A, '-append', 'delimiter', ',', 'precision', '%.12g');

  fid = fopen(txtfile, 'w');
  if fid < 0, error('No se pudo crear %s.', txtfile); end
  fprintf(fid, 'version=%s\n', res.version);
  fprintf(fid, 'modelo=%s\n', res.modelo);
  fprintf(fid, 'pumping_unit_manufacturer=%s\n', res.param.pumping_unit_manufacturer);
  fprintf(fid, 'pumping_unit_model=%s\n', res.param.pumping_unit_model);
  fprintf(fid, 'pumping_unit_type=%s\n', res.param.pumping_unit_type);
  fprintf(fid, 'pumping_unit_kinematic_model=%s\n', res.param.pumping_unit_kinematic_model);
  fprintf(fid, 'pumping_unit_status=%s\n', v.estado);
  fprintf(fid, 'pumping_unit_pr_load_max_kN=%.12g\n', v.carga_pr_max_kN);
  fprintf(fid, 'pumping_unit_torque_max_kNm=%.12g\n', v.torque_max_abs_kNm);
  fprintf(fid, 'pumping_unit_torque_rms_kNm=%.12g\n', v.torque_rms_kNm);
  fprintf(fid, 'pumping_unit_power_max_kW=%.12g\n', v.potencia_motor_max_kW);
  fprintf(fid, 'pumping_unit_counterbalance_recommended_kNm=%.12g\n', ...
    v.contrabalanceo_recomendado_kNm);
  fprintf(fid, 'tuberia_anclada=%d\n', res.param.tuberia_anclada);
  if isfield(res, 'tuberia') && isstruct(res.tuberia)
    if isfield(res.tuberia, 'schema_signo')
      fprintf(fid, 'tubing_sign_schema=%s\n', res.tuberia.schema_signo);
    endif
    if isfield(res.tuberia, 'convencion_signo')
      fprintf(fid, 'tubing_sign_convention=%s\n', ...
        res.tuberia.convencion_signo);
    endif
    if isfield(res.tuberia, 'rigidez_axial_N_m')
      fprintf(fid, 'tubing_axial_stiffness_N_m=%.12g\n', ...
        res.tuberia.rigidez_axial_N_m);
    endif
  endif
  fprintf(fid, 'bomba_lpp=%d\n', res.param.bomba_lpp);
  fprintf(fid, 'rod_design_mode=%s\n', res.param.rod_design_mode);
  fprintf(fid, 'rod_design_candidate=%s\n', d.candidata_seleccionada);
  fprintf(fid, 'rod_design_reason=%s\n', d.motivo_seleccion);
  fprintf(fid, 'rod_grade_name=%s\n', res.param.rod_grade_name);
  fprintf(fid, 'rod_num_tramos=%d\n', numel(plan));
  fprintf(fid, 'rod_masa_total_kg=%.12g\n', d.masa_total_varillas_kg);
  fprintf(fid, 'sarta_utilizacion_goodman_max=%.12g\n', d.utilizacion_max);
  fprintf(fid, 'sarta_aprobada=%d\n', d.aprobada_fatiga);
  for i = 1:numel(plan)
    s = plan(i);
    fprintf(fid, 'rod_tramo_%d_desde_m=%.12g\n', i, s.desde_m);
    fprintf(fid, 'rod_tramo_%d_hasta_m=%.12g\n', i, s.hasta_m);
    fprintf(fid, 'rod_tramo_%d_longitud_m=%.12g\n', i, s.longitud_m);
    fprintf(fid, 'rod_tramo_%d_diametro_mm=%.12g\n', i, s.diametro_mm);
    fprintf(fid, 'rod_tramo_%d_grado=%s\n', i, s.grado);
    fprintf(fid, 'rod_tramo_%d_varillas_completas=%d\n', ...
      i, s.cantidad_varillas_completas);
    fprintf(fid, 'rod_tramo_%d_pony_rod_m=%.12g\n', i, s.ajuste_pony_rod_m);
  end

  b = d.barras_peso;
  fprintf(fid, 'weight_bar_result=%s\n', b.resultado_operativo);
  fprintf(fid, 'weight_bar_count=%d\n', max(b.cantidad_instalada,b.cantidad_recomendada));
  fprintf(fid, 'weight_bar_length_each_m=%.12g\n', b.longitud_unitaria_m);
  fprintf(fid, 'weight_bar_total_length_m=%.12g\n', ...
    max(b.cantidad_instalada,b.cantidad_recomendada)*b.longitud_unitaria_m);
  fprintf(fid, 'weight_bar_diameter_mm=%.12g\n', b.diametro_mm);
  fprintf(fid, 'weight_bar_mass_total_kg=%.12g\n', ...
    max(b.cantidad_instalada,b.cantidad_recomendada)*b.masa_unitaria_aire_kg);

  e = d.espaciamiento;
  fprintf(fid, 'spacing_mode=%s\n', e.modo);
  fprintf(fid, 'spacing_referencia=%s\n', e.referencia);
  fprintf(fid, 'spacing_lift_after_tagging_mm=%.12g\n', ...
    e.levantamiento_despues_sensar_mm);
  fprintf(fid, 'spacing_installation_tolerance_mm=%.12g\n', ...
    e.tolerancia_ejecucion_mm);
  fprintf(fid, 'spacing_clearance_inferior_m=%.12g\n', ...
    e.clearance_inferior_estimado_m);
  fprintf(fid, 'spacing_clearance_superior_m=%.12g\n', ...
    e.clearance_superior_estimado_m);
  fprintf(fid, 'spacing_estado=%s\n', e.estado);
  fprintf(fid, 'spacing_instruction_1=%s\n', e.instruccion_1);
  fprintf(fid, 'spacing_instruction_2=%s\n', e.instruccion_2);
  fprintf(fid, 'spacing_instruction_3=%s\n', e.instruccion_3);
  fprintf(fid, 'spacing_instruction_4=%s\n', e.instruccion_4);
  fprintf(fid, 'spacing_instruction_5=%s\n', e.instruccion_5);
  fprintf(fid, 'lpp_deltaP_max_Pa=%.12g\n', res.metricas.lpp_deltaP_max_Pa);
  fprintf(fid, 'lpp_carga_adicional_max_N=%.12g\n', ...
    res.metricas.lpp_carga_adicional_max_N);
  fclose(fid);

  escribir_json_local(jsonfile, res);
  archivos = {csvfile, rodfile, installfile, unitfile, txtfile, jsonfile};
end

function escribir_json_local(archivo, valor)
  if ~((exist('jsonencode', 'builtin') == 5) || (exist('jsonencode', 'file') == 2))
    error('GF3: GNU Octave requiere jsonencode para exportar el resultado completo.');
  endif
  texto = jsonencode(valor);
  fid = fopen(archivo, 'w');
  if fid < 0, error('No se pudo crear %s.', archivo); endif
  fprintf(fid, '%s\n', texto);
  fclose(fid);
end

function s = limpiar_csv(valor)
  [s, ok] = aos_texto_seguro(valor, '');
  if ~ok
    error('GF3: valor CSV no convertible a texto escalar.');
  endif
  s = strrep(s, ',', ' ');
  s = strrep(s, sprintf('\n'), ' ');
  s = strrep(s, sprintf('\r'), ' ');
  s = strtrim(s);
endfunction
