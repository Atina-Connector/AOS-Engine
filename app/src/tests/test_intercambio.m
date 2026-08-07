% test_intercambio.m
% Prueba unitaria del flujo de intercambio (aosdat, aosrpt, catalogos)

% --- Agregar paths necesarios ---
addpath(fullfile(pwd, 'src', 'utilidades', 'nodal'));
addpath(fullfile(pwd, 'src', 'utilidades', 'intercambio'));
addpath(fullfile(pwd, 'src', 'utilidades', 'varios'));
addpath(fullfile(pwd, 'src', 'core', 'common', 'pvt'));
addpath(fullfile(pwd, 'src', 'core', 'common', 'ipr'));
addpath(fullfile(pwd, 'src', 'core', 'common', 'vlp'));

fprintf('\n============================================================\n');
fprintf('  TEST DE FUNCIONES DE INTERCAMBIO\n');
fprintf('  Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

% --- 1. Verificar que las carpetas existen ---
fprintf('--- 1. Verificando estructura de carpetas ---\n');
carpetas = {
    'intercambio/pozos/enviados'
    'intercambio/pozos/recibidos'
    'intercambio/reportes/enviados'
    'intercambio/reportes/recibidos'
    'intercambio/catalogos/enviados/bombas'
    'intercambio/catalogos/enviados/valvulas'
    'intercambio/catalogos/enviados/varillas'
    'intercambio/catalogos/enviados/unidades_bm'
    'intercambio/catalogos/recibidos/bombas'
    'intercambio/catalogos/recibidos/valvulas'
    'intercambio/catalogos/recibidos/varillas'
    'intercambio/catalogos/recibidos/unidades_bm'
};
for i = 1:length(carpetas)
    if exist(carpetas{i}, 'dir')
        fprintf('  ✅ %s\n', carpetas{i});
    else
        fprintf('  ❌ %s (NO EXISTE)\n', carpetas{i});
        mkdir(carpetas{i});
        fprintf('     Carpeta creada.\n');
    end
end

% --- 2. Verificar que las funciones existen ---
fprintf('\n--- 2. Verificando funciones ---\n');
funciones = {
    'exportar_aosdat'
    'importar_aosdat'
    'exportar_aosrpt'
    'importar_aosrpt'
    'exportar_aosrpt_enriquecido'
    'exportar_aosrpt_grafico'
};
for i = 1:length(funciones)
    if exist(funciones{i}, 'file')
        fprintf('  ✅ %s.m\n', funciones{i});
    else
        fprintf('  ❌ %s.m (NO ENCONTRADO)\n', funciones{i});
    end
end

% --- 3. Prueba de exportación/importación de .aosdat ---
fprintf('\n--- 3. Probando exportar_aosdat ---\n');
% Crear un parámetro de prueba
param_test.P_res = 200e5;
param_test.IP = 1e-10;
param_test.WC = 0.5;
param_test.GLR = 50;
param_test.P_wh = 10e5;
param_test.P_iny_sup = 150e5;
param_test.D_bomba = 2000;
param_test.D_res = 3000;
param_test.diam_tbg = 0.062;
param_test.rho_o = 850;
param_test.rho_w = 1000;
param_test.rho_g_std = 0.8;
param_test.T_sup = 300;
param_test.T_fondo = 380;
param_test.API = 35;
param_test.gamma_g = 0.7;
param_test.R_gas = 519.6;
param_test.modelo_VLP = 'HB';
param_test.modelo_IPR = 'linear';
param_test.factor_VLP = 1.0;

% Exportar
exportar_aosdat(param_test, 'intercambio/pozos/enviados/prueba.aosdat', {'CONFIG'});
if exist('intercambio/pozos/enviados/prueba.aosdat', 'file')
    fprintf('  ✅ Archivo .aosdat exportado correctamente.\n');
    % Importar
    param_importado = importar_aosdat('intercambio/pozos/enviados/prueba.aosdat');
    if ~isempty(param_importado)
        fprintf('  ✅ Archivo .aosdat importado correctamente.\n');
    else
        fprintf('  ❌ Falló la importación de .aosdat.\n');
    end
else
    fprintf('  ❌ Falló la exportación de .aosdat.\n');
end

% --- 4. Prueba de exportación/importación de .aosrpt ---
fprintf('\n--- 4. Probando exportar_aosrpt ---\n');
Ql_test = 0.001;
Qo_test = 0.0005;
Qiny_test = 0.0001;
exportar_aosrpt(param_test, Ql_test, Qo_test, Qiny_test, 'GL', 'intercambio/reportes/enviados/prueba.aosrpt');
if exist('intercambio/reportes/enviados/prueba.aosrpt', 'file')
    fprintf('  ✅ Archivo .aosrpt exportado correctamente.\n');
    % Importar (visualizar)
    fprintf('  Intentando importar reporte...\n');
    importar_aosrpt('intercambio/reportes/enviados/prueba.aosrpt');
else
    fprintf('  ❌ Falló la exportación de .aosrpt.\n');
end

fprintf('\n============================================================\n');
fprintf('  PRUEBAS COMPLETADAS\n');
fprintf('============================================================\n');
