% sens_Qiny_GL.m - Barrido de caudal de gas inyectado (solo GL).
% SENS-GLJGL-02:
%   - usa la misma configuracion efectiva y el mismo solver que el punto GL;
%   - conserva resultados crudos, pero publica NaN cuando el punto no es valido;
%   - usa precision uniforme y no optimiza curvas preliminares o no convergidas;
%   - ofrece tratamiento discreto o polinomico visible, nunca oculto.

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
[base, origen_base] = sens_cargar_base('SENS_GL');
base = sens_preparar_base(base, 'SENS_GL');

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.2f m3/d/bar\n', base.IP / 1.1574e-10);
fprintf('WC                      : %.4f (fraccion)\n', base.WC);
fprintf('P_wh                    : %s\n', aos_formato_presion(base.P_wh, 1));
fprintf('P_iny_sup               : %s\n', aos_formato_presion(base.P_iny_sup, 1));
fprintf('Prof. inyeccion/lev.    : %s\n', aos_formato_longitud(base.D_iny, 0));
fprintf('GLR                     : %.2f Sm3/m3\n', base.GLR);
fprintf('IPR                     : %s\n', base.modelo_IPR);
fprintf('VLP                     : %s\n', base.modelo_VLP);
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
  if ~isempty(val), base = aos_set_profundidad(base, 'GL', val); endif
  val = input(sprintf('  GLR (Sm3/m3) [%.2f]: ', base.GLR));
  if ~isempty(val), base.GLR = val; endif
else
  fprintf('Se conservan los parametros de la fuente seleccionada.\n');
endif
base = sens_preparar_base(base, 'SENS_GL');

% --- Seleccion de VLP; el IPR se preserva exactamente desde el caso base ---
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

% --- Politica numerica uniforme ---
modo_calc_gl = sens_menu_modo_general('GL', 'preciso');
if any(strcmp(modo_calc_gl, {'preciso','hibrido'}))
  n_nodal_gl = 1201;
  preliminar_gl = false;
elseif strcmp(modo_calc_gl, 'simple')
  n_nodal_gl = 121;
  preliminar_gl = true;
else
  n_nodal_gl = 61;
  preliminar_gl = true;
endif
base.sens_nodal_n_puntos = n_nodal_gl;
base.sens_modo_calculo = modo_calc_gl;
try
  base = aos_sincronizar_config(base, 'SENS_GL');
catch
end_try_catch

% --- Validacion previa y congelamiento del snapshot ---
val_base = sens_validar_base_gl_jgl(base, 'GL');
for i = 1:numel(val_base.advertencias)
  fprintf('[ADVERTENCIA BASE] %s\n', val_base.advertencias{i});
endfor
if ~val_base.ok
  fprintf(2, '\nLa sensibilidad GL fue bloqueada por datos invalidos:\n');
  for i = 1:numel(val_base.errores)
    fprintf(2, '  - %s\n', val_base.errores{i});
  endfor
  error('SENS-GLJGL-02: configuracion GL invalida. No se ejecuta el barrido.');
endif
base_snapshot = base;
config_firma = val_base.firma;
fprintf('\nSnapshot GL congelado: %s\n', config_firma);
fprintf('Origen de configuracion: %s\n', origen_base);
fprintf('IPR/VLP efectivos: %s / %s\n', base_snapshot.modelo_IPR, base_snapshot.modelo_VLP);
fprintf('Malla nodal uniforme: %d puntos (%s)\n', n_nodal_gl, upper(modo_calc_gl));
if preliminar_gl
  fprintf('[PRELIMINAR] Esta modalidad no habilita optimo tecnico ni economico.\n');
endif

% --- Tratamiento posterior de la curva: siempre visible ---
tratamiento_curva = sens_menu_tratamiento_curva('GL', 'DISCRETO');
if tratamiento_curva.cancelado
  fprintf('Sensibilidad GL cancelada antes del barrido.\n');
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

