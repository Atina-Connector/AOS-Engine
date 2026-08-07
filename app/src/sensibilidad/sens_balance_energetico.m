% sens_balance_energetico.m - Balance energetico JGL/GL, GNU Octave.
% El CFD no participa. Qiny=0 se informa como indice energetico N/A.
% SENS-GLJGL-02: el tratamiento polinomico es visible y opcional.
script_dir=fileparts(mfilename('fullpath'));AOS_root=fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root,'src'),'-begin');addpath(script_dir,'-begin');iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);
[base,origen_base]=sens_cargar_base(); %#ok<NASGU>
base=sens_preparar_base(base,'SENS_JGL');
if ~isfield(base,'cp_gas'),base.cp_gas=2300;end
if ~isfield(base,'eta_comp'),base.eta_comp=0.80;end
fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP %.3f m3/d/bar | WC %.3f | Pwh %.2f bar | Pinj %.2f bar\n',base.IP*86400*1e5,base.WC,base.P_wh/1e5,base.P_iny_sup/1e5);
fprintf('D_iny %.1f m | GLR %.2f Sm3/m3 | eta comp %.3f\n',base.D_iny,base.GLR,base.eta_comp);
if aos_preguntar_sn('Desea modificar parametros? (s/n) [n]: ', false)
 v=input(sprintf('  IP (m3/d/bar) [%.3f]: ',base.IP*86400*1e5));if ~isempty(v),base.IP=v/(86400*1e5);end
 v=input(sprintf('  WC [%.3f]: ',base.WC));if ~isempty(v),base.WC=v;end
 v=input(sprintf('  P_wh (bar) [%.2f]: ',base.P_wh/1e5));if ~isempty(v),base.P_wh=v*1e5;end
 v=input(sprintf('  P_iny_sup (bar) [%.2f]: ',base.P_iny_sup/1e5));if ~isempty(v),base.P_iny_sup=v*1e5;end
 v=input(sprintf('  D_iny (m) [%.1f]: ',base.D_iny));if ~isempty(v),base=aos_set_profundidad(base,'JGL',v);end
 v=input(sprintf('  GLR (Sm3/m3) [%.2f]: ',base.GLR));if ~isempty(v),base.GLR=v;end
 v=input(sprintf('  Eficiencia compresor [%.3f]: ',base.eta_comp));if ~isempty(v),base.eta_comp=max(min(v,1),0.01);end
end
base=sens_preparar_base(base,'SENS_JGL');
fprintf('\n--- MODELO VLP ---\n1 - Simplificado\n2 - Hagedorn-Brown\n3 - Duns & Ros\n');op=aos_opcion_modelo_vlp(base.modelo_VLP);v=input(sprintf('Seleccione VLP (1-3) [%d]: ',op));if isempty(v),v=op;end
if v==3,base.modelo_VLP='DR';elseif v==2,base.modelo_VLP='HB';else,base.modelo_VLP='simplified';end
[modo_jgl,max_iter]=jgl_menu_aproximacion('automatico',10);base.jgl_max_iter=max_iter;
tratamiento_curva=sens_menu_tratamiento_curva('BALANCE JGL/GL','DISCRETO');
if tratamiento_curva.cancelado,fprintf('Balance energetico cancelado antes del barrido.\n');return;endif
try,[qmax_ipr_poly,~]=ipr(base,base.modelo_IPR);tratamiento_curva.limite_ql_m3d=qmax_ipr_poly*86400;catch,tratamiento_curva.limite_ql_m3d=NaN;end_try_catch
tratamiento_JGL=tratamiento_curva;tratamiento_JGL.sistema='JGL';
tratamiento_GL=tratamiento_curva;tratamiento_GL.sistema='GL';
qmin=aos_qiny_limite_m3s(base,'min',0);qmax=aos_qiny_limite_m3s(base,'max',60000);npts=aos_sensibilidad_n_puntos_default(15);
fprintf('\n--- LIMITES DEL BARRIDO ---\nQiny min %.0f Sm3/d\nQiny max %.0f Sm3/d\nN puntos %d\n',aos_m3s_a_sm3d(qmin),aos_m3s_a_sm3d(qmax),npts);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
 v=input(sprintf('  Qiny min (Sm3/d) [%.0f]: ',aos_m3s_a_sm3d(qmin)));if ~isempty(v),qmin=aos_sm3d_a_m3s(max(v,0));end
 v=input(sprintf('  Qiny max (Sm3/d) [%.0f]: ',aos_m3s_a_sm3d(qmax)));if ~isempty(v),qmax=aos_sm3d_a_m3s(max(v,0));end
 v=input(sprintf('  N puntos [%d]: ',npts));if ~isempty(v),npts=max(2,round(v));end
