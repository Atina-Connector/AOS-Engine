function gibbs3_print(res)
% GIBBS3_PRINT Resumen operativo e instalable de la corrida GF3.

  m = res.metricas;
  fprintf('\n====================================================\n');
  fprintf(' AOS BM - GIBBS FOUNDATION 3 INTEGRAL\n');
  fprintf('====================================================\n');
  fprintf('Version                         : %s\n', res.version);
  fprintf('Modelo                          : %s\n', res.modelo);

  if isfield(res,'verificacion_aparato')
    a = res.verificacion_aparato;
    fprintf('\n--- APARATO DE BOMBEO ---\n');
    fprintf('Fabricante / modelo             : %s / %s\n', a.fabricante, a.modelo);
    fprintf('Tipo / cinematica               : %s / %s\n', a.tipo, a.modelo_cinematico);
    fprintf('Carrera / velocidad             : %.4f m / %.3f spm\n', ...
      a.carrera_operativa_m, a.spm);
    fprintf('Carga PR max/min                : %.3f / %.3f kN\n', ...
      a.carga_pr_max_kN, a.carga_pr_min_kN);
    fprintf('Torque max absoluto / RMS       : %.3f / %.3f kN.m\n', ...
      a.torque_max_abs_kNm, a.torque_rms_kNm);
    fprintf('Potencia motor max/media        : %.3f / %.3f kW\n', ...
      a.potencia_motor_max_kW, a.potencia_motor_media_kW);
    fprintf('Contrabalanceo recomendado      : %.3f kN.m; fase %.3f rad\n', ...
      a.contrabalanceo_recomendado_kNm, a.contrabalanceo_fase_recomendada_rad);
    fprintf('Estado capacidad                : %s\n', a.estado);
    imprimir_utilizacion('Carrera', a.utilizacion_carrera);
    imprimir_utilizacion('Velocidad', a.utilizacion_spm);
    imprimir_utilizacion('Carga PR', a.utilizacion_carga_pr);
    imprimir_utilizacion('Torque', a.utilizacion_torque);
    imprimir_utilizacion('Potencia', a.utilizacion_potencia);
  end

  fprintf('\n--- SISTEMA DE FONDO ---\n');
  fprintf('Condicion de tuberia            : %s\n', texto_anclaje(res.param.tuberia_anclada));
  fprintf('Tipo de bomba                   : %s\n', texto_bomba(res.param.bomba_lpp));
  fprintf('Carrera superficie              : %.4f m\n', m.carrera_superficie_m);
  fprintf('Carrera varilla en fondo        : %.4f m\n', m.carrera_varilla_fondo_m);
  fprintf('Movimiento tuberia en fondo     : %.4f m\n', m.movimiento_tuberia_fondo_m);
  fprintf('Elongacion maxima de tubing     : %.4f m\n', ...
    m.elongacion_tuberia_max_m);
  if isfield(res, 'tuberia') && isstruct(res.tuberia) && ...
      isfield(res.tuberia, 'convencion_signo')
    fprintf('Convencion de signo tubing      : %s\n', ...
      res.tuberia.convencion_signo);
  endif
  fprintf('Carrera piston relativa         : %.4f m\n', m.carrera_piston_relativa_m);
  fprintf('Transmision de carrera efectiva : %.2f %%\n', 100*m.transmision_carrera);
  fprintf('Velocidad PR maxima             : %.4f m/s\n', m.velocidad_PR_max_m_s);
  fprintf('Aceleracion PR maxima           : %.4f m/s2\n', m.aceleracion_PR_max_m_s2);
  fprintf('Carga superficie max/min        : %.3f / %.3f kN\n', ...
    m.carga_superficie_max_N/1000, m.carga_superficie_min_N/1000);
  fprintf('Carga bomba max/min             : %.3f / %.3f kN\n', ...
    m.carga_bomba_max_N/1000, m.carga_bomba_min_N/1000);
  fprintf('Caudal teorico bomba            : %.3f m3/d\n', m.caudal_teorico_bomba_m3_d);
  fprintf('Caudal estimado por llenado     : %.3f m3/d\n', m.caudal_estimado_m3_d);
  fprintf('Error periodicidad relativo     : %.5f [%s]\n', ...
    m.error_periodicidad_rel, ternario(m.periodicidad_aprobada, 'APROBADA', 'REVISAR'));

  if res.param.bomba_lpp
    fprintf('\n--- BOMBA LPP AESIR ---\n');
    fprintf('Longitud / ID interno piston    : %.3f m / %.2f mm\n', ...
      res.param.lpp_longitud_piston_m, res.param.lpp_id_piston_mm);
    fprintf('DeltaP LPP max                  : %.3f bar\n', m.lpp_deltaP_max_Pa/1e5);
    fprintf('Carga adicional LPP max         : %.3f kN\n', m.lpp_carga_adicional_max_N/1000);
    fprintf('Velocidad interna LPP max       : %.3f m/s\n', m.lpp_velocidad_interna_max_m_s);
  end

  if isfield(res, 'diseno_sarta_espaciamiento')
    d = res.diseno_sarta_espaciamiento;
    fprintf('\n====================================================\n');
    fprintf(' CONFIGURACION DE SARTA A INSTALAR\n');
    fprintf('====================================================\n');
    fprintf('Modo de diseno                  : %s\n', d.modo_sarta);
    fprintf('Candidata seleccionada          : %s\n', d.candidata_seleccionada);
    fprintf('Motivo de seleccion             : %s\n', d.motivo_seleccion);
    fprintf('Grado/material                  : %s\n', d.grado_sarta);
    fprintf('Profundidad de bomba            : %.2f m\n', res.param.D_bomba);
    fprintf('Cantidad de tramos              : %d\n', numel(d.plan_instalacion_sarta));
    fprintf('Longitud comercial varilla      : %.3f m\n', res.param.rod_longitud_comercial_m);
    fprintf('\nTramo  Desde MD  Hasta MD  Longitud  Diametro  Grado  Cantidad / ajuste\n');
    fprintf('-----  --------  --------  --------  --------  -----  -----------------\n');
    for i = 1:numel(d.plan_instalacion_sarta)
      s = d.plan_instalacion_sarta(i);
      ajuste = '';
      if s.ajuste_pony_rod_m > 1e-8
        ajuste = sprintf(' + pony %.2f m', s.ajuste_pony_rod_m);
      end
      fprintf('%5d  %8.1f  %8.1f  %8.1f  %8.1f  %-10s  %d completas%s\n', ...
        s.indice, s.desde_m, s.hasta_m, s.longitud_m, s.diametro_mm, ...
        s.grado, s.cantidad_varillas_completas, ajuste);
    end
    fprintf('Masa total de varillas          : %.1f kg\n', d.masa_total_varillas_kg);
    fprintf('Utilizacion Goodman maxima      : %.3f [%s]\n', ...
      d.utilizacion_max, ternario(d.aprobada_fatiga, 'VERDE', 'REVISAR'));
    fprintf('Elemento critico                : %d\n', d.elemento_critico);

    imprimir_candidatos(d);
    imprimir_barras_peso(d.barras_peso, res);
    imprimir_espaciamiento(d.espaciamiento, res.param);
  end

  fprintf('\nGraficas                        : 3 ventanas GF3\n');
  fprintf('  1) cartas, transmision y cargas\n');
  fprintf('  2) sarta instalable, barras de peso y espaciamiento\n');
  fprintf('  3) posicion, velocidad, aceleracion y torque del aparato\n');
