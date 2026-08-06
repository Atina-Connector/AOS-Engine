% sens_Qiny.m - Comparacion JGL vs GL para un barrido de Qiny.
% SENS-GLJGL-03:
%   - GL y JGL comparten una fotografia fisica inmutable del caso;
%   - JGL usa un metodo uniforme en toda la curva;
%   - cada sistema publica solo puntos aceptados y conserva el valor crudo;
%   - la armonizacion polinomica es opcional, visible y no reemplaza el solver;
%   - la condicion motriz JGL y las presiones requeridas son explicitas.

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

[base, origen_base] = sens_cargar_base('GL_JGL');
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.3f m3/d/bar\n', base.IP * 86400 * 1e5);
fprintf('WC                      : %.4f (fraccion)\n', base.WC);
fprintf('P_wh                    : %s\n', aos_formato_presion(base.P_wh, 1));
fprintf('P_iny_sup               : %s\n', aos_formato_presion(base.P_iny_sup, 1));
fprintf('Prof. inyeccion/lev.    : %s\n', aos_formato_longitud(base.D_iny, 0));
fprintf('GLR                     : %.2f Sm3/m3 liquido\n', base.GLR);
fprintf('IPR                     : %s\n', base.modelo_IPR);
fprintf('VLP                     : %s\n', base.modelo_VLP);
fprintf('a_eductor               : %.6g\n', base.a_eductor);
fprintf('b_eductor               : %.6g\n', base.b_eductor);
fprintf('---------------------------------------\n');

if aos_preguntar_sn('Desea modificar los parametros? (s/n) [n]: ', false)
  v = input(sprintf('  IP (m3/d/bar) [%.3f]: ', base.IP * 86400 * 1e5));
  if ~isempty(v), base.IP = v / 86400 / 1e5; endif
  v = input(sprintf('  WC (fraccion 0-1) [%.4f]: ', base.WC));
  if ~isempty(v), base.WC = v; endif
  v = input(sprintf('  P_wh (bar) [%.2f]: ', base.P_wh / 1e5));
  if ~isempty(v), base.P_wh = v * 1e5; endif
  v = input(sprintf('  P_iny_sup (bar) [%.2f]: ', base.P_iny_sup / 1e5));
  if ~isempty(v), base.P_iny_sup = v * 1e5; endif
  v = input(sprintf('  Prof. inyeccion/levantamiento (m) [%.1f]: ', base.D_iny));
  if ~isempty(v), base = aos_set_profundidad(base, 'JGL', v); endif
  v = input(sprintf('  GLR (Sm3/m3) [%.2f]: ', base.GLR));
  if ~isempty(v), base.GLR = v; endif
  v = input(sprintf('  a_eductor [%.6g]: ', base.a_eductor));
  if ~isempty(v), base.a_eductor = v; base.jgl_geometria_modo = 'calibrada'; endif
  v = input(sprintf('  b_eductor [%.6g]: ', base.b_eductor));
  if ~isempty(v), base.b_eductor = v; base.jgl_geometria_modo = 'calibrada'; endif
else
  fprintf('Se conservan los parametros de la fuente seleccionada.\n');
endif
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- MODELO VLP PARA LA COMPARACION ---\n');
fprintf('  1 - Simplificado\n');
fprintf('  2 - Hagedorn-Brown\n');
fprintf('  3 - Duns & Ros\n');
opdef = aos_opcion_modelo_vlp(base.modelo_VLP);
op = input(sprintf('Seleccione VLP (1-3) [%d]: ', opdef));
if isempty(op), op = opdef; endif
if op == 2
  base.modelo_VLP = 'HB';
elseif op == 3
  base.modelo_VLP = 'DR';
else
  base.modelo_VLP = 'simplified';
endif
fprintf('Usando IPR/VLP: %s / %s\n', base.modelo_IPR, base.modelo_VLP);
if isfield(base, 'survey') && ~isempty(base.survey)
  diagnostico_vlp(base.survey, base.modelo_VLP);
endif

[modo_jgl, max_iter] = jgl_menu_aproximacion('automatico', 10);
base.jgl_max_iter = max_iter;
base.jgl_modo = modo_jgl;
base = jgl_defaults(base);
try
  base = aos_sincronizar_config(base, 'SENS_JGL');
catch
end_try_catch

