function archivo = sens_exportar_resultados(nombre_variable, titulo, param, sistema)
% AOS_0_1_0_SENSIBILIDADES_TABLAS_TEXTO_NATIVO
% SENS_EXPORTAR_RESULTADOS Exportador comun y auditable de sensibilidades.
% GNU Octave. Contrato AOSRPT 1.7 para AOS Viewer.
% SENS-GLJGL-02 agrega tratamiento polinomico explicito.
% SENS-GLJGL-03 agrega el contrato de presion motriz JGL por Qiny.
%
% Reglas:
%   - Nunca serializa estructuras internas completas.
%   - El Viewer recibe solo unidades de usuario: bar, m, m3/d, Sm3/d, Hz.
%   - Cada punto se escribe como una fila de [SENSITIVITY_TABLE].
%   - Las tablas se serializan como texto y datos nativos, nunca como PNG.
%   - El enriquecido captura solo graficos reales de la sensibilidad y agrega
%     imagenes independientes de survey y punzados.
  archivo = '';
  if nargin < 4 || isempty(sistema), sistema = 'SENSIBILIDAD'; end
  if nargin < 3 || isempty(param), param = struct(); end
  if evalin('base', sprintf("exist('%s','var')", nombre_variable)) ~= 1
    fprintf('ADVERTENCIA: no se encontro %s; no se puede exportar.\n', nombre_variable);
    return;
  end
  datos = evalin('base', nombre_variable);
  paquete = sens_construir_paquete(datos, titulo, sistema);

  fprintf('\n--- EXPORTAR RESULTADOS DE SENSIBILIDAD ---\n');
  fprintf('1 - .aosrpt ligero (tabla completa + ganancias)\n');
  fprintf('2 - .aosrpt enriquecido (tabla textual + graficos + survey + punzados)\n');
  fprintf('3 - CSV\n');
  fprintf('0 - No exportar\n');
  op = input('Seleccione una opcion [0]: ');
  if isempty(op), op = 0; end
  if ~ismember(op,[0 1 2 3]), fprintf('Opcion invalida. No se exporta.\n'); return; end
  if op == 0, return; end

  carpeta_defecto = fullfile('intercambio','reportes','enviados');
  carpeta = aos_report_choose_directory(carpeta_defecto);
  base_nombre = regexprep([aos_nombre_pozo_local(param) '_' regexprep(lower(titulo),'[^a-zA-Z0-9]+','_')], '_+$','');
  ext = '.aosrpt'; if op == 3, ext = '.csv'; end
  fprintf('Nombre propuesto: %s%s\n', base_nombre, ext);
  nuevo = strtrim(input(sprintf('Nombre del archivo sin extension [%s]: ',base_nombre),'s'));
  if ~isempty(nuevo), base_nombre = regexprep(nuevo,'\.(aosrpt|csv)$',''); end
  archivo = fullfile(carpeta,[base_nombre ext]);

  if op == 3
    sens_escribir_csv(archivo, paquete);
    fprintf('CSV exportado: %s\n', archivo);
    return;
  end

  incluir = aos_preguntar_sn('Incluir survey, tubing, punzados y equipo de fondo? (s/n) [s]: ',true);
  sens_escribir_aosrpt(archivo, titulo, sistema, paquete, param, incluir, op==2);
  if exist('aos_finalizar_archivo_crypto','file') == 2
    aos_finalizar_archivo_crypto(archivo,true);
  else
    fprintf('ADVERTENCIA: modulo crypto no disponible; archivo guardado en texto plano.\n');
  end
  fprintf('Reporte exportado: %s\n', archivo);
end

