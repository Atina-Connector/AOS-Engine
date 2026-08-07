function aos_cad_hidraulica_mostrar_config()
% Muestra configuracion efectiva y registro de motores disponibles.
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD HID: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  cfg = aos_cad_hidraulica_defaults(modelo);
  fprintf('\n--- CONFIGURACION HIDRAULICA EFECTIVA ---\n');
  fprintf('Version              : %s\n', cfg.version);
  fprintf('Estado               : %s\n', cfg.estado);
  fprintf('Modelo               : %s\n', cfg.modelo);
  fprintf('Modelo multifasico   : %s\n', cfg.modelo_multifasico);
  fprintf('P minima             : %.6g bar\n', cfg.P_min_Pa / 1e5);
  fprintf('Tolerancia presion   : %.6g Pa\n', cfg.tol_presion_Pa);
  fprintf('Iteraciones maximas  : %d\n', cfg.max_iter_presion);
  fprintf('API                  : %.6g\n', cfg.fluido.API);
  fprintf('WC                   : %.6g\n', cfg.fluido.WC);
  fprintf('GLR                  : %.6g Sm3/m3\n', cfg.fluido.GLR);
  fprintf('Gravedad especifica g: %.6g\n', cfg.fluido.gamma_g);
  fprintf('Densidad aceite      : %.6g kg/m3\n', cfg.fluido.rho_o);
  fprintf('Densidad agua        : %.6g kg/m3\n', cfg.fluido.rho_w);
  fprintf('Viscosidad liquido   : %.6g cP\n', cfg.fluido.mu_l_Pas * 1000);
  [dominio, ~] = aos_cad_hidraulica_dominio_activo(modelo);
  if isempty(dominio)
    fprintf('Dominio hidraulico  : RED COMPLETA\n');
  else
    fprintf('Dominio hidraulico  : %s (%s -> %s)\n', ...
      char(dominio.id), char(dominio.nodo_inicio), char(dominio.nodo_fin));
    fprintf('Tipo de dominio     : %s\n', char(dominio.tipo));
    fprintf('Condiciones extremos: %s\n', campo_local(dominio, 'condicion_extremos', 'PENDIENTE'));
  endif

  fprintf('\n--- MOTORES DISPONIBLES ---\n');
  reg = aos_cad_hidraulica_registro_modelos();
  for i = 1:numel(reg)
    r = reg{i};
    fprintf('%2d  %-28s  %-28s\n', i, r.id, r.estado);
    fprintf('    %s\n', r.nombre);
    fprintf('    Dominio: %s\n', r.dominio);
  endfor
endfunction

function s = campo_local(r, campo, defecto)
  s = defecto;
  if isstruct(r) && isfield(r, campo) && ~isempty(r.(campo))
    s = char(r.(campo));
  endif
endfunction