% Valores publicables.
Ql_GL = NaN(1, npts);
Qo_GL = NaN(1, npts);
% Valores crudos para auditoria.
Ql_GL_raw = NaN(1, npts);
Qo_GL_raw = NaN(1, npts);
Qgas_total_raw = NaN(1, npts);
Qiny_efectivo = NaN(1, npts);
P_req_sol = NaN(1, npts);
P_s_sol = NaN(1, npts);
Qg_formacion = NaN(1, npts);
Qg_total_vlp = NaN(1, npts);
Residuo_GL_Pa = NaN(1, npts);
Estado_GL = cell(1, npts);
Detalle_GL = cell(1, npts);
Motivos_GL = cell(1, npts);
Advertencias_GL = cell(1, npts);
Firma_GL = cell(1, npts);
Convergido_GL = false(1, npts);
Aceptado_GL = false(1, npts);
ValidoCurva_GL = false(1, npts);
ValidoOptimo_GL = false(1, npts);

% --- Barrido canonico: mismo evaluador que GL puntual ---
opts_gl = struct('n_puntos', n_nodal_gl, 'preliminar', preliminar_gl);
fprintf('\n--- EJECUCION GL SENS-GLJGL-02 ---\n');
for i = 1:npts
  Qiny_actual = Qiny_vals(i);
  E = sens_gl_evaluar_punto(base_snapshot, Qiny_actual, opts_gl);

  % La firma debe ser identica en todos los puntos; Qiny esta excluido.
  if ~strcmp(E.config_firma, config_firma)
    E.aceptado = false;
    E.valido_para_curva = false;
    E.valido_para_optimo = false;
    E.Ql = NaN;
    E.Qo = NaN;
    E.motivos_rechazo{end+1} = 'La configuracion efectiva cambio dentro del barrido.';
  endif

  Ql_GL_raw(i) = E.Ql_raw * 86400;
  Qo_GL_raw(i) = E.Qo_raw * 86400;
  Qgas_total_raw(i) = E.Qgas_total_raw * 86400;
  Ql_GL(i) = E.Ql * 86400;
  Qo_GL(i) = E.Qo * 86400;
  Qiny_efectivo(i) = E.Qiny_efectivo;
  Residuo_GL_Pa(i) = E.residuo_Pa;
  Estado_GL{i} = E.estado;
  Detalle_GL{i} = E.detalle;
  Motivos_GL{i} = E.motivos_rechazo;
  Advertencias_GL{i} = E.advertencias;
  Firma_GL{i} = E.config_firma;
  Convergido_GL(i) = E.convergido;
  Aceptado_GL(i) = E.aceptado;
  ValidoCurva_GL(i) = E.valido_para_curva;
  ValidoOptimo_GL(i) = E.valido_para_optimo;

  if isstruct(E.detalle) && isfield(E.detalle, 'balance_solucion') && isstruct(E.detalle.balance_solucion)
    b = E.detalle.balance_solucion;
    if isfield(b, 'Qg_inyectado_std'), Qiny_efectivo(i) = b.Qg_inyectado_std; endif
    if isfield(b, 'Qg_formacion_std'), Qg_formacion(i) = b.Qg_formacion_std; endif
    if isfield(b, 'Qg_total_std'), Qg_total_vlp(i) = b.Qg_total_std; endif
    if isfield(b, 'P_s'), P_s_sol(i) = b.P_s / 1e5; endif
    if isfield(b, 'P_req'), P_req_sol(i) = b.P_req / 1e5; endif
  endif

  if E.valido_para_curva
    fprintf('[%02d/%02d] Qiny=%9.0f Sm3/d | Ql=%8.2f m3/d | %s\n', ...
      i, npts, aos_m3s_a_sm3d(Qiny_actual), Ql_GL(i), E.estado);
  else
    motivo = 'sin detalle';
    if ~isempty(E.motivos_rechazo), motivo = E.motivos_rechazo{1}; endif
    fprintf(2, '[%02d/%02d] Qiny=%9.0f Sm3/d | RECHAZADO | %s | %s\n', ...
      i, npts, aos_m3s_a_sm3d(Qiny_actual), E.estado, motivo);
  endif
endfor

% --- Clasificacion y ganancias solo con valores publicados ---
if preliminar_gl
  fprintf(['Modo GL preliminar: se conservan los puntos discretos calculados; ' ...
    'no se ejecuta ajuste polinomico auxiliar.\n']);
endif
clasif_curva = sens_clasificar_curva(Qiny_vals, Qo_GL);
Qo_optimo = Qo_GL;
Qo_optimo(~ValidoOptimo_GL) = NaN;
clasif_optimo = sens_clasificar_curva(Qiny_vals, Qo_optimo);
if preliminar_gl
  clasif_optimo.tipo = 'PRELIMINAR_SIN_OPTIMO';
  clasif_optimo.optimo_x = NaN;
  clasif_optimo.optimo_y = NaN;
  clasif_optimo.mensaje = 'Modo preliminar: no se declara optimo.';