end
qvals=linspace(qmin,qmax,npts);qvals=sens_agregar_qiny_referencia(qvals,base);npts=numel(qvals);
P=cell(1,npts);for i=1:npts,p=base;p=aos_set_qiny(p,qvals(i)*86400,'fijo');p.jgl_max_iter=max_iter;P{i}=p;end
RJ=jgl_sensibilidad_parametrica(P,qvals,modo_jgl);
sens_abreviado_imprimir(RJ, numel(qvals));
QlJ=RJ.Ql;QoJ=RJ.Qo;QlG=NaN(1,npts);QoG=NaN(1,npts);ValCurG=false(1,npts);ValOptG=false(1,npts);Pcomp=NaN(1,npts);PhJ=NaN(1,npts);PhG=NaN(1,npts);IndiceJ=NaN(1,npts);IndiceG=NaN(1,npts);EficJetJ=NaN(1,npts);Ptr=NaN(1,npts);Pdisp=NaN(1,npts);EnergiaJ=cell(1,npts);EnergiaG=cell(1,npts);
Patm=101325;k=1.30;rho_l=base.rho_o*(1-base.WC)+base.rho_w*base.WC;
for i=1:npts
 q=qvals(i);m=q*base.rho_g_std;ratio=max(base.P_iny_sup/Patm,1);
 Pcomp(i)=m*base.cp_gas*base.T_sup*(ratio^((k-1)/k)-1)/base.eta_comp;
 try
   Eg=sens_gl_evaluar_punto(base,q,struct('n_puntos',1201,'preliminar',false));
   QlG(i)=Eg.Ql;QoG(i)=Eg.Qo;ValCurG(i)=Eg.valido_para_curva;ValOptG(i)=Eg.valido_para_optimo;
   if ~Eg.valido_para_curva,fprintf(2,'GL punto %d rechazado: %s\n',i,Eg.estado);endif
 catch err
   fprintf('Error GL punto %d: %s\n',i,err.message);
 end_try_catch
 s=RJ.soluciones{i};
 if isfinite(QlJ(i))
   ej=aos_balance_energia_sla('JGL',P{i},QlJ(i),QoJ(i),q,s);
   EnergiaJ{i}=ej;metj=aos_metricas_energia_sla(ej,'JGL');PhJ(i)=ej.potencia_util_fondo_kW*1000;IndiceJ(i)=metj.indice_energetico_bruto_fondo_pct;EficJetJ(i)=metj.eficiencia_interna_jet_pct;
 endif
 if isfinite(QlG(i))
   sg=struct();
   eg=aos_balance_energia_sla('GL',base,QlG(i),QoG(i),q,sg);
   EnergiaG{i}=eg;metg=aos_metricas_energia_sla(eg,'GL');PhG(i)=eg.potencia_util_fondo_kW*1000;IndiceG(i)=metg.indice_energetico_bruto_fondo_pct;
 endif
 if isfield(s,'potencia_transferida'),Ptr(i)=s.potencia_transferida;end;if isfield(s,'potencia_disponible'),Pdisp(i)=s.potencia_disponible;end
end
% Solo declarar optimo si existen al menos dos eficiencias finitas y la curva no es plana.
plJ=true;plG=true;detJ=struct('rango',NaN,'umbral',NaN);detG=detJ;
if sum(isfinite(IndiceJ))>=2,[plJ,detJ]=sens_detectar_curva_plana(IndiceJ);end
if isfield(RJ,'preliminar')&&RJ.preliminar,plJ=true;end
if sum(isfinite(IndiceG))>=2,[plG,detG]=sens_detectar_curva_plana(IndiceG);end
qoptJ=NaN;eoptJ=NaN;qoptG=NaN;eoptG=NaN;if ~plJ,[qoptJ,eoptJ]=encontrar_optimo(qvals,IndiceJ);end;if ~plG,[qoptG,eoptG]=encontrar_optimo(qvals,IndiceG);end
if plJ,fprintf('\nJGL: indice energetico plano/no evaluable; no se declara optimo.\n');elseif isfinite(qoptJ),fprintf('\nMaximo indice energetico JGL: %.0f Sm3/d, %.2f %%\n',qoptJ*86400,eoptJ);end
if plG,fprintf('GL : indice energetico plano/no evaluable; no se declara optimo.\n');elseif isfinite(qoptG),fprintf('Maximo indice energetico GL: %.0f Sm3/d, %.2f %%\n',qoptG*86400,eoptG);end