end

function imprimir_candidatos(d)
  if ~isfield(d,'candidatos') || ~isstruct(d.candidatos) || isempty(d.candidatos)
    return;
  end
  fprintf('\n--- CANDIDATAS EVALUADAS ---\n');
  for i = 1:numel(d.candidatos)
    c = d.candidatos(i);
    estado = 'PRELIMINAR';
    util = c.utilizacion_estimada_max;
    if isfield(c,'verificacion_GF3_ok') && c.verificacion_GF3_ok
      util = c.utilizacion_dinamica_max;
      estado = ternario(c.aprobada_dinamica, 'APROBADA_GF3', 'REVISAR_GF3');
    end
    fprintf('%2d - %-28s | tramos %d | masa %.0f kg | Goodman %.3f | %s\n', ...
      i, c.nombre, numel(c.secciones), c.masa_total_kg, util, estado);
  end
end

function imprimir_barras_peso(b, res)
  fprintf('\n====================================================\n');
  fprintf(' BARRAS DE PESO A INSTALAR\n');
  fprintf('====================================================\n');
  fprintf('Resultado                        : %s\n', b.resultado_operativo);
  if b.instalar || b.cantidad_instalada > 0
    nmostrar = max(b.cantidad_instalada, b.cantidad_recomendada);
    fprintf('Cantidad                         : %d barras\n', nmostrar);
    fprintf('Longitud por barra               : %.2f m\n', b.longitud_unitaria_m);
    fprintf('Longitud total instalada         : %.2f m\n', nmostrar*b.longitud_unitaria_m);
    fprintf('Diametro exterior                : %.1f mm\n', b.diametro_mm);
    fprintf('Masa unitaria en aire            : %.1f kg\n', b.masa_unitaria_aire_kg);
    fprintf('Masa total en aire               : %.1f kg\n', nmostrar*b.masa_unitaria_aire_kg);
    fprintf('Peso aparente total en fluido    : %.2f kN\n', ...
      nmostrar*b.peso_aparente_unitario_N/1000);
    fprintf('Ubicacion                        : inmediatamente sobre la bomba\n');
    fprintf('Longitud teorica requerida       : %.2f m\n', b.longitud_teorica_requerida_m);
    fprintf('Fuerza descendente requerida     : %.3f kN\n', b.fuerza_requerida_N/1000);
    fprintf('Componente LPP                   : %.3f kN\n', b.componente_LPP_N/1000);
    fprintf('Integradas en corrida final GF3  : %s\n', ...
      ternario(isfield(res,'barras_peso_integradas') && res.barras_peso_integradas, 'SI', 'NO'));
    if isfield(b,'cantidad_requerida_postverificacion')
      fprintf('Cantidad requerida postverif.    : %d\n', ...
        b.cantidad_requerida_postverificacion);
      fprintf('Verificacion de cantidad         : %s\n', ...
        ternario(b.verificacion_instalacion, 'APROBADA', 'REVISAR'));
    end
  end
