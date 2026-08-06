function diag = diagnostico_bm_gibbs(param, Ql, varillas, opciones)
  % diagnostico_bm_gibbs.m - Diagnostico BM con modulo Gibbs/onda AOS v11.

  if nargin < 4 || isempty(opciones), opciones = struct(); end
  if ~isfield(opciones, 'graficar'), opciones.graficar = true; end
  if ~isfield(opciones, 'imprimir'), opciones.imprimir = true; end
  if ~isfield(opciones, 'n_tabla'), opciones.n_tabla = 36; end
  if ~isfield(opciones, 'metodo_forward')
      if isstruct(param) && isfield(param, 'gibbs_metodo_forward') && ischar(param.gibbs_metodo_forward)
          opciones.metodo_forward = param.gibbs_metodo_forward;
      else
          opciones.metodo_forward = 'estable';
      end
  end
  if nargin < 2 || isempty(Ql), Ql = 0; end
  if nargin < 3 || isempty(varillas)
      varillas = diseno_varillas(param, Ql);
  end

  if isfield(param, 'BM_resultado') && isstruct(param.BM_resultado) && isfield(param.BM_resultado, 'gibbs')
      res = param.BM_resultado.gibbs;
  else
      opciones_g = struct();
      opciones_g.modo = 'forward';
      if isfield(opciones, 'n_puntos'), opciones_g.n_t = opciones.n_puntos; end
      if isfield(opciones, 'n_t'), opciones_g.n_t = opciones.n_t; end
      if isfield(opciones, 'n_ciclos'), opciones_g.n_ciclos = opciones.n_ciclos; end
      if isfield(opciones, 'n_nodos_objetivo'), opciones_g.n_nodos_objetivo = opciones.n_nodos_objetivo; end
      if isfield(opciones, 'amortiguamiento'), opciones_g.amortiguamiento = opciones.amortiguamiento; end
      if isfield(opciones, 'metodo_forward'), opciones_g.metodo_forward = opciones.metodo_forward; end
      opciones_g.imprimir = false;
      opciones_g.graficar = false;
      res = gibbs_bm_resolver(param, varillas, opciones_g);
  end

  carta_sup = filtrar_picos_carta(res.carta_sup, 20);
  carta_fondo = filtrar_picos_carta(res.carta_fondo, 20);
  idx = unique(round(linspace(1, size(carta_sup,1), opciones.n_tabla)));

  diag = struct();
  diag.modelo = res.modelo;
  diag.res = res;
  diag.carta_sup = carta_sup;
  diag.carta_fondo = carta_fondo;
  diag.tabla_sup = carta_sup(idx,:);
  diag.tabla_fondo = carta_fondo(idx,:);
  diag.t = res.t;
  diag.varillas = varillas;
  diag.S_superficie_m = res.metricas.stroke_superficie_m;
  diag.S_fondo_m = res.metricas.stroke_fondo_m;
  diag.llenado_bomba = res.metricas.llenado_efectivo;
  diag.Q_teorico_fondo_m3s = res.metricas.Q_teorico_fondo_m3s;
  diag.Q_efectivo_m3s = res.metricas.Q_efectivo_m3s;
  diag.carga_sup_max_N = res.metricas.carga_sup_max_N;
  diag.carga_sup_min_N = res.metricas.carga_sup_min_N;
  diag.carga_fondo_max_N = res.metricas.carga_fondo_max_N;
  diag.carga_fondo_min_N = res.metricas.carga_fondo_min_N;
  diag.espaciamiento = res.espaciamiento;
  if exist('bm_semaforo_operacion', 'file')
      try
          diag.semaforo = bm_semaforo_operacion(param, Ql, varillas, diag);
      catch
          diag.semaforo = [];
      end
  else
      diag.semaforo = [];
  end

  if opciones.imprimir
      imprimir_diagnostico_gibbs(diag);
  end
  if opciones.graficar
      plot_cartas_gibbs(diag);
      drawnow;
  end
end

function imprimir_diagnostico_gibbs(diag)
  fprintf('\n--- DIAGNOSTICO GIBBS / BM AOS v11 ---\n');
  fprintf('Modelo                : %s\n', diag.modelo);
  fprintf('Carrera superficie    : %.3f m\n', diag.S_superficie_m);
  fprintf('Carrera fondo         : %.3f m\n', diag.S_fondo_m);
  fprintf('Relacion fondo/sup.   : %.3f\n', diag.S_fondo_m / max(diag.S_superficie_m, 1e-9));
  fprintf('Q teorico fondo       : %.2f m3/d\n', diag.Q_teorico_fondo_m3s * 86400);
  fprintf('Q efectivo Gibbs      : %.2f m3/d\n', diag.Q_efectivo_m3s * 86400);
  fprintf('Llenado bomba         : %.2f\n', diag.llenado_bomba);
  fprintf('Carga sup max/min     : %.1f / %.1f kN\n', diag.carga_sup_max_N/1000, diag.carga_sup_min_N/1000);
  fprintf('Carga fondo max/min   : %.1f / %.1f kN\n', diag.carga_fondo_max_N/1000, diag.carga_fondo_min_N/1000);
  if isfield(diag, 'semaforo') && isstruct(diag.semaforo)
      fprintf('Semaforo BM           : %s - %s\n', diag.semaforo.general, diag.semaforo.descripcion);
  end
  if isfield(diag, 'espaciamiento')
      fprintf('Espaciamiento recom.  : %.2f m (%s)\n', diag.espaciamiento.recomendacion_m, diag.espaciamiento.criterio);
  end
  if isfield(diag.res, 'info') && isfield(diag.res.info, 'aviso')
      fprintf('Aviso                 : %s\n', diag.res.info.aviso);
  end

  fprintf('\n--- TABLA DE CARTAS (%d puntos) ---\n', size(diag.tabla_sup,1));
  fprintf('Punto | Pos.Sup(m) | Carga Sup(kN) | Pos.Fondo(m) | Carga Fondo(kN)\n');
  fprintf('------|------------|---------------|--------------|----------------\n');
  for i = 1:size(diag.tabla_sup, 1)
      fprintf(' %3d  | %10.4f | %13.1f | %12.4f | %14.1f\n', i, ...
          diag.tabla_sup(i,1), diag.tabla_sup(i,2)/1000, ...
          diag.tabla_fondo(i,1), diag.tabla_fondo(i,2)/1000);
  end
  fprintf('------|------------|---------------|--------------|----------------\n');
end