endif
fprintf('\nGL curva publicada: %s\n', clasif_curva.mensaje);
fprintf('GL optimo: %s\n', clasif_optimo.mensaje);
Qiny_opt = NaN;
if strcmp(clasif_optimo.tipo, 'OPTIMO_INTERIOR')
  Qiny_opt = clasif_optimo.optimo_x;
  fprintf('Optimo interior GL: Qiny %.0f Sm3/d, Qo %.2f m3/d\n', ...
    Qiny_opt * 86400, clasif_optimo.optimo_y);
endif

x_vals = Qiny_vals * 86400;
[ganQl, ganQl_pct, ganQl_inc_pct, refQl] = sens_calcular_ganancias(Ql_GL, x_vals, true);
[ganQo, ganQo_pct, ganQo_inc_pct, refQo] = sens_calcular_ganancias(Qo_GL, x_vals, true);
fprintf('Referencia ganancia GL: %s\n', refQl.mensaje);

% --- Energia y optimizacion: exclusivamente puntos aceptados ---
IndiceBrutoGL = NaN(1, npts);
EnergiaGL = cell(1, npts);
for i = 1:npts
  if ~ValidoCurva_GL(i), continue; endif
  try
    pp = aos_set_qiny(base_snapshot, Qiny_vals(i) * 86400, 'fijo');
    eg = aos_balance_energia_sla('GL', pp, Ql_GL(i)/86400, Qo_GL(i)/86400, Qiny_vals(i), Detalle_GL{i});
    EnergiaGL{i} = eg;
    met = aos_metricas_energia_sla(eg, 'GL');
    IndiceBrutoGL(i) = met.indice_energetico_bruto_fondo_pct;
  catch err
    fprintf('Aviso energia GL punto %d: %s\n', i, err.message);
  end_try_catch
endfor
econ = sens_configurar_economia_inyeccion();
OPT_GL = sens_optimo_inyeccion(x_vals, IndiceBrutoGL, Ql_GL, Qo_GL, ...
  ValidoOptimo_GL, econ, tratamiento_curva, ValidoCurva_GL);
if tratamiento_curva.verificar_optimo
  opts_ver_gl = opts_gl;
  opts_ver_gl.tolerancia_verificacion_rel = 0.05;
  opts_ver_gl.tolerancia_verificacion_abs_m3d = 0.5;
  [OPT_GL, VER_POLY_GL] = sens_verificar_optimo_polinomico(OPT_GL, 'GL', base_snapshot, opts_ver_gl);
else
  VER_POLY_GL = struct('estado','NO_SOLICITADA','verificado',false);
  OPT_GL.verificacion_polinomica = VER_POLY_GL;
endif
sens_imprimir_optimo_inyeccion('GL', OPT_GL);

% --- Tabla auditable ---
fprintf('\n=== RESULTADOS GL SENS-GLJGL-02 ===\n');
fprintf('Qiny req | Ql raw | Ql pub | Qo pub | Residuo | Acept | Curva | Opt | Estado\n');
fprintf('(Sm3/d)  | (m3/d) | (m3/d) | (m3/d) |  (bar)  |        |       |     |\n');
for i = 1:npts
  fprintf('%8.0f | %7.2f | %7.2f | %7.2f | %8.4f |   %s   |  %s   | %s | %s\n', ...
    x_vals(i), Ql_GL_raw(i), Ql_GL(i), Qo_GL(i), Residuo_GL_Pa(i)/1e5, ...
    sens_si_no(Aceptado_GL(i)), sens_si_no(ValidoCurva_GL(i)), ...
    sens_si_no(ValidoOptimo_GL(i)), Estado_GL{i});
endfor
fprintf('Puntos publicados: %d/%d. Puntos habilitados para optimo: %d/%d.\n', ...
  sum(ValidoCurva_GL), npts, sum(ValidoOptimo_GL), npts);
fprintf('====================================\n');

