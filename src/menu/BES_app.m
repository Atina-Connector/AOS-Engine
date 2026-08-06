% BES_app.m – Simulación de Bombeo Electrosumergible (BES)
% Menú interactivo completo con todos los parámetros editables:
% IP, WC, P_wh, D_bomba, GLR, frecuencia, número de etapas,
% temperatura máxima del motor, eficiencia, cp del fluido,
% velocidad mínima de refrigeración, tensión del motor,
% resistencia de aislación base, factor de envejecimiento y viscosidad.
% Incluye catálogo de bombas seleccionable, alarma de sobredimensionamiento,
% análisis nodal y reporte geológico automático.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

% --- Cargar configuración base según arquitectura AOS ---
[param, origen_config] = aos_config_base('BES');
param = aos_normalizar_config(param, 'BES');
fprintf('Usando %s.\n', origen_config);

% --- Valores por defecto para BES (si no vienen del archivo) ---
if ~isfield(param, 'curva_bomba_file'),       param.curva_bomba_file = 'config/BES/curva_bomba.txt'; end
if ~isfield(param, 'D_bomba'),               param.D_bomba = validar_parametro(param, 'D_bomba', 'Profundidad de bomba', 'm', 2000); end
if ~isfield(param, 'frecuencia'),            param.frecuencia = 60; end
if ~isfield(param, 'frecuencia_base'),       param.frecuencia_base = 60; end
if ~isfield(param, 'num_etapas')
    if exist(param.curva_bomba_file, 'file')
        curva_temp = load_config(param.curva_bomba_file);
        if isfield(curva_temp, 'num_etapas')
            param.num_etapas = curva_temp.num_etapas;
        else
            param.num_etapas = 100;
        end
    else
        param.num_etapas = 100;
    end
end
if ~isfield(param, 'T_max_motor'),           param.T_max_motor = 120; end
if ~isfield(param, 'eficiencia_motor'),      param.eficiencia_motor = 0.85; end
if ~isfield(param, 'cp_fluido'),             param.cp_fluido = 3500; end
if ~isfield(param, 'velocidad_min_refrig'),  param.velocidad_min_refrig = 0.3; end
if ~isfield(param, 'voltaje_motor'),         param.voltaje_motor = 4000; end
if ~isfield(param, 'IR_base'),               param.IR_base = 1000; end
if ~isfield(param, 'factor_envejecimiento'), param.factor_envejecimiento = 1.0; end

% --- Inicializar viscosidad del petróleo si no viene en la configuración ---
if ~isfield(param, 'mu_o')
    pvt = pvt_calcular(param.P_res, param.T_fondo - 273.15, param.API, param.gamma_g);
    param.mu_o = pvt.mu_o;
end

% --- Escanear catálogo de bombas BES ---
catalogo_dir = fullfile('config/BES', 'catalogo');
if ~exist(catalogo_dir, 'dir')
    catalogo_dir = 'config/BES';   % fallback: usar la carpeta config/BES directamente
end
if exist(catalogo_dir, 'dir')
    archivos = dir(fullfile(catalogo_dir, '*.txt'));
    % Ignorar el archivo curva_bomba.txt si está en la misma carpeta
    archivos = archivos(~strcmp({archivos.name}, 'curva_bomba.txt'));
    n_bombas = length(archivos);
    if n_bombas > 0
        fprintf('\n--- CATÁLOGO DE BOMBAS BES ---\n');
        modelos = cell(n_bombas, 1);
        for k = 1:n_bombas
            curva_cat = load_config(fullfile(catalogo_dir, archivos(k).name));
            if isfield(curva_cat, 'modelo')
                modelos{k} = curva_cat.modelo;
            else
                modelos{k} = archivos(k).name(1:end-4);
            end
            fprintf('  %d - %s\n', k, modelos{k});
        end
        fprintf('  0 - Mantener curva actual [%s]\n', param.curva_bomba_file);
        op_bomba = input('Seleccione la bomba [0]: ');
        if isempty(op_bomba) || op_bomba == 0
            % Mantener exactamente el archivo cargado desde el .aosdat.
        elseif op_bomba >= 1 && op_bomba <= n_bombas
            param.curva_bomba_file = fullfile(catalogo_dir, archivos(op_bomba).name);
        else
            fprintf('Opción inválida, usando la primera bomba del catálogo.\n');
            param.curva_bomba_file = fullfile(catalogo_dir, archivos(1).name);
        end
    else
        param.curva_bomba_file = fullfile('config/BES', 'curva_bomba.txt');
    end
