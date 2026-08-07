function CGF_menu()
  [p,origen]=aos_config_base('GENERAL');p=cgf_defaults(p);
  fprintf('\n--- CGF V1 / COMPRESION DE GAS EN FONDO ---\nOrigen: %s\n',origen);
  files=dir(fullfile('config','CGF','catalogo','*.txt'));if ~isempty(files),for i=1:numel(files),fprintf(' %d - %s\n',i,files(i).name);endfor;op=input('Mapa [1]: ');if isempty(op),op=1;endif;if op>=1&&op<=numel(files),p.cgf_compresor_file=fullfile('config','CGF','catalogo',files(op).name);endif,endif
  fprintf('D CGF: %.1f m | RPM: %.0f | P res: %.1f bar | P wh: %.1f bar\n',p.D_cgf,p.cgf_rpm,p.P_res/1e5,p.P_wh/1e5);
  r=aos_preguntar_sn('Modificar parametros? (s/n) [n]: ',false);if r
    v=input(sprintf('  Profundidad CGF (m) [%.1f]: ',p.D_cgf));if ~isempty(v),p.D_cgf=v;p.cable_longitud_m=v;endif
    v=input(sprintf('  RPM [%.0f]: ',p.cgf_rpm));if ~isempty(v),p.cgf_rpm=v;endif
    v=input(sprintf('  IP gas (Sm3/d/bar) [%.1f]: ',p.IP_gas_Sm3_d_bar));if ~isempty(v),p.IP_gas_Sm3_d_bar=v;p.gas_ipr_C_Sm3_d_bar2n=NaN;endif
    v=input(sprintf('  Liquido producido (m3/d) [%.1f]: ',p.cgf_Qliq_m3_d));if ~isempty(v),p.cgf_Qliq_m3_d=v;endif
  endif
  sol=cgf_solver(p);cgf_imprimir_resultado(sol);cgf_plot_resultado(sol,'on');global CGF_ULTIMO_RESULTADO ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;CGF_ULTIMO_RESULTADO=sol;p.cgf_ultima_Qg_Sm3_d=sol.Qg_Sm3_d;ULTIMO_QL=0;ULTIMO_QO=0;ULTIMO_QINY=0;ULTIMO_TIPO='CGF';ULTIMO_PARAM=p;
  fprintf('\n1 - Exportar ligero\n2 - Exportar enriquecido\n0 - No exportar\n');op=input('Seleccione: ');if op==1,cgf_exportar_reporte(sol,false);elseif op==2,cgf_exportar_reporte(sol,true);endif
endfunction
