function candidatos = gibbs3_rod_design_verify_candidates(param, candidatos)
% GIBBS3_ROD_DESIGN_VERIFY_CANDIDATES Verifica candidatas con GF3.
% La prueba se ejecuta sin graficas, impresion ni integracion de barras de
% peso para comparar solamente la respuesta dinamica de las sartas.

  if isempty(candidatos), return; end

  fprintf('\nVerificacion dinamica GF3 de %d candidatas...\n', numel(candidatos));
  masas = [candidatos.masa_total_kg];
  masa_ref = max(min(masas(isfinite(masas))), 1.0);

  for k = 1:numel(candidatos)
    fprintf('  [%d/%d] %s ... ', k, numel(candidatos), candidatos(k).nombre);
    q = param;
    q.gibbs3_secciones_varillas = candidatos(k).secciones;
    q.gibbs3_secciones_varillas_base = candidatos(k).secciones;
    q.rod_design_mode = 'automatico_candidato';
    q.rod_design_configured = 1;
    q.spacing_configured = 1;
    q.spacing_mode = 'evaluacion';
    q.barras_peso_habilitadas = 0;
    q.barras_peso_integrar_en_GF3 = 0;
    q.barras_peso_aplicadas_cantidad = 0;
    q.barras_peso_aplicadas_longitud_m = 0;
    q.gibbs3_exportar_resultado = false;

    opciones = struct('graficar', false, 'imprimir', false, ...
      'validar', false, 'integrar_barras_peso', false);
    try
      r = gibbs3_run_case(q, opciones);
      d = r.diseno_sarta_espaciamiento;
      candidatos(k).verificacion_GF3_ok = true;
      candidatos(k).utilizacion_dinamica_max = d.utilizacion_max;
      candidatos(k).aprobada_dinamica = d.aprobada_fatiga;
      candidatos(k).carga_superficie_max_kN = ...
        r.metricas.carga_superficie_max_N/1000;
      candidatos(k).transmision_carrera = r.metricas.transmision_carrera;
      candidatos(k).mensaje_verificacion = 'OK';

      penal_falla = 0;
      if ~candidatos(k).aprobada_dinamica, penal_falla = 1000; end
      penal_uniforme = 0;
      if param.rod_auto_prefer_tapered && ~candidatos(k).escalonada
        penal_uniforme = 0.20;
      end
      candidatos(k).score = candidatos(k).masa_total_kg/masa_ref + ...
        0.35*abs(candidatos(k).utilizacion_dinamica_max - ...
        param.rod_auto_target_utilization) + penal_uniforme + penal_falla;
      fprintf('OK, Goodman %.3f, masa %.0f kg\n', ...
        candidatos(k).utilizacion_dinamica_max, candidatos(k).masa_total_kg);
    catch err
      candidatos(k).verificacion_GF3_ok = false;
      candidatos(k).aprobada_dinamica = false;
      candidatos(k).score = Inf;
      candidatos(k).mensaje_verificacion = err.message;
      fprintf('FALLO: %s\n', err.message);
    end
  end
end
