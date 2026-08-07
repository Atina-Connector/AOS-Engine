% sens_frecuencia_BES.m - Sensibilidad BES a frecuencia. GNU Octave.
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
xmin=max(20,0.7*base.frecuencia); xmax=min(90,1.3*base.frecuencia); npts=12;
fprintf('\nFrecuencia actual %.1f Hz | rango %.1f-%.1f Hz\n',base.frecuencia,xmin,xmax);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v=input(sprintf('  f min [%.1f]: ',xmin)); if ~isempty(v), xmin=v; end
  v=input(sprintf('  f max [%.1f]: ',xmax)); if ~isempty(v), xmax=v; end
  v=input(sprintf('  N puntos [%d]: ',npts)); if ~isempty(v), npts=max(2,round(v)); end
end
modo_calc_bes=sens_menu_modo_general('BES');
if strcmp(modo_calc_bes,'abreviado')
  n_solicitados=npts;
  npts=min(npts,7);
  fprintf('Modo abreviado: %d puntos solicitados -> %d puntos ancla calculados.\n',n_solicitados,npts);
end
x=linspace(xmin,xmax,npts);
Ql=NaN(1,npts); Qo=Ql; Tint=Ql; RL=Ql; I=Ql; Feff=Ql; estado=cell(1,npts); resultados=cell(1,npts);
for i=1:npts
  p=base; p.frecuencia=x(i); p=sens_bes_preparar_base(p);
  r=sens_bes_evaluar(p); resultados{i}=r;
  Feff(i)=r.audit.frecuencia_efectiva_Hz; Ql(i)=r.Ql*86400; Qo(i)=r.Qo*86400;
  Tint(i)=r.T_motor; RL(i)=r.run_life; I(i)=r.corriente; estado{i}=r.estado;
end
if strcmp(modo_calc_bes,'abreviado'), A_abrev=sens_abreviado_resumen_xy(x,Qo,'BES'); end
info=sens_clasificar_curva(x,Qo); fprintf('\nClasificacion: %s - %s\n',info.tipo,info.mensaje);
if strcmp(info.tipo,'OPTIMO_INTERIOR'), fprintf('Optimo interior %.1f Hz, Qo %.2f m3/d\n',info.optimo_x,info.optimo_y); end
fprintf('\nf_solic | f_efect | Ql | Qo | Tmotor | Corriente | RunLife | Estado\n');
for i=1:npts
  fprintf('%7.1f | %7.1f | %8.2f | %8.2f | %7.2f | %9.2f | %10.1f | %s\n',x(i),Feff(i),Ql(i),Qo(i),Tint(i),I(i),RL(i),estado{i});
end
SENS_FRECUENCIA_BES_AUDIT=struct('solicitado_Hz',x,'efectivo_Hz',Feff,'resultados',{resultados},'clasificacion',info);
assignin('base','SENS_FRECUENCIA_BES_AUDIT',SENS_FRECUENCIA_BES_AUDIT);
figure;
subplot(2,1,1); plot(x,Ql,'-o','LineWidth',2); grid on; xlabel('Frecuencia (Hz)'); ylabel('Ql (m3/d)'); title('BES: produccion vs frecuencia');
subplot(2,1,2); plot(x,Tint,'-s','LineWidth',2); grid on; xlabel('Frecuencia (Hz)'); ylabel('T motor (C)'); title('BES: temperatura vs frecuencia');
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_FRECUENCIA_BES_AUDIT', 'Frecuencia BES', base, 'BES');