econ=sens_configurar_economia_inyeccion();
valCurJ=isfinite(QlJ)&isfinite(QoJ);valOptJ=valCurJ;
if isfield(RJ,'valido_para_curva'),valCurJ=logical(RJ.valido_para_curva);endif
if isfield(RJ,'valido_para_optimo'),valOptJ=logical(RJ.valido_para_optimo);endif
valCurG=ValCurG&isfinite(QlG)&isfinite(QoG);valOptG=ValOptG&valCurG;
OPT_JGL=sens_optimo_inyeccion(qvals*86400,IndiceJ,QlJ*86400,QoJ*86400,valOptJ,econ,tratamiento_JGL,valCurJ);
OPT_GL=sens_optimo_inyeccion(qvals*86400,IndiceG,QlG*86400,QoG*86400,valOptG,econ,tratamiento_GL,valCurG);
if tratamiento_curva.verificar_optimo
 optsj=struct('modo',lower(RJ.modo_final_uniforme),'nodal_n_puntos',1201,'jgl_n_puntos',120, ...
  'preliminar',RJ.preliminar,'tolerancia_verificacion_rel',0.05,'tolerancia_verificacion_abs_m3d',0.5);
 if RJ.preliminar&&any(strcmp(lower(modo_jgl),{'abreviado','movil'})),optsj.nodal_n_puntos=121;optsj.jgl_n_puntos=81;endif
 [OPT_JGL,VER_POLY_JGL]=sens_verificar_optimo_polinomico(OPT_JGL,'JGL',base,optsj);
 optsg=struct('n_puntos',1201,'preliminar',false,'tolerancia_verificacion_rel',0.05,'tolerancia_verificacion_abs_m3d',0.5);
 [OPT_GL,VER_POLY_GL]=sens_verificar_optimo_polinomico(OPT_GL,'GL',base,optsg);
else
 VER_POLY_JGL=struct('estado','NO_SOLICITADA','verificado',false);VER_POLY_GL=VER_POLY_JGL;
 OPT_JGL.verificacion_polinomica=VER_POLY_JGL;OPT_GL.verificacion_polinomica=VER_POLY_GL;
endif
sens_imprimir_optimo_inyeccion('JGL',OPT_JGL);
sens_imprimir_optimo_inyeccion('GL',OPT_GL);
AUD_ENERGIA=sens_auditar_indice_jgl_gl(qvals*86400,IndiceJ,IndiceG,1e-6);
for ia=1:numel(AUD_ENERGIA.mensajes),fprintf('%s\n',AUD_ENERGIA.mensajes{ia});endfor
fprintf('\n=== BALANCE ENERGETICO JGL vs GL ===\n');
fprintf('Qiny | QlJ | QlG | Pcomp(kW) | PhJ(kW) | PhG(kW) | Ind.bruto J | Ind.bruto G | Efic.jet J | Ptr/Pdisp(kW) | Iter | Modo | Estado\n');
for i=1:npts
 ij='N/A';ig='N/A';jj='N/A';if isfinite(IndiceJ(i)),ij=sprintf('%.2f',IndiceJ(i));end;if isfinite(IndiceG(i)),ig=sprintf('%.2f',IndiceG(i));end;if isfinite(EficJetJ(i)),jj=sprintf('%.2f',EficJetJ(i));end
 fprintf('%6.0f | %7.2f | %7.2f | %9.2f | %7.2f | %7.2f | %12s | %12s | %10s | %7.2f/%7.2f | %4d | %s | %s\n',qvals(i)*86400,QlJ(i)*86400,QlG(i)*86400,Pcomp(i)/1000,PhJ(i)/1000,PhG(i)/1000,ij,ig,jj,Ptr(i)/1000,Pdisp(i)/1000,RJ.iteraciones(i),RJ.modos{i},RJ.estados{i});
