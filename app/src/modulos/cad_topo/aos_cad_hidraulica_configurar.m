function cfg = aos_cad_hidraulica_configurar()
% Editor interactivo de configuracion; toda modificacion invalida resultados.
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD HID: no hay modelo activo. Importe y prepare un DXF primero.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  cfg = aos_cad_hidraulica_defaults(modelo);
  cambiado = false;
  while true
    fprintf('\n--- CONFIGURAR SOLVER Y FLUIDO ---\n');
    fprintf(' 1 - Modelo general              : %s\n', cfg.modelo);
    fprintf(' 2 - Modelo multifasico         : %s\n', cfg.modelo_multifasico);
    fprintf(' 3 - Presion minima [bar]       : %.6g\n', cfg.P_min_Pa/1e5);
    fprintf(' 4 - API                        : %.6g\n', cfg.fluido.API);
    fprintf(' 5 - Water cut [0-1]            : %.6g\n', cfg.fluido.WC);
    fprintf(' 6 - GLR [Sm3/m3]               : %.6g\n', cfg.fluido.GLR);
    fprintf(' 7 - Gravedad especifica gas    : %.6g\n', cfg.fluido.gamma_g);
    fprintf(' 8 - Densidad aceite [kg/m3]    : %.6g\n', cfg.fluido.rho_o);
    fprintf(' 9 - Densidad agua [kg/m3]      : %.6g\n', cfg.fluido.rho_w);
    fprintf('10 - Viscosidad liquido [cP]    : %.6g\n', cfg.fluido.mu_l_Pas*1000);
    fprintf('11 - Restaurar defaults efectivos desde DXF\n');
    fprintf(' 0 - Guardar y volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        cfg.modelo = elegir_modelo_local(false, cfg.modelo);
        cambiado = true;
      case 2
        cfg.modelo_multifasico = elegir_modelo_local(true, cfg.modelo_multifasico);
        cambiado = true;
      case 3
        v = leer_num_local('Presion minima [bar]: ', cfg.P_min_Pa/1e5, 0.01, Inf);
        cfg.P_min_Pa = v * 1e5; cambiado = true;
      case 4
        cfg.fluido.API = leer_num_local('API: ', cfg.fluido.API, 1, 100); cambiado = true;
      case 5
        cfg.fluido.WC = leer_num_local('Water cut [0-1]: ', cfg.fluido.WC, 0, 1); cambiado = true;
      case 6
        cfg.fluido.GLR = leer_num_local('GLR [Sm3/m3]: ', cfg.fluido.GLR, 0, Inf); cambiado = true;
      case 7
        cfg.fluido.gamma_g = leer_num_local('Gravedad especifica gas: ', cfg.fluido.gamma_g, 0.1, 3); cambiado = true;
      case 8
        cfg.fluido.rho_o = leer_num_local('Densidad aceite [kg/m3]: ', cfg.fluido.rho_o, 100, 2000); cambiado = true;
      case 9
        cfg.fluido.rho_w = leer_num_local('Densidad agua [kg/m3]: ', cfg.fluido.rho_w, 100, 2000); cambiado = true;
      case 10
        cp = leer_num_local('Viscosidad liquido [cP]: ', cfg.fluido.mu_l_Pas*1000, 0.001, Inf);
        cfg.fluido.mu_l_Pas = cp / 1000; cambiado = true;
      case 11
        modelo0 = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
        if isfield(modelo0, 'simulacion') && isstruct(modelo0.simulacion) && ...
            isfield(modelo0.simulacion, 'configuracion_hidraulica')
          modelo0.simulacion = rmfield(modelo0.simulacion, 'configuracion_hidraulica');
        endif
        cfg = aos_cad_hidraulica_defaults(modelo0); cambiado = true;
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
  if cambiado
    aos_cad_hidraulica_aplicar_configuracion(cfg, false);
  else
    fprintf('Configuracion sin cambios.\n');
  endif
endfunction

function modelo = elegir_modelo_local(solo_multifasico, actual)
  reg = aos_cad_hidraulica_registro_modelos();
  disponibles = {};
  fprintf('\nModelos disponibles:\n');
  for i = 1:numel(reg)
    r = reg{i};
    if solo_multifasico && ~r.requiere_gas, continue; endif
    disponibles{end+1} = r.id; %#ok<AGROW>
    fprintf('%2d - %-28s %s\n', numel(disponibles), r.id, r.nombre);
  endfor
  op = aos_leer_opcion(sprintf('Seleccione [actual %s]: ', actual), []);
  modelo = actual;
  if ~isempty(op) && isfinite(op) && op >= 1 && op <= numel(disponibles)
    modelo = disponibles{op};
  endif
endfunction

function v = leer_num_local(mensaje, defecto, vmin, vmax)
  txt = strtrim(input(mensaje, 's'));
  if isempty(txt), v = defecto; return; endif
  v = str2double(strrep(txt, ',', '.'));
  if ~isfinite(v) || v < vmin || v > vmax
    fprintf('Valor invalido; se conserva %.6g.\n', defecto);
    v = defecto;
  endif
endfunction