% --- Condicion motriz visible para la rama JGL de la comparacion ---
[base, condicion_motriz_menu] = sens_menu_condicion_motriz_jgl(base,'COMPARACION JGL/GL');
if condicion_motriz_menu.cancelado
  fprintf('Comparacion JGL/GL cancelada durante la seleccion de condicion motriz.\n');
  return;
endif
try
  base = aos_sincronizar_config(base, 'SENS_JGL');
catch
end_try_catch

% --- Validacion previa y congelamiento ---
val_base = sens_validar_base_gl_jgl(base, 'GL_JGL');
for i = 1:numel(val_base.advertencias)
  fprintf('[ADVERTENCIA BASE] %s\n', val_base.advertencias{i});
endfor
if ~val_base.ok
  fprintf(2, '\nLa comparacion GL/JGL fue bloqueada por datos invalidos:\n');
  for i = 1:numel(val_base.errores)
    fprintf(2, '  - %s\n', val_base.errores{i});
  endfor
  error('SENS-GLJGL-03: configuracion GL/JGL invalida. No se ejecuta el barrido.');
endif
base_snapshot = base;
config_firma = val_base.firma;
fprintf('\nSnapshot GL/JGL congelado: %s\n', config_firma);
fprintf('Origen de configuracion: %s\n', origen_base);
fprintf('Modo JGL solicitado: %s | max iter: %d\n', upper(modo_jgl), max_iter);

% --- Tratamiento posterior comun: seleccion visible, resultados separados ---
tratamiento_curva = sens_menu_tratamiento_curva('GL/JGL', 'DISCRETO');
if tratamiento_curva.cancelado
  fprintf('Comparacion GL/JGL cancelada antes del barrido.\n');
  return;
endif
try
  [qmax_ipr_poly, ~] = ipr(base_snapshot, base_snapshot.modelo_IPR);
  tratamiento_curva.limite_ql_m3d = qmax_ipr_poly * 86400;
catch
  tratamiento_curva.limite_ql_m3d = NaN;
end_try_catch
tratamiento_JGL = tratamiento_curva;
tratamiento_JGL.sistema = 'JGL';
tratamiento_GL = tratamiento_curva;
tratamiento_GL.sistema = 'GL';

Qmin = aos_qiny_limite_m3s(base_snapshot, 'min', 20000);
Qmax = aos_qiny_limite_m3s(base_snapshot, 'max', 140000);
N = aos_sensibilidad_n_puntos_default(15);
fprintf('\n--- LIMITES DEL BARRIDO ---\n');
fprintf('Qiny min : %.0f Sm3/d (%.4f MMscf/d)\n', Qmin * 86400, aos_m3s_a_mmscfd(Qmin));
fprintf('Qiny max : %.0f Sm3/d (%.4f MMscf/d)\n', Qmax * 86400, aos_m3s_a_mmscfd(Qmax));
fprintf('N puntos : %d\n', N);
if aos_preguntar_sn('Desea modificar los limites? (s/n) [n]: ', false)
  v = input(sprintf('  Qiny min (Sm3/d) [%.0f]: ', Qmin * 86400));
  if ~isempty(v), Qmin = aos_sm3d_a_m3s(v); endif
  v = input(sprintf('  Qiny max (Sm3/d) [%.0f]: ', Qmax * 86400));
  if ~isempty(v), Qmax = aos_sm3d_a_m3s(v); endif
  v = input(sprintf('  N puntos [%d]: ', N));
  if ~isempty(v), N = max(2, round(v)); endif
endif
Qmin = max(Qmin, 0);
Qmax = max(Qmax, 0);
if Qmax < Qmin
  tmp = Qmin; Qmin = Qmax; Qmax = tmp;
endif
Qvals = linspace(Qmin, Qmax, N);
Qvals = sens_agregar_qiny_referencia(Qvals, base_snapshot);
N = numel(Qvals);

% Parametros por punto solo para energia/auditoria. La fisica no cambia.
parametros = cell(1, N);
for i = 1:N
  p = aos_set_qiny(base_snapshot, Qvals(i) * 86400, 'fijo');
  p.jgl_max_iter = max_iter;
  parametros{i} = p;
endfor

fprintf('\n--- EJECUCION COMPARATIVA SENS-GLJGL-03 ---\n');
R = sens_jgl_gl_malla(base_snapshot, Qvals, modo_jgl);