end
figure;subplot(2,1,1);plot(qvals*86400,IndiceJ,'-o',qvals*86400,IndiceG,'--s','LineWidth',2);grid on;xlabel('Qiny (Sm3/d)');ylabel('Indice energetico bruto de fondo (%)');legend('JGL','GL','Location','northeast');title('Indice QP producido / QP inyectado en fondo (Qiny=0 es N/A)');
subplot(2,1,2);plot(qvals*86400,PhJ/1000,'-o',qvals*86400,PhG/1000,'--s',qvals*86400,Pcomp/1000,'-','LineWidth',1.5);grid on;xlabel('Qiny (Sm3/d)');ylabel('Potencia (kW)');legend('QP producido fondo JGL','QP producido fondo GL','Compresor superficie ref.','Location','northeast');title('Indices de flujo-presion en fondo y potencia compresora de referencia');
exportar_grafico_modulo();

SENS_BALANCE_ENERGETICO_AUDIT=struct('Qiny_Sm3_d',qvals*86400, ...
  'Ql_JGL_m3d',QlJ*86400,'Ql_GL_m3d',QlG*86400,'P_compresor_kW',Pcomp/1000, ...
  'P_hidraulica_JGL_kW',PhJ/1000,'P_hidraulica_GL_kW',PhG/1000, ...
  'Indice_energetico_bruto_JGL_pct',IndiceJ,'Indice_energetico_bruto_GL_pct',IndiceG, ...
  'Eficiencia_interna_jet_JGL_pct',EficJetJ,'energia_JGL_por_punto',{EnergiaJ}, ...
  'energia_GL_por_punto',{EnergiaG},'auditoria_comparacion_energia',AUD_ENERGIA, ...
  'Eficiencia_JGL_pct',IndiceJ,'Eficiencia_GL_pct',IndiceG,'metodo_energia','INDICE_QP_LOCAL_FONDO', ...
  'P_transferida_kW',Ptr/1000,'P_disponible_kW',Pdisp/1000, ...
  'iteraciones',RJ.iteraciones,'modos',{RJ.modos},'estados',{RJ.estados}, ...
  'valido_para_curva_JGL',valCurJ,'valido_para_optimo_JGL',valOptJ, ...
  'valido_para_curva_GL',valCurG,'valido_para_optimo_GL',valOptG, ...
  'tratamiento_curva',tratamiento_curva,'tratamiento_curva_JGL',tratamiento_JGL, ...
  'tratamiento_curva_GL',tratamiento_GL,'verificacion_polinomica_JGL',VER_POLY_JGL, ...
  'verificacion_polinomica_GL',VER_POLY_GL, ...
  'optimizacion_JGL',OPT_JGL,'optimizacion_GL',OPT_GL,'economia',econ);
assignin('base','SENS_BALANCE_ENERGETICO_AUDIT',SENS_BALANCE_ENERGETICO_AUDIT);


figure;
hayj=isfield(OPT_JGL,'x_derivada_sm3d')&&~isempty(OPT_JGL.x_derivada_sm3d);
hayg=isfield(OPT_GL,'x_derivada_sm3d')&&~isempty(OPT_GL.x_derivada_sm3d);
legd={};
if hayj,plot(OPT_JGL.x_derivada_sm3d,OPT_JGL.derivada_rendimiento_pct_por_Sm3d,'-','LineWidth',2);hold on;legd{end+1}='JGL';endif
if hayg,plot(OPT_GL.x_derivada_sm3d,OPT_GL.derivada_rendimiento_pct_por_Sm3d,'--','LineWidth',2);legd{end+1}='GL';endif
if ~hayj&&~hayg,plot(NaN,NaN);text(0.1,0.5,'Derivadas no disponibles.');else,legend(legd,'Location','northeast');endif
grid on;xlabel('Qiny (Sm3/d)');ylabel('dI bruto/dQiny');title(sprintf('Derivada del indice - %s',tratamiento_curva.modo));
exportar_grafico_modulo();
if econ.habilitado
 figure;plot(OPT_JGL.economico.qiny_sm3d,OPT_JGL.economico.resultado_neto_dia,'-o','LineWidth',2);hold on;
 plot(OPT_GL.economico.qiny_sm3d,OPT_GL.economico.resultado_neto_dia,'--s','LineWidth',2);grid on;
 xlabel('Qiny (Sm3/d)');ylabel(sprintf('Resultado neto (%s/d)',econ.moneda));legend('JGL','GL','Location','northeast');title('Resultado economico de la inyeccion');exportar_grafico_modulo();
endif

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_BALANCE_ENERGETICO_AUDIT', 'Balance energetico JGL vs GL', base, 'JGL_GL');
