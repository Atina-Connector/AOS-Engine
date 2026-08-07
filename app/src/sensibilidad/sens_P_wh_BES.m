% sens_P_wh_BES.m - Sensibilidad BES a presion de cabeza. GNU Octave.
script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root,'src'),'-begin');
addpath(script_dir,'-begin');
iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);

[base, origen_base] = sens_cargar_base(); %#ok<NASGU>
base = sens_bes_preparar_base(base);
xmin = max(1, 0.5*base.P_wh/1e5);
xmax = max(xmin+1, 1.5*base.P_wh/1e5);
npts = 12;
fprintf('\nPwh actual %.2f bar | rango %.2f-%.2f bar\n',base.P_wh/1e5,xmin,xmax);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v=input(sprintf('  Pwh min [%.2f]: ',xmin)); if ~isempty(v), xmin=v; end
  v=input(sprintf('  Pwh max [%.2f]: ',xmax)); if ~isempty(v), xmax=v; end
  v=input(sprintf('  N puntos [%d]: ',npts)); if ~isempty(v), npts=max(2,round(v)); end
end
modo_calc_bes=sens_menu_modo_general('BES');
if strcmp(modo_calc_bes,'abreviado')
  n_solicitados=npts;
  npts=min(npts,7);
  fprintf('Modo abreviado: %d puntos solicitados -> %d puntos ancla calculados.\n',n_solicitados,npts);
end
x=linspace(xmin,xmax,npts);
Ql=NaN(1,npts); Qo=Ql; Pint=Ql; Peff=Ql; RL=Ql; estado=cell(1,npts); resultados=cell(1,npts);
for i=1:npts
  p=base; p.P_wh=x(i)*1e5; p=sens_bes_preparar_base(p);
  r=sens_bes_evaluar(p); resultados{i}=r;
  Peff(i)=r.audit.P_wh_efectivo_bar; Ql(i)=r.Ql*86400; Qo(i)=r.Qo*86400;
  Pint(i)=r.P_intake/1e5; RL(i)=r.run_life; estado{i}=r.estado;
end
if strcmp(modo_calc_bes,'abreviado'), A_abrev=sens_abreviado_resumen_xy(x,Qo,'BES'); end
info=sens_clasificar_curva(x,Qo);
fprintf('\nClasificacion: %s - %s\n',info.tipo,info.mensaje);
fprintf('\nPwh_solic | Pwh_efect | Ql | Qo | P_intake | RunLife | Estado\n');
for i=1:npts
  fprintf('%10.2f | %10.2f | %8.2f | %8.2f | %10.2f | %10.1f | %s\n',x(i),Peff(i),Ql(i),Qo(i),Pint(i),RL(i),estado{i});
end
SENS_PWH_BES_AUDIT=struct('solicitado_bar',x,'efectivo_bar',Peff,'resultados',{resultados},'clasificacion',info);
assignin('base','SENS_PWH_BES_AUDIT',SENS_PWH_BES_AUDIT);
figure; plot(x,Ql,'-o','LineWidth',2); grid on;
xlabel('Pwh (bar)'); ylabel('Ql (m3/d)'); title('BES: sensibilidad a Pwh');
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_PWH_BES_AUDIT', 'Presion de cabeza BES', base, 'BES');