% Verificar que la fotografia fisica no haya cambiado dentro del barrido.
for i = 1:N
  firma_j = R.jgl.config_firma{i};
  firma_g = R.config_firma_GL{i};
  if ~strcmp(firma_j, config_firma)
    R.jgl.aceptado(i) = false;
    R.jgl.valido_para_curva(i) = false;
    R.jgl.valido_para_optimo(i) = false;
    R.jgl.Ql(i) = NaN;
    R.jgl.Qo(i) = NaN;
    R.jgl.motivos_rechazo{i}{end+1} = 'La configuracion JGL cambio dentro del barrido.';
  endif
  if ~strcmp(firma_g, config_firma)
    R.aceptado_GL(i) = false;
    R.valido_para_curva_GL(i) = false;
    R.valido_para_optimo_GL(i) = false;
    R.Ql_GL(i) = NaN;
    R.Qo_GL(i) = NaN;
    R.motivos_rechazo_GL{i}{end+1} = 'La configuracion GL cambio dentro del barrido.';
  endif
endfor
R.Ql_JGL = R.jgl.Ql;
R.Qo_JGL = R.jgl.Qo;
R.aceptado_JGL = R.jgl.aceptado;
R.valido_para_curva_JGL = R.jgl.valido_para_curva;
R.valido_para_optimo_JGL = R.jgl.valido_para_optimo;
R.aceptado = R.aceptado_JGL & R.aceptado_GL;
R.valido_para_curva = R.valido_para_curva_JGL & R.valido_para_curva_GL;
R.valido_para_optimo = R.valido_para_optimo_JGL & R.valido_para_optimo_GL;

QlJ = R.Ql_JGL * 86400;
QoJ = R.Qo_JGL * 86400;
QlG = R.Ql_GL * 86400;
QoG = R.Qo_GL * 86400;
QlJ_raw = R.Ql_JGL_raw * 86400;
QoJ_raw = R.Qo_JGL_raw * 86400;
QlG_raw = R.Ql_GL_raw * 86400;
QoG_raw = R.Qo_GL_raw * 86400;
dPJ = R.deltaP_JGL / 1e5;
errDI = 100 * R.error_directo_iterativo;
ValidoCurvaJ = logical(R.valido_para_curva_JGL);
ValidoCurvaG = logical(R.valido_para_curva_GL);
ValidoOptimoJ = logical(R.valido_para_optimo_JGL);
ValidoOptimoG = logical(R.valido_para_optimo_GL);
AceptadoJ = logical(R.aceptado_JGL);
AceptadoG = logical(R.aceptado_GL);

try
  [QlJ, QoJ, QlG, QoG, avisos] = sens_aplicar_consistencia_jgl_gl(base_snapshot, Qvals, QlJ, QoJ, QlG, QoG);
  for i = 1:numel(avisos), fprintf('%s\n', avisos{i}); endfor
catch err
  fprintf('No se pudo evaluar la invariante JGL/GL: %s\n', err.message);
end_try_catch

for i = 1:N
  fprintf('[%02d/%02d] Qiny=%9.0f Sm3/d | JGL %s (%s) | GL %s (%s)\n', ...
    i, N, Qvals(i)*86400, cond_val_local(ValidoCurvaJ(i), QlJ(i)), R.estados_JGL{i}, ...
    cond_val_local(ValidoCurvaG(i), QlG(i)), R.estados_GL{i});
endfor
fprintf('Metodo JGL final uniforme: %s\n', R.jgl.modo_final_uniforme);
if R.jgl.preliminar
  fprintf('[PRELIMINAR] JGL no habilita optimo; GL conserva su validacion independiente.\n');
endif

% --- Clasificacion por sistema ---
cj_curva = sens_clasificar_curva(Qvals, QoJ);
cg_curva = sens_clasificar_curva(Qvals, QoG);
QoJ_opt = QoJ; QoJ_opt(~ValidoOptimoJ) = NaN;
QoG_opt = QoG; QoG_opt(~ValidoOptimoG) = NaN;
cj = sens_clasificar_curva(Qvals, QoJ_opt);
cg = sens_clasificar_curva(Qvals, QoG_opt);
if R.jgl.preliminar
  cj.tipo = 'PRELIMINAR_SIN_OPTIMO';
  cj.optimo_x = NaN;
  cj.optimo_y = NaN;
  cj.mensaje = 'Modo JGL preliminar: no se declara optimo.';
