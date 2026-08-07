% sens_RunLife_BES.m - Run life y potencia electrica BES vs frecuencia. GNU Octave.
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
if aos_preguntar_sn('Desea modificar rango de frecuencia? (s/n) [n]: ', false)
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
RL=NaN(1,npts); PkW=RL; Tint=RL; Ql=RL; Feff=RL; estado=cell(1,npts); resultados=cell(1,npts);
for i=1:npts
  p=base; p.frecuencia=x(i); p=sens_bes_preparar_base(p);
  r=sens_bes_evaluar(p); resultados{i}=r;
  Feff(i)=r.audit.frecuencia_efectiva_Hz; RL(i)=r.run_life; Tint(i)=r.T_motor; Ql(i)=r.Ql*86400;
  PkW(i)=r.corriente*r.param.voltaje_motor*sqrt(3)/1000; estado{i}=r.estado;
end
if strcmp(modo_calc_bes,'abreviado'), A_abrev=sens_abreviado_resumen_xy(x,RL,'BES RunLife'); end
info=sens_clasificar_curva(x,RL); fprintf('\nClasificacion Run Life: %s - %s\n',info.tipo,info.mensaje);
fprintf('\nf_solic | f_efect | Ql | Potencia(kW) | Tmotor(C) | RunLife(d) | Estado\n');
for i=1:npts
  fprintf('%7.1f | %7.1f | %8.2f | %12.2f | %9.2f | %10.1f | %s\n',x(i),Feff(i),Ql(i),PkW(i),Tint(i),RL(i),estado{i});
end
SENS_RUNLIFE_BES_AUDIT=struct('solicitado_Hz',x,'efectivo_Hz',Feff,'resultados',{resultados},'clasificacion',info);
assignin('base','SENS_RUNLIFE_BES_AUDIT',SENS_RUNLIFE_BES_AUDIT);
figure;
subplot(2,1,1); plot(x,RL,'-o','LineWidth',2); grid on; xlabel('Frecuencia (Hz)'); ylabel('Run Life (dias)'); title('BES: Run Life vs frecuencia');
subplot(2,1,2); plot(x,PkW,'-s','LineWidth',2); grid on; xlabel('Frecuencia (Hz)'); ylabel('Potencia electrica (kW)'); title('BES: potencia vs frecuencia');
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_RUNLIFE_BES_AUDIT', 'Run Life BES', base, 'BES');
