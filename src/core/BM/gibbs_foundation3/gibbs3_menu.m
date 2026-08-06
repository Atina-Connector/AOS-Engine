function gibbs3_menu()
% GIBBS3_MENU Flujo operativo integral GF3.

  fprintf('\n====================================================\n');
  fprintf(' BM - GIBBS FOUNDATION 3 v1.8 SIGNO TUBERIA LIBRE\n');
  fprintf(' Aparato + sarta + tubing libre con signo fisico + spacing seguro\n');
  fprintf('====================================================\n');

  global CONFIG_ACTIVA
  if isstruct(CONFIG_ACTIVA) && ~isempty(fieldnames(CONFIG_ACTIVA))
    base = CONFIG_ACTIVA;
    origen = '.aosdat/configuracion activa';
  else
    try
      [base, origen_base] = aos_config_base('BM');
      origen = ['configuracion base: ' origen_base];
    catch
      base = struct();
      origen = 'defaults GF3';
    end
  end
  base = gibbs3_defaults(gibbs3_normalize_aos(base));
  param = base;
  if ~isempty(param.gibbs3_secciones_varillas)
    param.rod_design_configured = 1;
    if strcmpi(param.rod_design_mode, 'no_configurado')
      param.rod_design_mode = 'aosdat_existente';
    end
  end

  fprintf('Origen: %s\n', origen);
  while true
    mostrar_parametros(param);
    fprintf('\n  1 - Ejecutar caso actual\n');
    fprintf('  2 - Seleccionar / configurar aparato de bombeo\n');
    fprintf('  3 - Seleccionar bomba convencional / LPP AESIR\n');
    fprintf('  4 - Configurar / disenar sarta y barras de peso\n');
    fprintf('  5 - Configurar espaciamiento\n');
    fprintf('  6 - Editar parametros operativos y tubing\n');
    fprintf('  7 - Editar discretizacion y amortiguamiento\n');
    fprintf('  8 - Editar borde de bomba y valvula\n');
    fprintf('  9 - Restaurar configuracion activa\n');
    fprintf(' 10 - Ejecutar autoprueba GF3 integral\n');
    fprintf(' 11 - Generar informe del ultimo resultado GF3\n');
    fprintf('  0 - Volver\n');
    op = input('Seleccione opcion [1]: ');
    if isempty(op), op = 1; end

    switch op
      case 0
        return;
      case 1
        [param, listo] = preparar_caso(param);
        if ~listo
          fprintf('Ejecucion cancelada: falta completar la configuracion.\n');
          continue;
        end
        try
          opciones = struct('graficar', true, 'imprimir', true, 'validar', true);
          res = gibbs3_run_case(param, opciones);
          res = gibbs3_upgrade_result_schema(res);
          assignin('base', 'GF3_ULTIMO_RESULTADO', res);
          fprintf('Resultado disponible en GF3_ULTIMO_RESULTADO.\n');
          % La oferta de informe es transversal y obligatoria despues de
          % toda corrida exitosa. El usuario puede elegir no exportar.
          try
            reporte = generar_informe_local(res);
            assignin('base', 'GF3_ULTIMO_REPORTE', reporte);
          catch err_reporte
            fprintf(2, 'ERROR INFORME AOS: %s\n', err_reporte.message);
            imprimir_stack(err_reporte);
          end
        catch err
          fprintf(2, 'ERROR GF3: %s\n', err.message);
          imprimir_stack(err);
        end
      case 2
        [param, ok] = gibbs3_pumping_unit_menu(param);
        if ok
          param.rod_design_configured = 0;
          param.spacing_configured = 0;
        end
      case 3
        [param, ok] = gibbs3_lpp_menu(param);
        if ok
          param.rod_design_configured = 0;
          param.spacing_configured = 0;
        end
      case 4
        [param, ~] = gibbs3_rod_design_menu(param);
      case 5
        [param, ~] = gibbs3_spacing_menu(param);
      case 6
        param = editar_operacion(param);
      case 7
        param = editar_numerico(param);
      case 8
        param = editar_bomba(param);
      case 9
        param = base;
        fprintf('Configuracion restaurada.\n');
      case 10
        gibbs3_selftest();
      case 11
        try
          res_ultimo = evalin('base', 'GF3_ULTIMO_RESULTADO');
          if ~isstruct(res_ultimo)
            error('GF3_ULTIMO_RESULTADO no contiene un resultado valido.');
          end
          [res_ultimo, cambios] = gibbs3_upgrade_result_schema(res_ultimo);
          cambios_spacing = {};
          if exist('gibbs3_repair_spacing_result', 'file') == 2
            [res_ultimo, cambios_spacing] = gibbs3_repair_spacing_result(res_ultimo);
          end
          assignin('base', 'GF3_ULTIMO_RESULTADO', res_ultimo);
          if ~isempty(cambios) || ~isempty(cambios_spacing)
            fprintf('Resultado GF3 anterior actualizado al esquema instalable y spacing seguro.\n');
          end
          reporte = generar_informe_local(res_ultimo);
          assignin('base', 'GF3_ULTIMO_REPORTE', reporte);
        catch err_reporte
          fprintf(2, 'No se pudo generar el informe del ultimo resultado: %s\n', ...
            err_reporte.message);
          imprimir_stack(err_reporte);
        end
      otherwise
        fprintf('Opcion no valida.\n');
    end
  end