endif
fprintf('\nJGL curva publicada: %s\n', cj_curva.mensaje);
fprintf('JGL optimo: %s\n', cj.mensaje);
fprintf('GL curva publicada : %s\n', cg_curva.mensaje);
fprintf('GL optimo : %s\n', cg.mensaje);
if strcmp(cj.tipo, 'OPTIMO_INTERIOR')
  fprintf('Optimo interior JGL: Qiny %.0f Sm3/d, Qo %.2f m3/d\n', cj.optimo_x*86400, cj.optimo_y);
endif
if strcmp(cg.tipo, 'OPTIMO_INTERIOR')
  fprintf('Optimo interior GL : Qiny %.0f Sm3/d, Qo %.2f m3/d\n', cg.optimo_x*86400, cg.optimo_y);
endif

x = Qvals * 86400;
[ganJ, ganJ_pct, ganJ_inc_pct, refJ] = sens_calcular_ganancias(QlJ, x, true);
[ganG, ganG_pct, ganG_inc_pct, refG] = sens_calcular_ganancias(QlG, x, true);
fprintf('Referencia ganancia JGL: %s\n', refJ.mensaje);
fprintf('Referencia ganancia GL : %s\n', refG.mensaje);

% --- Presiones motrices requeridas y factibilidad de la rama JGL ---
PRESIONES_JGL = sens_jgl_construir_presiones(R.jgl,x);
sens_jgl_imprimir_presiones(PRESIONES_JGL,'COMPARACION JGL/GL');

% --- Energia y optimizacion solo con puntos aceptados ---
IndiceBrutoJ = NaN(1, N);
IndiceBrutoG = NaN(1, N);
EficienciaJetJ = NaN(1, N);
EnergiaJ = cell(1, N);
EnergiaG = cell(1, N);
for i = 1:N
  if ValidoCurvaJ(i)
    try
      ej = aos_balance_energia_sla('JGL', parametros{i}, QlJ(i)/86400, QoJ(i)/86400, ...
        Qvals(i), R.jgl.soluciones{i});
      EnergiaJ{i} = ej;
      metj = aos_metricas_energia_sla(ej, 'JGL');
      IndiceBrutoJ(i) = metj.indice_energetico_bruto_fondo_pct;
      EficienciaJetJ(i) = metj.eficiencia_interna_jet_pct;
    catch err
      fprintf('Aviso energia JGL punto %d: %s\n', i, err.message);
    end_try_catch
  endif
  if ValidoCurvaG(i)
    try
      sg = struct();
      if isfield(R, 'detalle_GL') && numel(R.detalle_GL) >= i && isstruct(R.detalle_GL{i})
        sg = R.detalle_GL{i};
      endif
      eg = aos_balance_energia_sla('GL', parametros{i}, QlG(i)/86400, QoG(i)/86400, Qvals(i), sg);
      EnergiaG{i} = eg;
      metg = aos_metricas_energia_sla(eg, 'GL');
      IndiceBrutoG(i) = metg.indice_energetico_bruto_fondo_pct;
    catch err
      fprintf('Aviso energia GL punto %d: %s\n', i, err.message);
    end_try_catch
  endif
endfor
econ = sens_configurar_economia_inyeccion();
OPT_JGL = sens_optimo_inyeccion(x, IndiceBrutoJ, QlJ, QoJ, ValidoOptimoJ, econ, tratamiento_JGL, ValidoCurvaJ);
OPT_GL = sens_optimo_inyeccion(x, IndiceBrutoG, QlG, QoG, ValidoOptimoG, econ, tratamiento_GL, ValidoCurvaG);
if tratamiento_curva.verificar_optimo
  opts_ver_jgl = struct('modo',lower(R.jgl.modo_final_uniforme), ...
    'nodal_n_puntos',1201,'jgl_n_puntos',120,'preliminar',R.jgl.preliminar, ...
    'tolerancia_verificacion_rel',0.05,'tolerancia_verificacion_abs_m3d',0.5);
  if R.jgl.preliminar && any(strcmp(lower(modo_jgl), {'abreviado','movil'}))
    opts_ver_jgl.nodal_n_puntos = 121;
    opts_ver_jgl.jgl_n_puntos = 81;
  endif
  [OPT_JGL, VER_POLY_JGL] = sens_verificar_optimo_polinomico(OPT_JGL,'JGL',base_snapshot,opts_ver_jgl);
  opts_ver_gl = struct('n_puntos',1201,'preliminar',false, ...
    'tolerancia_verificacion_rel',0.05,'tolerancia_verificacion_abs_m3d',0.5);
  [OPT_GL, VER_POLY_GL] = sens_verificar_optimo_polinomico(OPT_GL,'GL',base_snapshot,opts_ver_gl);
