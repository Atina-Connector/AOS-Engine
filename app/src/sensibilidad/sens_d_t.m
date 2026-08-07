% sens_d_t.m - Sensibilidad JGL al diametro de garganta. GNU Octave.
script_dir=fileparts(mfilename('fullpath'));AOS_root=fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root,'src'),'-begin');addpath(script_dir,'-begin');iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);
[base,origen_base]=sens_cargar_base(); %#ok<NASGU>
base=sens_preparar_base(base,'SENS_JGL');base.jgl_geometria_modo='derivada';base=jgl_actualizar_geometria(base,'derivada');
fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP %.3f m3/d/bar | WC %.3f | Pwh %.2f bar | Pinj %.2f bar\n',base.IP*86400*1e5,base.WC,base.P_wh/1e5,base.P_iny_sup/1e5);
fprintf('D_iny %.1f m | GLR %.2f Sm3/m3 | A_n %.2f mm2 | d_t %.2f mm\n',base.D_iny,base.GLR,base.A_n*1e6,base.d_t*1000);
fprintf('Geometria JGL: DERIVADA; a_eductor y b_eductor se recalculan por punto.\n');
if aos_preguntar_sn('Desea modificar parametros principales? (s/n) [n]: ', false)
 v=input(sprintf('  IP (m3/d/bar) [%.3f]: ',base.IP*86400*1e5));if ~isempty(v),base.IP=v/(86400*1e5);end
 v=input(sprintf('  WC [%.3f]: ',base.WC));if ~isempty(v),base.WC=v;end
 v=input(sprintf('  P_wh (bar) [%.2f]: ',base.P_wh/1e5));if ~isempty(v),base.P_wh=v*1e5;end
 v=input(sprintf('  P_iny_sup (bar) [%.2f]: ',base.P_iny_sup/1e5));if ~isempty(v),base.P_iny_sup=v*1e5;end
 v=input(sprintf('  Prof. inyeccion (m) [%.1f]: ',base.D_iny));if ~isempty(v),base=aos_set_profundidad(base,'JGL',v);end
 v=input(sprintf('  GLR (Sm3/m3) [%.2f]: ',base.GLR));if ~isempty(v),base.GLR=v;end
 v=input(sprintf('  A_n fijo (mm2) [%.2f]: ',base.A_n*1e6));if ~isempty(v),base.A_n=v/1e6;end
end
base=sens_preparar_base(base,'SENS_JGL');base.jgl_geometria_modo='derivada';base=jgl_actualizar_geometria(base,'derivada');
fprintf('\n--- MODELO VLP ---\n1 - Simplificado\n2 - Hagedorn-Brown\n3 - Duns & Ros\n');op=aos_opcion_modelo_vlp(base.modelo_VLP);v=input(sprintf('Seleccione VLP (1-3) [%d]: ',op));if isempty(v),v=op;end
if v==3,base.modelo_VLP='DR';elseif v==2,base.modelo_VLP='HB';else,base.modelo_VLP='simplified';end
if isfield(base,'survey')&&~isempty(base.survey),diagnostico_vlp(base.survey,base.modelo_VLP);end
[modo_jgl,max_iter]=jgl_menu_aproximacion('automatico',10);base.jgl_max_iter=max_iter;[politica_q,q_fijo]=sens_menu_qiny_jgl(base);
dmin=25;dmax=50;npts=10;
fprintf('\n--- LIMITES DEL BARRIDO ---\nd_t min %.2f mm\nd_t max %.2f mm\nN puntos %d\n',dmin,dmax,npts);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
 v=input(sprintf('  d_t min (mm) [%.2f]: ',dmin));if ~isempty(v),dmin=v;end
 v=input(sprintf('  d_t max (mm) [%.2f]: ',dmax));if ~isempty(v),dmax=v;end
 v=input(sprintf('  N puntos [%d]: ',npts));if ~isempty(v),npts=max(2,round(v));end
end
dvals=linspace(dmin,dmax,npts)/1000;P=cell(1,npts);qvals=NaN(1,npts);avals=NaN(1,npts);bvals=NaN(1,npts);
for i=1:npts
 p=base;p.d_t=dvals(i);p.jgl_geometria_modo='derivada';p=jgl_actualizar_geometria(p,'derivada');
 if strcmp(politica_q,'automatico'),qvals(i)=jgl_calcular_qiny_automatico(p);else,qvals(i)=q_fijo;end
 p=aos_set_qiny(p,qvals(i)*86400,'fijo');p.jgl_max_iter=max_iter;P{i}=p;avals(i)=p.a_eductor;bvals(i)=p.b_eductor;
end
R=jgl_sensibilidad_parametrica(P,qvals,modo_jgl);
sens_abreviado_imprimir(R, numel(qvals));Ql=R.Ql*86400;Qo=R.Qo*86400;Qiny=R.qiny_efectivo*86400;dP=R.deltaP/1e5;
[plana,det_plana]=sens_detectar_curva_plana(Qo);dopt=NaN;Qoopt=NaN;if ~plana,[dopt,Qoopt]=encontrar_optimo(dvals,Qo);end
if plana,fprintf('\nCURVA PLANA DENTRO DE TOLERANCIA: rango %.3f m3/d < umbral %.3f m3/d. No se declara optimo.\n',det_plana.rango,det_plana.umbral);elseif isfinite(dopt),fprintf('\nOptimo JGL: d_t %.2f mm, Qo %.2f m3/d.\n',dopt*1000,Qoopt);end
fprintf('\n=== SENSIBILIDAD D_T JGL ===\n');fprintf('d_t(mm) | a_eductor | b_eductor | Qiny(Sm3/d) | Ql | Qo | dP(bar) | Iter | Modo | Estado\n');
for i=1:npts,fprintf('%7.2f | %9.5f | %9.5f | %12.0f | %7.2f | %7.2f | %7.3f | %4d | %s | %s\n',dvals(i)*1000,avals(i),bvals(i),Qiny(i),Ql(i),Qo(i),dP(i),R.iteraciones(i),R.modos{i},R.estados{i});end
figure;plot(dvals*1000,Ql,'-o','LineWidth',2);grid on;xlabel('Diametro de garganta d_t (mm)');ylabel('Liquido (m3/d)');title('Sensibilidad JGL a d_t');yf=Ql(isfinite(Ql));if ~isempty(yf),m=max(0.5,0.10*max(max(yf)-min(yf),0.5));ylim([min(yf)-m,max(yf)+m]);end
exportar_grafico_modulo();

SENS_DT_AUDIT=struct('d_t_mm',dvals*1000,'a_eductor',avals,'b_eductor',bvals, ...
  'Qiny_Sm3_d',Qiny,'Ql_m3d',Ql,'Qo_m3d',Qo,'DeltaP_bar',dP, ...
  'iteraciones',R.iteraciones,'modos',{R.modos},'estados',{R.estados});
assignin('base','SENS_DT_AUDIT',SENS_DT_AUDIT);

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_DT_AUDIT', 'Diametro de garganta', base, 'JGL');