end

function imprimir_espaciamiento(e, p)
  fprintf('\n====================================================\n');
  fprintf(' ESPACIAMIENTO RECOMENDADO\n');
  fprintf('====================================================\n');
  fprintf('Modelo                          : %s\n', ...
    campo_txt_spacing(e, 'modelo', 'NO_ESPECIFICADO'));
  fprintf('Modo / referencia               : %s / %s\n', ...
    campo_txt_spacing(e, 'modo', 'NO_CONFIGURADO'), ...
    campo_txt_spacing(e, 'referencia', 'NO_ESPECIFICADA'));
  fprintf('Condicion termica al sensar     : %s\n', ...
    campo_txt_spacing(e, 'condicion_termica_sensado', 'NO_ESPECIFICADA'));
  fprintf('Estado geometrico               : %s\n', ...
    campo_txt_spacing(e, 'estado', 'NO_EVALUADO'));
  fprintf('Validacion                      : %s\n', ...
    campo_txt_spacing(e, 'validacion', 'NO_DISPONIBLE'));

  fprintf('\nINFORMACION ABSOLUTA (NO SE SUMA):\n');
  fprintf('Elongacion absoluta equilibrio  : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'elongacion_absoluta_equilibrio_m', NaN));
  fprintf('Elongacion por peso propio      : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'elongacion_absoluta_peso_propio_m', NaN));
  fprintf('Ya presente al sensar fondo     : %s\n', ...
    ternario(campo_bool_spacing(e, 'peso_propio_ya_incluido_al_sensar', false), ...
      'SI', 'NO'));
  fprintf('Contribucion peso propio        : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'contribucion_peso_propio_al_levantamiento_m', NaN));

  fprintf('\nCOMPONENTES DIFERENCIALES DEL LEVANTAMIENTO:\n');
  fprintf('Clearance inferior objetivo     : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'clearance_inferior_objetivo_m', ...
      p.spacing_clearance_inferior_m));
  fprintf('Elongacion adicional por carga  : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'elongacion_diferencial_carga_m', NaN));
  fprintf('Movimiento diferencial tubing   : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'movimiento_diferencial_tubing_m', NaN));
  fprintf('Correccion dinamica residual    : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'correccion_dinamica_m', NaN));
  fprintf('Expansion termica dif. varillas : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'expansion_termica_diferencial_varillas_m', NaN));
  fprintf('Expansion termica dif. tubing   : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'expansion_termica_diferencial_tuberia_m', NaN));
  fprintf('Correccion termica neta         : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'correccion_termica_neta_m', NaN));
  fprintf('Correccion neta requerida       : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'correccion_requerida_m', NaN));
  fprintf('Margen adicional instalacion    : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'margen_instalacion_m', ...
      p.spacing_margen_instalacion_m));

  fprintf('\nRESULTADO OPERATIVO:\n');
  fprintf('Levantamiento luego de sensar   : %.0f mm\n', ...
    campo_num_spacing(e, 'levantamiento_despues_sensar_mm', NaN));
  fprintf('Tolerancia de ejecucion         : +/- %.0f mm\n', ...
    campo_num_spacing(e, 'tolerancia_ejecucion_mm', NaN));
  fprintf('Clearance inferior nominal      : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'clearance_inferior_estimado_m', NaN));
  fprintf('Clearance inferior peor caso    : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'clearance_inferior_peor_caso_m', NaN));
  fprintf('Clearance superior nominal      : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'clearance_superior_estimado_m', NaN));
  fprintf('Clearance superior peor caso    : %.1f mm\n', ...
    1000*campo_num_spacing(e, 'clearance_superior_peor_caso_m', NaN));

  if campo_bool_spacing(e, 'capacidad_ajuste_informada', false)
    fprintf('Levantamiento maximo disponible : %.0f mm\n', ...
      1000*campo_num_spacing(e, 'levantamiento_maximo_disponible_m', NaN));
    fprintf('Capacidad de ajuste             : %s\n', ...
      ternario(campo_bool_spacing(e, 'capacidad_ajuste_aprobada', false), ...
        'APROBADA', 'EXCEDIDA'));
  else
    fprintf('Capacidad de ajuste             : NO INFORMADA\n');
  end

  fprintf('\nINSTRUCCION DE CAMPO:\n');
  fprintf('  1. %s\n', campo_txt_spacing(e, 'instruccion_1', 'NO DISPONIBLE'));
  fprintf('  2. %s\n', campo_txt_spacing(e, 'instruccion_2', 'NO DISPONIBLE'));
  fprintf('  3. %s\n', campo_txt_spacing(e, 'instruccion_3', 'NO DISPONIBLE'));
  fprintf('  4. %s\n', campo_txt_spacing(e, 'instruccion_4', 'NO DISPONIBLE'));
  fprintf('  5. %s\n', campo_txt_spacing(e, 'instruccion_5', 'NO DISPONIBLE'));
  if p.tuberia_anclada
    fprintf('Nota: no confundir la fijacion de la grampa con el ancla de tubing.\n');
  end
end

function v = campo_num_spacing(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if isnumeric(x) && isscalar(x), v = x; end
  end
end

function v = campo_txt_spacing(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if ischar(x), v = x; end
  end
end

function v = campo_bool_spacing(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
    x = s.(campo);
    if islogical(x) || (isnumeric(x) && isscalar(x))
      v = logical(x);
    end
  end
end

function imprimir_utilizacion(nombre, valor)
  if isfinite(valor)
    fprintf('Utilizacion %-18s : %.1f %%\n', nombre, 100*valor);
  else
    fprintf('Utilizacion %-18s : NO EVALUADA\n', nombre);
  end
end

function s = ternario(tf, a, b)
  if tf, s = a; else, s = b; end
end

function s = texto_anclaje(v)
  if v, s = 'ANCLADA'; else, s = 'LIBRE'; end
end

function s = texto_bomba(v)
  if v, s = 'LPP AESIR'; else, s = 'CONVENCIONAL'; end
end