else
  VER_POLY_JGL = struct('estado','NO_SOLICITADA','verificado',false);
  VER_POLY_GL = struct('estado','NO_SOLICITADA','verificado',false);
  OPT_JGL.verificacion_polinomica = VER_POLY_JGL;
  OPT_GL.verificacion_polinomica = VER_POLY_GL;
endif
sens_imprimir_optimo_inyeccion('JGL', OPT_JGL);
sens_imprimir_optimo_inyeccion('GL', OPT_GL);
AUD_ENERGIA = sens_auditar_indice_jgl_gl(x, IndiceBrutoJ, IndiceBrutoG, 1e-6);
for ia = 1:numel(AUD_ENERGIA.mensajes)
  fprintf('%s\n', AUD_ENERGIA.mensajes{ia});
endfor

% --- Tabla auditable ---
fprintf('\n=== RESULTADOS COMPARATIVOS SENS-GLJGL-03 ===\n');
fprintf('Qiny | JGL raw | JGL pub | A/C/O | Estado JGL | GL raw | GL pub | A/C/O | Estado GL\n');
fprintf('(Sm3/d)|(m3/d) | (m3/d) |       |            |(m3/d) |(m3/d) |       |\n');
for i = 1:N
  fprintf('%8.0f | %7.2f | %7.2f | %s/%s/%s | %-18s | %7.2f | %7.2f | %s/%s/%s | %s\n', ...
    x(i), QlJ_raw(i), QlJ(i), sens_si_no(AceptadoJ(i)), sens_si_no(ValidoCurvaJ(i)), ...
    sens_si_no(ValidoOptimoJ(i)), R.estados_JGL{i}, QlG_raw(i), QlG(i), ...
    sens_si_no(AceptadoG(i)), sens_si_no(ValidoCurvaG(i)), sens_si_no(ValidoOptimoG(i)), R.estados_GL{i});
endfor
fprintf('JGL publicados: %d/%d | GL publicados: %d/%d | pares comparables: %d/%d\n', ...
  sum(ValidoCurvaJ), N, sum(ValidoCurvaG), N, sum(R.valido_para_curva), N);
fprintf('=================================================\n');

