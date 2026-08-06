function tablas=cgf_report_build_tables(sol)
% CGF_REPORT_BUILD_TABLES Tablas CGF para compositor transversal.
  tablas=struct([]);if ~isstruct(sol)||~isfield(sol,'compresor')||~isstruct(sol.compresor),return;endif
  c=sol.compresor;
  if isfield(c,'Qcorr_Sm3_d')&&isfield(c,'PR_base')&&isfield(c,'eta_p')
    n=min([numel(c.Qcorr_Sm3_d),numel(c.PR_base),numel(c.eta_p)]);
    if n>0
      M=[c.Qcorr_Sm3_d(1:n)(:),c.PR_base(1:n)(:),c.eta_p(1:n)(:)];
      t=aos_report_table_from_matrix('cgf_compressor_map','Mapa del compresor CGF','CGF',M, ...
        {'Qcorr_Sm3_d','PR_base','eta_p'},{'Caudal corregido','Relacion de presion','Eficiencia politropica'}, ...
        {'Sm3/d','',''},'role','MAP_TABLE','category','CATALOG','priority','SECONDARY', ...
        'default_mode','FULL_APPENDIX','source','CGF_COMPRESSOR_CATALOG');
      tablas=aos_report_append_tables(tablas,t);
    endif
  endif
endfunction
