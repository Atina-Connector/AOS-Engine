function tablas=bes2_report_build_tables(sol)
% BES2_REPORT_BUILD_TABLES Tablas BES2 para compositor transversal.
  tablas=struct([]);if ~isstruct(sol),return;endif
  if isfield(sol,'curva')&&isstruct(sol.curva)&&isfield(sol.curva,'Q_m3_d')&&isfield(sol.curva,'head_m')&&isfield(sol.curva,'eta')
    n=min([numel(sol.curva.Q_m3_d),numel(sol.curva.head_m),numel(sol.curva.eta)]);
    if n>0
      M=[sol.curva.Q_m3_d(1:n)(:),sol.curva.head_m(1:n)(:),100*sol.curva.eta(1:n)(:)];
      t=aos_report_table_from_matrix('bes2_pump_curve','Curva de la bomba BES V2','BES2',M, ...
        {'Q_m3_d','Head_m','Eficiencia_pct'},{'Caudal','Head','Eficiencia'},{'m3/d','m','%'}, ...
        'role','CURVE_TABLE','category','CATALOG','priority','SECONDARY','default_mode','FULL_APPENDIX','source','BES2_PUMP_CATALOG');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
endfunction
