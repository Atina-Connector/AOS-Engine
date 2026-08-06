% sens_P_iny.m - Sensibilidad de presion de inyeccion JGL vs GL.
% Usa la misma politica de Qiny en ambos sistemas y un modo JGL realmente
% iterativo, directo o hibrido de malla. GNU Octave es el entorno objetivo.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
try
  aos_registro_graficos('reset',mfilename());
catch err_reg
  fprintf('Aviso registro graficos: %s\n',err_reg.message);
end_try_catch
cd(AOS_root);

[base, origen_base] = sens_cargar_base(); %#ok<NASGU>
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                    : %.3f m3/d/bar\n', base.IP * 86400 * 1e5);
fprintf('WC                    : %.3f\n', base.WC);
fprintf('P_wh                  : %.2f bar\n', base.P_wh / 1e5);
fprintf('Prof. iny/eductor     : %.1f m\n', base.D_iny);
fprintf('GLR                   : %.2f Sm3/m3\n', base.GLR);
fprintf('---------------------------------------\n');
if aos_preguntar_sn('Desea modificar parametros base? (s/n) [n]: ', false)
  v = input(sprintf('  IP (m3/d/bar) [%.3f]: ', base.IP * 86400 * 1e5));
  if ~isempty(v), base.IP = v / 86400 / 1e5; end
  v = input(sprintf('  WC [%.3f]: ', base.WC));
  if ~isempty(v), base.WC = v; end
  v = input(sprintf('  P_wh (bar) [%.2f]: ', base.P_wh / 1e5));
  if ~isempty(v), base.P_wh = v * 1e5; end
  v = input(sprintf('  Prof. iny/eductor (m) [%.1f]: ', base.D_iny));
  if ~isempty(v), base = aos_set_profundidad(base, 'JGL', v); end
  v = input(sprintf('  GLR (Sm3/m3) [%.2f]: ', base.GLR));
  if ~isempty(v), base.GLR = v; end
end
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- MODELO VLP ---\n');
fprintf('1 - Simplificado\n2 - Hagedorn-Brown\n3 - Duns & Ros\n');
opdef = aos_opcion_modelo_vlp(base.modelo_VLP);
op = input(sprintf('Seleccione VLP (1-3) [%d]: ', opdef));
if isempty(op), op = opdef; end
if op == 2
  base.modelo_VLP = 'HB';
elseif op == 3
  base.modelo_VLP = 'DR';
else
  base.modelo_VLP = 'simplified';
end
if isfield(base, 'survey') && ~isempty(base.survey)
  diagnostico_vlp(base.survey, base.modelo_VLP);
end

[modo_jgl, max_iter] = jgl_menu_aproximacion('automatico', 10);
base.jgl_max_iter = max_iter;

% En una sensibilidad de P_iny, Qiny no puede mantenerse fijo: debe
% recalcularse en cada punto con la presion superficial correspondiente.
% Esto evita comparar presiones distintas con el mismo caudal motriz.
politica_q = 'presion';
q_fijo = NaN;
fprintf('\n--- POLITICA DE GAS PARA ESTA SENSIBILIDAD ---\n');
fprintf('Qiny se calculara automaticamente en cada punto del barrido de P_iny.\n');
fprintf('No se solicita un Qiny fijo porque seria incoherente con la variable barrida.\n');

Pmin = max(0.5 * base.P_iny_sup, base.P_wh);
Pmax = max(2.0 * base.P_iny_sup, Pmin + 50e5);
N = 12;
fprintf('\n--- LIMITES DEL BARRIDO ---\n');
fprintf('P_iny min: %.1f bar\nP_iny max: %.1f bar\nN puntos : %d\n', Pmin / 1e5, Pmax / 1e5, N);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v = input(sprintf('  P_iny min (bar) [%.1f]: ', Pmin / 1e5));
  if ~isempty(v), Pmin = v * 1e5; end
  v = input(sprintf('  P_iny max (bar) [%.1f]: ', Pmax / 1e5));
  if ~isempty(v), Pmax = v * 1e5; end
  v = input(sprintf('  N puntos [%d]: ', N));
  if ~isempty(v), N = max(2, round(v)); end
