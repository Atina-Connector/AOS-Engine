% sens_A_n.m - Sensibilidad JGL al area de tobera. GNU Octave.
script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin'); addpath(script_dir, '-begin');
iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);

[base, origen_base] = sens_cargar_base(); %#ok<NASGU>
base = sens_preparar_base(base, 'SENS_JGL');
base.jgl_geometria_modo = 'derivada';
base = jgl_actualizar_geometria(base, 'derivada');

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.3f m3/d/bar\n', base.IP*86400*1e5);
fprintf('WC                      : %.3f\n', base.WC);
fprintf('P_wh                    : %.2f bar\n', base.P_wh/1e5);
fprintf('P_iny_sup               : %.2f bar\n', base.P_iny_sup/1e5);
fprintf('Prof. inyeccion         : %.1f m\n', base.D_iny);
fprintf('GLR                     : %.2f Sm3/m3\n', base.GLR);
fprintf('A_n actual              : %.2f mm2\n', base.A_n*1e6);
fprintf('d_t actual              : %.2f mm\n', base.d_t*1000);
fprintf('Geometria JGL           : DERIVADA (a y b se recalculan por punto)\n');

cambiar = aos_preguntar_sn('Desea modificar parametros principales? (s/n) [n]: ', false);
if cambiar
  v=input(sprintf('  IP (m3/d/bar) [%.3f]: ',base.IP*86400*1e5)); if ~isempty(v),base.IP=v/(86400*1e5);end
  v=input(sprintf('  WC [%.3f]: ',base.WC)); if ~isempty(v),base.WC=v;end
  v=input(sprintf('  P_wh (bar) [%.2f]: ',base.P_wh/1e5)); if ~isempty(v),base.P_wh=v*1e5;end
  v=input(sprintf('  P_iny_sup (bar) [%.2f]: ',base.P_iny_sup/1e5)); if ~isempty(v),base.P_iny_sup=v*1e5;end
  v=input(sprintf('  Prof. inyeccion (m) [%.1f]: ',base.D_iny)); if ~isempty(v),base=aos_set_profundidad(base,'JGL',v);end
  v=input(sprintf('  GLR (Sm3/m3) [%.2f]: ',base.GLR)); if ~isempty(v),base.GLR=v;end
  v=input(sprintf('  d_t fijo (mm) [%.2f]: ',base.d_t*1000)); if ~isempty(v),base.d_t=v/1000;end
end
base = sens_preparar_base(base, 'SENS_JGL');
base.jgl_geometria_modo='derivada'; base=jgl_actualizar_geometria(base,'derivada');

fprintf('\n--- MODELO VLP ---\n1 - Simplificado\n2 - Hagedorn-Brown\n3 - Duns & Ros\n');
op=aos_opcion_modelo_vlp(base.modelo_VLP); v=input(sprintf('Seleccione VLP (1-3) [%d]: ',op)); if isempty(v),v=op;end
if v==3,base.modelo_VLP='DR';elseif v==2,base.modelo_VLP='HB';else,base.modelo_VLP='simplified';end
if isfield(base,'survey') && ~isempty(base.survey), diagnostico_vlp(base.survey,base.modelo_VLP); end
[modo_jgl,max_iter]=jgl_menu_aproximacion('automatico',10); base.jgl_max_iter=max_iter;
[politica_q,q_fijo]=sens_menu_qiny_jgl(base);

Amin=8; Amax=16; npts=10;
fprintf('\n--- LIMITES DEL BARRIDO ---\nA_n min: %.2f mm2\nA_n max: %.2f mm2\nN puntos: %d\n',Amin,Amax,npts);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v=input(sprintf('  A_n min (mm2) [%.2f]: ',Amin));if ~isempty(v),Amin=v;end
  v=input(sprintf('  A_n max (mm2) [%.2f]: ',Amax));if ~isempty(v),Amax=v;end
  v=input(sprintf('  N puntos [%d]: ',npts));if ~isempty(v),npts=max(2,round(v));end
end
Avals=linspace(Amin,Amax,npts)/1e6;
P=cell(1,npts); qvals=NaN(1,npts); avals=NaN(1,npts); bvals=NaN(1,npts);
for i=1:npts
  p=base; p.A_n=Avals(i); p.jgl_geometria_modo='derivada'; p=jgl_actualizar_geometria(p,'derivada');
  if strcmp(politica_q,'automatico'),qvals(i)=jgl_calcular_qiny_automatico(p);else,qvals(i)=q_fijo;end
  p=aos_set_qiny(p,qvals(i)*86400,'fijo'); p.jgl_max_iter=max_iter;
  P{i}=p; avals(i)=p.a_eductor; bvals(i)=p.b_eductor;
end
R=jgl_sensibilidad_parametrica(P,qvals,modo_jgl);
sens_abreviado_imprimir(R, numel(qvals));
Ql=R.Ql*86400;Qo=R.Qo*86400;Qiny=R.qiny_efectivo*86400;dP=R.deltaP/1e5;
[plana,det_plana]=sens_detectar_curva_plana(Qo);
Aopt=NaN;Qoopt=NaN;if ~plana,[Aopt,Qoopt]=encontrar_optimo(Avals,Qo);end
if plana
 fprintf('\nCURVA PLANA DENTRO DE TOLERANCIA: rango %.3f m3/d < umbral %.3f m3/d. No se declara optimo.\n',det_plana.rango,det_plana.umbral);
elseif isfinite(Aopt)
 fprintf('\nOptimo JGL: A_n %.2f mm2, Qo %.2f m3/d.\n',Aopt*1e6,Qoopt);
end
fprintf('\n=== SENSIBILIDAD A_N JGL ===\n');
fprintf('A_n(mm2) | a_eductor | b_eductor | Qiny(Sm3/d) | Ql | Qo | dP(bar) | Iter | Modo | Estado\n');
for i=1:npts
 fprintf('%8.2f | %9.5f | %9.5f | %12.0f | %7.2f | %7.2f | %7.3f | %4d | %s | %s\n',Avals(i)*1e6,avals(i),bvals(i),Qiny(i),Ql(i),Qo(i),dP(i),R.iteraciones(i),R.modos{i},R.estados{i});
end
figure;plot(Avals*1e6,Ql,'-o','LineWidth',2);grid on;xlabel('Area de tobera A_n (mm2)');ylabel('Liquido (m3/d)');title('Sensibilidad JGL a A_n');
yf=Ql(isfinite(Ql));if ~isempty(yf),m=max(0.5,0.10*max(max(yf)-min(yf),0.5));ylim([min(yf)-m,max(yf)+m]);end
exportar_grafico_modulo();

SENS_A_N_AUDIT=struct('A_n_mm2',Avals*1e6,'a_eductor',avals,'b_eductor',bvals, ...
  'Qiny_Sm3_d',Qiny,'Ql_m3d',Ql,'Qo_m3d',Qo,'DeltaP_bar',dP, ...
  'iteraciones',R.iteraciones,'modos',{R.modos},'estados',{R.estados});
assignin('base','SENS_A_N_AUDIT',SENS_A_N_AUDIT);

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_A_N_AUDIT', 'Area de tobera', base, 'JGL');
