function archivo = bes3_exportar_resultado_enriquecido(contexto, archivo)
  sol=contexto.resultado;
  if isfield(contexto,'param')&&isstruct(contexto.param),sol.param=contexto.param;endif
  archivo=bes3_exportar_reporte(sol,true,archivo,false);
endfunction