else
    param.curva_bomba_file = fullfile('config/BES', 'curva_bomba.txt');
end

% --- Menú interactivo de parámetros ---
fprintf('\n--- PARÁMETROS ACTUALES (BES) ---\n');
fprintf('IP                      : %.3f m3/d/bar\n', param.IP*86400*1e5);
fprintf('WC                      : %.2f\n', param.WC);
fprintf('P_wh                    : %s\n', aos_formato_presion(param.P_wh, 1));
fprintf('D_bomba (prof. BES)     : %s\n', aos_formato_longitud(param.D_bomba, 1));
fprintf('GLR                     : %.1f sm³/m³\n', param.GLR);
fprintf('Curva de bomba          : %s\n', param.curva_bomba_file);
fprintf('Frecuencia              : %.1f Hz (base: %.1f Hz)\n', param.frecuencia, param.frecuencia_base);
fprintf('Número de etapas        : %.0f\n', param.num_etapas);
fprintf('Temperatura máx. motor  : %.0f °C\n', param.T_max_motor);
fprintf('Eficiencia del motor    : %.2f\n', param.eficiencia_motor);
fprintf('Calor específico fluido : %.0f J/kg·K\n', param.cp_fluido);
fprintf('Velocidad mín. refrig.  : %.2f m/s\n', param.velocidad_min_refrig);
fprintf('Tensión del motor       : %.0f V\n', param.voltaje_motor);
fprintf('IR base (20°C)          : %.0f MΩ\n', param.IR_base);
fprintf('Factor de envejecimiento: %.2f\n', param.factor_envejecimiento);
fprintf('Viscosidad del petróleo : %.4f Pa·s\n', param.mu_o);
fprintf('---------------------------------------\n');

if aos_preguntar_sn('Modificar los parametros? (s/n) [n]: ', false)
    val = input(sprintf('  IP (m3/d/bar) [%.3f]: ', param.IP*86400*1e5));
    if ~isempty(val), param.IP = val / 86400 / 1e5; end
    val = input(sprintf('  WC (fracción) [%.2f]: ', param.WC));
    if ~isempty(val), param.WC = val; end
    val = input(sprintf('  P_wh (bar) [%.1f]: ', param.P_wh/1e5));
    if ~isempty(val), param.P_wh = val * 1e5; end
    val = input(sprintf('  D_bomba (m) [%.0f]: ', param.D_bomba));
    if ~isempty(val), param = aos_set_profundidad(param, 'BES', val); end
    val = input(sprintf('  GLR (sm³/m³) [%.1f]: ', param.GLR));
    if ~isempty(val), param.GLR = val; end
    val = input(sprintf('  Curva de bomba (archivo) [%s]: ', param.curva_bomba_file), 's');
    if ~isempty(val), param.curva_bomba_file = val; end
    val = input(sprintf('  Frecuencia (Hz) [%.1f]: ', param.frecuencia));
    if ~isempty(val), param.frecuencia = val; end
    val = input(sprintf('  Número de etapas [%.0f]: ', param.num_etapas));
    if ~isempty(val), param.num_etapas = val; end
    val = input(sprintf('  T_max_motor (°C) [%.0f]: ', param.T_max_motor));
    if ~isempty(val), param.T_max_motor = val; end
    val = input(sprintf('  Eficiencia del motor [%.2f]: ', param.eficiencia_motor));
    if ~isempty(val), param.eficiencia_motor = val; end
    val = input(sprintf('  cp_fluido (J/kg·K) [%.0f]: ', param.cp_fluido));
    if ~isempty(val), param.cp_fluido = val; end
    val = input(sprintf('  Velocidad mín. refrig. (m/s) [%.2f]: ', param.velocidad_min_refrig));
    if ~isempty(val), param.velocidad_min_refrig = val; end
    val = input(sprintf('  Tensión del motor (V) [%.0f]: ', param.voltaje_motor));
    if ~isempty(val), param.voltaje_motor = val; end
    val = input(sprintf('  IR base a 20°C (MΩ) [%.0f]: ', param.IR_base));
    if ~isempty(val), param.IR_base = val; end
    val = input(sprintf('  Factor de envejecimiento [%.2f]: ', param.factor_envejecimiento));
    if ~isempty(val), param.factor_envejecimiento = val; end
    val = input(sprintf('  Viscosidad del petróleo (Pa·s) [%.4f]: ', param.mu_o));
    if ~isempty(val), param.mu_o = val; end
    fprintf('Parámetros actualizados.\n');