SENS_QINY_AUDIT = struct();
SENS_QINY_AUDIT.hotfix = 'SENS-GLJGL-03';
SENS_QINY_AUDIT.politica = 'CONFIG_CONGELADA_PARIDAD_PUNTO_METODO_UNIFORME_PUBLICACION_ESTRICTA_TRATAMIENTO_CURVA_Y_CONDICION_MOTRIZ_EXPLICITAS';
SENS_QINY_AUDIT.origen_base = origen_base;
SENS_QINY_AUDIT.config_firma = config_firma;
SENS_QINY_AUDIT.Qiny = Qvals;
SENS_QINY_AUDIT.parametros = parametros;
SENS_QINY_AUDIT.resultado = R;
SENS_QINY_AUDIT.Ql_JGL_raw_m3d = QlJ_raw;
SENS_QINY_AUDIT.Qo_JGL_raw_m3d = QoJ_raw;
SENS_QINY_AUDIT.Ql_GL_raw_m3d = QlG_raw;
SENS_QINY_AUDIT.Qo_GL_raw_m3d = QoG_raw;
SENS_QINY_AUDIT.Ql_JGL_m3d = QlJ;
SENS_QINY_AUDIT.Qo_JGL_m3d = QoJ;
SENS_QINY_AUDIT.Ql_GL_m3d = QlG;
SENS_QINY_AUDIT.Qo_GL_m3d = QoG;
SENS_QINY_AUDIT.aceptado_JGL = AceptadoJ;
SENS_QINY_AUDIT.aceptado_GL = AceptadoG;
SENS_QINY_AUDIT.valido_para_curva_JGL = ValidoCurvaJ;
SENS_QINY_AUDIT.valido_para_curva_GL = ValidoCurvaG;
SENS_QINY_AUDIT.valido_para_optimo_JGL = ValidoOptimoJ;
SENS_QINY_AUDIT.valido_para_optimo_GL = ValidoOptimoG;
SENS_QINY_AUDIT.aceptado = R.aceptado;
SENS_QINY_AUDIT.valido_para_curva = R.valido_para_curva;
SENS_QINY_AUDIT.valido_para_optimo = R.valido_para_optimo;
SENS_QINY_AUDIT.residuo_JGL_Pa = R.residuo_JGL_Pa;
SENS_QINY_AUDIT.residuo_GL_Pa = R.residuo_GL_Pa;
SENS_QINY_AUDIT.estados_JGL = R.estados_JGL;
SENS_QINY_AUDIT.estados_GL = R.estados_GL;
SENS_QINY_AUDIT.motivos_rechazo_JGL = R.motivos_rechazo_JGL;
SENS_QINY_AUDIT.motivos_rechazo_GL = R.motivos_rechazo_GL;
SENS_QINY_AUDIT.ganancia_JGL_m3d = ganJ;
SENS_QINY_AUDIT.ganancia_GL_m3d = ganG;
SENS_QINY_AUDIT.ganancia_JGL_pct = ganJ_pct;
SENS_QINY_AUDIT.ganancia_GL_pct = ganG_pct;
SENS_QINY_AUDIT.ganancia_incremental_JGL_pct = ganJ_inc_pct;
SENS_QINY_AUDIT.ganancia_incremental_GL_pct = ganG_inc_pct;
SENS_QINY_AUDIT.referencia_ganancia = refJ.tipo;
SENS_QINY_AUDIT.referencia_Qiny_Sm3_d = refJ.x;
SENS_QINY_AUDIT.clasificacion_JGL = cj;
SENS_QINY_AUDIT.clasificacion_GL = cg;
SENS_QINY_AUDIT.clasificacion_curva_JGL = cj_curva;
SENS_QINY_AUDIT.clasificacion_curva_GL = cg_curva;
SENS_QINY_AUDIT.Indice_energetico_bruto_JGL_pct = IndiceBrutoJ;
SENS_QINY_AUDIT.Indice_energetico_bruto_GL_pct = IndiceBrutoG;
SENS_QINY_AUDIT.Eficiencia_interna_jet_JGL_pct = EficienciaJetJ;
SENS_QINY_AUDIT.energia_JGL_por_punto = EnergiaJ;
SENS_QINY_AUDIT.energia_GL_por_punto = EnergiaG;
SENS_QINY_AUDIT.auditoria_comparacion_energia = AUD_ENERGIA;
SENS_QINY_AUDIT.rendimiento_energetico_JGL_pct = IndiceBrutoJ;
SENS_QINY_AUDIT.rendimiento_energetico_GL_pct = IndiceBrutoG;
SENS_QINY_AUDIT.optimizacion_JGL = OPT_JGL;
SENS_QINY_AUDIT.optimizacion_GL = OPT_GL;
SENS_QINY_AUDIT.tratamiento_curva = tratamiento_curva;
SENS_QINY_AUDIT.tratamiento_curva_JGL = tratamiento_JGL;
SENS_QINY_AUDIT.tratamiento_curva_GL = tratamiento_GL;
SENS_QINY_AUDIT.verificacion_polinomica_JGL = VER_POLY_JGL;
SENS_QINY_AUDIT.verificacion_polinomica_GL = VER_POLY_GL;
SENS_QINY_AUDIT.condicion_motriz_menu = condicion_motriz_menu;
SENS_QINY_AUDIT.presiones_motrices_JGL = PRESIONES_JGL;
SENS_QINY_AUDIT.P_succion_eductor_JGL_bar = PRESIONES_JGL.P_succion_eductor_bar;
SENS_QINY_AUDIT.DeltaP_motriz_requerida_JGL_bar = PRESIONES_JGL.DeltaP_motriz_requerida_bar;
SENS_QINY_AUDIT.P_motriz_fondo_requerida_JGL_bar = PRESIONES_JGL.P_motriz_fondo_requerida_bar;
SENS_QINY_AUDIT.P_motriz_fondo_disponible_JGL_bar = PRESIONES_JGL.P_motriz_fondo_disponible_bar;
SENS_QINY_AUDIT.P_iny_sup_requerida_JGL_bar = PRESIONES_JGL.P_iny_sup_requerida_bar;
SENS_QINY_AUDIT.P_iny_sup_disponible_JGL_bar = PRESIONES_JGL.P_iny_sup_disponible_bar;
SENS_QINY_AUDIT.DeltaP_columna_gas_JGL_bar = PRESIONES_JGL.DeltaP_columna_gas_bar;
SENS_QINY_AUDIT.DeltaP_friccion_inyeccion_JGL_bar = PRESIONES_JGL.DeltaP_friccion_inyeccion_bar;
SENS_QINY_AUDIT.Margen_presion_JGL_bar = PRESIONES_JGL.Margen_presion_superficie_bar;
SENS_QINY_AUDIT.Factible_presion_JGL = PRESIONES_JGL.factible_por_presion;
SENS_QINY_AUDIT.estado_presion_JGL = PRESIONES_JGL.estado_presion_motriz;
SENS_QINY_AUDIT.modo_condicion_motriz_JGL = PRESIONES_JGL.modo_condicion_motriz;
SENS_QINY_AUDIT.limite_presion_JGL = PRESIONES_JGL.limite_presion;
if isfield(OPT_JGL,'ql_polinomio_en_puntos_m3d') && numel(OPT_JGL.ql_polinomio_en_puntos_m3d)==N
  SENS_QINY_AUDIT.Ql_JGL_polinomio_m3d = OPT_JGL.ql_polinomio_en_puntos_m3d;
  SENS_QINY_AUDIT.Qo_JGL_polinomio_m3d = OPT_JGL.qo_polinomio_en_puntos_m3d;
