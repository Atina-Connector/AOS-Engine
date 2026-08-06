function gibbs2_menu()
  fprintf('\n====================================================\n');
  fprintf(' BM - GIBBS FOUNDATION 2 v1.0 (ACADÉMICO)\n');
  fprintf('====================================================\n');

  % Intentar cargar la configuración activa del .aosdat
  global CONFIG_ACTIVA
  if isstruct(CONFIG_ACTIVA) && ~isempty(fieldnames(CONFIG_ACTIVA))
      param_base = CONFIG_ACTIVA;
      % Asegurar defaults de GF2 sobre la configuración importada
      param_base = gibbs2_defaults(param_base);
      origen = '.aosdat importado';
  else
      % Si no hay .aosdat activo, usar defaults del sistema
      try
          [param_base, origen_base] = aos_config_base('BM');
          param_base = gibbs2_defaults(param_base);
          origen = ['configuración base: ' origen_base];
      catch
          param_base = gibbs2_defaults(struct());
          origen = 'defaults locales GF2';
      end
  end

  param = param_base;  % copia de trabajo
  fprintf('Configuración activa: %s\n', origen);

  while true
      fprintf('\n--- CASOS GF2 ---\n');
      fprintf('  1 - Caso base (restaura configuración activa)\n');
      fprintf('  2 - Bomba con llenado parcial\n');
      fprintf('  3 - Parámetros editables\n');
      fprintf('  4 - Solo cambiar cantidad de ciclos\n');
      fprintf('  5 - Solo cambiar diámetro de bomba\n');
      fprintf('  6 - Revisión de cargas de superficie\n');
      fprintf('  7 - Cambiar modo solver\n');
      fprintf('  8 - Barrido de amortiguamiento (δ)\n');
      fprintf('  9 - Configurar amortiguamiento (δ)\n');
      fprintf(' 10 - Restaurar defaults GF2 (valores académicos)\n');
      fprintf('  0 - Volver al menú BM\n');
      op = input('Seleccione caso [1]: ');
      if isempty(op), op = 1; end
      if op == 0, return; end

      switch op
          case 1
              param = param_base;
              fprintf('Configuración restaurada: %s\n', origen);
          case 2
              val = input(sprintf('Llenado bomba [%.2f]: ', param.gibbs2_llenado_bomba));
              if ~isempty(val), param.gibbs2_llenado_bomba = min(max(val,0.05),1.2); end
          case 3
              param = gibbs2_editar_parametros(param);
          case 4
              param = gibbs2_editar_ciclos(param);
          case 5
              val = input(sprintf('Diámetro bomba (mm) [%.1f]: ', param.D_bomba_mm));
              if ~isempty(val), param.D_bomba_mm = max(1, val); end
          case 6
              param = gibbs2_editar_cargas(param);
          case 7
              param = gibbs2_editar_modo(param);
          case 8
              nuevo = gibbs2_sweep_damping(param);
              if isfinite(nuevo)
                  param.gibbs2_delta_damping = nuevo;
              end
              continue;
          case 9
              fprintf('δ actual = %.3f\n', param.gibbs2_delta_damping);
              if aos_preguntar_sn('Modificar? (s/n) [n]: ', false)
                  val = input(sprintf('Nuevo δ [%.3f]: ', param.gibbs2_delta_damping));
                  if ~isempty(val) && isnumeric(val) && val >= 0
                      param.gibbs2_delta_damping = val;
                  end
              end
              continue;
          case 10
              param = gibbs2_defaults(struct());
              origen_defaults = 'defaults académicos GF2';
              fprintf('Defaults GF2 restaurados (valores académicos).\n');
              % No modifica param_base ni origen
          otherwise
              continue;
      end

      % Ejecutar simulación con los parámetros actuales
      res = gibbs2_run_case(param);
      assignin('base', 'ULTIMO_GIBBS2', res);
  end
end

% ----------------------------------------------------------
% Subfunciones de edición (idénticas a las anteriores)
% ----------------------------------------------------------
function p = gibbs2_editar_parametros(p)
  fprintf('\n--- Editar parámetros GF2 ---\n');
  val = input(sprintf('Carrera PR (m) [%.3f]: ', p.S_carrera));
  if ~isempty(val), p.S_carrera = val; end
  val = input(sprintf('Velocidad (gpm) [%.1f]: ', p.N_velocidad));
  if ~isempty(val), p.N_velocidad = val; end
  val = input(sprintf('Profundidad bomba (m) [%.1f]: ', p.D_bomba));
  if ~isempty(val), p.D_bomba = val; end
  val = input(sprintf('Diámetro bomba (mm) [%.1f]: ', p.D_bomba_mm));
  if ~isempty(val), p.D_bomba_mm = val; end
  val = input(sprintf('Nodos [%d]: ', p.gibbs2_n_nodos));
  if ~isempty(val), p.gibbs2_n_nodos = max(8, round(val)); end
  p = gibbs2_editar_ciclos(p);
  val = input(sprintf('Amortiguamiento δ [%.3f]: ', p.gibbs2_delta_damping));
  if ~isempty(val), p.gibbs2_delta_damping = max(0, val); end
  val = input(sprintf('Llenado bomba [%.2f]: ', p.gibbs2_llenado_bomba));
  if ~isempty(val), p.gibbs2_llenado_bomba = min(max(val,0.05),1.2); end
end

function p = gibbs2_editar_ciclos(p)
  fprintf('\n--- Ciclos ---\n');
  val = input(sprintf('Ciclos a simular [%d]: ', p.gibbs2_n_ciclos));
  if ~isempty(val), p.gibbs2_n_ciclos = max(1, round(val)); end
  if p.gibbs2_n_ciclos > 1
      val = input(sprintf('Ciclos a descartar [%d]: ', p.gibbs2_descartar_ciclos));
      if ~isempty(val), p.gibbs2_descartar_ciclos = max(0, min(round(val), p.gibbs2_n_ciclos-1)); end
  end
end

function p = gibbs2_editar_cargas(p)
  fprintf('\n--- Cargas de superficie ---\n');
  fprintf('Offset actual: ');
  if isfield(p, 'gibbs2_surface_offset_manual_N') && ~isnan(p.gibbs2_surface_offset_manual_N)
      fprintf('manual %.1f kN\n', p.gibbs2_surface_offset_manual_N / 1000);
  else
      fprintf('automático\n');
  end
  if aos_preguntar_sn('Definir manual? (s/n) [n]: ', false)
      val = input('Offset (kN): ');
      if ~isempty(val), p.gibbs2_surface_offset_manual_N = val * 1000; end
  else
      p.gibbs2_surface_offset_manual_N = NaN;
  end
end

function p = gibbs2_editar_modo(p)
  fprintf('\n--- Modo solver ---\n');
  fprintf('Actual: %s\n', p.gibbs2_modo_solver);
  fprintf('1 - automático\n2 - cuasiestático\n3 - dinámico\n');
  op = input('Modo [1]: ');
  if isempty(op), op = 1; end
  switch op
      case 2, p.gibbs2_modo_solver = 'cuasiestatico';
      case 3, p.gibbs2_modo_solver = 'dinamico';
      otherwise, p.gibbs2_modo_solver = 'automatico';
  end
end
