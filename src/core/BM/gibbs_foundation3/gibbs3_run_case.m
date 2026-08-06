function res = gibbs3_run_case(param, opciones)
% GIBBS3_RUN_CASE Flujo GF3 con segunda pasada opcional de barras de peso.

  if nargin < 1, param = struct(); end
  if nargin < 2 || ~isstruct(opciones), opciones = struct(); end
  if ~isfield(opciones, 'graficar'), opciones.graficar = true; end
  if ~isfield(opciones, 'imprimir'), opciones.imprimir = true; end
  if ~isfield(opciones, 'validar'), opciones.validar = true; end
  if ~isfield(opciones, 'integrar_barras_peso')
    opciones.integrar_barras_peso = true;
  end

  param = preparar_parametros_local(param);
  res = resolver_una_pasada_local(param);
  res.barras_peso_integradas = false;

  if opciones.integrar_barras_peso && param.barras_peso_habilitadas && ...
      param.barras_peso_integrar_en_GF3 && ...
      isfield(res, 'diseno_sarta_espaciamiento') && ...
      isfield(res.diseno_sarta_espaciamiento, 'barras_peso')
    b0 = res.diseno_sarta_espaciamiento.barras_peso;
    n0 = b0.cantidad_recomendada;
    if isfinite(n0) && n0 > 0
      try
        p2 = gibbs3_apply_weight_bars(param, n0);
        res2 = resolver_una_pasada_local(p2);
        res2.barras_peso_integradas = true;
        res2.barras_peso_dimensionamiento_inicial = b0;
        b2 = res2.diseno_sarta_espaciamiento.barras_peso;
        b2.cantidad_dimensionamiento_inicial = n0;
        b2.cantidad_instalada = n0;
        b2.longitud_instalada_m = n0 * p2.barras_peso_longitud_unitaria_m;
        b2.cantidad_requerida_postverificacion = b2.cantidad_recomendada;
        b2.verificacion_instalacion = ...
          n0 >= b2.cantidad_requerida_postverificacion;
        b2.resultado_operativo = sprintf('INSTALAR %d BARRAS DE PESO', n0);
        res2.diseno_sarta_espaciamiento.barras_peso = b2;
        res = res2;
      catch err_barras
        res.advertencias = {['No se pudo integrar la segunda pasada de barras de peso: ' ...
          err_barras.message]};
      end
    end
  end

  % Garantiza el esquema instalable incluso si alguna parte del flujo
  % proviene de un resultado o funcion cargada de una version anterior.
  res = gibbs3_upgrade_result_schema(res);

  if opciones.validar
    [ok, msg] = gibbs3_validate_result(res);
    res.validacion = struct('ok', ok, 'mensajes', {msg});
  end

  res.figuras = [];
  if ~isfield(res, 'advertencias') || ~iscell(res.advertencias)
    res.advertencias = {};
  end
  if opciones.graficar
    try
      res.figuras = gibbs3_plot(res);
      if ~isempty(res.figuras), res.figura = res.figuras(1); end
    catch err_plot
      res.advertencias{end+1} = ['No se pudieron generar graficas: ' err_plot.message];
      fprintf(2, 'ADVERTENCIA GF3 GRAFICAS: %s\n', err_plot.message);
    end
  end

  if opciones.imprimir
    gibbs3_print(res);
  end

  if param.gibbs3_exportar_resultado
    res.archivos_exportados = gibbs3_export_case(res, ...
      param.gibbs3_directorio_exportacion);
  end
end

function p = preparar_parametros_local(p)
  p = gibbs3_normalize_aos(p);
  p = gibbs3_defaults(p);
  if isnan(p.gibbs3_llenado_bomba)
    p.gibbs3_llenado_bomba = p.eta_vol;
  end
  if ~isfinite(p.viscosidad_fluido_cP) || p.viscosidad_fluido_cP <= 0
    try
      p = aos_bm_propiedades_fluido(p);
    catch
      p.viscosidad_fluido_cP = 10.0;
      p.origen_viscosidad = 'FALLBACK_GF3_10cP';
    end
  end
  if isempty(p.gibbs3_secciones_varillas_base) && ...
      ~isempty(p.gibbs3_secciones_varillas)
    p.gibbs3_secciones_varillas_base = p.gibbs3_secciones_varillas;
  end
  gibbs3_validate_params(p);
end

function res = resolver_una_pasada_local(p)
  malla = gibbs3_build_rod_mesh(p);
  res = gibbs3_solver_dynamic(p, malla);
  res = gibbs3_postprocess(res);
  res.metricas = gibbs3_metrics(res);
end