function sens_escribir_aosrpt(archivo,titulo,sistema,p,param,incluir,enriquecido)
  tabla=tabla_nativa_local(p,titulo);
  tabla.role='SENSITIVITY_TABLE';tabla.category='SENSITIVITY';tabla.priority='PRIMARY';
  tabla.default_mode='FULL_BODY';tabla.mandatory=true;tabla.source='AOS_SENSITIVITY_SOLVER';
  [param,tablas,comp]=aos_report_prepare_tables(param,sistema,tabla,struct());
  n_graficos=0;
  if enriquecido&&exist('aos_registro_graficos','file')==2
    try,r=aos_registro_graficos('list');n_graficos=numel(r);catch,n_graficos=0;end_try_catch
  endif
  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear %s',archivo);endif
  c=onCleanup(@() fclose(fid));
  fprintf(fid,'[AOS_REPORT]\nversion=1.7\nviewer_schema=AOS_VIEWER_SENSITIVITY_1.3\n');
  fprintf(fid,'fecha=%s\nsistema=%s\nmodulo=SENSIBILIDAD\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),sistema);
  fprintf(fid,'titulo=%s\nnombre_pozo=%s\n',limpiar_txt(titulo),aos_nombre_pozo_local(param));
  fprintf(fid,'formato=%s\ncontract_revision=AOSRPT_TABLES_1.1\n',cond(enriquecido,'ENRIQUECIDO','LIGERO'));
  [~,rid,~]=fileparts(archivo);mi=struct('report_id',rid,'report_type',[regexprep(upper(sistema),'[^A-Z0-9_-]+','_') '_SENSITIVITY'], ...
    'module',regexprep(upper(sistema),'[^A-Z0-9_-]+','_'),'workbench','AOS_SLA','viewer_schema','AOS_VIEWER_SENSITIVITY_1.3','graphics_count',n_graficos);
  aos_report_write_manifest(fid,mi,comp);

  fprintf(fid,'\n[SENSITIVITY_SUMMARY]\nvariable=%s\nunidad_variable=%s\nmetodo=%s\nn_puntos=%d\n',p.variable,p.unidad_variable,p.metodo,p.n);
  if p.n>0,xv=p.columnas{1};fprintf(fid,'rango_min=%.10g\nrango_max=%.10g\n',min_finito(xv),max_finito(xv));endif
  fprintf(fid,'puntos_aceptados=%d\npuntos_rechazados=%d\npuntos_validos_curva=%d\npuntos_validos_optimo=%d\nconfianza_global=%s\nclasificacion_principal=%s\nmensaje=%s\n', ...
    sum(p.aceptado),sum(~p.aceptado),sum(p.valido_para_curva),sum(p.valido_para_optimo), ...
    p.confianza_global,p.clasificacion_principal,limpiar_txt(p.mensaje));
  fprintf(fid,'tabla_punto_a_punto=SI\ntable_id=%s\nrender_mode=%s\n',tablas(1).id,tablas(1).render_mode);
  if isfinite(p.referencia_variable),fprintf(fid,'referencia_variable=%.10g\nreferencia_tipo=%s\n',p.referencia_variable,p.referencia_tipo);endif
  if ~isempty(p.ganancias)
    for ig=1:numel(p.ganancias),gg=p.ganancias(ig);clave=campo_seguro_local(gg.respuesta);fprintf(fid,'ganancia_%s_base=%.10g\n',clave,gg.valor_base);if isfinite(gg.ganancia_max_pct),fprintf(fid,'ganancia_%s_max_pct=%.10g\nganancia_%s_variable_max=%.10g\n',clave,gg.ganancia_max_pct,clave,gg.variable_ganancia_max);endif,endfor
  endif
  diag=aos_sensibilidad_diagnosticar(p,sistema,param);aos_rpt_escribir_diagnostico(fid,diag);
  aos_rpt_escribir_tablas(fid,tablas,comp);
  aos_report_write_reference(fid,'SENSITIVITY_TABLE',tablas(1),'DISPONIBLE');
  sens_escribir_resumen_ganancias(fid,p);
  sens_escribir_tratamiento_curva_local(fid,p);
  sens_escribir_presion_motriz_jgl_local(fid,p);
  sens_escribir_clasificacion(fid,'JGL',p.clasificacion_JGL,p);
  sens_escribir_clasificacion(fid,'GL',p.clasificacion_GL,p);
  sens_escribir_clasificacion(fid,'BES',p.clasificacion_BES,p);
  if exist('aos_exportar_contexto_viewer','file')==2,aos_exportar_contexto_viewer(fid,param,sistema,incluir);endif
  if enriquecido
    if incluir,aos_rpt_exportar_graficos_sensibilidad(fid,p,param,sistema,archivo);else,aos_rpt_exportar_graficos_sensibilidad(fid,p,struct(),sistema,archivo);endif
  endif
end

function p=sens_construir_paquete(d,titulo,sistema)
  p=struct('variable','PARAMETRO','unidad_variable','-', 'metodo','NO_INFORMADO',...
    'n',0,'nombres',{{}},'unidades',{{}},'columnas',{{}},'aceptado',[],...
    'valido_para_curva',[],'valido_para_optimo',[],...
    'confianza_global','NO_EVALUADA','clasificacion_principal','NO_EVALUADA',...
    'mensaje','Sin clasificacion','clasificacion_JGL',struct(),...
    'clasificacion_GL',struct(),'clasificacion_BES',struct(),...
    'ganancias',struct([]),'referencia_variable',NaN,...
    'referencia_tipo','NO_DEFINIDA','tratamiento_curva',struct(),...
    'tratamiento_curva_JGL',struct(),'tratamiento_curva_GL',struct(),...
    'optimizacion_JGL',struct(),'optimizacion_GL',struct(),...
    'verificacion_polinomica_JGL',struct(),'verificacion_polinomica_GL',struct(),...
    'condicion_motriz_menu',struct(),'presiones_motrices_JGL',struct(),...
    'limite_presion_JGL',struct());

  % Variable independiente y unidad visible.
  [x,xname,xunit]=sens_variable_independiente(d,titulo);
  p.variable=xname; p.unidad_variable=xunit; p.n=numel(x);
  p=sens_add_col(p,xname,xunit,x);

  % Columnas canonicas, primero las ya expresadas en unidades de usuario.
  p=add_top(p,d,{'Ql_JGL_m3d','Qo_JGL_m3d','Ql_GL_m3d','Qo_GL_m3d',...
    'Ql_JGL_polinomio_m3d','Qo_JGL_polinomio_m3d',...
    'Ql_GL_polinomio_m3d','Qo_GL_polinomio_m3d',...
    'Ql_JGL_raw_m3d','Qo_JGL_raw_m3d','Ql_GL_raw_m3d','Qo_GL_raw_m3d',...
    'Ql_raw_m3d','Qo_raw_m3d','residuo_JGL_Pa','residuo_GL_Pa',...
    'P_s_bar','P_req_bar','DeltaP_bar','iteraciones','a_eductor','b_eductor',...
    'P_succion_eductor_JGL_bar','DeltaP_motriz_requerida_JGL_bar',...
    'P_motriz_fondo_requerida_JGL_bar','P_motriz_fondo_disponible_JGL_bar',...
    'P_iny_sup_requerida_JGL_bar','P_iny_sup_disponible_JGL_bar',...
    'DeltaP_columna_gas_JGL_bar','DeltaP_friccion_inyeccion_JGL_bar',...
    'Margen_presion_JGL_bar',...
    'P_compresor_kW','P_hidraulica_JGL_kW','P_hidraulica_GL_kW',...
    'Indice_energetico_bruto_JGL_pct','Indice_energetico_bruto_GL_pct',...
    'Eficiencia_interna_jet_JGL_pct','rendimiento_energetico_JGL_pct',...
    'rendimiento_energetico_GL_pct','rendimiento_energetico_pct',...
    'Eficiencia_JGL_pct','Eficiencia_GL_pct','P_transferida_kW','P_disponible_kW',...
    'solicitado_bar','efectivo_bar','solicitado_Hz','efectivo_Hz',...
    'solicitado_m','efectivo_m'},p.n);

  % Las respuestas genericas se renombran segun el sistema para evitar
  % columnas duplicadas y conservar semantica en Viewer/CSV.
  ql_generico=get_vec(d,'Ql_m3d',p.n); qo_generico=get_vec(d,'Qo_m3d',p.n);
  ql_raw_generico=get_vec(d,'Ql_raw_m3d',p.n); qo_raw_generico=get_vec(d,'Qo_raw_m3d',p.n);
  modo_generico=first_cell({get_cell(d,'modos',p.n),get_cell(d,'modo',p.n)},p.n);
  estado_generico=first_cell({get_cell(d,'estados',p.n),get_cell(d,'estado',p.n)},p.n);
  if strcmpi(sistema,'JGL')
    p=add_num(p,'Ql_JGL_m3d','m3/d',ql_generico,p.n);
    p=add_num(p,'Qo_JGL_m3d','m3/d',qo_generico,p.n);
    p=add_num(p,'Ql_JGL_raw_m3d','m3/d',ql_raw_generico,p.n);
    p=add_num(p,'Qo_JGL_raw_m3d','m3/d',qo_raw_generico,p.n);
    p=add_cell(p,'Modo_JGL','-',modo_generico,p.n);
    p=add_cell(p,'Estado_JGL','-',estado_generico,p.n);
  elseif strcmpi(sistema,'GL')
    p=add_num(p,'Ql_GL_m3d','m3/d',ql_generico,p.n);
    p=add_num(p,'Qo_GL_m3d','m3/d',qo_generico,p.n);
    p=add_num(p,'Ql_GL_raw_m3d','m3/d',ql_raw_generico,p.n);
    p=add_num(p,'Qo_GL_raw_m3d','m3/d',qo_raw_generico,p.n);
    p=add_cell(p,'Estado_GL','-',estado_generico,p.n);
  else
    p=add_num(p,'Ql_m3d','m3/d',ql_generico,p.n);
    p=add_num(p,'Qo_m3d','m3/d',qo_generico,p.n);
    p=add_num(p,'Ql_raw_m3d','m3/d',ql_raw_generico,p.n);
    p=add_num(p,'Qo_raw_m3d','m3/d',qo_raw_generico,p.n);
    p=add_cell(p,'Modo','-',modo_generico,p.n);
    p=add_cell(p,'Estado','-',estado_generico,p.n);
  endif
  if ~strcmpi(p.variable,'Qiny')
    p=add_num(p,'Qiny_Sm3_d','Sm3/d',get_vec(d,'Qiny_Sm3_d',p.n),p.n);
  endif
  p=add_num(p,'Qiny_efectivo_Sm3_d','Sm3/d',get_vec(d,'Qiny_efectivo',p.n)*86400,p.n);
  p=add_num(p,'Qg_formacion_Sm3_d','Sm3/d',get_vec(d,'Qg_formacion',p.n)*86400,p.n);
  p=add_num(p,'Qg_total_VLP_Sm3_d','Sm3/d',get_vec(d,'Qg_total_VLP',p.n)*86400,p.n);
  p=add_cell(p,'Factible_presion_JGL','-',get_tristate(d,'Factible_presion_JGL',p.n),p.n);
  p=add_cell(p,'Estado_presion_JGL','-',get_cell(d,'estado_presion_JGL',p.n),p.n);
  p=add_cell(p,'Modo_condicion_motriz_JGL','-',get_cell(d,'modo_condicion_motriz_JGL',p.n),p.n);

  % Resultado JGL/GL anidado usado por las sensibilidades actuales.
  R=get_struct(d,'resultado');
  J=get_struct(R,'jgl');
  p=add_num(p,'Ql_JGL_m3d','m3/d',get_vec(R,'Ql_JGL',p.n)*86400,p.n);
  p=add_num(p,'Qo_JGL_m3d','m3/d',get_vec(R,'Qo_JGL',p.n)*86400,p.n);
  p=add_num(p,'Ql_GL_m3d','m3/d',get_vec(R,'Ql_GL',p.n)*86400,p.n);
  p=add_num(p,'Qo_GL_m3d','m3/d',get_vec(R,'Qo_GL',p.n)*86400,p.n);
  p=add_num(p,'Ql_JGL_raw_m3d','m3/d',get_vec(R,'Ql_JGL_raw',p.n)*86400,p.n);
  p=add_num(p,'Qo_JGL_raw_m3d','m3/d',get_vec(R,'Qo_JGL_raw',p.n)*86400,p.n);
  p=add_num(p,'Ql_GL_raw_m3d','m3/d',get_vec(R,'Ql_GL_raw',p.n)*86400,p.n);
  p=add_num(p,'Qo_GL_raw_m3d','m3/d',get_vec(R,'Qo_GL_raw',p.n)*86400,p.n);
  p=add_num(p,'Residuo_JGL_bar','bar',get_vec(R,'residuo_JGL_Pa',p.n)*1e-5,p.n);
  p=add_num(p,'Residuo_GL_bar','bar',get_vec(R,'residuo_GL_Pa',p.n)*1e-5,p.n);
  p=add_num(p,'Qiny_JGL_Sm3_d','Sm3/d',get_vec(J,'qiny_efectivo',p.n)*86400,p.n);
  p=add_num(p,'Qiny_GL_Sm3_d','Sm3/d',get_vec(R,'qiny_efectivo_GL',p.n)*86400,p.n);
  p=add_num(p,'DeltaP_JGL_bar','bar',first_vec({get_vec(R,'deltaP_JGL',p.n),get_vec(J,'deltaP',p.n)},p.n)*1e-5,p.n);
  p=add_num(p,'Iteraciones_JGL','-',first_vec({get_vec(R,'iteraciones_JGL',p.n),get_vec(J,'iteraciones',p.n)},p.n),p.n);
  p=add_cell(p,'Modo_JGL','-',first_cell({get_cell(R,'modos_JGL',p.n),get_cell(J,'modos',p.n)},p.n),p.n);
  p=add_cell(p,'Estado_JGL','-',first_cell({get_cell(R,'estados_JGL',p.n),get_cell(J,'estados',p.n)},p.n),p.n);
  p=add_cell(p,'Estado_GL','-',first_cell({get_cell(R,'estados_GL',p.n),get_cell(R,'estado_GL',p.n)},p.n),p.n);
  p=add_num(p,'Qg_formacion_GL_Sm3_d','Sm3/d',get_vec(R,'Qg_formacion_GL',p.n)*86400,p.n);
  p=add_num(p,'Qg_total_VLP_GL_Sm3_d','Sm3/d',get_vec(R,'Qg_total_VLP_GL',p.n)*86400,p.n);
  p=add_num(p,'P_req_GL_bar','bar',get_vec(R,'P_req_GL',p.n)*1e-5,p.n);
  p=add_num(p,'P_s_GL_bar','bar',get_vec(R,'P_s_GL',p.n)*1e-5,p.n);
  err=first_vec({get_vec(R,'error_directo_iterativo',p.n),get_vec(J,'error_directo_iterativo',p.n)},p.n);
  p=add_num(p,'Error_Directo_Iterativo_pct','%',100*err,p.n);
  p=add_num(p,'Verificado_Iterativo','-',first_vec({get_vec(R,'seleccion_iterativa',p.n),get_vec(J,'seleccion_iterativa',p.n)},p.n),p.n);
  p=add_num(p,'P_succion_eductor_JGL_bar','bar',get_vec(J,'P_succion_eductor',p.n)*1e-5,p.n);
  p=add_num(p,'DeltaP_motriz_requerida_JGL_bar','bar',get_vec(J,'deltaP_motriz_requerida',p.n)*1e-5,p.n);
  p=add_num(p,'P_motriz_fondo_requerida_JGL_bar','bar',get_vec(J,'P_motriz_fondo_requerida',p.n)*1e-5,p.n);
  p=add_num(p,'P_motriz_fondo_disponible_JGL_bar','bar',get_vec(J,'P_motriz_fondo_disponible',p.n)*1e-5,p.n);
  p=add_num(p,'P_iny_sup_requerida_JGL_bar','bar',get_vec(J,'P_iny_sup_requerida',p.n)*1e-5,p.n);
  p=add_num(p,'P_iny_sup_disponible_JGL_bar','bar',get_vec(J,'P_iny_sup_disponible',p.n)*1e-5,p.n);
  p=add_num(p,'DeltaP_columna_gas_JGL_bar','bar',get_vec(J,'deltaP_columna_gas_requerida',p.n)*1e-5,p.n);
  p=add_num(p,'DeltaP_friccion_inyeccion_JGL_bar','bar',get_vec(J,'deltaP_friccion_inyeccion',p.n)*1e-5,p.n);
  p=add_num(p,'Margen_presion_JGL_bar','bar',get_vec(J,'margen_presion_superficie',p.n)*1e-5,p.n);
  p=add_cell(p,'Factible_presion_JGL','-',get_tristate(J,'factible_por_presion',p.n),p.n);
  p=add_cell(p,'Estado_presion_JGL','-',get_cell(J,'estado_presion_motriz',p.n),p.n);
  p=add_cell(p,'Modo_condicion_motriz_JGL','-',get_cell(J,'modo_condicion_motriz',p.n),p.n);
  if strcmpi(sistema,'JGL')
    p=add_cell(p,'Motivo_rechazo_JGL','-',first_reason({ ...
      get_reason(d,'motivos_rechazo',p.n),get_reason(J,'motivos_rechazo',p.n)},p.n),p.n);
    p=add_cell(p,'Config_firma_JGL','-',first_cell({ ...
      get_cell(d,'config_firma_por_punto',p.n),get_cell(J,'config_firma',p.n)},p.n),p.n);
  elseif strcmpi(sistema,'GL')
    p=add_cell(p,'Motivo_rechazo_GL','-',get_reason(d,'motivos_rechazo',p.n),p.n);
    p=add_cell(p,'Config_firma_GL','-',get_cell(d,'config_firma_por_punto',p.n),p.n);
  else
    p=add_cell(p,'Motivo_rechazo_JGL','-',first_reason({ ...
      get_reason(d,'motivos_rechazo_JGL',p.n),get_reason(R,'motivos_rechazo_JGL',p.n), ...
      get_reason(J,'motivos_rechazo',p.n)},p.n),p.n);
    p=add_cell(p,'Motivo_rechazo_GL','-',first_reason({ ...
      get_reason(d,'motivos_rechazo_GL',p.n),get_reason(R,'motivos_rechazo_GL',p.n)},p.n),p.n);
    p=add_cell(p,'Config_firma_JGL','-',first_cell({ ...
      get_cell(J,'config_firma',p.n),get_cell(R,'config_firma_JGL',p.n)},p.n),p.n);
    p=add_cell(p,'Config_firma_GL','-',get_cell(R,'config_firma_GL',p.n),p.n);
  endif

  % Validez por sistema. En comparaciones se conserva cada mascara por
  % separado; la columna generica posterior representa el par comparable.
  if strcmpi(sistema,'JGL')
    p=add_mask_col(p,'Aceptado_JGL',get_mask(d,'aceptado',p.n),p.n);
    p=add_mask_col(p,'Valido_curva_JGL',get_mask(d,'valido_para_curva',p.n),p.n);
    p=add_mask_col(p,'Valido_optimo_JGL',get_mask(d,'valido_para_optimo',p.n),p.n);
  elseif strcmpi(sistema,'GL')
    p=add_mask_col(p,'Aceptado_GL',get_mask(d,'aceptado',p.n),p.n);
    p=add_mask_col(p,'Valido_curva_GL',get_mask(d,'valido_para_curva',p.n),p.n);
    p=add_mask_col(p,'Valido_optimo_GL',get_mask(d,'valido_para_optimo',p.n),p.n);
  else
    p=add_mask_col(p,'Aceptado_JGL',first_mask({ ...
      get_mask(d,'aceptado_JGL',p.n),get_mask(R,'aceptado_JGL',p.n), ...
      get_mask(J,'aceptado',p.n)},p.n),p.n);
    p=add_mask_col(p,'Valido_curva_JGL',first_mask({ ...
      get_mask(d,'valido_para_curva_JGL',p.n),get_mask(R,'valido_para_curva_JGL',p.n), ...
      get_mask(J,'valido_para_curva',p.n)},p.n),p.n);
    p=add_mask_col(p,'Valido_optimo_JGL',first_mask({ ...
      get_mask(d,'valido_para_optimo_JGL',p.n),get_mask(R,'valido_para_optimo_JGL',p.n), ...
      get_mask(J,'valido_para_optimo',p.n)},p.n),p.n);
    p=add_mask_col(p,'Aceptado_GL',first_mask({ ...
      get_mask(d,'aceptado_GL',p.n),get_mask(R,'aceptado_GL',p.n)},p.n),p.n);
    p=add_mask_col(p,'Valido_curva_GL',first_mask({ ...
      get_mask(d,'valido_para_curva_GL',p.n),get_mask(R,'valido_para_curva_GL',p.n)},p.n),p.n);
    p=add_mask_col(p,'Valido_optimo_GL',first_mask({ ...
      get_mask(d,'valido_para_optimo_GL',p.n),get_mask(R,'valido_para_optimo_GL',p.n)},p.n),p.n);
  endif

  % Sensibilidades JGL puras: resultado puede contener soluciones celda.
  RJ=get_struct(d,'resultado');
  sols=get_cell(RJ,'soluciones',p.n);
  if ~isempty(sols)
    [ql,qo,dp,it,mo,es,er,qe]=extraer_soluciones(sols,p.n);
    p=add_num(p,'Ql_JGL_m3d','m3/d',ql,p.n);
    p=add_num(p,'Qo_JGL_m3d','m3/d',qo,p.n);
    p=add_num(p,'Qiny_JGL_Sm3_d','Sm3/d',qe,p.n);
    p=add_num(p,'DeltaP_JGL_bar','bar',dp,p.n);
    p=add_num(p,'Iteraciones_JGL','-',it,p.n);
    p=add_cell(p,'Modo_JGL','-',mo,p.n);
    p=add_cell(p,'Estado_JGL','-',es,p.n);
    p=add_num(p,'Error_Directo_Iterativo_pct','%',er,p.n);
  end

  % BES: extraer resultados por punto sin exponer estructuras.
  rb=get_cell(d,'resultados',p.n);
  if ~isempty(rb)
    [ql,qo,pint,tmot,corr,rl,estado]=extraer_bes(rb,p.n);
    p=add_num(p,'Ql_m3d','m3/d',ql,p.n); p=add_num(p,'Qo_m3d','m3/d',qo,p.n);
    p=add_num(p,'P_intake_bar','bar',pint,p.n); p=add_num(p,'T_motor_C','C',tmot,p.n);
    p=add_num(p,'Corriente_A','A',corr,p.n); p=add_num(p,'RunLife_d','d',rl,p.n);
    p=add_cell(p,'Estado','-',estado,p.n);
  end

  if ~any(strcmpi(sistema,{'GL','JGL','JGL_GL','GL_JGL'}))
    p=add_cell(p,'Motivo_rechazo','-',get_reason(d,'motivos_rechazo',p.n),p.n);
    p=add_cell(p,'Config_firma','-',get_cell(d,'config_firma_por_punto',p.n),p.n);
  endif

  % Estado/aceptacion y confianza por punto. SENS-GLJGL-01 usa los
  % vectores explicitos del solver cuando existen; solo cae al texto legado
  % para sensibilidades anteriores que no publican contrato de validez.
  estado=buscar_col_cell(p,{'Estado_JGL','Estado'});
  estado_gl=buscar_col_cell(p,{'Estado_GL'});
  err=buscar_col_num(p,{'Error_Directo_Iterativo_pct'});

  acept_exp=first_mask({ ...
    get_mask(d,'aceptado',p.n), ...
    get_mask(R,'aceptado',p.n), ...
    get_mask(J,'aceptado',p.n)},p.n);
  curva_exp=first_mask({ ...
    get_mask(d,'valido_para_curva',p.n), ...
    get_mask(R,'valido_para_curva',p.n), ...
    get_mask(J,'valido_para_curva',p.n)},p.n);
  opt_exp=first_mask({ ...
    get_mask(d,'valido_para_optimo',p.n), ...
    get_mask(R,'valido_para_optimo',p.n), ...
    get_mask(J,'valido_para_optimo',p.n)},p.n);

  if isempty(acept_exp)
    acept=true(1,p.n);
  else
    acept=acept_exp;
  endif
  if isempty(curva_exp), curva=acept; else, curva=curva_exp; endif
  if isempty(opt_exp), optimo=curva; else, optimo=opt_exp; endif

  hay_err_finito=~isempty(err)&&any(isfinite(err));
  conf=repmat({'ALTA'},1,p.n);
  for i=1:p.n
    if isempty(acept_exp)
      e=''; if ~isempty(estado),e=upper(estado{i});endif
      eg=''; if ~isempty(estado_gl),eg=upper(estado_gl{i});endif
      if estado_rechazado_local(e)||estado_rechazado_local(eg)
        acept(i)=false;curva(i)=false;optimo(i)=false;
      endif
    endif

    if ~acept(i)||~curva(i)
      conf{i}='BAJA';
    elseif ~optimo(i)
      conf{i}='MEDIA';
    elseif hay_err_finito&&isfinite(err(i))&&err(i)>10
      acept(i)=false;curva(i)=false;optimo(i)=false;conf{i}='BAJA';
    elseif hay_err_finito&&isfinite(err(i))&&err(i)>5
      conf{i}='MEDIA';
    elseif hay_err_finito&&~isfinite(err(i))
      conf{i}='NO_EVALUADA';
    endif
  endfor

  p.aceptado=logical(acept);
  p.valido_para_curva=logical(curva);
  p.valido_para_optimo=logical(optimo);
  p=sens_add_col(p,'Aceptado','-',num2cell_si_no(p.aceptado));
  p=sens_add_col(p,'Valido_curva','-',num2cell_si_no(p.valido_para_curva));
  p=sens_add_col(p,'Valido_optimo','-',num2cell_si_no(p.valido_para_optimo));
  p=sens_add_col(p,'Confianza','-',conf);
  if any(~p.aceptado)||any(~p.valido_para_curva)
    p.confianza_global='MEDIA';
  elseif any(~p.valido_para_optimo)
    p.confianza_global='MEDIA';
  else
    p.confianza_global='ALTA';
  endif
  if all(cellfun(@(s)strcmp(s,'NO_EVALUADA'),conf))
    p.confianza_global='NO_EVALUADA';
  endif

  p=sens_agregar_ganancias(p,d);

  p.tratamiento_curva=get_struct(d,'tratamiento_curva');
  p.tratamiento_curva_JGL=get_struct(d,'tratamiento_curva_JGL');
  p.tratamiento_curva_GL=get_struct(d,'tratamiento_curva_GL');
  p.optimizacion_JGL=get_struct(d,'optimizacion_JGL');
  p.optimizacion_GL=get_struct(d,'optimizacion_GL');
  p.verificacion_polinomica_JGL=get_struct(d,'verificacion_polinomica_JGL');
  p.verificacion_polinomica_GL=get_struct(d,'verificacion_polinomica_GL');
  p.condicion_motriz_menu=get_struct(d,'condicion_motriz_menu');
  p.presiones_motrices_JGL=get_struct(d,'presiones_motrices_JGL');
  p.limite_presion_JGL=get_struct(d,'limite_presion_JGL');
  if isempty(fieldnames(p.limite_presion_JGL)) && isstruct(p.presiones_motrices_JGL)
    p.limite_presion_JGL=get_struct(p.presiones_motrices_JGL,'limite_presion');
  endif
  opt_unico=get_struct(d,'optimizacion_inyeccion');
  ver_unica=get_struct(d,'verificacion_polinomica');
  if strcmpi(sistema,'JGL')
    if isempty(fieldnames(p.optimizacion_JGL)),p.optimizacion_JGL=opt_unico;endif
    if isempty(fieldnames(p.verificacion_polinomica_JGL)),p.verificacion_polinomica_JGL=ver_unica;endif
    if isempty(fieldnames(p.tratamiento_curva_JGL)),p.tratamiento_curva_JGL=p.tratamiento_curva;endif
  elseif strcmpi(sistema,'GL')
    if isempty(fieldnames(p.optimizacion_GL)),p.optimizacion_GL=opt_unico;endif
    if isempty(fieldnames(p.verificacion_polinomica_GL)),p.verificacion_polinomica_GL=ver_unica;endif
    if isempty(fieldnames(p.tratamiento_curva_GL)),p.tratamiento_curva_GL=p.tratamiento_curva;endif
  else
    if isempty(fieldnames(p.tratamiento_curva_JGL)) && ~isempty(fieldnames(p.tratamiento_curva))
      p.tratamiento_curva_JGL=p.tratamiento_curva;
    endif
    if isempty(fieldnames(p.tratamiento_curva_GL)) && ~isempty(fieldnames(p.tratamiento_curva))
      p.tratamiento_curva_GL=p.tratamiento_curva;
    endif
  endif

  p.metodo=detectar_metodo(d,R,J,sistema);
  p.clasificacion_JGL=get_struct(d,'clasificacion_JGL');
  p.clasificacion_GL=get_struct(d,'clasificacion_GL');
  p.clasificacion_BES=get_struct(d,'clasificacion');
  [p.clasificacion_principal,p.mensaje]=clasificacion_texto(p);
end

function [x,n,u]=sens_variable_independiente(d,titulo)
  if isfield(d,'Qiny'),x=d.Qiny*86400;n='Qiny';u='Sm3/d';return;end
  if isfield(d,'Qiny_Sm3_d'),x=d.Qiny_Sm3_d;n='Qiny';u='Sm3/d';return;end
  if isfield(d,'Qiny_solicitado'),x=d.Qiny_solicitado*86400;n='Qiny';u='Sm3/d';return;end
  if isfield(d,'qiny_solicitado'),x=d.qiny_solicitado*86400;n='Qiny';u='Sm3/d';return;end
  if isfield(d,'Piny_Pa'),x=d.Piny_Pa*1e-5;n='Piny';u='bar';return;end
  if isfield(d,'Pwh_Pa'),x=d.Pwh_Pa*1e-5;n='Pwh';u='bar';return;end
  if isfield(d,'Diny_m'),x=d.Diny_m;n='Profundidad_inyeccion';u='m';return;end
  if isfield(d,'A_n_mm2'),x=d.A_n_mm2;n='Area_tobera';u='mm2';return;end
  if isfield(d,'d_t_mm'),x=d.d_t_mm;n='Diametro_garganta';u='mm';return;end
  if isfield(d,'solicitado_bar'),x=d.solicitado_bar;n='Pwh';u='bar';return;end
  if isfield(d,'solicitado_Hz'),x=d.solicitado_Hz;n='Frecuencia';u='Hz';return;end
  if isfield(d,'solicitado_m'),x=d.solicitado_m;n='Profundidad';u='m';return;end
  if isfield(d,'solicitado'),x=d.solicitado;n='Parametro';u='-';return;end
  f=fieldnames(d);x=[];
  for k=1:numel(f),v=d.(f{k});if isnumeric(v)&&isvector(v)&&numel(v)>1,x=v;n=f{k};u='-';return;end,end
  x=0;n=regexprep(titulo,'[^A-Za-z0-9]','_');u='-';
end

function p=add_top(p,d,names,n)
  for k=1:numel(names)
    f=names{k};if isfield(d,f)&&isnumeric(d.(f))&&isvector(d.(f))&&numel(d.(f))==n
      [nm,un]=nombre_unidad(f);p=add_num(p,nm,un,d.(f),n);
    end
  end
end
function [n,u]=nombre_unidad(f)
  n=f;u='-';lf=lower(f);
  if ~isempty(strfind(lf,'pct'))
    u='%';
  elseif ~isempty(strfind(lf,'m3d'))
    u='m3/d';
  elseif ~isempty(strfind(lf,'bar'))
    u='bar';
  elseif ~isempty(strfind(lf,'_pa'))
    u='Pa';
  elseif ~isempty(strfind(lf,'hz'))
    u='Hz';
  elseif ~isempty(strfind(lf,'_m'))
    u='m';
  endif
endfunction
function p=add_num(p,n,u,v,N)
  if isempty(v)||numel(v)~=N||any(strcmp(p.nombres,n)),return;end
  p=sens_add_col(p,n,u,double(v(:)'));
end
function p=add_cell(p,n,u,v,N)
  if isempty(v)||numel(v)~=N||any(strcmp(p.nombres,n)),return;end
  p=sens_add_col(p,n,u,v(:)');
end
function p=add_mask_col(p,n,v,N)
  if isempty(v)||numel(v)~=N||any(strcmp(p.nombres,n)),return;endif
  p=sens_add_col(p,n,'-',num2cell_si_no(logical(v(:)')));
endfunction
function p=sens_add_col(p,n,u,v)
  p.nombres{end+1}=n;p.unidades{end+1}=u;p.columnas{end+1}=v;
end

function [ql,qo,dp,it,mo,es,er,qe]=extraer_soluciones(c,N)
  ql=nan(1,N);qo=ql;dp=ql;it=ql;er=ql;qe=ql;mo=repmat({''},1,N);es=mo;
  for i=1:N
    s=c{i};if ~isstruct(s),continue;end
    ql(i)=numfield(s,{'Ql'},NaN)*86400;qo(i)=numfield(s,{'Qo'},NaN)*86400;
    dp(i)=numfield(s,{'deltaP','DeltaP'},NaN)*1e-5;it(i)=numfield(s,{'iteraciones'},NaN);
    er(i)=100*numfield(s,{'error_directo_iterativo'},NaN);qe(i)=numfield(s,{'Qiny','qiny_efectivo'},NaN)*86400;
    mo{i}=txtfield(s,{'modo_utilizado','modo'},'');es{i}=txtfield(s,{'estado'},'');
  end
end
function [ql,qo,pint,tmot,corr,rl,estado]=extraer_bes(c,N)
  ql=nan(1,N);qo=ql;pint=ql;tmot=ql;corr=ql;rl=ql;estado=repmat({''},1,N);
  for i=1:N
    s=c{i};if ~isstruct(s),continue;end
    ql(i)=numfield(s,{'Ql'},NaN)*86400;qo(i)=numfield(s,{'Qo'},NaN)*86400;
    pint(i)=numfield(s,{'P_intake'},NaN)*1e-5;tmot(i)=numfield(s,{'T_motor'},NaN);
    corr(i)=numfield(s,{'corriente'},NaN);rl(i)=numfield(s,{'run_life'},NaN);estado{i}=txtfield(s,{'estado'},'');
  end
end
function s=get_struct(a,f),s=struct();if isstruct(a)&&isfield(a,f)&&isstruct(a.(f)),s=a.(f);end,end
function v=get_vec(a,f,N),v=[];if isstruct(a)&&isfield(a,f)&&isnumeric(a.(f))&&isvector(a.(f))&&numel(a.(f))==N,v=double(a.(f)(:))';end,end
function c=get_cell(a,f,N),c={};if isstruct(a)&&isfield(a,f)&&iscell(a.(f))&&isvector(a.(f))&&numel(a.(f))==N,c=a.(f)(:)';end,end
function c=get_tristate(a,f,N)
  c={};
  if ~isstruct(a)||~isfield(a,f),return;endif
  v=a.(f);
  if ~(islogical(v)||isnumeric(v))||~isvector(v)||numel(v)~=N,return;endif
  v=v(:)';c=cell(1,N);
  for i=1:N
    if islogical(v)
      if v(i),c{i}='SI';else,c{i}='NO';endif
    elseif ~isfinite(v(i))
      c{i}='NO_EVALUADA';
    elseif v(i)~=0
      c{i}='SI';
    else
      c{i}='NO';
    endif
  endfor
endfunction
function c=get_reason(a,f,N)
  c={};
  if ~isstruct(a)||~isfield(a,f)||~iscell(a.(f))||numel(a.(f))~=N,return;endif
  src=a.(f);c=cell(1,N);
  for i=1:N
    x=src{i};
    if ischar(x)
      c{i}=limpiar_txt(x);
    elseif iscell(x)
      t='';
      for j=1:numel(x)
        if ischar(x{j})&&~isempty(strtrim(x{j}))
          if isempty(t),t=limpiar_txt(x{j});else,t=[t ' | ' limpiar_txt(x{j})];endif
        endif
      endfor
      c{i}=t;
    else
      c{i}='';
    endif
  endfor
endfunction
function c=first_reason(C,N)
  c={};
  for i=1:numel(C)
    if ~isempty(C{i})&&numel(C{i})==N,c=C{i};return;endif
  endfor
endfunction
function m=get_mask(a,f,N)
  m=[];
  if ~isstruct(a)||~isfield(a,f),return;endif
  v=a.(f);
  if (islogical(v)||isnumeric(v))&&isvector(v)&&numel(v)==N
    m=logical(v(:)');
  endif
endfunction
function m=first_mask(C,N)
  m=[];
  for i=1:numel(C)
    if ~isempty(C{i})&&numel(C{i})==N,m=logical(C{i});return;endif
  endfor
endfunction
function tf=estado_rechazado_local(e)
  tf=false;if ~ischar(e)||isempty(e),return;endif
  claves={'NO_CONVERGE','ERROR','INVALID','SIN_CRUCE','SIN_CAMBIO_SIGNO', ...
    'SIN_EVALUACION','SIN_QMAX','LIMITADO_POR_VLP','NO_FISICO', ...
    'EDUCTOR_NO_FACTIBLE','PRESION_MOTRIZ','POTENCIA_INSUFICIENTE'};
  for i=1:numel(claves)
    if ~isempty(strfind(e,claves{i})),tf=true;return;endif
  endfor
endfunction
function v=first_vec(C,N),v=[];for i=1:numel(C),if ~isempty(C{i})&&numel(C{i})==N,v=C{i};return;end,end,end
function c=first_cell(C,N),c={};for i=1:numel(C),if ~isempty(C{i})&&numel(C{i})==N,c=C{i};return;end,end,end
function v=numfield(s,fs,d),v=d;for k=1:numel(fs),if isfield(s,fs{k})&&isnumeric(s.(fs{k}))&&isscalar(s.(fs{k})),v=s.(fs{k});return;end,end,end
function v=txtfield(s,fs,d),v=d;for k=1:numel(fs),if isfield(s,fs{k})&&ischar(s.(fs{k})),v=s.(fs{k});return;end,end,end
function c=buscar_col_cell(p,names),c={};for k=1:numel(names),i=find(strcmp(p.nombres,names{k}),1);if ~isempty(i)&&iscell(p.columnas{i}),c=p.columnas{i};return;end,end,end
function v=buscar_col_num(p,names),v=[];for k=1:numel(names),i=find(strcmp(p.nombres,names{k}),1);if ~isempty(i)&&isnumeric(p.columnas{i}),v=p.columnas{i};return;end,end,end
function c=num2cell_si_no(v),c=cell(1,numel(v));for i=1:numel(v),if v(i),c{i}='SI';else,c{i}='NO';end,end,end

function m=detectar_metodo(d,R,J,sistema)
  m='NO_INFORMADO';
  c={txtfield(d,{'modo_solicitado','metodo'},''),txtfield(R,{'modo_solicitado'},''),txtfield(J,{'modo_solicitado'},'')};
  for k=1:numel(c),if ~isempty(c{k}),m=upper(c{k});return;end,end
  if strcmpi(sistema,'BES'),m='SOLVER_BES';end
end
function [t,msg]=clasificacion_texto(p)
  S={p.clasificacion_JGL,p.clasificacion_GL,p.clasificacion_BES};t='NO_EVALUADA';msg='Sin clasificacion';
  for k=1:numel(S)
    s=S{k};if isstruct(s)&&~isempty(fieldnames(s))
      t=txtfield(s,{'tipo'},'NO_EVALUADA');msg=txtfield(s,{'mensaje'},t);return;
    end
  end
end
function sens_escribir_clasificacion(fid,nombre,s,p)
  if ~isstruct(s)||isempty(fieldnames(s)),return;end
  fprintf(fid,'\n[CLASSIFICATION_%s]\n',nombre);
  fprintf(fid,'tipo=%s\n',txtfield(s,{'tipo'},'NO_EVALUADA'));
  fprintf(fid,'mensaje=%s\n',limpiar_txt(txtfield(s,{'mensaje'},'')));
  ox=numfield(s,{'optimo_x'},NaN);oy=numfield(s,{'optimo_y'},NaN);
  if isfinite(ox)
    if strcmp(p.unidad_variable,'Sm3/d')&&abs(ox)<100,ox=ox*86400;end
    if strcmp(p.unidad_variable,'bar')&&abs(ox)>1e4,ox=ox*1e-5;end
    fprintf(fid,'optimo_variable=%.10g\n',ox);fprintf(fid,'unidad_optimo_variable=%s\n',p.unidad_variable);
  end
  if isfinite(oy),fprintf(fid,'optimo_respuesta=%.10g\n',oy);end
end

% Las figuras enriquecidas se exportan exclusivamente mediante el registro
% transversal aos_registro_graficos. No se aplica limite fijo ni deduplicacion
% por titulo en este exportador numerico.

function sens_escribir_csv(archivo,p)
  fid=fopen(archivo,'w');if fid<0,error('No se pudo crear CSV');end;c=onCleanup(@()fclose(fid));
  fprintf(fid,'%s\n',strjoin(p.nombres,','));
  fprintf(fid,'%s\n',strjoin(p.unidades,','));
  for i=1:p.n
    vals=cell(1,numel(p.columnas));for j=1:numel(p.columnas),v=p.columnas{j};if iscell(v),vals{j}=csv_inline(v{i});else,vals{j}=num_inline(v(i));end,end
    fprintf(fid,'%s\n',strjoin(vals,','));
  end
end
function s=num_inline(v),if ~isfinite(v),s='';else,s=sprintf('%.12g',v);end,end
function s=csv_inline(x),if ~ischar(x),x='';end;x=strrep(x,'"','""');s=['"' x '"'];end
function s=limpiar_txt(x),if ~ischar(x),x='';end;s=regexprep(x,'[\r\n=]',' ');end
function b=leer_base64(a),f=fopen(a,'rb');if f<0,b='';return;end;bytes=fread(f,Inf,'uint8=>uint8');fclose(f);b=base64_encode(bytes);end
function n=aos_nombre_pozo_local(p)
  n='pozo';campos={'nombre_pozo','pozo','nombre','archivo_aosdat'};
  for i=1:numel(campos)
    if isstruct(p)&&isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i})))
      n=p.(campos{i});break;
    end
  end
  global AOSDAT_ACTIVO;
  if strcmp(n,'pozo') && ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO),n=AOSDAT_ACTIVO;end
  [~,base,ext]=fileparts(n);if ~isempty(base),n=base;elseif ~isempty(ext),n=[base ext];end
  n=regexprep(n,'[^a-zA-Z0-9_-]','_');n=regexprep(n,'_+','_');n=regexprep(n,'^_+|_+$','');
  if isempty(n),n='pozo';end
end

function t=tabla_nativa_local(p,titulo)
  t=struct();t.id='sensibilidad_001';t.title=limpiar_txt(titulo);
  t.schema='AOS_NATIVE_TABLE_1.1';t.section='SENSIBILIDAD';t.role='SENSITIVITY_TABLE';
  t.category='SENSITIVITY';t.priority='PRIMARY';t.default_mode='FULL_BODY';t.mandatory=true;
  t.columns=p.nombres;t.labels=p.nombres;
  t.units=p.unidades;t.rows=cell(p.n,numel(p.nombres));
  t.types=cell(1,numel(p.nombres));t.precision=cell(1,numel(p.nombres));
  for j=1:numel(p.nombres)
    v=p.columnas{j};
    if iscell(v),t.types{j}='text';t.precision{j}='';
    else,t.types{j}='number';t.precision{j}='6';end
    for i=1:p.n
      if iscell(v),t.rows{i,j}=v{i};else,t.rows{i,j}=v(i);end
    end
  end
end

function v=min_finito(x),y=x(isfinite(x));if isempty(y),v=NaN;else,v=min(y);end,end
function v=max_finito(x),y=x(isfinite(x));if isempty(y),v=NaN;else,v=max(y);end,end

function p=sens_agregar_ganancias(p,d)
  if p.n <= 0 || isempty(p.columnas)
    return;
  endif
  x=p.columnas{1};
  preferir_cero=strcmpi(p.variable,'Qiny');
  candidatos={'Ql_JGL_m3d','Qo_JGL_m3d','Ql_GL_m3d','Qo_GL_m3d','Ql_m3d','Qo_m3d'};
  ganancias=struct('respuesta',{},'unidad',{},'indice_referencia',{},...
    'variable_referencia',{},'valor_base',{},'tipo_referencia',{},...
    'porcentaje_calculable',{},'ganancia_max_pct',{},...
    'variable_ganancia_max',{},'valor_max',{});
  refs=[];
  tipos={};
  for k=1:numel(candidatos)
    nombre=candidatos{k};
    idx=find(strcmp(p.nombres,nombre),1);
    if isempty(idx) || ~isnumeric(p.columnas{idx})
      continue;
    endif
    y=p.columnas{idx};
    [ga,gp,gi,info]=sens_calcular_ganancias(y,x,preferir_cero);
    base=regexprep(nombre,'_m3d$','');
    p=add_num(p,['Ganancia_' base '_m3d'],'m3/d',ga,p.n);
    p=add_num(p,['Ganancia_' base '_pct'],'%',gp,p.n);
    p=add_num(p,['Ganancia_incremental_' base '_pct'],'%',gi,p.n);
    g=struct();
    g.respuesta=nombre;g.unidad='m3/d';g.indice_referencia=info.indice;
    g.variable_referencia=info.x;g.valor_base=info.base;g.tipo_referencia=info.tipo;
    g.porcentaje_calculable=info.porcentaje_calculable;
    [g.ganancia_max_pct,g.variable_ganancia_max,g.valor_max]=maximo_ganancia_local(gp,x,y,p.aceptado);
    ganancias(end+1)=g;
    if isfinite(info.x),refs(end+1)=info.x;tipos{end+1}=info.tipo;endif
  endfor
  p.ganancias=ganancias;
  if ~isempty(refs)
    p.referencia_variable=refs(1);
    p.referencia_tipo=tipos{1};
  elseif isstruct(d) && isfield(d,'referencia_ganancia') && ischar(d.referencia_ganancia)
    p.referencia_tipo=d.referencia_ganancia;
  endif
endfunction

function [gmax,xmax,ymax]=maximo_ganancia_local(g,x,y,aceptado)
  gmax=NaN;xmax=NaN;ymax=NaN;
  ok=isfinite(g)&isfinite(x)&isfinite(y);
  if nargin>=4 && numel(aceptado)==numel(ok)
    ok=ok&logical(aceptado);
  endif
  ids=find(ok);
  if isempty(ids),return;endif
  [gmax,j]=max(g(ids));i=ids(j);xmax=x(i);ymax=y(i);
endfunction

function sens_escribir_resumen_ganancias(fid,p)
  fprintf(fid,'\n[SENSITIVITY_GAIN_SUMMARY]\n');
  fprintf(fid,'schema=AOS_SENSITIVITY_GAIN_1.0\n');
  fprintf(fid,'n_respuestas=%d\n',numel(p.ganancias));
  fprintf(fid,'referencia_tipo=%s\n',p.referencia_tipo);
  if isfinite(p.referencia_variable)
    fprintf(fid,'referencia_variable=%.10g\n',p.referencia_variable);
    fprintf(fid,'referencia_unidad=%s\n',p.unidad_variable);
  endif
  for i=1:numel(p.ganancias)
    g=p.ganancias(i);
    fprintf(fid,'respuesta_%02d=%s\n',i,g.respuesta);
    fprintf(fid,'respuesta_%02d_valor_base=%.10g\n',i,g.valor_base);
    fprintf(fid,'respuesta_%02d_indice_referencia=%.0f\n',i,g.indice_referencia);
    fprintf(fid,'respuesta_%02d_tipo_referencia=%s\n',i,g.tipo_referencia);
    fprintf(fid,'respuesta_%02d_pct_calculable=%s\n',i,cond(g.porcentaje_calculable,'SI','NO'));
    if isfinite(g.ganancia_max_pct)
      fprintf(fid,'respuesta_%02d_ganancia_max_pct=%.10g\n',i,g.ganancia_max_pct);
      fprintf(fid,'respuesta_%02d_variable_ganancia_max=%.10g\n',i,g.variable_ganancia_max);
      fprintf(fid,'respuesta_%02d_valor_max=%.10g\n',i,g.valor_max);
    endif
  endfor
endfunction

function sens_escribir_presion_motriz_jgl_local(fid,p)
% Resumen auditable. Los vectores completos permanecen en SENSITIVITY_TABLE.
  P=p.presiones_motrices_JGL;
  M=p.condicion_motriz_menu;
  L=p.limite_presion_JGL;
  if (~isstruct(P)||isempty(fieldnames(P))) && ...
      (~isstruct(M)||isempty(fieldnames(M))) && ...
      (~isstruct(L)||isempty(fieldnames(L)))
    return;
  endif
  fprintf(fid,'\n[JGL_MOTIVE_PRESSURE]\n');
  fprintf(fid,'schema=AOS_JGL_MOTIVE_PRESSURE_SENSITIVITY_1.0\n');
  fprintf(fid,'hotfix=SENS-GLJGL-03\n');
  fprintf(fid,'seleccion_visible=SI\n');
  fprintf(fid,'sobrescritura_oculta=NO\n');
  fprintf(fid,'formula_fondo=Pm_req=Ps+DeltaP_motriz_req\n');
  fprintf(fid,'formula_superficie=P_sup_req=(Pm_req+DeltaP_friccion)/factor_columna\n');
  fprintf(fid,'fuente_vectores=SENSITIVITY_TABLE\n');
  if isstruct(P)&&~isempty(fieldnames(P))
    fprintf(fid,'modo=%s\n',texto_struct_local(P,'modo_global','NO_INFORMADO'));
    fprintf(fid,'origen=%s\n',texto_struct_local(P,'origen_global','NO_DEFINIDO'));
    escribir_num_si_finito_local(fid,'P_iny_sup_disponible_bar', ...
      numero_struct_local(P,'P_iny_sup_disponible_global_bar',NaN));
  endif
  if isstruct(M)&&~isempty(fieldnames(M))
    escribir_num_si_finito_local(fid,'P_iny_sup_original_bar', ...
      numero_struct_local(M,'P_iny_sup_original_Pa',NaN)*1e-5);
    fprintf(fid,'menu_modo=%s\n',texto_struct_local(M,'modo','NO_INFORMADO'));
    fprintf(fid,'menu_mensaje=%s\n',texto_struct_local(M,'mensaje',''));
  endif
  if isstruct(L)&&~isempty(fieldnames(L))
    fprintf(fid,'limite_estado=%s\n',texto_struct_local(L,'estado','NO_EVALUADO'));
    fprintf(fid,'limite_evaluado=%s\n',cond(logico_struct_local(L,'evaluado',false),'SI','NO'));
    escribir_num_si_finito_local(fid,'Qiny_max_presion_Sm3_d', ...
      numero_struct_local(L,'Qiny_max_presion_Sm3_d',NaN));
    escribir_num_si_finito_local(fid,'P_disponible_bar', ...
      numero_struct_local(L,'P_disponible_bar',NaN));
  endif
endfunction

function sens_escribir_tratamiento_curva_local(fid,p)
% Secciones derivadas. Nunca reemplazan SENSITIVITY_TABLE.
  escribir_sistema_local(fid,'JGL',p.tratamiento_curva_JGL,p.optimizacion_JGL,p.verificacion_polinomica_JGL);
  escribir_sistema_local(fid,'GL',p.tratamiento_curva_GL,p.optimizacion_GL,p.verificacion_polinomica_GL);
endfunction

function escribir_sistema_local(fid,sistema,T,O,V)
  if ~isstruct(T)||isempty(fieldnames(T)),return;endif
  sec=regexprep(upper(sistema),'[^A-Z0-9_]+','_');
  fprintf(fid,'\n[CURVE_TREATMENT_%s]\n',sec);
  fprintf(fid,'schema=AOS_CURVE_TREATMENT_1.0\n');
  fprintf(fid,'hotfix=SENS-GLJGL-02\n');
  fprintf(fid,'modo=%s\n',texto_struct_local(T,'modo','DISCRETO'));
  fprintf(fid,'seleccion_visible=SI\npolinomio_oculto=NO\n');
  fprintf(fid,'habilitado=%s\n',cond(logico_struct_local(T,'habilitado',false),'SI','NO'));
  fprintf(fid,'grado_solicitado=%s\n',grado_struct_local(T));
  fprintf(fid,'grado_maximo=%.0f\n',numero_struct_local(T,'grado_maximo',5));
  fprintf(fid,'n_grid=%.0f\n',numero_struct_local(T,'n_grid',0));
  fprintf(fid,'extrapolacion=NO\nfuente_primaria=SENSITIVITY_TABLE\n');

  if ~isstruct(O)||isempty(fieldnames(O)),return;endif
  if isfield(O,'ajuste_polinomico')&&isstruct(O.ajuste_polinomico)
    escribir_fit_local(fid,sec,'QL',get_struct(O.ajuste_polinomico,'ql'));
    escribir_fit_local(fid,sec,'QO',get_struct(O.ajuste_polinomico,'qo'));
    escribir_fit_local(fid,sec,'RENDIMIENTO',get_struct(O.ajuste_polinomico,'rendimiento'));
    Aq=get_struct(O.ajuste_polinomico,'ql');Ao=get_struct(O.ajuste_polinomico,'qo');
    if es_serie_fit_local(Aq)||es_serie_fit_local(Ao)
      fprintf(fid,'\n[POLYNOMIAL_CURVE_%s]\n',sec);
      fprintf(fid,'schema=AOS_POLYNOMIAL_CURVE_1.0\nsource=DERIVED_FROM_VALIDATED_SOLVER_POINTS\n');
      x=[];if es_serie_fit_local(Aq),x=Aq.x_grid;elseif es_serie_fit_local(Ao),x=Ao.x_grid;endif
      fprintf(fid,'Qiny_Sm3_d=%s\n',vector_num_local(x));
      if es_serie_fit_local(Aq),fprintf(fid,'Ql_m3_d=%s\n',vector_num_local(Aq.y_grid));endif
      if es_serie_fit_local(Ao),fprintf(fid,'Qo_m3_d=%s\n',vector_num_local(Ao.y_grid));endif
    endif
  endif

  if ~isstruct(V)||isempty(fieldnames(V))
    V=get_struct(O,'verificacion_polinomica');
  endif
  if isstruct(V)&&~isempty(fieldnames(V))
    fprintf(fid,'\n[POLYNOMIAL_OPTIMUM_VERIFICATION_%s]\n',sec);
    fprintf(fid,'schema=AOS_POLYNOMIAL_OPTIMUM_VERIFICATION_1.0\n');
    fprintf(fid,'estado=%s\n',texto_struct_local(V,'estado','NO_EVALUADO'));
    fprintf(fid,'verificado=%s\n',cond(logico_struct_local(V,'verificado',false),'SI','NO'));
    escribir_num_si_finito_local(fid,'Qiny_estimado_Sm3_d',numero_struct_local(V,'qiny_estimado_sm3d',NaN));
    escribir_num_si_finito_local(fid,'Qiny_efectivo_Sm3_d',numero_struct_local(V,'qiny_efectivo_sm3d',NaN));
    escribir_num_si_finito_local(fid,'Ql_estimado_m3_d',numero_struct_local(V,'ql_estimado_m3d',NaN));
    escribir_num_si_finito_local(fid,'Ql_solver_m3_d',numero_struct_local(V,'ql_solver_m3d',NaN));
    escribir_num_si_finito_local(fid,'Qo_estimado_m3_d',numero_struct_local(V,'qo_estimado_m3d',NaN));
    escribir_num_si_finito_local(fid,'Qo_solver_m3_d',numero_struct_local(V,'qo_solver_m3d',NaN));
    escribir_num_si_finito_local(fid,'residuo_Pa',numero_struct_local(V,'residuo_Pa',NaN));
  endif
endfunction

function escribir_fit_local(fid,sec,nombre,A)
  if ~isstruct(A)||isempty(fieldnames(A)),return;endif
  fprintf(fid,'\n[POLYNOMIAL_FIT_%s_%s]\n',sec,nombre);
  fprintf(fid,'schema=AOS_POLYNOMIAL_FIT_1.0\n');
  fprintf(fid,'estado=%s\n',texto_struct_local(A,'estado','NO_EVALUADO'));
  fprintf(fid,'grado_solicitado=%s\n',grado_struct_local(A));
  escribir_num_si_finito_local(fid,'grado_efectivo',numero_struct_local(A,'grado_efectivo',NaN));
  escribir_num_si_finito_local(fid,'dominio_min_Sm3_d',numero_struct_local(A,'dominio_min',NaN));
  escribir_num_si_finito_local(fid,'dominio_max_Sm3_d',numero_struct_local(A,'dominio_max',NaN));
  escribir_num_si_finito_local(fid,'n_puntos_usados',numero_struct_local(A,'n_puntos_usados',NaN));
  escribir_num_si_finito_local(fid,'r2',numero_struct_local(A,'r2',NaN));
  escribir_num_si_finito_local(fid,'rmse',numero_struct_local(A,'rmse',NaN));
  escribir_num_si_finito_local(fid,'error_maximo',numero_struct_local(A,'error_maximo',NaN));
  escribir_num_si_finito_local(fid,'condicion',numero_struct_local(A,'condicion',NaN));
  fprintf(fid,'discontinuidad=%s\n',cond(logico_struct_local(A,'discontinuidad',false),'SI','NO'));
  fprintf(fid,'apto_informativo=%s\n',cond(logico_struct_local(A,'apto_informativo',false),'SI','NO'));
  fprintf(fid,'apto_optimizacion=%s\n',cond(logico_struct_local(A,'apto_para_optimizacion',false),'SI','NO'));
  if isfield(A,'coeficientes_normalizados')&&isnumeric(A.coeficientes_normalizados)
    fprintf(fid,'coeficientes_normalizados=%s\n',vector_num_local(A.coeficientes_normalizados));
  endif
endfunction

function tf=es_serie_fit_local(A)
  tf=isstruct(A)&&isfield(A,'x_grid')&&isnumeric(A.x_grid)&&~isempty(A.x_grid)&& ...
    isfield(A,'y_grid')&&isnumeric(A.y_grid)&&numel(A.y_grid)==numel(A.x_grid);
endfunction
function s=vector_num_local(v)
  if ~isnumeric(v)||isempty(v),s='';return;endif
  c=cell(1,numel(v));for ii=1:numel(v),c{ii}=num_inline(v(ii));endfor;s=strjoin(c,',');
endfunction
function escribir_num_si_finito_local(fid,n,v),if isfinite(v),fprintf(fid,'%s=%.12g\n',n,v);endif,endfunction
function v=numero_struct_local(S,n,d),v=d;if isstruct(S)&&isfield(S,n)&&isnumeric(S.(n))&&~isempty(S.(n))&&isfinite(S.(n)(1)),v=double(S.(n)(1));endif,endfunction
function t=texto_struct_local(S,n,d),t=d;if isstruct(S)&&isfield(S,n)&&ischar(S.(n))&&~isempty(S.(n)),t=limpiar_txt(S.(n));endif,endfunction
function tf=logico_struct_local(S,n,d),tf=d;if isstruct(S)&&isfield(S,n),x=S.(n);if islogical(x)&&~isempty(x),tf=x(1);elseif isnumeric(x)&&~isempty(x),tf=x(1)~=0;endif;endif,endfunction
function s=grado_struct_local(S),g=numero_struct_local(S,'grado_solicitado',NaN);if isfinite(g),if g==0,s='AUTO';else,s=sprintf('%.0f',g);endif;else,s='N/A';endif,endfunction

function sens_escribir_resultados_texto_nativo(fid,p)
% Escribe una tabla humana en una seccion estandar de resultados.
% Esta seccion es texto real del .aosrpt: puede copiarse, buscarse y
% reconstruirse sin rasterizar informacion numerica.
  fprintf(fid,'\n[RESULTADOS]\n');
  fprintf(fid,'tipo_resultado=SENSIBILIDAD\n');
  fprintf(fid,'variable_sensibilizada=%s\n',limpiar_txt(p.variable));
  fprintf(fid,'unidad_variable=%s\n',limpiar_txt(p.unidad_variable));
  fprintf(fid,'numero_puntos=%d\n',p.n);
  fprintf(fid,'formato_tabla=TEXTO_NATIVO\n');
  fprintf(fid,'tabla_imagen=NO\n');
  fprintf(fid,'tabla_titulo=Produccion y resultados punto a punto\n');
  [idx,nombres]=columnas_principales_local(p,10);
  fprintf(fid,'tabla_columnas=%s\n',limpiar_txt(strjoin(nombres,' | ')));
  fprintf(fid,'tabla_unidades=%s\n',limpiar_txt(strjoin(p.unidades(idx),' | ')));
  for i=1:p.n
    vals=cell(1,numel(idx));
    for k=1:numel(idx)
      v=p.columnas{idx(k)};
      if iscell(v)
        vals{k}=texto_corto_local(v{i},24);
      else
        vals{k}=num_inline(v(i));
      endif
    endfor
    fprintf(fid,'punto_%03d=%s\n',i,limpiar_txt(strjoin(vals,' | ')));
  endfor
  if ~isempty(p.ganancias)
    fprintf(fid,'ganancia_referencia_tipo=%s\n',limpiar_txt(p.referencia_tipo));
    if isfinite(p.referencia_variable)
      fprintf(fid,'ganancia_referencia_variable=%.10g\n',p.referencia_variable);
    endif
    for i=1:numel(p.ganancias)
      g=p.ganancias(i);
      clave=campo_seguro_local(g.respuesta);
      fprintf(fid,'ganancia_%s_base=%.10g\n',clave,g.valor_base);
      if isfinite(g.ganancia_max_pct)
        fprintf(fid,'ganancia_%s_max_pct=%.10g\n',clave,g.ganancia_max_pct);
        fprintf(fid,'ganancia_%s_variable_max=%.10g\n',clave,g.variable_ganancia_max);
      endif
    endfor
  endif
endfunction

function sens_escribir_datos_compatibles(fid,p)
  fprintf(fid,'\n[SENSITIVITY_DATA]\n');
  fprintf(fid,'schema=AOS_SENSITIVITY_VECTORS_1.0\n');
  fprintf(fid,'nota=Compatibilidad con Viewer previo; la fuente canonica es SENSITIVITY_TABLE.\n');
  for j=1:numel(p.columnas)
    clave=campo_seguro_local(p.nombres{j});
    v=p.columnas{j};
    vals=cell(1,p.n);
    for i=1:p.n
      if iscell(v),vals{i}=vector_txt_local(v{i});else,vals{i}=num_inline(v(i));endif
    endfor
    fprintf(fid,'%s=%s\n',clave,strjoin(vals,','));
    fprintf(fid,'%s_unidad=%s\n',clave,limpiar_txt(p.unidades{j}));
  endfor
endfunction

function sens_escribir_tabla_texto(fid,p)
  fprintf(fid,'\n[SENSITIVITY_TABLE_TEXT]\n');
  fprintf(fid,'schema=AOS_SENSITIVITY_TEXT_1.1\n');
  fprintf(fid,'render_mode=TEXT_NATIVE\n');
  fprintf(fid,'image_ref=NONE\n');
  [idx,nombres]=columnas_principales_local(p,10);
  encabezado=strjoin(nombres,' | ');
  fprintf(fid,'encabezado=%s\n',limpiar_txt(encabezado));
  fprintf(fid,'unidades=%s\n',limpiar_txt(strjoin(p.unidades(idx),' | ')));
  for i=1:p.n
    vals=cell(1,numel(idx));
    for k=1:numel(idx)
      v=p.columnas{idx(k)};
      if iscell(v),vals{k}=texto_corto_local(v{i},18);else,vals{k}=num_inline(v(i));endif
    endfor
    fprintf(fid,'fila_%03d=%s\n',i,limpiar_txt(strjoin(vals,' | ')));
  endfor
endfunction

function [idx,nombres]=columnas_principales_local(p,maxn)
  prioridad={p.variable,'Ql_JGL_m3d','Ganancia_Ql_JGL_pct','Qo_JGL_m3d',...
    'Ganancia_Qo_JGL_pct','Ql_GL_m3d','Ganancia_Ql_GL_pct','Qo_GL_m3d',...
    'Ganancia_Qo_GL_pct','Ql_m3d','Ganancia_Ql_pct','Qo_m3d',...
    'Ganancia_Qo_pct','Indice_energetico_bruto_JGL_pct',...
    'Eficiencia_interna_jet_JGL_pct','Indice_energetico_bruto_GL_pct',...
    'DeltaP_JGL_bar','Iteraciones_JGL','Estado_JGL',...
    'Estado_GL','Estado','Aceptado','Confianza'};
  idx=[];
  for i=1:numel(prioridad)
    j=find(strcmp(p.nombres,prioridad{i}),1);
    if ~isempty(j)&&~any(idx==j),idx(end+1)=j;endif
    if numel(idx)>=maxn,break;endif
  endfor
  if isempty(idx),idx=1:min(maxn,numel(p.nombres));endif
  nombres=p.nombres(idx);
endfunction

function s=campo_seguro_local(x)
  if ~ischar(x),x='campo';endif
  s=regexprep(x,'[^A-Za-z0-9_]+','_');
  s=regexprep(s,'^_+|_+$','');
  if isempty(s),s='campo';endif
endfunction

function s=vector_txt_local(x)
  if ~ischar(x),x='';endif
  x=strrep(x,',',';');x=strrep(x,'=','-');x=regexprep(x,'[\r\n]',' ');
  s=['"' strrep(x,'"','""') '"'];
endfunction

function s=texto_corto_local(x,n)
  if ~ischar(x),x='';endif
  x=regexprep(x,'[\r\n|=]',' ');
  if numel(x)>n,x=[x(1:max(1,n-3)) '...'];endif
  s=x;
endfunction

function s=cond(c,a,b),if c,s=a;else,s=b;end,end
