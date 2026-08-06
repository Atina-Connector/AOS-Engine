% JGL_menu.m - Jet Gas Lift, interfaz metrica AOS 0.0.11.
% La fisica del eductor permanece en 0.0.11; el acople iterativo sera 0.0.12.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

[param, origen_config] = aos_config_base('JGL');
param = aos_normalizar_config(param, 'JGL');
param = jgl_defaults(param);
fprintf('Usando %s.\n', origen_config);

if ~isfield(param, 'A_n') || isempty(param.A_n), param.A_n = 12e-6; end
if ~isfield(param, 'd_t') || isempty(param.d_t), param.d_t = 0.038; end
if ~isfield(param, 'a_eductor') || isempty(param.a_eductor)
    R_area = pi * (param.d_t/2)^2 / max(param.A_n, 1e-12);
    param.a_eductor = 0.0020 * R_area;
end
if ~isfield(param, 'b_eductor') || isempty(param.b_eductor)
    R_area = pi * (param.d_t/2)^2 / max(param.A_n, 1e-12);
    param.b_eductor = 0.00010 * R_area;
end
if ~isfield(param, 'eta_n'), param.eta_n = 0.98; end
if ~isfield(param, 'eta_t'), param.eta_t = 0.85; end
if ~isfield(param, 'eta_d'), param.eta_d = 0.80; end
param.survey = obtener_survey(param);

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.3f m3/d/bar\n', param.IP * 86400 * 1e5);
fprintf('WC                      : %.3f\n', param.WC);
fprintf('P_res                   : %s\n', aos_formato_presion(param.P_res, 1));
fprintf('P_wh                    : %s\n', aos_formato_presion(param.P_wh, 1));
fprintf('P_iny_sup               : %s\n', aos_formato_presion(param.P_iny_sup, 1));
fprintf('Prof. eductor/iny.      : %s\n', aos_formato_longitud(param.D_iny, 1));
fprintf('Prof. reservorio        : %s\n', aos_formato_longitud(param.D_res, 1));
fprintf('GLR                     : %.2f Sm3/m3 liquido\n', param.GLR);
fprintf('A_n                     : %.1f mm2\n', param.A_n * 1e6);
fprintf('d_t                     : %.1f mm\n', param.d_t * 1000);
fprintf('Modelo IPR              : %s\n', param.modelo_IPR);
fprintf('Modelo VLP              : %s\n', param.modelo_VLP);
[Qcfg, fuente_q] = aos_qiny_configurada(param);
if ~isempty(Qcfg), fprintf('Qiny configurado        : %s [%s]\n', aos_formato_caudal_gas(Qcfg), fuente_q); end
fprintf('---------------------------------------\n');

cambiar = aos_preguntar_sn('Desea modificar los parametros principales? (s/n) [n]: ', false);
if cambiar
    val = input(sprintf('  IP (m3/d/bar) [%.3f]: ', param.IP * 86400 * 1e5));
    if ~isempty(val), param.IP = val / 86400 / 1e5; end
    val = input(sprintf('  WC (fraccion) [%.3f]: ', param.WC));
    if ~isempty(val), param.WC = val; end
    val = input(sprintf('  P_wh (bar) [%.2f]: ', param.P_wh / 1e5));
    if ~isempty(val), param.P_wh = val * 1e5; end
    val = input(sprintf('  P_iny_sup (bar) [%.2f]: ', param.P_iny_sup / 1e5));
    if ~isempty(val), param.P_iny_sup = val * 1e5; end
    val = input(sprintf('  Prof. eductor/inyeccion (m) [%.1f]: ', param.D_iny));
    if ~isempty(val), param = aos_set_profundidad(param, 'JGL', val); end
    val = input(sprintf('  GLR (Sm3/m3 de liquido) [%.2f]: ', param.GLR));
    if ~isempty(val), param.GLR = val; end
    val = input(sprintf('  Area tobera A_n (mm2) [%.1f]: ', param.A_n*1e6));
    if ~isempty(val), param.A_n = val * 1e-6; end
    val = input(sprintf('  Diametro garganta d_t (mm) [%.1f]: ', param.d_t*1000));
    if ~isempty(val), param.d_t = val / 1000; end
    fprintf('Parametros actualizados.\n');