SENS_QINY_GL_AUDIT = struct();
SENS_QINY_GL_AUDIT.hotfix = 'SENS-GLJGL-02';
SENS_QINY_GL_AUDIT.politica = 'CONFIG_CONGELADA_PUNTO_CANONICO_PUBLICACION_ESTRICTA_TRATAMIENTO_CURVA_EXPLICITO';
SENS_QINY_GL_AUDIT.origen_base = origen_base;
SENS_QINY_GL_AUDIT.config_firma = config_firma;
SENS_QINY_GL_AUDIT.config_firma_por_punto = Firma_GL;
SENS_QINY_GL_AUDIT.modo_solicitado = modo_calc_gl;
SENS_QINY_GL_AUDIT.preliminar = preliminar_gl;
SENS_QINY_GL_AUDIT.nodal_n_puntos = n_nodal_gl;
SENS_QINY_GL_AUDIT.Qiny_solicitado = Qiny_vals;
SENS_QINY_GL_AUDIT.Qiny_efectivo = Qiny_efectivo;
SENS_QINY_GL_AUDIT.Qg_formacion = Qg_formacion;
SENS_QINY_GL_AUDIT.Qg_total_VLP = Qg_total_vlp;
SENS_QINY_GL_AUDIT.Qgas_total_raw_Sm3_d = Qgas_total_raw;
SENS_QINY_GL_AUDIT.Ql_raw_m3d = Ql_GL_raw;
SENS_QINY_GL_AUDIT.Qo_raw_m3d = Qo_GL_raw;
SENS_QINY_GL_AUDIT.Ql_m3d = Ql_GL;
SENS_QINY_GL_AUDIT.Qo_m3d = Qo_GL;
SENS_QINY_GL_AUDIT.convergido = Convergido_GL;
SENS_QINY_GL_AUDIT.aceptado = Aceptado_GL;
SENS_QINY_GL_AUDIT.valido_para_curva = ValidoCurva_GL;
SENS_QINY_GL_AUDIT.valido_para_optimo = ValidoOptimo_GL;
SENS_QINY_GL_AUDIT.residuo_GL_Pa = Residuo_GL_Pa;
SENS_QINY_GL_AUDIT.estado = Estado_GL;
SENS_QINY_GL_AUDIT.motivos_rechazo = Motivos_GL;
SENS_QINY_GL_AUDIT.advertencias = Advertencias_GL;
SENS_QINY_GL_AUDIT.detalle_por_punto = Detalle_GL;
SENS_QINY_GL_AUDIT.ganancia_Ql_m3d = ganQl;
SENS_QINY_GL_AUDIT.ganancia_Ql_pct = ganQl_pct;
SENS_QINY_GL_AUDIT.ganancia_incremental_Ql_pct = ganQl_inc_pct;
SENS_QINY_GL_AUDIT.ganancia_Qo_m3d = ganQo;
SENS_QINY_GL_AUDIT.ganancia_Qo_pct = ganQo_pct;
SENS_QINY_GL_AUDIT.ganancia_incremental_Qo_pct = ganQo_inc_pct;
SENS_QINY_GL_AUDIT.referencia_ganancia = refQl.tipo;
SENS_QINY_GL_AUDIT.referencia_Qiny_Sm3_d = refQl.x;
SENS_QINY_GL_AUDIT.P_s_bar = P_s_sol;
SENS_QINY_GL_AUDIT.P_req_bar = P_req_sol;
SENS_QINY_GL_AUDIT.clasificacion = clasif_optimo;
SENS_QINY_GL_AUDIT.clasificacion_curva = clasif_curva;
SENS_QINY_GL_AUDIT.Indice_energetico_bruto_GL_pct = IndiceBrutoGL;
SENS_QINY_GL_AUDIT.energia_por_punto = EnergiaGL;
SENS_QINY_GL_AUDIT.rendimiento_energetico_pct = IndiceBrutoGL;
SENS_QINY_GL_AUDIT.optimizacion_inyeccion = OPT_GL;
SENS_QINY_GL_AUDIT.tratamiento_curva = tratamiento_curva;
SENS_QINY_GL_AUDIT.verificacion_polinomica = VER_POLY_GL;
if isfield(OPT_GL,'ql_polinomio_en_puntos_m3d') && numel(OPT_GL.ql_polinomio_en_puntos_m3d)==npts
  SENS_QINY_GL_AUDIT.Ql_GL_polinomio_m3d = OPT_GL.ql_polinomio_en_puntos_m3d;
else
  SENS_QINY_GL_AUDIT.Ql_GL_polinomio_m3d = NaN(1,npts);