end

function [p, listo] = preparar_caso(p)
  listo = false;
  if ~logical(p.pumping_unit_config_confirmada) || ...
      ~logical(p.pumping_unit_configured)
    fprintf('\nAntes de simular debe seleccionarse el aparato de bombeo.\n');
    [p, ok] = gibbs3_pumping_unit_menu(p);
    if ~ok, return; end
  end
  if ~logical(p.gibbs3_config_lpp_confirmada)
    fprintf('\nDebe confirmarse si la bomba es convencional o LPP AESIR.\n');
    [p, ok] = gibbs3_lpp_menu(p);
    if ~ok, return; end
  end
  if ~logical(p.rod_design_configured)
    fprintf('\nLa sarta aun no fue configurada.\n');
    [p, ok] = gibbs3_rod_design_menu(p);
    if ~ok, return; end
  end
  if ~logical(p.spacing_configured)
    fprintf('\nEl espaciamiento aun no fue configurado.\n');
    [p, ok] = gibbs3_spacing_menu(p);
    if ~ok, return; end
  end
  listo = true;
end

function reporte = generar_informe_local(res)
  contexto = gibbs3_report_context(res);
  reporte = aos_report_dispatcher(contexto);
end

function mostrar_parametros(p)
  fprintf('\n--- CONFIGURACION GF3 ---\n');
  fprintf('Profundidad bomba MD       : %.3f m\n', p.D_bomba);
  if isfinite(p.D_bomba_TVD)
    fprintf('Profundidad bomba TVD      : %.3f m\n', p.D_bomba_TVD);
  end
  fprintf('Aparato                    : %s / %s [%s]\n', ...
    p.pumping_unit_type, p.pumping_unit_model, texto_config(p.pumping_unit_configured));
  fprintf('Cinematica                 : %s\n', p.pumping_unit_kinematic_model);
  fprintf('Bomba / carrera / velocidad: %.2f mm / %.3f m / %.3f spm\n', ...
    p.D_bomba_mm, p.S_carrera, p.N_velocidad);
  fprintf('Tuberia                    : %s; OD/ID %.1f/%.1f mm\n', ...
    texto_anclaje(p.tuberia_anclada), p.OD_tuberia_mm, p.ID_tuberia_mm);
  fprintf('Tipo de bomba de fondo     : %s [%s]\n', ...
    texto_bomba(p.bomba_lpp), texto_config(p.gibbs3_config_lpp_confirmada));
  fprintf('Sarta                      : %s [%s]\n', ...
    p.rod_design_mode, texto_config(p.rod_design_configured));
  fprintf('Candidata de sarta         : %s\n', p.rod_design_candidate_name);
  fprintf('Material base              : %s\n', p.rod_grade_name);
  fprintf('Varilla comercial          : %.2f m\n', p.rod_longitud_comercial_m);
  fprintf('Barra de peso comercial    : %.2f m x %.1f mm\n', ...
    p.barras_peso_longitud_unitaria_m, p.barras_peso_diametro_mm);
  fprintf('Espaciamiento              : %s [%s]\n', ...
    p.spacing_mode, texto_config(p.spacing_configured));
  fprintf('Nodos / ciclos / puntos    : %d / %d / %d\n', ...
    p.gibbs3_n_nodos, p.gibbs3_n_ciclos, p.gibbs3_puntos_por_ciclo);
end

