% sens_D_bomba.m - Sensibilidad de profundidad de inyeccion/eductor.
% El nombre historico se conserva por compatibilidad. Solo modifica D_iny;
% nunca D_bomba de BES/BM. Usa el modo JGL seleccionado en toda la malla.

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
fprintf('IP %.3f m3/d/bar | WC %.3f | Pwh %.2f bar | Piny %.2f bar | D_iny %.1f m\n', ...
  base.IP * 86400 * 1e5, base.WC, base.P_wh / 1e5, base.P_iny_sup / 1e5, base.D_iny);
if aos_preguntar_sn('Desea modificar parametros base? (s/n) [n]: ', false)
  v = input(sprintf('  IP (m3/d/bar) [%.3f]: ', base.IP * 86400 * 1e5));
  if ~isempty(v), base.IP = v / 86400 / 1e5; end
  v = input(sprintf('  WC [%.3f]: ', base.WC)); if ~isempty(v), base.WC = v; end
  v = input(sprintf('  P_wh (bar) [%.2f]: ', base.P_wh / 1e5)); if ~isempty(v), base.P_wh = v * 1e5; end
  v = input(sprintf('  P_iny_sup (bar) [%.2f]: ', base.P_iny_sup / 1e5)); if ~isempty(v), base.P_iny_sup = v * 1e5; end
  v = input(sprintf('  GLR [%.2f]: ', base.GLR)); if ~isempty(v), base.GLR = v; end
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
[politica_q, q_fijo] = sens_menu_qiny_comun(base, 'presion');

Dmin = 500;
Dmax = base.D_res;
N = 12;
fprintf('\nBarrido D_iny: %.0f a %.0f m, %d puntos.\n', Dmin, Dmax, N);
if aos_preguntar_sn('Desea modificar limites? (s/n) [n]: ', false)
  v = input(sprintf('  D_iny min (m) [%.0f]: ', Dmin)); if ~isempty(v), Dmin = v; end
  v = input(sprintf('  D_iny max (m) [%.0f]: ', Dmax)); if ~isempty(v), Dmax = min(v, base.D_res); end
  v = input(sprintf('  N puntos [%d]: ', N)); if ~isempty(v), N = max(2, round(v)); end
end
Dmin = max(Dmin, 0);
Dmax = min(max(Dmax, Dmin), base.D_res);

Dvals = linspace(Dmin, Dmax, N);
parametros = cell(1, N);
qvals = zeros(1, N);
D_bomba_base = NaN;
if isfield(base, 'D_bomba'), D_bomba_base = base.D_bomba; end
for i = 1:N
  p = aos_set_profundidad(base, 'JGL', Dvals(i));
  p = aos_sincronizar_config(p, 'SENS_JGL');
  if isfield(p, 'survey') && ~isempty(p.survey)
    try, p.diam_tbg = p.survey.get_ID(Dvals(i)); catch, end
  end
  if strcmpi(politica_q, 'presion')
    qvals(i) = aos_calcular_qiny_auto_gl(p, Dvals(i));
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
cj = sens_clasificar_curva(Dvals, QoJ);
cg = sens_clasificar_curva(Dvals, QoG);
fprintf('\nJGL: %s\nGL : %s\n', cj.mensaje, cg.mensaje);

fprintf('\n=== SENSIBILIDAD PROFUNDIDAD DE INYECCION ===\n');
fprintf('Diny(m) | Qiny req | Qiny JGL | Qiny GL | Ql JGL | Ql GL | dP | Iter | Modo JGL | Err D/I | Estado JGL\n');
for i = 1:N
  fprintf('%7.0f | %8.0f | %8.0f | %7.0f | %6.1f | %5.1f | %4.2f | %4d | %-12s | %7.2f | %s\n', ...
    Dvals(i), qvals(i) * 86400, R.jgl.qiny_efectivo(i) * 86400, ...
    R.qiny_efectivo_GL(i) * 86400, QlJ(i), QlG(i), dPJ(i), ...
    R.iteraciones_JGL(i), R.modos_JGL{i}, errDI(i), R.estados_JGL{i});
end

% Guardia transversal: esta sensibilidad no debe modificar la profundidad de bomba.
if isfinite(D_bomba_base)
  for i = 1:N
    if isfield(parametros{i}, 'D_bomba') && abs(parametros{i}.D_bomba - D_bomba_base) > 1e-9
      error('sens_D_bomba altero D_bomba de BES/BM en el punto %d.', i);
    end
  end
end

SENS_D_INY_AUDIT = struct('Diny_m', Dvals, 'parametros', {parametros}, ...
  'qiny_solicitado', qvals, 'resultado', R, 'D_bomba_base', D_bomba_base, ...
  'clasificacion_JGL', cj, 'clasificacion_GL', cg);
assignin('base', 'SENS_D_INY_AUDIT', SENS_D_INY_AUDIT);

figure;
plot(Dvals, QlJ, '-o', 'LineWidth', 2);
hold on;
plot(Dvals, QlG, '--o', 'LineWidth', 2);
grid on;
xlabel('Profundidad de inyeccion/eductor (m)');
ylabel('Liquido (m3/d)');
title('JGL vs GL - sensibilidad a profundidad');
legend('JGL', 'GL', 'Location', 'best');
y = [QlJ(isfinite(QlJ)), QlG(isfinite(QlG))];
if ~isempty(y)
  r = max(y) - min(y);
  pad = max(0.5, 0.15 * max(r, 0.5));
  ylim([min(y) - pad, max(y) + pad]);
end
if strcmp(cj.tipo, 'OPTIMO_INTERIOR')
  yl = ylim; plot([cj.optimo_x cj.optimo_x], yl, 'k--');
end
if strcmp(cg.tipo, 'OPTIMO_INTERIOR')
  yl = ylim; plot([cg.optimo_x cg.optimo_x], yl, 'm--');
end
exportar_grafico_modulo();

% Exportacion transversal pre-AOS 0.1.0
sens_exportar_resultados('SENS_D_INY_AUDIT', 'Profundidad BES', base, 'BES');
