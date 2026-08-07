% GL_puro_menu.m - Gas Lift convencional, interfaz metrica AOS 0.0.11.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

[config, origen_config] = aos_config_base('GL');
config = aos_normalizar_config(config, 'GL');
fprintf('Usando %s.\n', origen_config);
config.survey = obtener_survey(config);

fprintf('\n--- PARAMETROS ACTUALES ---\n');
fprintf('IP                      : %.3f m3/d/bar\n', config.IP * 86400 * 1e5);
fprintf('WC                      : %.3f\n', config.WC);
fprintf('P_res                   : %s\n', aos_formato_presion(config.P_res, 1));
fprintf('P_wh                    : %s\n', aos_formato_presion(config.P_wh, 1));
fprintf('P_iny_sup               : %s\n', aos_formato_presion(config.P_iny_sup, 1));
fprintf('Prof. inyeccion/lev.    : %s\n', aos_formato_longitud(config.D_iny, 1));
fprintf('Prof. reservorio        : %s\n', aos_formato_longitud(config.D_res, 1));
fprintf('GLR                     : %.2f Sm3/m3 liquido\n', config.GLR);
fprintf('Modelo IPR              : %s\n', config.modelo_IPR);
fprintf('Modelo VLP              : %s\n', config.modelo_VLP);
[Qcfg, fuente_q] = aos_qiny_configurada(config);
if ~isempty(Qcfg), fprintf('Qiny configurado        : %s [%s]\n', aos_formato_caudal_gas(Qcfg), fuente_q); end
fprintf('---------------------------------------\n');

cambiar = aos_preguntar_sn('Desea modificar los parametros principales? (s/n) [n]: ', false);
if cambiar
    val = input(sprintf('  IP (m3/d/bar) [%.3f]: ', config.IP * 86400 * 1e5));
    if ~isempty(val), config.IP = val / 86400 / 1e5; end
    val = input(sprintf('  WC (fraccion) [%.3f]: ', config.WC));
    if ~isempty(val), config.WC = val; end
    val = input(sprintf('  P_wh (bar) [%.2f]: ', config.P_wh / 1e5));
    if ~isempty(val), config.P_wh = val * 1e5; end
    val = input(sprintf('  P_iny_sup (bar) [%.2f]: ', config.P_iny_sup / 1e5));
    if ~isempty(val), config.P_iny_sup = val * 1e5; end
    val = input(sprintf('  Prof. inyeccion/levantamiento (m) [%.1f]: ', config.D_iny));
    if ~isempty(val)
        config = aos_set_profundidad(config, 'GL', val);
    end
    val = input(sprintf('  GLR (Sm3/m3 de liquido) [%.2f]: ', config.GLR));
    if ~isempty(val), config.GLR = val; end
    fprintf('Parametros actualizados.\n');
else
    fprintf('Se conservan los parametros del .aosdat/configuracion.\n');
end

config = aos_normalizar_config(config, 'GL');
config.survey = obtener_survey(config);
fprintf('Profundidad solicitada   : %.1f m\n', config.D_iny);
fprintf('Profundidad solver GL    : %.1f m\n', config.D_iny);

if isfield(config, 'factor_IP_residual')
    fprintf('Factor de declinacion activo: %.3f\n', config.factor_IP_residual);
    nuevo_factor = input('Nuevo factor (Enter para mantener): ');
    if ~isempty(nuevo_factor), config.factor_IP_residual = nuevo_factor; end
    config.IP = config.IP * config.factor_IP_residual;
    config = aos_sincronizar_config(config, 'GL');
end

% Modelo IPR: el valor importado es el default.
fprintf('\n--- CONFIGURACION DE SIMULACION GL ---\n');
fprintf('Modelos IPR: 1-Linear | 2-Vogel | 3-Fetkovich\n');
op_def = aos_opcion_modelo_ipr(config.modelo_IPR);
opcion = input(sprintf('Seleccione IPR (1-3) [%d]: ', op_def));
if isempty(opcion), opcion = op_def; end
if opcion == 2
    config.modelo_IPR = 'Vogel';
    P_b_def = config.P_b / 1e5;
    val = input(sprintf('Presion de burbuja (bar) [%.2f]: ', P_b_def));
    if ~isempty(val), config.P_b = val * 1e5; end
elseif opcion == 3
    config.modelo_IPR = 'Fetkovich';
else
    config.modelo_IPR = 'linear';
