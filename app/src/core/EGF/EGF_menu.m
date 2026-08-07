function EGF_menu()
  [p,origen]=aos_config_base('GENERAL');p=egf_defaults(p);
  fprintf('\n--- EGF V1 / EDUCTOR GAS-GAS DE FONDO ---\nOrigen: %s\n',origen);
  files=dir(fullfile('config','EGF','catalogo','*.txt'));if ~isempty(files),for i=1:numel(files),fprintf(' %d - %s\n',i,files(i).name);endfor;op=input('Eyector [1]: ');if isempty(op),op=1;endif;if op>=1&&op<=numel(files),p.egf_eyector_file=fullfile('config','EGF','catalogo',files(op).name);endif,endif
  fprintf('D EGF: %.1f m | P motriz sup: %.1f bar | P wh: %.1f bar\n',p.D_egf,p.P_motriz_sup/1e5,p.P_wh/1e5);
  r=aos_preguntar_sn('Modificar parametros? (s/n) [n]: ',false);if r
    v=input(sprintf('  Profundidad EGF (m) [%.1f]: ',p.D_egf));if ~isempty(v),p.D_egf=v;endif
    v=input(sprintf('  P motriz superficie (bar) [%.1f]: ',p.P_motriz_sup/1e5));if ~isempty(v),p.P_motriz_sup=v*1e5;endif
    v=input(sprintf('  IP gas (Sm3/d/bar) [%.1f]: ',p.IP_gas_Sm3_d_bar));if ~isempty(v),p.IP_gas_Sm3_d_bar=v;p.gas_ipr_C_Sm3_d_bar2n=NaN;endif
  endif
  sol=egf_solver(p);egf_imprimir_resultado(sol);egf_plot_resultado(sol,'on');global EGF_ULTIMO_RESULTADO ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;EGF_ULTIMO_RESULTADO=sol;p.egf_ultima_Qs_Sm3_d=sol.Qg_aspirado_Sm3_d;p.egf_ultima_Qm_Sm3_d=sol.Qg_motriz_Sm3_d;ULTIMO_QL=0;ULTIMO_QO=0;ULTIMO_QINY=0;ULTIMO_TIPO='EGF';ULTIMO_PARAM=p;
  fprintf('\n1 - Exportar ligero\n2 - Exportar enriquecido\n0 - No exportar\n');op=input('Seleccione: ');if op==1,egf_exportar_reporte(sol,false);elseif op==2,egf_exportar_reporte(sol,true);endif
endfunction
