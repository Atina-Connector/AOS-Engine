% sens_Qiny_JGL.m - Barrido de caudal de gas inyectado (solo JGL).
% SENS-GLJGL-03:
%   - una curva usa un unico metodo y una unica resolucion;
%   - NO_CONVERGE y estados no publicables quedan como NaN en la curva;
%   - los valores crudos, estados, residuos y motivos quedan auditados;
%   - la armonizacion polinomica es visible, opcional y posterior al solver;
%   - la condicion motriz y las presiones requeridas se seleccionan y reportan.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
try
  aos_registro_graficos('reset', mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n', err_reg.message);
end_try_catch
cd(AOS_root);

% --- Cargar y preparar una unica configuracion base ---
[base, origen_base] = sens_cargar_base('SENS_JGL');
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.2f m3/d/bar\n', base.IP / 1.1574e-10);
fprintf('WC                      : %.4f (fraccion)\n', base.WC);
fprintf('P_wh                    : %s\n', aos_formato_presion(base.P_wh, 1));
fprintf('P_iny_sup               : %s\n', aos_formato_presion(base.P_iny_sup, 1));
fprintf('Prof. inyeccion/lev.    : %s\n', aos_formato_longitud(base.D_iny, 0));
fprintf('GLR                     : %.2f Sm3/m3\n', base.GLR);
fprintf('IPR                     : %s\n', base.modelo_IPR);
fprintf('VLP                     : %s\n', base.modelo_VLP);
fprintf('a_eductor               : %.6g\n', base.a_eductor);
fprintf('b_eductor               : %.6g\n', base.b_eductor);
fprintf('Geometria JGL           : %s\n', base.jgl_geometria_modo);
fprintf('---------------------------------------\n');

if aos_preguntar_sn('Modificar los parametros? (s/n) [n]: ', false)
  val = input(sprintf('  IP (m3/d/bar) [%.2f]: ', base.IP / 1.1574e-10));
  if ~isempty(val), base.IP = val * 1.1574e-10; endif
  val = input(sprintf('  WC (fraccion 0-1) [%.4f]: ', base.WC));
  if ~isempty(val), base.WC = val; endif
  val = input(sprintf('  P_wh (bar) [%.1f]: ', base.P_wh / 1e5));
  if ~isempty(val), base.P_wh = val * 1e5; endif
  val = input(sprintf('  P_iny_sup (bar) [%.1f]: ', base.P_iny_sup / 1e5));
  if ~isempty(val), base.P_iny_sup = val * 1e5; endif
  val = input(sprintf('  Prof. inyeccion/levantamiento (m) [%.0f]: ', base.D_iny));
  if ~isempty(val), base = aos_set_profundidad(base, 'JGL', val); endif
  val = input(sprintf('  GLR (Sm3/m3) [%.2f]: ', base.GLR));
  if ~isempty(val), base.GLR = val; endif
  val = input(sprintf('  a_eductor [%.6g]: ', base.a_eductor));
  if ~isempty(val), base.a_eductor = val; base.jgl_geometria_modo = 'calibrada'; endif
  val = input(sprintf('  b_eductor [%.6g]: ', base.b_eductor));
  if ~isempty(val), base.b_eductor = val; base.jgl_geometria_modo = 'calibrada'; endif
else
  fprintf('Se conservan los parametros de la fuente seleccionada.\n');
endif
base = sens_preparar_base(base, 'SENS_JGL');

% --- Seleccion de VLP; el IPR se preserva desde el caso base ---
fprintf('\n--- MODELO VLP ---\n');
fprintf('  1 - Simplificado (sin friccion)\n');
fprintf('  2 - Hagedorn-Brown\n');
fprintf('  3 - Duns & Ros\n');
opcion_vlp_def = aos_opcion_modelo_vlp(base.modelo_VLP);
opcion_vlp = input(sprintf('Seleccione VLP (1-3) [%d]: ', opcion_vlp_def));
if isempty(opcion_vlp), opcion_vlp = opcion_vlp_def; endif
if opcion_vlp == 1
  base.modelo_VLP = 'simplified';
elseif opcion_vlp == 3
  base.modelo_VLP = 'DR';
else
  base.modelo_VLP = 'HB';
endif
if isfield(base, 'survey') && ~isempty(base.survey)
  diagnostico_vlp(base.survey, base.modelo_VLP);
endif

% Automatico ahora significa iterativo uniforme, no mezcla de metodos.
[modo_jgl_sens, max_iter_jgl] = jgl_menu_aproximacion('automatico', 10);
base.jgl_modo = modo_jgl_sens;
base.jgl_max_iter = max_iter_jgl;
base = jgl_defaults(base);
try
  base = aos_sincronizar_config(base, 'SENS_JGL');
catch
end_try_catch

% --- Condicion motriz visible: no interpretar P_iny_sup=0 en forma oculta ---
[base, condicion_motriz_menu] = sens_menu_condicion_motriz_jgl(base,'SENSIBILIDAD JGL');
if condicion_motriz_menu.cancelado
  fprintf('Sensibilidad JGL cancelada durante la seleccion de condicion motriz.\n');
  return;
endif
try
  base = aos_sincronizar_config(base, 'SENS_JGL');
catch
end_try_catch

% --- Validacion previa y snapshot ---
val_base = sens_validar_base_gl_jgl(base, 'JGL');
for i = 1:numel(val_base.advertencias)
  fprintf('[ADVERTENCIA BASE] %s\n', val_base.advertencias{i});
endfor
if ~val_base.ok
  fprintf(2, '\nLa sensibilidad JGL fue bloqueada por datos invalidos:\n');
  for i = 1:numel(val_base.errores)
    fprintf(2, '  - %s\n', val_base.errores{i});
  endfor
  error('SENS-GLJGL-03: configuracion JGL invalida. No se ejecuta el barrido.');
endif
base_snapshot = base;
config_firma = val_base.firma;
fprintf('\nSnapshot JGL congelado: %s\n', config_firma);
fprintf('Origen de configuracion: %s\n', origen_base);
fprintf('IPR/VLP efectivos: %s / %s\n', base_snapshot.modelo_IPR, base_snapshot.modelo_VLP);
fprintf('Modo solicitado: %s | iteraciones maximas: %d\n', upper(modo_jgl_sens), max_iter_jgl);
fprintf('Condicion motriz: %s\n', jgl_modo_condicion_motriz(base_snapshot));

% --- Tratamiento posterior de la curva: siempre visible ---
tratamiento_curva = sens_menu_tratamiento_curva('JGL', 'DISCRETO');
if tratamiento_curva.cancelado
  fprintf('Sensibilidad JGL cancelada antes del barrido.\n');
  return;
endif
try
  [qmax_ipr_poly, ~] = ipr(base_snapshot, base_snapshot.modelo_IPR);
  tratamiento_curva.limite_ql_m3d = qmax_ipr_poly * 86400;
catch
  tratamiento_curva.limite_ql_m3d = NaN;
end_try_catch

% --- Limites del barrido ---
Qiny_min = aos_qiny_limite_m3s(base_snapshot, 'min', 20000);
Qiny_max = aos_qiny_limite_m3s(base_snapshot, 'max', 140000);
n_barrido = 15;
fprintf('\n--- LIMITES DEL BARRIDO ---\n');
fprintf('Qiny min : %.0f Sm3/d (%.4f MMscf/d)\n', aos_m3s_a_sm3d(Qiny_min), aos_m3s_a_mmscfd(Qiny_min));
fprintf('Qiny max : %.0f Sm3/d (%.4f MMscf/d)\n', aos_m3s_a_sm3d(Qiny_max), aos_m3s_a_mmscfd(Qiny_max));
fprintf('N puntos : %d\n', n_barrido);
if aos_preguntar_sn('Desea modificar los limites? (s/n) [n]: ', false)
  val = input(sprintf('  Qiny min (Sm3/d) [%.0f]: ', aos_m3s_a_sm3d(Qiny_min)));
  if ~isempty(val), Qiny_min = aos_sm3d_a_m3s(val); endif
  val = input(sprintf('  Qiny max (Sm3/d) [%.0f]: ', aos_m3s_a_sm3d(Qiny_max)));
  if ~isempty(val), Qiny_max = aos_sm3d_a_m3s(val); endif
  val = input(sprintf('  N puntos [%d]: ', n_barrido));
  if ~isempty(val), n_barrido = max(2, round(val)); endif
endif
Qiny_min = max(Qiny_min, 0);
Qiny_max = max(Qiny_max, 0);
if Qiny_max < Qiny_min
  tmp = Qiny_min; Qiny_min = Qiny_max; Qiny_max = tmp;
endif
Qiny_vals = linspace(Qiny_min, Qiny_max, n_barrido);
Qiny_vals = sens_agregar_qiny_referencia(Qiny_vals, base_snapshot);
npts = numel(Qiny_vals);

% --- Barrido uniforme ---
fprintf('\n--- EJECUCION JGL SENS-GLJGL-03 ---\n');
R_uniforme = jgl_sensibilidad_ejecutar(base_snapshot, Qiny_vals, modo_jgl_sens);
Ql_JGL = R_uniforme.Ql * 86400;
Qo_JGL = R_uniforme.Qo * 86400;
Ql_JGL_raw = R_uniforme.Ql_raw * 86400;
Qo_JGL_raw = R_uniforme.Qo_raw * 86400;
Convergido_JGL = logical(R_uniforme.convergido);
Aceptado_JGL = logical(R_uniforme.aceptado);
ValidoCurva_JGL = logical(R_uniforme.valido_para_curva);
ValidoOptimo_JGL = logical(R_uniforme.valido_para_optimo);
Residuo_JGL_Pa = R_uniforme.residuo_Pa;
preliminar_jgl = R_uniforme.preliminar;

% Verificacion de firma y reporte de progreso.
for i = 1:npts
  if ~strcmp(R_uniforme.config_firma{i}, config_firma)
    Aceptado_JGL(i) = false;
    ValidoCurva_JGL(i) = false;
    ValidoOptimo_JGL(i) = false;
    Ql_JGL(i) = NaN;
    Qo_JGL(i) = NaN;
    R_uniforme.aceptado(i) = false;
    R_uniforme.valido_para_curva(i) = false;
    R_uniforme.valido_para_optimo(i) = false;
    R_uniforme.Ql(i) = NaN;
    R_uniforme.Qo(i) = NaN;
    R_uniforme.motivos_rechazo{i}{end+1} = 'La configuracion efectiva cambio dentro del barrido.';
  endif

  if ValidoCurva_JGL(i)
    fprintf('[%02d/%02d] Qiny=%9.0f Sm3/d | Ql=%8.2f m3/d | %s | %s\n', ...
      i, npts, aos_m3s_a_sm3d(Qiny_vals(i)), Ql_JGL(i), ...
      R_uniforme.modos{i}, R_uniforme.estados{i});
  else
    motivo = 'sin detalle';
    if ~isempty(R_uniforme.motivos_rechazo{i})
      motivo = R_uniforme.motivos_rechazo{i}{1};
    endif
    fprintf(2, '[%02d/%02d] Qiny=%9.0f Sm3/d | RECHAZADO | %s | %s\n', ...
      i, npts, aos_m3s_a_sm3d(Qiny_vals(i)), R_uniforme.estados{i}, motivo);
  endif
endfor
R_uniforme.aceptado = Aceptado_JGL;
R_uniforme.valido_para_curva = ValidoCurva_JGL;
R_uniforme.valido_para_optimo = ValidoOptimo_JGL;
R_uniforme.Ql = Ql_JGL / 86400;
R_uniforme.Qo = Qo_JGL / 86400;

fprintf('Metodo final uniforme: %s\n', R_uniforme.modo_final_uniforme);
fprintf('Puntos iterativos: %d/%d. Puntos publicados: %d/%d.\n', ...
  sum(R_uniforme.seleccion_iterativa), npts, sum(ValidoCurva_JGL), npts);
if preliminar_jgl
  fprintf('[PRELIMINAR] Esta modalidad no habilita optimo tecnico ni economico.\n');
endif

% --- Clasificacion y ganancias ---
clasif_curva = sens_clasificar_curva(Qiny_vals, Qo_JGL);
Qo_optimo = Qo_JGL;
Qo_optimo(~ValidoOptimo_JGL) = NaN;
clasif_optimo = sens_clasificar_curva(Qiny_vals, Qo_optimo);
if preliminar_jgl
  clasif_optimo.tipo = 'PRELIMINAR_SIN_OPTIMO';
  clasif_optimo.optimo_x = NaN;
  clasif_optimo.optimo_y = NaN;
  clasif_optimo.mensaje = 'Modo preliminar: no se declara optimo.';
endif
fprintf('\nJGL curva publicada: %s\n', clasif_curva.mensaje);
fprintf('JGL optimo: %s\n', clasif_optimo.mensaje);
Qiny_opt = NaN;
if strcmp(clasif_optimo.tipo, 'OPTIMO_INTERIOR')
  Qiny_opt = clasif_optimo.optimo_x;
  fprintf('Optimo interior JGL: Qiny %.0f Sm3/d, Qo %.2f m3/d\n', ...
    Qiny_opt * 86400, clasif_optimo.optimo_y);
endif

x_vals = Qiny_vals * 86400;
[ganQl, ganQl_pct, ganQl_inc_pct, refQl] = sens_calcular_ganancias(Ql_JGL, x_vals, true);
[ganQo, ganQo_pct, ganQo_inc_pct, refQo] = sens_calcular_ganancias(Qo_JGL, x_vals, true);
fprintf('Referencia ganancia JGL: %s\n', refQl.mensaje);

% --- Presiones motrices requeridas y factibilidad por Qiny ---
PRESIONES_JGL = sens_jgl_construir_presiones(R_uniforme,x_vals);
sens_jgl_imprimir_presiones(PRESIONES_JGL,'JGL');

% --- Energia y optimizacion solo con puntos publicables ---
IndiceBrutoJGL = NaN(1, npts);
EficienciaJetJGL = NaN(1, npts);
EnergiaJGL = cell(1, npts);
for i = 1:npts
  if ~ValidoCurva_JGL(i), continue; endif
  try
    pp = aos_set_qiny(base_snapshot, Qiny_vals(i) * 86400, 'fijo');
    ej = aos_balance_energia_sla('JGL', pp, R_uniforme.Ql(i), R_uniforme.Qo(i), ...
      Qiny_vals(i), R_uniforme.soluciones{i});
    EnergiaJGL{i} = ej;
    met = aos_metricas_energia_sla(ej, 'JGL');
    IndiceBrutoJGL(i) = met.indice_energetico_bruto_fondo_pct;
    EficienciaJetJGL(i) = met.eficiencia_interna_jet_pct;
  catch err
    fprintf('Aviso energia JGL punto %d: %s\n', i, err.message);
  end_try_catch
endfor
econ = sens_configurar_economia_inyeccion();
OPT_JGL = sens_optimo_inyeccion(x_vals, IndiceBrutoJGL, Ql_JGL, Qo_JGL, ...
  ValidoOptimo_JGL, econ, tratamiento_curva, ValidoCurva_JGL);
if tratamiento_curva.verificar_optimo
  opts_ver_jgl = struct('modo', lower(R_uniforme.modo_final_uniforme), ...
    'nodal_n_puntos',1201,'jgl_n_puntos',120,'preliminar',preliminar_jgl, ...
    'tolerancia_verificacion_rel',0.05,'tolerancia_verificacion_abs_m3d',0.5);
  if preliminar_jgl && any(strcmp(lower(modo_jgl_sens), {'abreviado','movil'}))
    opts_ver_jgl.nodal_n_puntos = 121;
    opts_ver_jgl.jgl_n_puntos = 81;
  endif
  [OPT_JGL, VER_POLY_JGL] = sens_verificar_optimo_polinomico(OPT_JGL, 'JGL', ...
    base_snapshot, opts_ver_jgl);
else
  VER_POLY_JGL = struct('estado','NO_SOLICITADA','verificado',false);
  OPT_JGL.verificacion_polinomica = VER_POLY_JGL;
endif
sens_imprimir_optimo_inyeccion('JGL', OPT_JGL);

% --- Tabla auditable ---
fprintf('\n=== RESULTADOS JGL SENS-GLJGL-03 ===\n');
fprintf('Qiny req | Ql raw | Ql pub | Qo pub | Residuo | Iter | Acept | Curva | Opt | Estado\n');
fprintf('(Sm3/d)  | (m3/d) | (m3/d) | (m3/d) |  (bar)  |      |       |       |     |\n');
for i = 1:npts
  ss = R_uniforme.soluciones{i};
  iter = NaN;
  if isstruct(ss) && isfield(ss, 'iteraciones'), iter = ss.iteraciones; endif
  fprintf('%8.0f | %7.2f | %7.2f | %7.2f | %8.4f | %4.0f |   %s   |  %s   | %s | %s\n', ...
    x_vals(i), Ql_JGL_raw(i), Ql_JGL(i), Qo_JGL(i), Residuo_JGL_Pa(i)/1e5, iter, ...
    sens_si_no(Aceptado_JGL(i)), sens_si_no(ValidoCurva_JGL(i)), ...
    sens_si_no(ValidoOptimo_JGL(i)), R_uniforme.estados{i});
endfor
fprintf('Puntos publicados: %d/%d. Puntos habilitados para optimo: %d/%d.\n', ...
  sum(ValidoCurva_JGL), npts, sum(ValidoOptimo_JGL), npts);
fprintf('=====================================\n');

SENS_QINY_JGL_AUDIT = struct();
SENS_QINY_JGL_AUDIT.hotfix = 'SENS-GLJGL-03';
SENS_QINY_JGL_AUDIT.politica = 'CONFIG_CONGELADA_METODO_UNIFORME_PUBLICACION_ESTRICTA_TRATAMIENTO_CURVA_Y_CONDICION_MOTRIZ_EXPLICITAS';
SENS_QINY_JGL_AUDIT.origen_base = origen_base;
SENS_QINY_JGL_AUDIT.config_firma = config_firma;
SENS_QINY_JGL_AUDIT.config_firma_por_punto = R_uniforme.config_firma;
SENS_QINY_JGL_AUDIT.modo_solicitado = modo_jgl_sens;
SENS_QINY_JGL_AUDIT.modo_final_uniforme = R_uniforme.modo_final_uniforme;
SENS_QINY_JGL_AUDIT.preliminar = preliminar_jgl;
SENS_QINY_JGL_AUDIT.Qiny_solicitado = Qiny_vals;
SENS_QINY_JGL_AUDIT.resultado = R_uniforme;
SENS_QINY_JGL_AUDIT.Ql_raw_m3d = Ql_JGL_raw;
SENS_QINY_JGL_AUDIT.Qo_raw_m3d = Qo_JGL_raw;
SENS_QINY_JGL_AUDIT.Ql_m3d = Ql_JGL;
SENS_QINY_JGL_AUDIT.Qo_m3d = Qo_JGL;
SENS_QINY_JGL_AUDIT.convergido = Convergido_JGL;
SENS_QINY_JGL_AUDIT.aceptado = Aceptado_JGL;
SENS_QINY_JGL_AUDIT.valido_para_curva = ValidoCurva_JGL;
SENS_QINY_JGL_AUDIT.valido_para_optimo = ValidoOptimo_JGL;
SENS_QINY_JGL_AUDIT.residuo_JGL_Pa = Residuo_JGL_Pa;
SENS_QINY_JGL_AUDIT.estados = R_uniforme.estados;
SENS_QINY_JGL_AUDIT.modos = R_uniforme.modos;
SENS_QINY_JGL_AUDIT.motivos_rechazo = R_uniforme.motivos_rechazo;
SENS_QINY_JGL_AUDIT.advertencias = R_uniforme.advertencias;
SENS_QINY_JGL_AUDIT.ganancia_Ql_m3d = ganQl;
SENS_QINY_JGL_AUDIT.ganancia_Ql_pct = ganQl_pct;
SENS_QINY_JGL_AUDIT.ganancia_incremental_Ql_pct = ganQl_inc_pct;
SENS_QINY_JGL_AUDIT.ganancia_Qo_m3d = ganQo;
SENS_QINY_JGL_AUDIT.ganancia_Qo_pct = ganQo_pct;
SENS_QINY_JGL_AUDIT.ganancia_incremental_Qo_pct = ganQo_inc_pct;
SENS_QINY_JGL_AUDIT.referencia_ganancia = refQl.tipo;
SENS_QINY_JGL_AUDIT.referencia_Qiny_Sm3_d = refQl.x;
SENS_QINY_JGL_AUDIT.clasificacion = clasif_optimo;
SENS_QINY_JGL_AUDIT.clasificacion_curva = clasif_curva;
SENS_QINY_JGL_AUDIT.Indice_energetico_bruto_JGL_pct = IndiceBrutoJGL;
SENS_QINY_JGL_AUDIT.Eficiencia_interna_jet_JGL_pct = EficienciaJetJGL;
SENS_QINY_JGL_AUDIT.energia_por_punto = EnergiaJGL;
SENS_QINY_JGL_AUDIT.rendimiento_energetico_pct = IndiceBrutoJGL;
SENS_QINY_JGL_AUDIT.optimizacion_inyeccion = OPT_JGL;
SENS_QINY_JGL_AUDIT.tratamiento_curva = tratamiento_curva;
SENS_QINY_JGL_AUDIT.verificacion_polinomica = VER_POLY_JGL;
SENS_QINY_JGL_AUDIT.condicion_motriz_menu = condicion_motriz_menu;
SENS_QINY_JGL_AUDIT.presiones_motrices_JGL = PRESIONES_JGL;
SENS_QINY_JGL_AUDIT.P_succion_eductor_JGL_bar = PRESIONES_JGL.P_succion_eductor_bar;
SENS_QINY_JGL_AUDIT.DeltaP_motriz_requerida_JGL_bar = PRESIONES_JGL.DeltaP_motriz_requerida_bar;
SENS_QINY_JGL_AUDIT.P_motriz_fondo_requerida_JGL_bar = PRESIONES_JGL.P_motriz_fondo_requerida_bar;
SENS_QINY_JGL_AUDIT.P_motriz_fondo_disponible_JGL_bar = PRESIONES_JGL.P_motriz_fondo_disponible_bar;
SENS_QINY_JGL_AUDIT.P_iny_sup_requerida_JGL_bar = PRESIONES_JGL.P_iny_sup_requerida_bar;
SENS_QINY_JGL_AUDIT.P_iny_sup_disponible_JGL_bar = PRESIONES_JGL.P_iny_sup_disponible_bar;
SENS_QINY_JGL_AUDIT.DeltaP_columna_gas_JGL_bar = PRESIONES_JGL.DeltaP_columna_gas_bar;
SENS_QINY_JGL_AUDIT.DeltaP_friccion_inyeccion_JGL_bar = PRESIONES_JGL.DeltaP_friccion_inyeccion_bar;
SENS_QINY_JGL_AUDIT.Margen_presion_JGL_bar = PRESIONES_JGL.Margen_presion_superficie_bar;
SENS_QINY_JGL_AUDIT.Factible_presion_JGL = PRESIONES_JGL.factible_por_presion;
SENS_QINY_JGL_AUDIT.estado_presion_JGL = PRESIONES_JGL.estado_presion_motriz;
SENS_QINY_JGL_AUDIT.modo_condicion_motriz_JGL = PRESIONES_JGL.modo_condicion_motriz;
SENS_QINY_JGL_AUDIT.limite_presion_JGL = PRESIONES_JGL.limite_presion;
if isfield(OPT_JGL,'ql_polinomio_en_puntos_m3d') && numel(OPT_JGL.ql_polinomio_en_puntos_m3d)==npts
  SENS_QINY_JGL_AUDIT.Ql_JGL_polinomio_m3d = OPT_JGL.ql_polinomio_en_puntos_m3d;
else
  SENS_QINY_JGL_AUDIT.Ql_JGL_polinomio_m3d = NaN(1,npts);
endif
if isfield(OPT_JGL,'qo_polinomio_en_puntos_m3d') && numel(OPT_JGL.qo_polinomio_en_puntos_m3d)==npts
  SENS_QINY_JGL_AUDIT.Qo_JGL_polinomio_m3d = OPT_JGL.qo_polinomio_en_puntos_m3d;
else
  SENS_QINY_JGL_AUDIT.Qo_JGL_polinomio_m3d = NaN(1,npts);
endif
SENS_QINY_JGL_AUDIT.economia = econ;
assignin('base', 'SENS_QINY_JGL_AUDIT', SENS_QINY_JGL_AUDIT);

% --- Graficos: puntos del solver siempre visibles; polinomio solo si fue elegido ---
clear Aql_plot;
figure;
plot(x_vals, Ql_JGL, 'b-o', 'LineWidth', 2);
hold on;
leyendas = {'Puntos JGL validados'};
if tratamiento_curva.habilitado && isfield(OPT_JGL,'ajuste_polinomico') && ...
    isfield(OPT_JGL.ajuste_polinomico,'ql') && OPT_JGL.ajuste_polinomico.ql.apto_informativo
  Aql_plot = OPT_JGL.ajuste_polinomico.ql;
  plot(Aql_plot.x_grid, Aql_plot.y_grid, '-', 'LineWidth', 2);
  leyendas{end+1} = sprintf('Polinomio JGL grado %d',Aql_plot.grado_efectivo);
endif
if isfield(VER_POLY_JGL,'verificado') && VER_POLY_JGL.verificado
  plot(VER_POLY_JGL.qiny_efectivo_sm3d, VER_POLY_JGL.ql_solver_m3d, ...
    'ks', 'MarkerSize', 10, 'LineWidth', 2);
  leyendas{end+1} = 'Optimo polinomico verificado';
endif
xlabel('Caudal de gas inyectado [Sm3/d]');
ylabel('Liquido (m3/d)');
title('Produccion JGL vs Q_{iny}: solver y tratamiento seleccionado');
grid on;
legend(leyendas,'Location','northeast');
yf = Ql_JGL(isfinite(Ql_JGL));
if tratamiento_curva.habilitado && exist('Aql_plot','var')
  yf = [yf Aql_plot.y_grid(isfinite(Aql_plot.y_grid))];
endif
if ~isempty(yf)
  yr = max(yf) - min(yf);
  pad = max(0.5, 0.15 * max(yr, 0.5));
  ylim([min(yf)-pad, max(yf)+pad]);
endif
exportar_grafico_modulo();

figure;
plot(x_vals, ganQl_pct, '-o', 'LineWidth', 2);
grid on;
xlabel('Caudal de gas inyectado [Sm3/d]');
ylabel('Ganancia de liquido (%)');
title(sprintf('JGL: ganancia respecto de Qiny %.0f Sm3/d', refQl.x));
exportar_grafico_modulo();

sens_jgl_graficar_presiones(PRESIONES_JGL,'JGL');
exportar_grafico_modulo();

figure;
subplot(2,1,1);
plot(x_vals, IndiceBrutoJGL, '-o', 'LineWidth', 2);
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('Indice energetico bruto de fondo (%)');
title('JGL: indice energetico bruto de fondo');
subplot(2,1,2);
if isfield(OPT_JGL, 'x_derivada_sm3d') && ...
    isfield(OPT_JGL, 'derivada_rendimiento_pct_por_Sm3d') && ...
    ~isempty(OPT_JGL.x_derivada_sm3d)
  plot(OPT_JGL.x_derivada_sm3d, OPT_JGL.derivada_rendimiento_pct_por_Sm3d, '-', 'LineWidth', 2);
else
  plot(NaN, NaN);
  text(0.1, 0.5, 'Derivada no disponible: puntos validos insuficientes.');
endif
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('dI bruto/dQiny');
title(sprintf('JGL: derivada (%s)',tratamiento_curva.modo));
exportar_grafico_modulo();

if econ.habilitado && isfield(OPT_JGL, 'economico') && isfield(OPT_JGL.economico, 'qiny_sm3d')
  figure;
  plot(OPT_JGL.economico.qiny_sm3d, OPT_JGL.economico.resultado_neto_dia, '-o', 'LineWidth', 2);
  hold on;
  leg_e = {'Economia discreta'};
  if tratamiento_curva.habilitado && isfield(OPT_JGL,'economico_polinomico') && ...
      isfield(OPT_JGL.economico_polinomico,'habilitado') && OPT_JGL.economico_polinomico.habilitado
    plot(OPT_JGL.economico_polinomico.qiny_sm3d, ...
      OPT_JGL.economico_polinomico.resultado_neto_dia, '-', 'LineWidth', 2);
    leg_e{end+1} = 'Economia polinomica derivada';
  endif
  grid on;
  xlabel('Qiny (Sm3/d)');
  ylabel(sprintf('Resultado neto (%s/d)', econ.moneda));
  title('JGL: resultado economico de la inyeccion');
  legend(leg_e,'Location','northeast');
  exportar_grafico_modulo();
endif

sens_exportar_resultados('SENS_QINY_JGL_AUDIT', 'Qiny JGL', base_snapshot, 'JGL');