end
fprintf('Modelo IPR usado: %s\n', config.modelo_IPR);

fprintf('\nModelos VLP: 1-Simplificado | 2-Hagedorn-Brown | 3-Duns & Ros\n');
op_vlp_def = aos_opcion_modelo_vlp(config.modelo_VLP);
opcion_vlp = input(sprintf('Seleccione VLP (1-3) [%d]: ', op_vlp_def));
if isempty(opcion_vlp), opcion_vlp = op_vlp_def; end
if opcion_vlp == 2
    config.modelo_VLP = 'HB';
elseif opcion_vlp == 3
    config.modelo_VLP = 'DR';
else
    config.modelo_VLP = 'simplified';
end
fprintf('Modelo VLP usado: %s\n', config.modelo_VLP);
if isfield(config, 'survey') && ~isempty(config.survey), diagnostico_vlp(config.survey, config.modelo_VLP); end

% Caudal de gas en Sm3/d; 0 solicita calculo automatico.
[config, info_qiny] = aos_menu_qiny(config, 'CAUDAL DE GAS A INYECTAR'); %#ok<NASGU>
config=aos_sincronizar_config(config,'GL');

[Ql, Qo, Qgas_total, Q_iny, Qiny_MMscfd, diagnostico, sol_gl] = GL_puro_core(config); %#ok<NASGU>
% Una sola fuente canonica para consola, grafico y .aosrpt.
energia_sla = aos_balance_energia_sla('GL',config,Ql,Qo,Q_iny,sol_gl);
sol_gl.energia_sla = energia_sla;
config.energia_sla = energia_sla;
config.GL_resultado = sol_gl;
config.Q_iny = Q_iny;
config = aos_sincronizar_config(config, 'GL');

fprintf('\n===== RESULTADOS GAS LIFT PURO =====\n');
fprintf('Liquido total      : %s\n', aos_formato_caudal_liquido(Ql));
fprintf('Petroleo           : %s\n', aos_formato_caudal_liquido(Qo));
fprintf('Agua               : %s\n', aos_formato_caudal_liquido(max(Ql-Qo, 0)));
fprintf('Gas inyectado      : %s\n', aos_formato_caudal_gas(Q_iny));
fprintf('Gas total producido: %s\n', aos_formato_caudal_gas(Qgas_total));
if isfield(sol_gl,'audit') && isfield(sol_gl.audit,'Qiny_efectivo')
    fprintf('Qiny usado dentro VLP: %s\n', aos_formato_caudal_gas(sol_gl.audit.Qiny_efectivo));
end
fprintf('Modelo IPR         : %s\n', config.modelo_IPR);
fprintf('Modelo VLP         : %s\n', config.modelo_VLP);
if ischar(diagnostico) && ~isempty(strtrim(diagnostico)), fprintf('Diagnostico GL     : %s\n', diagnostico); end
fprintf('====================================\n');
aos_imprimir_balance_energia_sla(energia_sla,'GL');

if (!strcmpi(getenv("AOS_GRAPHICS_MODE"), "off"))
  plot_nodal(config, Ql, 'GL');
else
  fprintf("Grafico nodal omitido: modo CLI.\n");
endif

try
    opciones_tuberia = struct('Qgas_total_std', Qgas_total, 'D_inyeccion', config.D_iny, 'detalle', true);
    diagnostico_tuberia = diagnostico_tuberia_produccion(config, 'GL', Ql, Q_iny, opciones_tuberia);
    config.diagnostico_tuberia = diagnostico_tuberia;
catch err
    fprintf('No se pudo generar diagnostico comun de tuberia: %s\n', err.message);
end

try
    extra_sem = struct('diagnostico', diagnostico, 'Qgas_total', Qgas_total);
    if exist('diagnostico_tuberia', 'var'), extra_sem.diagnostico_tuberia = diagnostico_tuberia; end
    semaforos = aos_semaforo_operacion('GL', config, Ql, Qo, Q_iny, extra_sem);
    config.semaforos = semaforos;
    aos_imprimir_semaforos(semaforos, 'GL');
catch err
    fprintf('No se pudo generar semaforo operativo GL: %s\n', err.message);
end

preguntar_reporte(Ql, config);

global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
ULTIMO_QL = Ql; ULTIMO_QO = Qo; ULTIMO_QINY = Q_iny; ULTIMO_TIPO = 'GL'; ULTIMO_PARAM = config;
preguntar_exportar_aosrpt;
