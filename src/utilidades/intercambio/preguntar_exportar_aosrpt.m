function preguntar_exportar_aosrpt()
  % Exporta el ultimo resultado y permite incluir el contexto portable del pozo.
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  if isempty(ULTIMO_QL),return;end
  fprintf('\n--- EXPORTAR REPORTE ---\n');
  fprintf('  1 - Formato ligero (texto y datos reconstruibles)\n');
  fprintf('  2 - Formato enriquecido (datos + graficos embebidos)\n');
  fprintf('  0 - No exportar\n');
  op=input('Seleccione una opcion (1/2/0): ');
  if isempty(op)||op==0,fprintf('No se exporto el reporte.\n');return;end
  if op~=1&&op~=2,fprintf('Opcion no valida. No se exporto el reporte.\n');return;end

  incluir=aos_preguntar_sn('Incluir survey, tubing, punzados y equipo de fondo? (s/n) [s]: ',true);
  p=ULTIMO_PARAM;p.aosrpt_incluir_contexto_viewer=incluir;
  if incluir
    if op==2,fprintf('Se incluiran datos del pozo y una imagen PNG del survey.\n');else,fprintf('Se incluiran datos reconstruibles del survey y completacion.\n');end
  else
    fprintf('El reporte se exportara sin contexto geometrico del pozo.\n');
  end
  if op==2 && strcmpi(ULTIMO_TIPO,'GL')
    incluir_mand=aos_preguntar_sn('Incluir diseno de mandriles y su grafico? (s/n) [n]: ',false);
    if incluir_mand
      R=[];
      try, R=evalin('base','MANDRILES_V2_RESULTADO'); catch, end_try_catch
      if isempty(R) || ~isstruct(R)
        if aos_preguntar_sn('No existe un diseno vigente. Calcularlo ahora con la configuracion efectiva GL? (s/n) [n]: ',false)
          try, R=mandriles_diseno_unloading(p); catch err, fprintf('No se pudo calcular mandriles: %s\n',err.message); R=[]; end_try_catch
        endif
      endif
      if isstruct(R) && ~isempty(fieldnames(R)), p.mandriles_resultado=R; endif
    endif
  endif
  if op==1
    exportar_aosrpt(p,ULTIMO_QL,ULTIMO_QO,ULTIMO_QINY,ULTIMO_TIPO);
  else
    exportar_aosrpt_enriquecido(p,ULTIMO_QL,ULTIMO_QO,ULTIMO_QINY,ULTIMO_TIPO);
  end
end
