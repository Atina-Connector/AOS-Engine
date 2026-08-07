% sens_etapas_BES.m - Sensibilidad BES al numero de etapas. GNU Octave.
script_dir=fileparts(mfilename('fullpath')); AOS_root=fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root,'src'),'-begin'); addpath(script_dir,'-begin'); iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);
[base,origen_base]=sens_cargar_base(); %#ok<NASGU>
base=sens_bes_preparar_base(base);
fprintf('\n--- BASE BES ---\nIP %.3f m3/d/bar | Pwh %.2f bar | D_bomba %.1f m | f %.1f Hz | etapas %.0f\n',base.IP*86400*1e5,base.P_wh/1e5,base.D_bomba,base.frecuencia,base.num_etapas);
if aos_preguntar_sn('Desea modificar base? (s/n) [n]: ', false)
  v=input(sprintf('  IP (m3/d/bar) [%.3f]: ',base.IP*86400*1e5)); if ~isempty(v), base.IP=v/(86400*1e5); end
  v=input(sprintf('  P_wh (bar) [%.2f]: ',base.P_wh/1e5)); if ~isempty(v), base.P_wh=v*1e5; end
  v=input(sprintf('  D_bomba (m) [%.1f]: ',base.D_bomba)); if ~isempty(v), base=aos_set_profundidad(base,'BES',v); end
  v=input(sprintf('  Frecuencia (Hz) [%.1f]: ',base.frecuencia)); if ~isempty(v), base.frecuencia=v; end
end
base=sens_bes_preparar_base(base);
nmin=10; nmax=200; npts=12;
fprintf('\nEtapas min %.0f | max %.0f | puntos %d\n',nmin,nmax,npts);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v=input(sprintf('  Etapas min [%.0f]: ',nmin)); if ~isempty(v), nmin=v; end
  v=input(sprintf('  Etapas max [%.0f]: ',nmax)); if ~isempty(v), nmax=v; end
  v=input(sprintf('  N puntos [%d]: ',npts)); if ~isempty(v), npts=max(2,round(v)); end
end
modo_calc_bes=sens_menu_modo_general('BES');
if strcmp(modo_calc_bes,'abreviado')
  n_solicitados=npts;
  npts=min(npts,7);
  fprintf('Modo abreviado: %d puntos solicitados -> %d puntos ancla calculados.\n',n_solicitados,npts);
end
x=unique(round(linspace(nmin,nmax,npts))); npts=numel(x);
Ql=NaN(1,npts); Qo=Ql; Tint=Ql; RL=Ql; Pint=Ql; Neff=Ql; estado=cell(1,npts); resultados=cell(1,npts);
for i=1:npts
  p=base; p.num_etapas=x(i); p=sens_bes_preparar_base(p);
  r=sens_bes_evaluar(p); resultados{i}=r;
  Neff(i)=r.audit.num_etapas_efectivo; Ql(i)=r.Ql*86400; Qo(i)=r.Qo*86400;
  Tint(i)=r.T_motor; RL(i)=r.run_life; Pint(i)=r.P_intake/1e5; estado{i}=r.estado;
end
if strcmp(modo_calc_bes,'abreviado'), A_abrev=sens_abreviado_resumen_xy(x,Qo,'BES'); end
info=sens_clasificar_curva(x,Qo); fprintf('\nClasificacion: %s - %s\n',info.tipo,info.mensaje);
if strcmp(info.tipo,'OPTIMO_INTERIOR'), fprintf('Optimo interior: %.0f etapas, Qo %.2f m3/d\n',info.optimo_x,info.optimo_y); end
fprintf('\nEtapas req | Etapas eff | Ql | Qo | P_intake(bar) | T_motor(C) | RunLife(d) | Estado\n');
for i=1:npts
  fprintf('%10.0f | %10.0f | %8.2f | %8.2f | %13.2f | %10.2f | %10.1f | %s\n',x(i),Neff(i),Ql(i),Qo(i),Pint(i),Tint(i),RL(i),estado{i});
end
SENS_ETAPAS_BES_AUDIT=struct('solicitado',x,'efectivo',Neff,'resultados',{resultados},'clasificacion',info);
assignin('base','SENS_ETAPAS_BES_AUDIT',SENS_ETAPAS_BES_AUDIT);
figure;
subplot(2,1,1); plot(x,Ql,'-o','LineWidth',2); grid on; xlabel('Numero de etapas'); ylabel('Ql (m3/d)'); title('BES: produccion vs etapas');
subplot(2,1,2); plot(x,Pint,'-s','LineWidth',2); grid on; xlabel('Numero de etapas'); ylabel('P intake (bar)'); title('BES: intake vs etapas');
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_ETAPAS_BES_AUDIT', 'Etapas BES', base, 'BES');
