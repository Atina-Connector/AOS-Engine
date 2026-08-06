function aos_cad_hidraulica_mostrar_resultados(modo)
% Presenta las tablas primarias de la ultima corrida hidraulica.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(modo), modo = 'TODO'; endif
  modo = upper(char(modo));
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('AOSCAD HID: no hay modelo activo.');
  endif
  modelo = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  if ~isfield(modelo, 'tablas_resultados') || ~isstruct(modelo.tablas_resultados)
    error('AOSCAD HID: no hay resultados. Ejecute la simulacion.');
  endif
  tr = modelo.tablas_resultados;
  if any(strcmp(modo, {'RESUMEN','TODO'})), mostrar_resumen_local(modelo, tr); endif
  if any(strcmp(modo, {'NODOS','TODO'})), mostrar_nodos_local(tr); endif
  if any(strcmp(modo, {'TRAMOS','TODO'})), mostrar_tramos_local(tr); endif
endfunction

function mostrar_resumen_local(modelo, tr)
  fprintf('\n--- RESUMEN HIDRAULICO ---\n');
  if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion)
    fprintf('Motor   : %s\n', campo_local(modelo.simulacion, 'motor', ''));
    fprintf('Estado  : %s\n', campo_local(modelo.simulacion, 'estado', ''));
    fprintf('Corrida : %s\n', campo_local(modelo.simulacion, 'corrida_id', ''));
    fprintf('Fecha   : %s\n', campo_local(modelo.simulacion, 'fecha', ''));
  endif
  filas = filas_local(tr, 'resumen');
  if isempty(filas), fprintf('Sin tabla resumen.\n'); return; endif
  r = filas{1};
  if isfield(r, 'dominio_hidraulico_id') && ~isempty(r.dominio_hidraulico_id)
    fprintf('Dominio : %s | %s | %s -> %s\n', ...
      campo_local(r, 'dominio_hidraulico_id', ''), ...
      campo_local(r, 'dominio_hidraulico_tipo', ''), ...
      campo_local(r, 'nodo_inicio', ''), campo_local(r, 'nodo_fin', ''));
  else
    fprintf('Dominio : RED COMPLETA\n');
  endif
  imprimir_campo_num_local(r, 'caudal_liquido_total_m3d', 'Ql total', 'm3/d');
  imprimir_campo_num_local(r, 'caudal_gas_total_std_m3d', 'Qg total', 'Sm3/d');
  imprimir_campo_num_local(r, 'presion_minima_bar', 'P minima', 'bar');
  imprimir_campo_num_local(r, 'presion_maxima_bar', 'P maxima', 'bar');
  if isfield(r, 'n_bifurcaciones')
    fprintf('%-12s: %d\n', 'Bifurcaciones', r.n_bifurcaciones(1));
  endif
  if isfield(r, 'topologia_resuelta') && ~isempty(r.topologia_resuelta)
    fprintf('%-12s: %s\n', 'Topologia', char(r.topologia_resuelta));
  endif
  imprimir_campo_num_local(r, 'residual_balance_max_m3s', 'Res. balance', 'm3/s');
  if isfield(r, 'metodo_lazo') && ~isempty(r.metodo_lazo)
    fprintf('%-12s: %s\n', 'Metodo lazo', char(r.metodo_lazo));
  endif
  if isfield(r, 'iteraciones_lazo')
    fprintf('%-12s: %d\n', 'Iter. lazo', r.iteraciones_lazo(1));
  endif
  imprimir_campo_num_local(r, 'residual_lazo_max_Pa', 'Res. lazo', 'Pa');
endfunction

function mostrar_nodos_local(tr)
  filas = filas_local(tr, 'nodos');
  fprintf('\n--- RESULTADOS NODALES (%d) ---\n', numel(filas));
  fprintf('%-14s %12s %12s %12s %14s %-18s\n', ...
          'Nodo', 'P [bar]', 'Ql [m3/d]', 'Qg [Sm3/d]', 'Bal [m3/s]', 'Estado');
  for i = 1:numel(filas)
    r = filas{i};
    fprintf('%-14s %12.4f %12.4f %12.4f %14.3e %-18s\n', ...
      campo_local(r, 'id', sprintf('N%03d', i)), ...
      num_local(r, 'presion_Pa', NaN)/1e5, ...
      num_local(r, 'demanda_liquido_m3s', 0)*86400, ...
      num_local(r, 'demanda_gas_std_m3s', 0)*86400, ...
      num_local(r, 'balance_nodal_m3s', 0), ...
      campo_local(r, 'estado', ''));
  endfor
endfunction

function mostrar_tramos_local(tr)
  filas = filas_local(tr, 'tramos');
  fprintf('\n--- RESULTADOS POR TRAMO (%d) ---\n', numel(filas));
  fprintf('%-12s %-10s %-10s %11s %10s %10s %-10s %-22s %-14s\n', ...
          'Tramo','Desde','Hasta','Q [m3/d]','Pin bar','Pout bar','Sentido','Modelo','Estado');
  for i = 1:numel(filas)
    r = filas{i};
    fprintf('%-12s %-10s %-10s %11.3f %10.3f %10.3f %-10s %-22s %-14s\n', ...
      campo_local(r, 'id', sprintf('T%03d', i)), ...
      campo_local(r, 'nodo_entrada', ''), campo_local(r, 'nodo_salida', ''), ...
      num_local(r, 'caudal_liquido_m3s', num_local(r, 'caudal_m3s', 0))*86400, ...
      num_local(r, 'P_in_Pa', NaN)/1e5, num_local(r, 'P_out_Pa', NaN)/1e5, ...
      campo_local(r, 'sentido_flujo', ''), ...
      campo_local(r, 'modelo', ''), campo_local(r, 'estado', ''));
  endfor
endfunction

function filas = filas_local(s, campo)
  filas = {};
  if isstruct(s) && isfield(s, campo) && ~isempty(s.(campo))
    filas = s.(campo);
    if isstruct(filas), filas = num2cell(filas); endif
  endif
endfunction

function s = campo_local(r, campo, defecto)
  s = defecto;
  if isstruct(r) && isfield(r, campo) && ~isempty(r.(campo))
    try s = char(r.(campo)); catch, s = defecto; end_try_catch
  endif
endfunction

function v = num_local(r, campo, defecto)
  v = defecto;
  if isstruct(r) && isfield(r, campo) && isnumeric(r.(campo)) && ~isempty(r.(campo))
    v = r.(campo)(1);
  endif
endfunction

function imprimir_campo_num_local(r, campo, etiqueta, unidad)
  if isfield(r, campo) && isnumeric(r.(campo)) && ~isempty(r.(campo))
    fprintf('%-12s: %.6g %s\n', etiqueta, r.(campo)(1), unidad);
  endif
endfunction
