function aos_cad_hidraulica_imprimir(modelo, resultados)
% AOS_CAD_HIDRAULICA_IMPRIMIR Resumen textual de la corrida.
  fprintf('\n====================================================\n');
  fprintf(' AOSCAD HIDRAULICA DXF 0.0.1 DEV1\n');
  fprintf('====================================================\n');
  fprintf('motor       : %s\n', char(modelo.simulacion.motor));
  fprintf('estado      : %s\n', char(modelo.simulacion.estado));
  fprintf('corrida_id  : %s\n', char(modelo.simulacion.corrida_id));
  fprintf('nodos       : %d\n', numel(resultados.nodos));
  fprintf('tramos      : %d\n', numel(resultados.tramos));
  if isfield(resultados, 'resumen') && ~isempty(resultados.resumen)
    rr = resultados.resumen{1};
    fprintf('Ql total    : %.6g m3/s (%.3f m3/d)\n', ...
            rr.caudal_liquido_total_m3s, rr.caudal_liquido_total_m3d);
    fprintf('Qg total    : %.6g Sm3/s (%.3f Sm3/d)\n', ...
            rr.caudal_gas_total_std_m3s, rr.caudal_gas_total_std_m3d);
    if isfield(rr, 'metodo_lazo')
      fprintf('metodo lazo : %s\n', char(rr.metodo_lazo));
    endif
    if isfield(rr, 'iteraciones_lazo')
      fprintf('iter lazo   : %d\n', rr.iteraciones_lazo);
    endif
    if isfield(rr, 'residual_lazo_max_Pa')
      fprintf('res lazo    : %.6g Pa\n', rr.residual_lazo_max_Pa);
    endif
  endif
  fprintf('\n--- RESULTADOS POR TRAMO ---\n');
  fprintf('%-12s %-10s %-10s %10s %10s %10s %-10s %-22s %-12s\n', ...
          'Tramo','Desde','Hasta','Q m3/d','Pin bar','Pout bar','Sentido','Modelo','Estado');
  for i = 1:numel(resultados.tramos)
    r = resultados.tramos{i};
    if ~isfield(r, 'P_in_Pa')
      fprintf('%-12s %-10s %-10s %10s\n', r.id, r.nodo_entrada, r.nodo_salida, r.estado);
      continue;
    endif
    sentido = '';
    if isfield(r, 'sentido_flujo'), sentido = char(r.sentido_flujo); endif
    fprintf('%-12s %-10s %-10s %10.3f %10.3f %10.3f %-10s %-22s %-12s\n', ...
      r.id, r.nodo_entrada, r.nodo_salida, r.caudal_liquido_m3s*86400, ...
      r.P_in_Pa/1e5, r.P_out_Pa/1e5, sentido, r.modelo, r.estado);
  endfor
  if ~isempty(modelo.simulacion.advertencias)
    fprintf('\nAdvertencias (%d):\n', numel(modelo.simulacion.advertencias));
    for i = 1:min(20, numel(modelo.simulacion.advertencias))
      fprintf(' - %s\n', modelo.simulacion.advertencias{i});
    endfor
  endif
endfunction