else
    fprintf('Se conservan los parametros del .aosdat/configuracion.\n');
end
param = aos_sincronizar_config(param, 'JGL');
param = jgl_defaults(param);
param.survey = obtener_survey(param);
fprintf('Profundidad solicitada   : %.1f m\n', param.D_iny);
fprintf('Profundidad solver JGL   : %.1f m\n', param.D_iny);

fprintf('\n--- CONFIGURACION DE SIMULACION JGL ---\n');
fprintf('Modelos IPR: 1-Linear | 2-Vogel | 3-Fetkovich\n');
op_def = aos_opcion_modelo_ipr(param.modelo_IPR);
opcion = input(sprintf('Seleccione IPR (1-3) [%d]: ', op_def));
if isempty(opcion), opcion = op_def; end
if opcion == 2
    param.modelo_IPR = 'Vogel';
    P_b_def = param.P_b / 1e5;
    val = input(sprintf('Presion de burbuja (bar) [%.2f]: ', P_b_def));
    if ~isempty(val), param.P_b = val * 1e5; end
elseif opcion == 3
    param.modelo_IPR = 'Fetkovich';
else
    param.modelo_IPR = 'linear';
end
fprintf('Modelo IPR usado: %s\n', param.modelo_IPR);

fprintf('\nModelos VLP: 1-Simplificado | 2-Hagedorn-Brown | 3-Duns & Ros\n');
op_vlp_def = aos_opcion_modelo_vlp(param.modelo_VLP);
opcion_vlp = input(sprintf('Seleccione VLP (1-3) [%d]: ', op_vlp_def));
if isempty(opcion_vlp), opcion_vlp = op_vlp_def; end
if opcion_vlp == 2
    param.modelo_VLP = 'HB';
elseif opcion_vlp == 3
    param.modelo_VLP = 'DR';
else
    param.modelo_VLP = 'simplified';
end
fprintf('Modelo VLP usado: %s\n', param.modelo_VLP);
if isfield(param, 'survey') && ~isempty(param.survey), diagnostico_vlp(param.survey, param.modelo_VLP); end

if isfield(param, 'factor_IP_residual')
    fprintf('Factor de declinacion activo: %.3f\n', param.factor_IP_residual);
    nuevo_factor = input('Nuevo factor (Enter para mantener): ');
    if ~isempty(nuevo_factor), param.factor_IP_residual = nuevo_factor; end
    param.IP = param.IP * param.factor_IP_residual;
    param = aos_sincronizar_config(param, 'JGL');
end

[param, info_qiny] = aos_menu_qiny(param, 'CAUDAL DE GAS A INYECTAR');
param=aos_sincronizar_config(param,'JGL');

% SENS-GLJGL-03: un Qiny puntual forzado usa el mismo contrato motriz
% explicito que la sensibilidad. No se deriva presion en forma oculta.
qiny_puntual = 0;
if isfield(param,'Q_iny') && isnumeric(param.Q_iny) && ~isempty(param.Q_iny) && isfinite(param.Q_iny(1))
  qiny_puntual = max(double(param.Q_iny(1)),0);
endif
if isstruct(info_qiny) && isfield(info_qiny,'modo') && ...
    ~strcmpi(info_qiny.modo,'automatico') && qiny_puntual > 1e-12
  [param, info_motriz_puntual] = sens_menu_condicion_motriz_jgl(param,'SIMULACION PUNTUAL JGL'); %#ok<NASGU>
  if info_motriz_puntual.cancelado
    fprintf('Simulacion JGL cancelada durante la seleccion de condicion motriz.\n');
    return;
  endif
else
  param.jgl_condicion_motriz_modo = 'AUTO_ESTRICTO';
endif
param=aos_sincronizar_config(param,'JGL');

