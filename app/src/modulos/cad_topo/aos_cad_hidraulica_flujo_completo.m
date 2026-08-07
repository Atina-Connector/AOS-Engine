function salidas = aos_cad_hidraulica_flujo_completo()
% Ejecuta solver, valida y genera ambos perfiles .aoscad.
  aos_cad_hidraulica_ejecutar(false);
  aos_cad_validar_topologia(true);
  simple = aos_aoscad_escribir([], 'SIMPLE', false);
  enriquecido = aos_cad_hidraulica_guardar_enriquecido();
  salidas = struct('simple', simple, 'enriquecido', enriquecido);
  fprintf('\nFLUJO HIDRAULICO COMPLETO FINALIZADO\n');
  fprintf('Simple      : %s\n', simple);
  fprintf('Enriquecido : %s\n', enriquecido);
endfunction