else
    fprintf('Se conservan los parámetros de configuración.\n');
end

% --- Seleccion de modelos; los valores importados son los defaults ---
fprintf('\n--- Configuracion de simulacion BES ---\n');
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

fprintf('Modelos VLP: 1-Simplificado | 2-Hagedorn-Brown | 3-Duns & Ros\n');
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

% --- Consolidar snapshot runtime y cargar survey ---
param = aos_sincronizar_config(param, 'BES');
param.survey = obtener_survey(param);

% --- Ejecutar simulación ---
[Ql, Qo, Qg_total, P_intake, T_motor, Q_recirc, ...
    corriente, IR_actual, IR_estado, run_life, diagnostico_sla] = BES_sim(param);
param.BES_resultado = struct('P_intake',P_intake,'T_motor',T_motor,'Q_recirc',Q_recirc, ...
    'corriente',corriente,'IR_actual',IR_actual,'IR_estado',IR_estado, ...
    'run_life',run_life,'diagnostico_sla',diagnostico_sla,'Qg_total',Qg_total);
param.BES_resultado.audit = struct('IP_efectivo',param.IP,'P_wh_efectiva',param.P_wh, ...
    'D_bomba_efectiva',param.D_bomba,'frecuencia_efectiva',param.frecuencia, ...
    'num_etapas_efectivo',param.num_etapas,'modelo_IPR',param.modelo_IPR, ...
    'modelo_VLP',param.modelo_VLP);

% --- Resultados ---
Ql_d = Ql * 86400;
Qo_d = Qo * 86400;
fprintf('\n===== RESULTADOS BES =====\n');
fprintf('Liquido total       : %s\n', aos_formato_caudal_liquido(Ql));
fprintf('Petroleo            : %s\n', aos_formato_caudal_liquido(Qo));
fprintf('Agua                : %s\n', aos_formato_caudal_liquido(max(Ql-Qo,0)));
fprintf('Gas total producido : %s\n', aos_formato_caudal_gas(Qg_total));
fprintf('Presion de intake   : %s\n', aos_formato_presion(P_intake, 1));
if exist('diagnostico_sla', 'var') && ~isempty(diagnostico_sla)
    fprintf('Diagnóstico SLA      : %s\n', diagnostico_sla);
end
if P_intake < 2e5   % menos de 2 bar absolutos
    fprintf('⚠️  ALERTA: Presión de intake por debajo del mínimo seguro (2 bar).\n');
    fprintf('   Riesgo de cavitación. Considere reducir etapas, frecuencia o\n');
    fprintf('   seleccionar una bomba de menor capacidad.\n');
end
fprintf('=========================\n');

% --- Alarma de bomba sobredimensionada ---
[Ql_max_aux, ~] = ipr(param, 'linear');
if Ql > 0.99 * Ql_max_aux
    fprintf('\n⚠️  ALERTA: La bomba está sobredimensionada para este yacimiento.\n');
    fprintf('   El límite de producción lo impone la IP (caudal máximo del reservorio).\n');
    fprintf('   Considere reducir el número de etapas o la frecuencia para operar dentro de la curva.\n');