param = jgl_defaults(param);
fprintf('\n--- MODO DE SOLVER JGL AOS 0.0.12 ---\n');
fprintf('1 - Preciso iterativo (referencia)\n');
fprintf('2 - Rapido directo (exploracion)\n');
fprintf('3 - Automatico/hibrido (recomendado)\n');
op_jgl = input('Seleccione modo [3]: '); if isempty(op_jgl), op_jgl=3; end
if op_jgl==1, param.jgl_modo='iterativo'; elseif op_jgl==2, param.jgl_modo='directo'; else, param.jgl_modo='automatico'; end
if any(strcmp(param.jgl_modo,{'iterativo','automatico'}))
  v=input(sprintf('Maximo de iteraciones del solver preciso [%d]: ',param.jgl_max_iter));
  if ~isempty(v),param.jgl_max_iter=max(3,min(100,round(v)));end
  fprintf('Solver preciso: minimo %d, maximo %d iteraciones.\n',param.jgl_min_iter,param.jgl_max_iter);
end
param=aos_sincronizar_config(param,'JGL');
[Ql, Qo, Qgas_total, Qiny, Qiny_MMscfd, diagnostico, sol_jgl] = JGL_core(param); %#ok<NASGU>
% Una sola fuente canonica para consola, grafico y .aosrpt.
energia_sla = aos_balance_energia_sla('JGL',param,Ql,Qo,Qiny,sol_jgl);
sol_jgl.energia_sla = energia_sla;
param.energia_sla = energia_sla;
param.Qiny_plot = Qiny; param.sol_jgl=sol_jgl; param.Q_iny=Qiny; param=aos_sincronizar_config(param,'JGL');

fprintf('\n========== RESULTADOS JET GAS LIFT ==========\n');
fprintf('Liquido total      : %s\n', aos_formato_caudal_liquido(Ql));
fprintf('Petroleo           : %s\n', aos_formato_caudal_liquido(Qo));
fprintf('Agua               : %s\n', aos_formato_caudal_liquido(max(Ql-Qo, 0)));
fprintf('Gas inyectado      : %s\n', aos_formato_caudal_gas(Qiny));
fprintf('Gas total producido: %s\n', aos_formato_caudal_gas(Qgas_total));
fprintf('Modelo IPR         : %s\n', param.modelo_IPR);
fprintf('Modelo VLP         : %s\n', param.modelo_VLP);
fprintf('Modo utilizado     : %s\n', sol_jgl.modo_utilizado);
fprintf('Estado solver      : %s\n', sol_jgl.estado);
fprintf('DeltaP eductor     : %.3f bar\n', sol_jgl.deltaP/1e5);
fprintf('Confianza          : %s (%d/100)\n', sol_jgl.confianza.nivel, sol_jgl.confianza.puntaje);
if isfinite(sol_jgl.error_directo_iterativo), fprintf('Error dir/iter     : %.2f %%\n', 100*sol_jgl.error_directo_iterativo); end
if ischar(diagnostico) && ~isempty(strtrim(diagnostico)), fprintf('Diagnostico JGL    : %s\n', diagnostico); end
fprintf('=============================================\n');
aos_imprimir_balance_energia_sla(energia_sla,'JGL');

plot_nodal(param, Ql, 'JGL', sol_jgl);

try
    opciones_tuberia = struct('Qgas_total_std', Qgas_total, 'D_inyeccion', param.D_iny, 'detalle', true);
    diagnostico_tuberia = diagnostico_tuberia_produccion(param, 'JGL', Ql, Qiny, opciones_tuberia);
    param.diagnostico_tuberia = diagnostico_tuberia;
catch err
    fprintf('No se pudo generar diagnostico comun de tuberia: %s\n', err.message);
end

try
    extra_sem = struct('diagnostico', diagnostico, 'Qgas_total', Qgas_total);
    if exist('diagnostico_tuberia', 'var'), extra_sem.diagnostico_tuberia = diagnostico_tuberia; end
    semaforos = aos_semaforo_operacion('JGL', param, Ql, Qo, Qiny, extra_sem);
    param.semaforos = semaforos;
    aos_imprimir_semaforos(semaforos, 'JGL');
catch err
    fprintf('No se pudo generar semaforo operativo JGL: %s\n', err.message);
end

preguntar_reporte(Ql, param);

global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
ULTIMO_QL = Ql; ULTIMO_QO = Qo; ULTIMO_QINY = Qiny; ULTIMO_TIPO = 'JGL'; ULTIMO_PARAM = param;
preguntar_exportar_aosrpt;
