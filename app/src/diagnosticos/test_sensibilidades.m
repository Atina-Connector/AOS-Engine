% test_sensibilidades.m – Diagnóstico automático de módulos de sensibilidad
% Verifica existencia, sintaxis básica y ejecuta una prueba funcional de JGL vs GL.
% Guarda el reporte en la carpeta diagnosticos/ (se crea si no existe).
% Ejecutar desde la raíz de AOS: test_sensibilidades

iniciar_aos(true);

% Carpeta dedicada para reportes de diagnóstico
carpeta_diag = 'diagnosticos';
if ~exist(carpeta_diag, 'dir')
    mkdir(carpeta_diag);
end

% Configuración base para la prueba funcional
global CONFIG_ACTIVA;
if isempty(CONFIG_ACTIVA)
    CONFIG_ACTIVA = load_config('config/GL/config_jgl.txt');
end
CONFIG_ACTIVA.survey = obtener_survey(CONFIG_ACTIVA);

% Lista de módulos a verificar
modulos = {
    'sens_Qiny_JGL'
    'sens_Qiny_GL'
    'sens_Qiny'
    'sens_P_iny'
    'sens_D_bomba'
    'sens_A_n'
    'sens_d_t'
    'sens_P_wh'
    'sens_balance_energetico'
    'sens_P_wh_BES'
    'sens_frecuencia_BES'
    'sens_sumergencia_BES'
    'sens_RunLife_BES'
    'sens_etapas_BES'
};

fprintf('\n============================================================\n');
fprintf('  DIAGNÓSTICO DE SENSIBILIDADES\n');
fprintf('  Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

% Archivo de reporte
reporte_file = fullfile(carpeta_diag, sprintf('test_sensibilidades_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
fid = fopen(reporte_file, 'w');
if fid == -1
    error('No se pudo crear el archivo de reporte en %s', reporte_file);
end
fprintf(fid, 'DIAGNÓSTICO DE SENSIBILIDADES\n');
fprintf(fid, 'Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '============================================================\n\n');

% 1. Verificar existencia de archivos
fprintf('--- Verificación de existencia ---\n');
fprintf(fid, '--- Verificación de existencia ---\n');
for i = 1:length(modulos)
    nombre = modulos{i};
    ruta = which(nombre);
    if ~isempty(ruta)
        fprintf('  ✅ %s\n', nombre);
        fprintf(fid, '  ✅ %s\n', nombre);
    else
        fprintf('  ❌ %s (no encontrado)\n', nombre);
        fprintf(fid, '  ❌ %s (no encontrado)\n', nombre);
    end
end

% 2. Verificar sintaxis básica (balance de bloques if/for)
fprintf('\n--- Verificación de sintaxis (balance de bloques) ---\n');
fprintf(fid, '\n--- Verificación de sintaxis (balance de bloques) ---\n');
for i = 1:length(modulos)
    nombre = modulos{i};
    ruta = which(nombre);
    if isempty(ruta)
        fprintf('  ⚠️  %s (omitido, archivo no existe)\n', nombre);
        fprintf(fid, '  ⚠️  %s (omitido, archivo no existe)\n', nombre);
        continue;
    end
    try
        contenido = fileread(ruta);
        % Verificar balance de bloques if/for/while y end
        ifs   = length(strfind(contenido, 'if ')) + length(strfind(contenido, 'if('));
        ends  = length(strfind(contenido, 'end'));
        fors  = length(strfind(contenido, 'for ')) + length(strfind(contenido, 'for('));
        whiles = length(strfind(contenido, 'while ')) + length(strfind(contenido, 'while('));
        % Total de aperturas: ifs + fors + whiles
        aperturas = ifs + fors + whiles;
        if aperturas == ends
            fprintf('  ✅ %s\n', nombre);
            fprintf(fid, '  ✅ %s\n', nombre);
        else
            fprintf('  ❌ %s (balance incorrecto: %d aperturas, %d ends)\n', nombre, aperturas, ends);
            fprintf(fid, '  ❌ %s (balance incorrecto: %d aperturas, %d ends)\n', nombre, aperturas, ends);
        end
    catch err
        fprintf('  ❌ %s (error al leer: %s)\n', nombre, err.message);
        fprintf(fid, '  ❌ %s (error al leer: %s)\n', nombre, err.message);
    end
end

% 3. Prueba funcional (solo JGL vs GL)
fprintf('\n--- Prueba funcional: sens_Qiny (JGL vs GL) ---\n');
fprintf(fid, '\n--- Prueba funcional: sens_Qiny (JGL vs GL) ---\n');
try
    sens_Qiny;
    fprintf('  ✅ Prueba funcional completada\n');
    fprintf(fid, '  ✅ Prueba funcional completada\n');
catch err
    fprintf('  ❌ Falló: %s\n', err.message);
    fprintf(fid, '  ❌ Falló: %s\n', err.message);
end

fclose(fid);
fprintf('\nReporte guardado en: %s\n', reporte_file);
close all;

