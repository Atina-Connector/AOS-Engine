% sens_P_wh.m - Sensibilidad de presion de cabeza JGL vs GL.
% Usa una politica de gas comun y el modo JGL seleccionado en toda la malla.

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
fprintf('IP %.3f m3/d/bar | WC %.3f | P_iny %.2f bar | D_iny %.1f m | GLR %.2f\n', ...
  base.IP * 86400 * 1e5, base.WC, base.P_iny_sup / 1e5, base.D_iny, base.GLR);
if aos_preguntar_sn('Desea modificar parametros base? (s/n) [n]: ', false)
  v = input(sprintf('  IP (m3/d/bar) [%.3f]: ', base.IP * 86400 * 1e5));
  if ~isempty(v), base.IP = v / 86400 / 1e5; end
  v = input(sprintf('  WC [%.3f]: ', base.WC));
  if ~isempty(v), base.WC = v; end
  v = input(sprintf('  P_iny_sup (bar) [%.2f]: ', base.P_iny_sup / 1e5));
  if ~isempty(v), base.P_iny_sup = v * 1e5; end
  v = input(sprintf('  D_iny (m) [%.1f]: ', base.D_iny));
  if ~isempty(v), base = aos_set_profundidad(base, 'JGL', v); end
  v = input(sprintf('  GLR (Sm3/m3) [%.2f]: ', base.GLR));
  if ~isempty(v), base.GLR = v; end
end
base = sens_preparar_base(base, 'SENS_JGL');

fprintf('\n--- MODELO VLP ---\n1 - Simplificado\n2 - Hagedorn-Brown\n3 - Duns & Ros\n');
opdef = aos_opcion_modelo_vlp(base.modelo_VLP);
op = input(sprintf('Seleccione VLP [%d]: ', opdef));
if isempty(op), op = opdef; end
if op == 2
  base.modelo_VLP = 'HB';
elseif op == 3
  base.modelo_VLP = 'DR';
else
  base.modelo_VLP = 'simplified';
end

[modo_jgl, max_iter] = jgl_menu_aproximacion('automatico', 10);
base.jgl_max_iter = max_iter;
[politica_q, q_fijo] = sens_menu_qiny_comun(base, 'fijo');

Pmin = 5e5;
Pmax = 50e5;
N = 12;
if aos_preguntar_sn('Desea modificar limites P_wh 5-50 bar? (s/n) [n]: ', false)
  v = input('  P_wh min (bar) [5]: '); if ~isempty(v), Pmin = v * 1e5; end
  v = input('  P_wh max (bar) [50]: '); if ~isempty(v), Pmax = v * 1e5; end
  v = input('  N puntos [12]: '); if ~isempty(v), N = max(2, round(v)); end
end
if Pmax < Pmin, tmp = Pmin; Pmin = Pmax; Pmax = tmp; end

Pvals = linspace(Pmin, Pmax, N);
parametros = cell(1, N);
qvals = zeros(1, N);
for i = 1:N
  p = base;
  p.P_wh = Pvals(i);
  p = aos_sincronizar_config(p, 'SENS_JGL');
  if strcmpi(politica_q, 'presion')
    qvals(i) = aos_calcular_qiny_auto_gl(p, p.D_iny);
  else
    qvals(i) = q_fijo;
  end
  p = aos_set_qiny(p, qvals(i) * 86400, 'fijo');
  p.jgl_max_iter = max_iter;
  parametros{i} = p;
end

R = sens_jgl_gl_malla(parametros, qvals, modo_jgl);
QlJ = R.Ql_JGL * 86400; QoJ = R.Qo_JGL * 86400;
QlG = R.Ql_GL * 86400; QoG = R.Qo_GL * 86400;
dPJ = R.deltaP_JGL / 1e5;
errDI = 100 * R.error_directo_iterativo;
cj = sens_clasificar_curva(Pvals, QoJ);
cg = sens_clasificar_curva(Pvals, QoG);
fprintf('\nJGL: %s\nGL : %s\n', cj.mensaje, cg.mensaje);

fprintf('\n=== SENSIBILIDAD P_WH ===\n');
fprintf('Pwh(bar) | Qiny req | Qiny JGL | Qiny GL | Ql JGL | Ql GL | dP | Iter | Modo JGL | Err D/I | Estado JGL\n');
for i = 1:N
  fprintf('%8.1f | %8.0f | %8.0f | %7.0f | %6.1f | %5.1f | %4.2f | %4d | %-12s | %7.2f | %s\n', ...
    Pvals(i) / 1e5, qvals(i) * 86400, R.jgl.qiny_efectivo(i) * 86400, ...
    R.qiny_efectivo_GL(i) * 86400, QlJ(i), QlG(i), dPJ(i), ...
    R.iteraciones_JGL(i), R.modos_JGL{i}, errDI(i), R.estados_JGL{i});
end

SENS_P_WH_AUDIT = struct('Pwh_Pa', Pvals, 'parametros', {parametros}, ...
  'qiny_solicitado', qvals, 'resultado', R, 'clasificacion_JGL', cj, ...
  'clasificacion_GL', cg);
assignin('base', 'SENS_P_WH_AUDIT', SENS_P_WH_AUDIT);

figure;
x = Pvals / 1e5;
plot(x, QlJ, '-o', 'LineWidth', 2);
hold on;
plot(x, QlG, '--o', 'LineWidth', 2);
grid on;
xlabel('P_{wh} (bar)');
ylabel('Liquido (m3/d)');
title('JGL vs GL - sensibilidad a P_{wh}');
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
sens_exportar_resultados('SENS_P_WH_AUDIT', 'Presion de cabeza', base, 'JGL_GL');
