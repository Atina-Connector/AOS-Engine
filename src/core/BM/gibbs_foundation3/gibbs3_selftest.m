function ok = gibbs3_selftest()
% GIBBS3_SELFTEST Prueba integral convencional, LPP y aparato.

  ok = false;
  try
    p = caso_base();
    r1 = gibbs3_run_case(p, struct('graficar', false, ...
      'imprimir', false, 'validar', true));
    e1 = r1.diseno_sarta_espaciamiento.espaciamiento;
    cond1 = r1.validacion.ok && all(isfinite(r1.U(:))) && ...
      r1.metricas.carrera_bomba_m > 0 && ...
      isfield(r1, 'diseno_sarta_espaciamiento') && ...
      isfield(e1, 'valido_calculo') && logical(e1.valido_calculo) && ...
      isfield(e1, 'mensaje_validacion') && ...
      isfield(r1, 'verificacion_aparato') && ...
      isfinite(r1.verificacion_aparato.torque_max_abs_kNm);

    p.bomba_lpp = 1;
    p.gibbs3_config_lpp_confirmada = 1;
    p.lpp_longitud_piston_m = 1.5;
    p.lpp_id_piston_mm = 20;
    p.viscosidad_fluido_cP = 8;
    r2 = gibbs3_run_case(p, struct('graficar', false, ...
      'imprimir', false, 'validar', true));
    e2 = r2.diseno_sarta_espaciamiento.espaciamiento;
    cond2 = r2.validacion.ok && ...
      isfield(e2, 'valido_calculo') && logical(e2.valido_calculo) && ...
      r2.metricas.lpp_carga_adicional_max_N >= 0 && ...
      strcmp(e2.referencia, 'PISTON_LPP');

    p.bomba_lpp = 0;
    p.pumping_unit_kinematic_model = 'linkage_conventional';
    c = gibbs3_pumping_unit_cycle(p, linspace(0,60/p.N_velocidad,181)');
    cond3 = all(isfinite(c.posicion_m)) && ...
      max(c.posicion_m)-min(c.posicion_m) > 0.99*p.S_carrera;

    % Prueba especifica de signo para tubing libre. Durante la toma de
    % carga, F=k*x debe mostrar rigidez positiva en la carta de fondo.
    pt = gibbs3_defaults(struct('D_bomba', 1000, ...
      'longitud_tuberia_m', 1000, 'tuberia_anclada', 0));
    Ft = [0; 1000; 2000; 1000; 0];
    tub = gibbs3_tubing_motion(pt, Ft);
    urod = zeros(size(Ft));
    urel = urod - tub.u_fondo_m;
    pendiente = diff(Ft(1:3)) ./ diff(urel(1:3));
    k_teorica = pt.E_tuberia_Pa * tub.area_metal_m2 / tub.longitud_m;
    cond4 = all(tub.elongacion_m >= -1e-12) && ...
      max(abs(tub.u_fondo_m + tub.elongacion_m)) < 1e-12 && ...
      all(pendiente > 0) && ...
      max(abs(pendiente-k_teorica))/max(k_teorica,eps) < 1e-10;

    pt.tuberia_anclada = 1;
    tub_a = gibbs3_tubing_motion(pt, Ft);
    cond5 = all(abs(tub_a.elongacion_m) < 1e-12) && ...
      all(abs(tub_a.u_fondo_m) < 1e-12);

    ok = cond1 && cond2 && cond3 && cond4 && cond5;
    if ~cond1
      fprintf(2, 'GF3 SELFTEST DETALLE: caso convencional no aprobado.\n');
      imprimir_validacion_local(r1);
    endif
    if ~cond2
      fprintf(2, 'GF3 SELFTEST DETALLE: caso LPP no aprobado.\n');
      imprimir_validacion_local(r2);
    endif
    if ~cond3
      fprintf(2, 'GF3 SELFTEST DETALLE: cinematica linkage no cubre la carrera esperada.\n');
    endif
    if ~cond4
      fprintf(2, 'GF3 SELFTEST DETALLE: contrato de signo/rigidez de tubing libre invalido.\n');
    endif
    if ~cond5
      fprintf(2, 'GF3 SELFTEST DETALLE: tubing anclado presenta movimiento no nulo.\n');
    endif
  catch err
    fprintf(2, 'GF3 SELFTEST ERROR: %s\n', err.message);
  end

  if ok
    fprintf('GF3 SELFTEST INTEGRAL: APROBADO\n');
  else
    fprintf(2, 'GF3 SELFTEST INTEGRAL: NO APROBADO\n');
  end
end

function imprimir_validacion_local(r)
  if isstruct(r) && isfield(r, 'validacion') && ...
      isstruct(r.validacion) && isfield(r.validacion, 'mensajes')
    m = r.validacion.mensajes;
    if ischar(m), m = {m}; endif
    if iscell(m)
      for i = 1:numel(m)
        if ischar(m{i}), fprintf(2, '  - %s\n', m{i}); endif
      endfor
    endif
  endif
  if isstruct(r) && isfield(r, 'diseno_sarta_espaciamiento') && ...
      isfield(r.diseno_sarta_espaciamiento, 'espaciamiento')
    e = r.diseno_sarta_espaciamiento.espaciamiento;
    if isfield(e, 'estado'), fprintf(2, '  spacing estado: %s\n', e.estado); endif
    if isfield(e, 'mensaje_validacion')
      fprintf(2, '  spacing: %s\n', e.mensaje_validacion);
    elseif isfield(e, 'validacion')
      fprintf(2, '  spacing: %s\n', e.validacion);
    endif
  endif
endfunction

function p = caso_base()
  p = struct();
  p.D_bomba = 300;
  p.D_bomba_TVD = 300;
  p.D_bomba_mm = 32;
  p.S_carrera = 1.0;
  p.N_velocidad = 6;
  p.WC = 0.4;
  p.rho_o = 860;
  p.rho_w = 1010;
  p.P_wh = 8e5;
  p.P_intake = 2.5e5;
  p.eta_vol = 0.82;
  p.viscosidad_fluido_cP = 8;
  p.gibbs3_n_nodos = 21;
  p.gibbs3_n_ciclos = 3;
  p.gibbs3_descartar_ciclos = 1;
  p.gibbs3_puntos_por_ciclo = 180;
  p.gibbs3_oversampling = 1;
  p.gibbs3_delta_damping = 0.10;
  p.pumping_unit_configured = 1;
  p.pumping_unit_config_confirmada = 1;
  p.pumping_unit_mode = 'selftest';
  p.pumping_unit_model = 'SELFTEST_CONV';
  p.pumping_unit_type = 'Convencional';
  p.pumping_unit_kinematic_model = 'perfil_convencional_representativo';
  p.pumping_unit_stroke_max_m = 2.0;
  p.pumping_unit_spm_min = 1;
  p.pumping_unit_spm_max = 12;
  p.pumping_unit_max_pr_load_kN = 200;
  p.pumping_unit_gearbox_torque_kNm = 100;
  p.pumping_unit_motor_power_kW = 100;
  p.gibbs3_config_lpp_confirmada = 1;
  p.rod_design_configured = 1;
  p.rod_design_mode = 'uniforme_selftest';
  p.spacing_configured = 1;
  p.spacing_mode = 'automatico';
  p = gibbs3_defaults(p);
  mat = struct('nombre', 'Acero Grado D', 'rho_kg_m3', 7850, ...
    'E_Pa', 210e9, 'Se_MPa', 280, 'Sut_MPa', 793, 'Sy_MPa', 550);
  s = struct('longitud_m', p.D_bomba, 'diametro_mm', 22.2, ...
    'E_Pa', mat.E_Pa, 'rho_kg_m3', mat.rho_kg_m3, ...
    'grado', mat.nombre, 'Se_MPa', mat.Se_MPa, ...
    'Sut_MPa', mat.Sut_MPa, 'Sy_MPa', mat.Sy_MPa);
  p.gibbs3_secciones_varillas = s;
end
