function [p, ok] = gibbs3_spacing_menu(p)
% GIBBS3_SPACING_MENU Configuracion del espaciamiento diferencial.
%
% El calculo compara el estado al sensar fondo con el estado operativo.
% La elongacion absoluta por peso propio no se suma nuevamente.

  p = gibbs3_defaults(p);
  ok = false;

  fprintf('\n====================================================\n');
  fprintf(' GF3 - CONFIGURACION DE ESPACIAMIENTO DIFERENCIAL\n');
  fprintf('====================================================\n');
  if p.bomba_lpp
    fprintf('Referencia geometrica: PISTON LPP AESIR\n');
    fprintf('Longitud disponible actual: %.3f m\n', p.lpp_longitud_piston_m);
  else
    fprintf('Referencia geometrica: BARRIL CONVENCIONAL\n');
    fprintf('Longitud util actual del barril: %.3f m\n', p.longitud_barril_util_m);
  end
  fprintf(['\nEl levantamiento se calcula entre el estado de sensado y la ' ...
    'operacion.\n']);
  fprintf(['La elongacion por peso propio ya presente al sensar se informa, ' ...
    'pero no se suma.\n']);

  fprintf('\n  1 - Calculo automatico diferencial\n');
  fprintf('  2 - Ingresar levantamiento de superficie manual\n');
  fprintf('  3 - Evaluar el valor manual actual\n');
  fprintf('  0 - Cancelar\n');
  op = input('Seleccione opcion [1]: ');
  if isempty(op), op = 1; end
  if op == 0, return; end

  if p.bomba_lpp
    p.lpp_longitud_piston_m = leer_numero( ...
      'Longitud del piston LPP que define la carrera disponible (m)', ...
      p.lpp_longitud_piston_m);
  else
    p.longitud_barril_util_m = leer_numero( ...
      'Longitud util del barril convencional (m)', ...
      p.longitud_barril_util_m);
  end

  p.spacing_clearance_inferior_m = leer_numero( ...
    'Clearance inferior objetivo (m)', p.spacing_clearance_inferior_m);
  p.spacing_clearance_superior_m = leer_numero( ...
    'Clearance superior objetivo (m)', p.spacing_clearance_superior_m);
  p.spacing_margen_instalacion_m = leer_numero( ...
    'Margen adicional de instalacion (m)', p.spacing_margen_instalacion_m);
  p.spacing_tolerancia_ejecucion_m = leer_numero( ...
    'Tolerancia de ejecucion en campo (m)', p.spacing_tolerancia_ejecucion_m);
  p.spacing_redondeo_mm = leer_numero( ...
    'Incremento de redondeo hacia arriba (mm)', p.spacing_redondeo_mm);

  p.temperatura_superficie_C = leer_numero( ...
    'Temperatura de superficie en operacion (C)', p.temperatura_superficie_C);
  p.temperatura_fondo_C = leer_numero( ...
    'Temperatura de fondo en operacion (C)', p.temperatura_fondo_C);

  fprintf('\nCONDICION TERMICA AL SENSAR FONDO\n');
  fprintf('  1 - Sarta termicamente estabilizada [recomendado]\n');
  fprintf('  2 - Sarta en condicion fria; integrar perfil lineal\n');
  fprintf('  3 - Ingresar correccion termica diferencial manual\n');
  opt = input('Seleccione condicion [1]: ');
  if isempty(opt), opt = 1; end
  switch opt
    case 1
      p.spacing_condicion_termica_sensado = 'estabilizada';
      p.spacing_correccion_termica_manual_m = 0.0;
    case 2
      p.spacing_condicion_termica_sensado = 'fria';
      p.spacing_temperatura_sensado_superficie_C = leer_numero( ...
        'Temperatura de la sarta en superficie al sensar (C)', ...
        p.spacing_temperatura_sensado_superficie_C);
      p.spacing_temperatura_sensado_fondo_C = leer_numero( ...
        'Temperatura de la sarta en fondo al sensar (C)', ...
        p.spacing_temperatura_sensado_fondo_C);
    case 3
      p.spacing_condicion_termica_sensado = 'manual';
      p.spacing_correccion_termica_manual_m = leer_numero( ...
        ['Correccion termica neta operacion menos sensado ' ...
         '(m; positiva baja el piston)'], ...
        p.spacing_correccion_termica_manual_m);
    otherwise
      fprintf('Opcion termica no valida. Se usa estabilizada.\n');
      p.spacing_condicion_termica_sensado = 'estabilizada';
      p.spacing_correccion_termica_manual_m = 0.0;
  end

  cap = p.spacing_levantamiento_maximo_disponible_m;
  if ~isfinite(cap) || cap <= 0, cap = 0.0; end
  cap = leer_numero( ...
    'Levantamiento maximo disponible en vastago/grampa (m; 0=no informado)', ...
    cap);
  if cap > 0
    p.spacing_levantamiento_maximo_disponible_m = cap;
  else
    p.spacing_levantamiento_maximo_disponible_m = NaN;
  end

  switch op
    case 1
      p.spacing_mode = 'automatico';
      p.spacing_offset_manual_m = NaN;
    case 2
      p.spacing_mode = 'manual';
      actual = p.spacing_offset_manual_m;
      if ~isfinite(actual), actual = 0.20; end
      p.spacing_offset_manual_m = leer_numero( ...
        'Levantamiento aplicado luego de sensar fondo (m)', actual);
    case 3
      p.spacing_mode = 'evaluacion';
      if ~isfinite(p.spacing_offset_manual_m)
        actual = leer_numero( ...
          'Levantamiento existente que se desea evaluar (m)', 0.20);
        p.spacing_offset_manual_m = actual;
      end
    otherwise
      fprintf('Opcion no valida.\n');
      return;
  end

  p.spacing_modelo = 'diferencial_entre_sensado_y_operacion';
  p.spacing_perfil_termico = 'lineal';
  p.spacing_configured = 1;
  ok = true;

  fprintf('\nEspaciamiento configurado en modo: %s\n', p.spacing_mode);
  fprintf('Condicion termica al sensar: %s\n', ...
    p.spacing_condicion_termica_sensado);
  fprintf(['El resultado indicara: sensar fondo, levantar X mm y fijar la ' ...
    'grampa.\n']);
end

function v = leer_numero(etiqueta, actual)
  x = input(sprintf('%s [%.6g]: ', etiqueta, actual));
  if isempty(x), v = actual; else, v = x; end
end
