function archivo = bes3_exportar_resultado_simple(contexto, archivo)
  sol=contexto.resultado;
  if isfield(contexto,'param')&&isstruct(contexto.param),sol.param=contexto.param;endif
  archivo=bes3_exportar_reporte(sol,false,archivo,false);
endfunction
