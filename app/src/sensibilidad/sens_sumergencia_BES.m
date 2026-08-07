% sens_sumergencia_BES.m - Sensibilidad BES a profundidad de bomba. GNU Octave.
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
dmin=max(100,min(base.D_bomba,500)); dmax=min(base.D_res,max(base.D_bomba,base.D_res)); npts=12;
fprintf('\nD_bomba actual %.1f m | rango %.1f-%.1f m | puntos %d\n',base.D_bomba,dmin,dmax,npts);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v=input(sprintf('  D min (m) [%.1f]: ',dmin)); if ~isempty(v), dmin=v; end
  v=input(sprintf('  D max (m) [%.1f]: ',dmax)); if ~isempty(v), dmax=v; end
  v=input(sprintf('  N puntos [%d]: ',npts)); if ~isempty(v), npts=max(2,round(v)); end
end
modo_calc_bes=sens_menu_modo_general('BES');
if strcmp(modo_calc_bes,'abreviado')
  n_solicitados=npts;
  npts=min(npts,7);
  fprintf('Modo abreviado: %d puntos solicitados -> %d puntos ancla calculados.\n',n_solicitados,npts);
end
x=linspace(dmin,dmax,npts);
Ql=NaN(1,npts); Qo=Ql; Tint=Ql; RL=Ql; Pint=Ql; Deff=Ql; estado=cell(1,npts); resultados=cell(1,npts);
for i=1:npts
  p=aos_set_profundidad(base,'BES',x(i)); p=sens_bes_preparar_base(p);
  r=sens_bes_evaluar(p); resultados{i}=r;
  Deff(i)=r.audit.D_bomba_efectiva_m; Ql(i)=r.Ql*86400; Qo(i)=r.Qo*86400;
  Tint(i)=r.T_motor; RL(i)=r.run_life; Pint(i)=r.P_intake/1e5; estado{i}=r.estado;
end
if strcmp(modo_calc_bes,'abreviado'), A_abrev=sens_abreviado_resumen_xy(x,Qo,'BES'); end
info=sens_clasificar_curva(x,Qo); fprintf('\nClasificacion: %s - %s\n',info.tipo,info.mensaje);
if strcmp(info.tipo,'OPTIMO_INTERIOR'), fprintf('Optimo interior: D %.1f m, Qo %.2f m3/d\n',info.optimo_x,info.optimo_y); end
fprintf('\nD_solic(m) | D_efect(m) | Ql | Qo | P_intake(bar) | T_motor(C) | RunLife(d) | Estado\n');
for i=1:npts
  fprintf('%10.1f | %10.1f | %8.2f | %8.2f | %13.2f | %10.2f | %10.1f | %s\n',x(i),Deff(i),Ql(i),Qo(i),Pint(i),Tint(i),RL(i),estado{i});
end
SENS_SUMERGENCIA_BES_AUDIT=struct('solicitado_m',x,'efectivo_m',Deff,'resultados',{resultados},'clasificacion',info);
assignin('base','SENS_SUMERGENCIA_BES_AUDIT',SENS_SUMERGENCIA_BES_AUDIT);
figure;
subplot(2,1,1); plot(x,Ql,'-o','LineWidth',2); grid on; xlabel('D_bomba (m)'); ylabel('Ql (m3/d)'); title('BES: produccion vs profundidad');
subplot(2,1,2); plot(x,Tint,'-s','LineWidth',2); grid on; xlabel('D_bomba (m)'); ylabel('T motor (C)'); title('BES: temperatura vs profundidad');
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_SUMERGENCIA_BES_AUDIT', 'Sumergencia BES', base, 'BES');