else
  SENS_QINY_AUDIT.Ql_JGL_polinomio_m3d = NaN(1,N);
  SENS_QINY_AUDIT.Qo_JGL_polinomio_m3d = NaN(1,N);
endif
if isfield(OPT_GL,'ql_polinomio_en_puntos_m3d') && numel(OPT_GL.ql_polinomio_en_puntos_m3d)==N
  SENS_QINY_AUDIT.Ql_GL_polinomio_m3d = OPT_GL.ql_polinomio_en_puntos_m3d;
  SENS_QINY_AUDIT.Qo_GL_polinomio_m3d = OPT_GL.qo_polinomio_en_puntos_m3d;
else
  SENS_QINY_AUDIT.Ql_GL_polinomio_m3d = NaN(1,N);
  SENS_QINY_AUDIT.Qo_GL_polinomio_m3d = NaN(1,N);
endif
SENS_QINY_AUDIT.economia = econ;
assignin('base', 'SENS_QINY_AUDIT', SENS_QINY_AUDIT);

% --- Graficos: puntos fisicos siempre visibles; armonizacion superpuesta ---
figure;
plot(x, QlJ, '-o', 'LineWidth', 2);
hold on;
plot(x, QlG, '--s', 'LineWidth', 2);
leg = {'Puntos JGL validados','Puntos GL validados'};
y = [QlJ(isfinite(QlJ)), QlG(isfinite(QlG))];
if tratamiento_curva.habilitado && isfield(OPT_JGL,'ajuste_polinomico') && ...
    isfield(OPT_JGL.ajuste_polinomico,'ql') && OPT_JGL.ajuste_polinomico.ql.apto_informativo
  AJ = OPT_JGL.ajuste_polinomico.ql;
  plot(AJ.x_grid,AJ.y_grid,'-','LineWidth',2);
  leg{end+1}=sprintf('Polinomio JGL grado %d',AJ.grado_efectivo);
  y=[y AJ.y_grid(isfinite(AJ.y_grid))];
endif
if tratamiento_curva.habilitado && isfield(OPT_GL,'ajuste_polinomico') && ...
    isfield(OPT_GL.ajuste_polinomico,'ql') && OPT_GL.ajuste_polinomico.ql.apto_informativo
  AG = OPT_GL.ajuste_polinomico.ql;
  plot(AG.x_grid,AG.y_grid,'--','LineWidth',2);
  leg{end+1}=sprintf('Polinomio GL grado %d',AG.grado_efectivo);
  y=[y AG.y_grid(isfinite(AG.y_grid))];
endif
if isfield(VER_POLY_JGL,'verificado') && VER_POLY_JGL.verificado
  plot(VER_POLY_JGL.qiny_efectivo_sm3d,VER_POLY_JGL.ql_solver_m3d,'ko','MarkerSize',10,'LineWidth',2);
  leg{end+1}='Optimo JGL verificado';
endif
if isfield(VER_POLY_GL,'verificado') && VER_POLY_GL.verificado
  plot(VER_POLY_GL.qiny_efectivo_sm3d,VER_POLY_GL.ql_solver_m3d,'ks','MarkerSize',10,'LineWidth',2);
  leg{end+1}='Optimo GL verificado';
