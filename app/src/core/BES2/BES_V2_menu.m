function BES_V2_menu()
  [p,origen]=aos_config_base('BES');p=bes2_defaults(p);
  fprintf('\n--- BES V2 / AOS 0.1.1-R1 [BETA] ---\nOrigen: %s\n',origen);
  archivos=dir(fullfile('config','BES_V2','catalogo','*.txt'));
  if ~isempty(archivos)
    fprintf('Catalogo de bombas BES V2:\n');for i=1:numel(archivos),fprintf(' %d - %s\n',i,archivos(i).name);endfor
    op=input('Seleccione [1]: ');if isempty(op),op=1;endif;if op>=1&&op<=numel(archivos),p.bes2_bomba_file=fullfile('config','BES_V2','catalogo',archivos(op).name);endif
  endif
  fprintf('Profundidad intake : %.1f m\nFrecuencia         : %.1f Hz\nEtapas             : %d\nSeparador gas      : %.0f %%\n',p.D_bomba,p.frecuencia,p.num_etapas,100*p.bes2_eta_separador);
  r=aos_preguntar_sn('Modificar parametros? (s/n) [n]: ',false);
  if r
    v=input(sprintf('  D_bomba/intake (m) [%.1f]: ',p.D_bomba));if ~isempty(v),p.D_bomba=v;p.cable_longitud_m=v;endif
    v=input(sprintf('  Frecuencia (Hz) [%.1f]: ',p.frecuencia));if ~isempty(v),p.frecuencia=v;endif
    v=input(sprintf('  Numero de etapas [%d]: ',p.num_etapas));if ~isempty(v),p.num_etapas=round(v);endif
    v=input(sprintf('  Eficiencia separador [%.2f]: ',p.bes2_eta_separador));if ~isempty(v),p.bes2_eta_separador=v;endif
  endif
  sol=bes2_solver(p);bes2_imprimir_resultado(sol);bes2_plot_resultado(sol,'on');
  global BES2_ULTIMO_RESULTADO ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  BES2_ULTIMO_RESULTADO=sol;ULTIMO_QL=sol.Ql_m3_d/86400;ULTIMO_QO=sol.Qo_m3_d/86400;ULTIMO_QINY=0;ULTIMO_TIPO='BES_V2';ULTIMO_PARAM=p;
  fprintf('\n1 - Exportar ligero\n2 - Exportar enriquecido\n0 - No exportar\n');op=input('Seleccione: ');if op==1,bes2_exportar_reporte(sol,false);elseif op==2,bes2_exportar_reporte(sol,true);endif
endfunction