end
if Pmax < Pmin, tmp = Pmin; Pmin = Pmax; Pmax = tmp; end

Pvals = linspace(Pmin, Pmax, N);
parametros = cell(1, N);
qvals = zeros(1, N);
qdetalle = cell(1, N);
for i = 1:N
  p = base;
  p.P_iny_sup = Pvals(i);
  p = aos_sincronizar_config(p, 'SENS_JGL');
  if strcmpi(politica_q, 'presion')
    [qvals(i), qdetalle{i}] = aos_calcular_qiny_auto_gl(p, p.D_iny);
  else
    qvals(i) = q_fijo;
    qdetalle{i} = struct('estado', 'FIJO', 'Qiny', q_fijo);
  end
  p = aos_set_qiny(p, qvals(i) * 86400, 'fijo');
  p.jgl_max_iter = max_iter;
  parametros{i} = p;
end

R = sens_jgl_gl_malla(parametros, qvals, modo_jgl);
QlJ = R.Ql_JGL * 86400;
QoJ = R.Qo_JGL * 86400;
QlG = R.Ql_GL * 86400;
QoG = R.Qo_GL * 86400;
dPJ = R.deltaP_JGL / 1e5;
errDI = 100 * R.error_directo_iterativo;

cj = sens_clasificar_curva(Pvals, QoJ);
cg = sens_clasificar_curva(Pvals, QoG);
fprintf('\nJGL: %s\n', cj.mensaje);
fprintf('GL : %s\n', cg.mensaje);

fprintf('\n=== SENSIBILIDAD P_INY: MISMO QINY PARA JGL Y GL ===\n');
fprintf('Piny | Qiny req. | Qiny JGL | Qiny GL | Ql JGL | Ql GL | dP | Iter | Modo JGL | Err D/I | Estado JGL\n');
fprintf('(bar)| (Sm3/d)   | (Sm3/d)  | (Sm3/d)| (m3/d) |(m3/d)|bar |      |          |   (%%)   |\n');
for i = 1:N
  fprintf('%5.1f | %9.0f | %8.0f | %7.0f | %6.1f | %5.1f | %4.2f | %4d | %-12s | %7.2f | %s\n', ...
    Pvals(i) / 1e5, qvals(i) * 86400, R.jgl.qiny_efectivo(i) * 86400, ...
    R.qiny_efectivo_GL(i) * 86400, QlJ(i), QlG(i), dPJ(i), ...
    R.iteraciones_JGL(i), R.modos_JGL{i}, errDI(i), R.estados_JGL{i});
end
fprintf('===========================================================\n');

SENS_P_INY_AUDIT = struct('Piny_Pa', Pvals, 'parametros', {parametros}, ...
  'qiny_solicitado', qvals, 'qiny_detalle', {qdetalle}, 'resultado', R, ...
  'clasificacion_JGL', cj, 'clasificacion_GL', cg);
assignin('base', 'SENS_P_INY_AUDIT', SENS_P_INY_AUDIT);

figure;
x = Pvals / 1e5;
plot(x, QlJ, '-o', 'LineWidth', 2);
hold on;
plot(x, QlG, '--o', 'LineWidth', 2);
grid on;
xlabel('Presion de inyeccion (bar)');
ylabel('Liquido (m3/d)');
title('JGL vs GL - sensibilidad a P_{iny}');
legend('JGL', 'GL', 'Location', 'best');
y = [QlJ(isfinite(QlJ)), QlG(isfinite(QlG))];
if ~isempty(y)
  r = max(y) - min(y);
  pad = max(0.5, 0.15 * max(r, 0.5));
  ylim([min(y) - pad, max(y) + pad]);
end
if strcmp(cj.tipo, 'OPTIMO_INTERIOR')
  yl = ylim; plot([cj.optimo_x cj.optimo_x] / 1e5, yl, 'k--');
end
if strcmp(cg.tipo, 'OPTIMO_INTERIOR')
  yl = ylim; plot([cg.optimo_x cg.optimo_x] / 1e5, yl, 'm--');
end
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_P_INY_AUDIT', 'Presion de inyeccion', base, 'JGL_GL');