endif
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('Liquido (m3/d)');
title('Produccion GL/JGL: solver y tratamiento seleccionado');
legend(leg,'Location','best');
if ~isempty(y)
  rr = max(y) - min(y);
  pad = max(0.5, 0.15 * max(rr, 0.5));
  ylim([min(y)-pad, max(y)+pad]);
endif
exportar_grafico_modulo();

figure;
plot(x, ganJ_pct, '-o', 'LineWidth', 2);
hold on;
plot(x, ganG_pct, '--s', 'LineWidth', 2);
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('Ganancia de liquido (%)');
title(sprintf('Ganancia respecto de Qiny %.0f Sm3/d', refJ.x));
legend('JGL', 'GL', 'Location', 'best');
exportar_grafico_modulo();

sens_jgl_graficar_presiones(PRESIONES_JGL,'JGL vs GL');
exportar_grafico_modulo();

figure;
subplot(2,1,1);
plot(x, IndiceBrutoJ, '-o', 'LineWidth', 2);
hold on;
plot(x, IndiceBrutoG, '--s', 'LineWidth', 2);
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('Indice energetico bruto de fondo (%)');
legend('JGL', 'GL', 'Location', 'best');
title('Indice energetico bruto');
subplot(2,1,2);
hay_der_j = isfield(OPT_JGL,'x_derivada_sm3d') && ~isempty(OPT_JGL.x_derivada_sm3d) && ...
  isfield(OPT_JGL,'derivada_rendimiento_pct_por_Sm3d');
hay_der_g = isfield(OPT_GL,'x_derivada_sm3d') && ~isempty(OPT_GL.x_derivada_sm3d) && ...
  isfield(OPT_GL,'derivada_rendimiento_pct_por_Sm3d');
legd = {};
if hay_der_j
  plot(OPT_JGL.x_derivada_sm3d,OPT_JGL.derivada_rendimiento_pct_por_Sm3d,'-','LineWidth',2);
  hold on; legd{end+1}='JGL';
endif
if hay_der_g
  plot(OPT_GL.x_derivada_sm3d,OPT_GL.derivada_rendimiento_pct_por_Sm3d,'--','LineWidth',2);
  legd{end+1}='GL';
endif
if ~hay_der_j && ~hay_der_g
  plot(NaN,NaN); text(0.1,0.5,'Derivadas no disponibles: puntos validos insuficientes.');
else
  legend(legd,'Location','best');
endif
grid on;
xlabel('Qiny (Sm3/d)');
ylabel('dI bruto/dQiny');
title(sprintf('Derivada - tratamiento %s',tratamiento_curva.modo));
exportar_grafico_modulo();

if econ.habilitado && isfield(OPT_JGL,'economico') && isfield(OPT_GL,'economico') && ...
   isfield(OPT_JGL.economico,'qiny_sm3d') && isfield(OPT_GL.economico,'qiny_sm3d')
  figure;
  plot(OPT_JGL.economico.qiny_sm3d,OPT_JGL.economico.resultado_neto_dia,'-o','LineWidth',2);
  hold on;
  plot(OPT_GL.economico.qiny_sm3d,OPT_GL.economico.resultado_neto_dia,'--s','LineWidth',2);
  lege={'JGL discreto','GL discreto'};
  if tratamiento_curva.habilitado && isfield(OPT_JGL,'economico_polinomico') && ...
      isfield(OPT_JGL.economico_polinomico,'habilitado') && OPT_JGL.economico_polinomico.habilitado
    plot(OPT_JGL.economico_polinomico.qiny_sm3d,OPT_JGL.economico_polinomico.resultado_neto_dia,'-','LineWidth',2);
    lege{end+1}='JGL polinomico derivado';
  endif
  if tratamiento_curva.habilitado && isfield(OPT_GL,'economico_polinomico') && ...
      isfield(OPT_GL.economico_polinomico,'habilitado') && OPT_GL.economico_polinomico.habilitado
    plot(OPT_GL.economico_polinomico.qiny_sm3d,OPT_GL.economico_polinomico.resultado_neto_dia,'--','LineWidth',2);
    lege{end+1}='GL polinomico derivado';
  endif
  grid on;
  xlabel('Qiny (Sm3/d)');
  ylabel(sprintf('Resultado neto (%s/d)', econ.moneda));
  legend(lege,'Location','best');
  title('Resultado economico de la inyeccion');
  exportar_grafico_modulo();
endif

sens_exportar_resultados('SENS_QINY_AUDIT', 'Qiny JGL vs GL', base_snapshot, 'JGL_GL');