end

% --- Diagnóstico térmico y de refrigeración ---
if ~isnan(T_motor)
    fprintf('\n--- DIAGNÓSTICO TÉRMICO ---\n');
    fprintf('Temperatura estimada del motor : %.1f °C\n', T_motor);
    if T_motor > param.T_max_motor
        fprintf('⚠️  ALERTA: Temperatura del motor excede el límite (%d °C).\n', param.T_max_motor);
        fprintf('   Se recomienda aumentar el caudal o mejorar la refrigeración.\n');
    else
        fprintf('✅  Temperatura dentro del rango seguro.\n');
    end
    fprintf('----------------------------\n');

    if Q_recirc > 0
        fprintf('\n--- RECOMENDACIÓN DE RECIRCULACIÓN ---\n');
        fprintf('Caudal mínimo para refrigeración : %.1f m³/d\n', (Ql + Q_recirc)*86400);
        fprintf('Caudal actual                    : %.1f m³/d\n', Ql_d);
        fprintf('Recircular desde descarga        : %.1f m³/d\n', Q_recirc*86400);
        fprintf('(Esto protege el motor pero reduce la producción neta)\n');
        fprintf('---------------------------------------\n');
    end
end

% --- Diagnóstico eléctrico y de aislación ---
if ~isnan(corriente)
    fprintf('\n--- DIAGNÓSTICO ELÉCTRICO ---\n');
    fprintf('Corriente estimada del motor : %.1f A\n', corriente);
    fprintf('Resistencia de aislación     : %.2f MΩ  (%s)\n', IR_actual, IR_estado);
    fprintf('Run life remanente estimado  : %.1f días\n', run_life);
    if strcmp(IR_estado, 'MALO')
        fprintf('⚠️  ALERTA: Aislación del motor en estado crítico. Considere reemplazo.\n');
    end
    fprintf('-----------------------------\n');
end

% --- Análisis nodal BES ---
plot_nodal_BES(param, Ql);

% --- Diagnostico comun de tuberia: erosion, carga liquida y Taitel ---
try
    opciones_tuberia = struct();
    if exist('Qg_total', 'var'), opciones_tuberia.Qgas_total_std = Qg_total; end
    if isfield(param, 'D_bomba'), opciones_tuberia.D_inyeccion = param.D_bomba; end
    opciones_tuberia.detalle = true;
    diagnostico_tuberia = diagnostico_tuberia_produccion(param, 'BES', Ql, 0, opciones_tuberia);
    param.diagnostico_tuberia = diagnostico_tuberia;
catch err
    fprintf('No se pudo generar diagnostico comun de tuberia: %s\n', err.message);
end

% --- Reporte geológico automático ---
try
    if exist('Ql', 'var') && exist('param', 'var')
        preguntar_reporte(Ql, param);
    else
        fprintf('No se pudo generar el reporte geológico (variables no definidas).\n');
    end
catch err
    fprintf('Error en reporte geologico: %s\n', err.message);
end

% --- Semaforos operativos globales ---
try
    extra_sem = struct();
    extra_sem.P_intake = P_intake;
    extra_sem.T_motor = T_motor;
    extra_sem.IR_estado = IR_estado;
    extra_sem.run_life = run_life;
    if exist('diagnostico_tuberia', 'var'), extra_sem.diagnostico_tuberia = diagnostico_tuberia; end
    semaforos = aos_semaforo_operacion('BES', param, Ql, Qo, 0, extra_sem);
    param.semaforos = semaforos;
    aos_imprimir_semaforos(semaforos, 'BES');
catch err
    fprintf('No se pudo generar semaforo operativo BES: %s\n', err.message);
end

% --- Almacenar resultados para posible exportacion ---
global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
ULTIMO_QL = Ql;
ULTIMO_QO = Qo;
ULTIMO_QINY = 0;          % BES no tiene inyección de gas
ULTIMO_TIPO = 'BES';
ULTIMO_PARAM = param;

% --- Preguntar exportación de reporte (ligero o enriquecido) ---
preguntar_exportar_aosrpt;