function p = editar_operacion(p)
  p.D_bomba = leer('Profundidad bomba MD (m)', p.D_bomba);
  p.D_bomba_mm = leer('Diametro bomba (mm)', p.D_bomba_mm);
  p.S_carrera = leer('Carrera superficial (m)', p.S_carrera);
  p.N_velocidad = leer('Velocidad (spm)', p.N_velocidad);
  p.WC = leer('Water cut (0-1)', p.WC);
  p.P_wh = 1e5*leer('Presion cabeza (bar)', p.P_wh/1e5);
  p.P_intake = 1e5*leer('Presion intake (bar)', presion_bar(p));
  p.eta_vol = leer('Eficiencia/llenado (0-1.2)', p.eta_vol);
  p.gibbs3_llenado_bomba = p.eta_vol;
  p.tuberia_anclada = round(leer('Tuberia anclada (1=si,0=libre)', p.tuberia_anclada));
  p.OD_tuberia_mm = leer('OD tuberia (mm)', p.OD_tuberia_mm);
  p.ID_tuberia_mm = leer('ID tuberia (mm)', p.ID_tuberia_mm);
  p.E_tuberia_Pa = 1e9*leer('Modulo elastico tuberia (GPa)', p.E_tuberia_Pa/1e9);
  p.longitud_piston_m = leer('Longitud piston convencional (m)', p.longitud_piston_m);
  p.holgura_radial_mm = leer('Holgura radial piston-barril (mm)', p.holgura_radial_mm);
  p.temperatura_fondo_C = leer('Temperatura fondo (C)', p.temperatura_fondo_C);
  mu = leer('Viscosidad fluido cP (0=estimar)', valor_viscosidad(p));
  if mu > 0
    p.viscosidad_fluido_cP = mu;
  end
  try
    p = aos_bm_propiedades_fluido(p);
  catch
  end
  p.pumping_unit_configured = 0;
  p.pumping_unit_config_confirmada = 0;
  p.rod_design_configured = 0;
  p.spacing_configured = 0;
end

function p = editar_numerico(p)
  p.gibbs3_n_nodos = round(leer('Cantidad de nodos', p.gibbs3_n_nodos));
  p.gibbs3_n_ciclos = round(leer('Ciclos simulados', p.gibbs3_n_ciclos));
  p.gibbs3_descartar_ciclos = round(leer('Ciclos descartados', p.gibbs3_descartar_ciclos));
  p.gibbs3_puntos_por_ciclo = round(leer('Puntos por ciclo', p.gibbs3_puntos_por_ciclo));
  p.gibbs3_oversampling = round(leer('Oversampling', p.gibbs3_oversampling));
  p.gibbs3_cfl = leer('Factor CFL', p.gibbs3_cfl);
  p.gibbs3_delta_damping = leer('Delta damping', p.gibbs3_delta_damping);
end

function p = editar_bomba(p)
  p.gibbs3_friccion_ascenso_N = leer('Friccion ascenso (N)', p.gibbs3_friccion_ascenso_N);
  p.gibbs3_friccion_descenso_N = leer('Friccion descenso (N)', p.gibbs3_friccion_descenso_N);
  p.gibbs3_velocidad_transicion_valvula_m_s = leer( ...
    'Velocidad transicion valvula (m/s)', p.gibbs3_velocidad_transicion_valvula_m_s);
  p.gibbs3_constante_tiempo_valvula_s = leer( ...
    'Constante de tiempo valvula (s)', p.gibbs3_constante_tiempo_valvula_s);
  p.rod_design_configured = 0;
  p.spacing_configured = 0;
end

function v = leer(etiqueta, actual)
  x = input(sprintf('%s [%.6g]: ', etiqueta, actual));
  if isempty(x), v = actual; else, v = x; end
end

function b = presion_bar(p)
  if isfinite(p.P_intake), b = p.P_intake/1e5; else, b = p.P_intake_min/1e5; end
end

function v = valor_viscosidad(p)
  if isfinite(p.viscosidad_fluido_cP), v = p.viscosidad_fluido_cP; else, v = 0; end
end

function s = texto_anclaje(v)
  if v, s = 'ANCLADA'; else, s = 'LIBRE'; end
end

function s = texto_bomba(v)
  if v, s = 'LPP AESIR'; else, s = 'CONVENCIONAL'; end
end

function s = texto_config(v)
  if v, s = 'CONFIGURADO'; else, s = 'PENDIENTE'; end
end

function imprimir_stack(err)
  if isfield(err, 'stack')
    for k = 1:numel(err.stack)
      fprintf(2, '  en %s, linea %d\n', err.stack(k).file, err.stack(k).line);
    end
  end
end