endif
if isfield(OPT_GL,'qo_polinomio_en_puntos_m3d') && numel(OPT_GL.qo_polinomio_en_puntos_m3d)==npts
  SENS_QINY_GL_AUDIT.Qo_GL_polinomio_m3d = OPT_GL.qo_polinomio_en_puntos_m3d;
else
  SENS_QINY_GL_AUDIT.Qo_GL_polinomio_m3d = NaN(1,npts);
endif
SENS_QINY_GL_AUDIT.economia = econ;
assignin('base', 'SENS_QINY_GL_AUDIT', SENS_QINY_GL_AUDIT);

% --- Graficos: puntos del solver siempre visibles; polinomio solo si fue elegido ---
clear Aql_plot;
figure;
plot(x_vals, Ql_GL, 'b-o', 'LineWidth', 2);
hold on;
leyendas = {'Puntos GL validados'};
if tratamiento_curva.habilitado && isfield(OPT_GL,'ajuste_polinomico') && ...
    isfield(OPT_GL.ajuste_polinomico,'ql') && OPT_GL.ajuste_polinomico.ql.apto_informativo
  Aql_plot = OPT_GL.ajuste_polinomico.ql;
  plot(Aql_plot.x_grid, Aql_plot.y_grid, '-', 'LineWidth', 2);
  leyendas{end+1} = sprintf('Polinomio GL grado %d',Aql_plot.grado_efectivo);
endif
if isfield(VER_POLY_GL,'verificado') && VER_POLY_GL.verificado
  plot(VER_POLY_GL.qiny_efectivo_sm3d, VER_POLY_GL.ql_solver_m3d, 'ks', 'MarkerSize', 10, 'LineWidth', 2);
  leyendas{end+1} = 'Optimo polinomico verificado';
endif
xlabel('Caudal de gas inyectado [Sm3/d]');
ylabel('Liquido (m3/d)');
title('Produccion GL vs Q_{iny}: solver y tratamiento seleccionado');
grid on;
legend(leyendas,'Location','northeast');
yf = Ql_GL(isfinite(Ql_GL));
if tratamiento_curva.habilitado && exist('Aql_plot','var'), yf=[yf Aql_plot.y_grid(isfinite(Aql_plot.y_grid))]; endif
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
title(sprintf('GL: ganancia respecto de Qiny %.0f Sm3/d', refQl.x));
exportar_grafico_modulo();

figure;
subplot(2,1,1);
plot(x_vals, IndiceBrutoGL, '-o', 'LineWidth', 2);
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('Indice energetico bruto de fondo (%)');
title('GL: indice energetico bruto de fondo');
subplot(2,1,2);
if isfield(OPT_GL, 'x_derivada_sm3d') && isfield(OPT_GL, 'derivada_rendimiento_pct_por_Sm3d') && ...
    ~isempty(OPT_GL.x_derivada_sm3d)
  plot(OPT_GL.x_derivada_sm3d, OPT_GL.derivada_rendimiento_pct_por_Sm3d, '-', 'LineWidth', 2);
else
  plot(NaN, NaN);
  text(0.1, 0.5, 'Derivada no disponible: puntos validos insuficientes.');
endif
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('dI bruto/dQiny');
title(sprintf('GL: derivada (%s)',tratamiento_curva.modo));
exportar_grafico_modulo();

if econ.habilitado && isfield(OPT_GL, 'economico') && isfield(OPT_GL.economico, 'qiny_sm3d')
  figure;
  plot(OPT_GL.economico.qiny_sm3d, OPT_GL.economico.resultado_neto_dia, '-o', 'LineWidth', 2);
  hold on;
  leg_e = {'Economia discreta'};
  if tratamiento_curva.habilitado && isfield(OPT_GL,'economico_polinomico') && ...
      isfield(OPT_GL.economico_polinomico,'habilitado') && OPT_GL.economico_polinomico.habilitado
    plot(OPT_GL.economico_polinomico.qiny_sm3d, OPT_GL.economico_polinomico.resultado_neto_dia, '-', 'LineWidth', 2);
    leg_e{end+1}='Economia polinomica derivada';
  endif
  grid on;
  xlabel('Qiny (Sm3/d)');
  ylabel(sprintf('Resultado neto (%s/d)', econ.moneda));
  title('GL: resultado economico de la inyeccion');
  legend(leg_e,'Location','northeast');
  exportar_grafico_modulo();
endif

sens_exportar_resultados('SENS_QINY_GL_AUDIT', 'Qiny GL', base_snapshot, 'GL');

