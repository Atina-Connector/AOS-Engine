function m = aos_imprimir_balance_energia_sla(e, tipo)
% Imprime indicadores energeticos sin usar la palabra ambigua "rendimiento".
  if nargin<2 || isempty(tipo), tipo='GENERAL'; endif
  m=aos_metricas_energia_sla(e,tipo);
  fprintf('\n--- ANALISIS ENERGETICO EN LA FRONTERA DEL SLA ---\n');
  imprimir_local('Indice energetico bruto de fondo', ...
    m.indice_energetico_bruto_fondo_pct,m.estado_indice_energetico_bruto);
  if strcmpi(tipo,'JGL')
    imprimir_local('Eficiencia interna del jet', ...
      m.eficiencia_interna_jet_pct,m.estado_eficiencia_interna_jet);
  else
    fprintf('%-37s : N/A (solo aplica al eductor JGL)\n','Eficiencia interna del jet');
  endif
  fprintf('Nota: el indice bruto incluye energia del reservorio y puede superar 100 %%.\n');
  fprintf('---------------------------------------------------\n');
endfunction
function imprimir_local(etiqueta,v,estado)
  if isfinite(v)
    fprintf('%-37s : %.3f %% [%s]\n',etiqueta,v,estado);
  else
    fprintf('%-37s : N/A [%s]\n',etiqueta,estado);
  endif
endfunction
