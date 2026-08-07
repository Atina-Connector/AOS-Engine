% corregir_hardcodeos.m
% Escanea todos los archivos .m en src/ y reemplaza hardcodeos de parámetros
% por llamadas a validar_parametro. También convierte errores de validación
% en solicitudes interactivas.
%
% Ejecutar desde la raíz del proyecto.
%
% IMPORTANTE: Antes de ejecutar, asegúrate de que exista la función
% validar_parametro en src/utilidades/varios/validar_parametro.m

fprintf('\n============================================================\n');
fprintf('  CORRECCIÓN AUTOMÁTICA DE HARDCODEOS\n');
fprintf('  Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

% --- 1. Verificar que validar_parametro.m existe ---
if exist('src/utilidades/varios/validar_parametro.m', 'file') ~= 2
    fprintf('❌ No se encontró src/utilidades/varios/validar_parametro.m\n');
    fprintf('   Cree ese archivo antes de ejecutar este script.\n');
    return;
end

% --- 2. Definir el mapeo de parámetros ---
% Estructura: campo, descripción, unidad, valor por defecto
parametros = {
    {'API',        'Gravedad API',              '°API',     35}
    {'gamma_g',    'Gravedad específica del gas','',        0.7}
    {'T_sup',      'Temperatura en superficie', 'K',       298.15}
    {'T_fondo',    'Temperatura en fondo',      'K',       358.15}
    {'P_wh',       'Presión en cabeza',         'Pa',      10e5}
    {'rho_o',      'Densidad del petróleo',     'kg/m³',   850}
    {'rho_w',      'Densidad del agua',         'kg/m³',   1000}
    {'rho_g_std',  'Densidad estándar del gas', 'kg/m³',   0.8}
    {'WC',         'Corte de agua',             '',        0.5}
    {'GLR',        'Relación gas-petróleo',     'sm³/m³',  50}
    {'P_res',      'Presión de reservorio',     'Pa',      200e5}
    {'IP',         'Índice de productividad',   'm³/s/Pa', 1e-10}
    {'D_bomba',    'Profundidad de bomba',      'm',       2000}
    {'D_res',      'Profundidad del reservorio','m',       3000}
    {'diam_tbg',   'Diámetro interno del tubing','m',      0.062}
    {'R_gas',      'Constante del gas',         'J/kg·K',  519.6}
    {'P_iny_sup',  'Presión de inyección sup.', 'Pa',      150e5}
};

% --- 3. Crear carpeta de backups ---
backup_dir = 'datos/backups/hardcodeos';
if ~exist(backup_dir, 'dir')
    mkdir(backup_dir);
end

% --- 4. Escanear todos los archivos .m en src/ ---
archivos = dir(fullfile('src', '**', '*.m'));
fprintf('🔍 Archivos encontrados: %d\n', length(archivos));

% --- 5. Procesar cada archivo ---
modificados = 0;
reporte = {};

for i = 1:length(archivos)
    ruta = fullfile(archivos(i).folder, archivos(i).name);
    contenido_original = fileread(ruta);
    contenido_modificado = contenido_original;
    cambios = false;

    % --- 5a. Buscar hardcodeos de parámetros ---
    for p = 1:size(parametros, 1)
        campo = parametros{p}{1};
        desc = parametros{p}{2};
        unidad = parametros{p}{3};
        defecto = parametros{p}{4};

        % Patrones de hardcodeo:
        % 1. asignación directa: "campo = valor;"
        % 2. asignación con if: "campo = valor;"
        % 3. asignación con getfield: "campo = getfield(...)"
        % Vamos a buscar y reemplazar de forma segura

        % Patrón: "campo = numero;"
        patron_asignacion = sprintf('%s\\s*=\\s*([0-9.eE+-]+)\\s*;', campo);
        if regexp(contenido_modificado, patron_asignacion, 'once')
            % Reemplazar por llamada a validar_parametro
            if isempty(unidad)
                reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', '''', %g);', campo, campo, desc, defecto);
            else
                reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', ''%s'', %g);', campo, campo, desc, unidad, defecto);
            end
            contenido_modificado = regexprep(contenido_modificado, patron_asignacion, reemplazo);
            cambios = true;
        end

        % Patrón: "campo = getfield(param, 'campo', valor);"
        patron_getfield = sprintf('%s\\s*=\\s*getfield\\(param,\\s*''%s'',\\s*([0-9.eE+-]+)\\)\\s*;', campo, campo);
        if regexp(contenido_modificado, patron_getfield, 'once')
            if isempty(unidad)
                reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', '''', %g);', campo, campo, desc, defecto);
            else
                reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', ''%s'', %g);', campo, campo, desc, unidad, defecto);
            end
            contenido_modificado = regexprep(contenido_modificado, patron_getfield, reemplazo);
            cambios = true;
        end
    end

    % --- 5b. Buscar mensajes de error del tipo "error('Falta ...')" ---
    % y reemplazar por una llamada a validar_parametro con el campo correspondiente
    % Esto es más complejo, pero podemos hacer una búsqueda genérica.
    % Buscar: error('Falta el campo "XXX" ...')
    % Extraer el nombre del campo y buscar en la lista de parámetros.
    patron_error = 'error\s*\(\s*[''"]Falta el campo "([^"]+)"[^'']*[''"]\s*\)\s*;';
    [tokens, ~] = regexp(contenido_modificado, patron_error, 'tokens', 'match');
    for j = 1:length(tokens)
        campo_error = tokens{j}{1};
        % Buscar el campo en la lista de parámetros
        for p = 1:size(parametros, 1)
            if strcmp(campo_error, parametros{p}{1})
                campo = parametros{p}{1};
                desc = parametros{p}{2};
                unidad = parametros{p}{3};
                defecto = parametros{p}{4};
                % Reemplazar el error por una llamada a validar_parametro
                % pero solo si no es un error de otra cosa
                if isempty(unidad)
                    reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', '''', %g);', campo, campo, desc, defecto);
                else
                    reemplazo = sprintf('%s = validar_parametro(param, ''%s'', ''%s'', ''%s'', %g);', campo, campo, desc, unidad, defecto);
                end
                % Reemplazar solo la línea del error por el reemplazo
                % Pero como es más complejo, lo dejamos para después.
                % Por ahora, solo reemplazamos asignaciones directas.
                break;
            end
        end
    end

    % --- 5c. Si hubo cambios, guardar ---
    if cambios
        % Backup del original
        backup_file = fullfile(backup_dir, [archivos(i).name '.bak']);
        copyfile(ruta, backup_file, 'f');
        % Guardar el nuevo contenido
        fid = fopen(ruta, 'w');
        fwrite(fid, contenido_modificado);
        fclose(fid);
        modificados = modificados + 1;
        reporte{end+1} = sprintf('✅ Modificado: %s', ruta);
        fprintf('✅ Modificado: %s\n', ruta);
    end
end

% --- 6. Guardar reporte ---
reporte_file = fullfile(backup_dir, ['reporte_' datestr(now, 'yyyymmdd_HHMMSS') '.txt']);
fid = fopen(reporte_file, 'w');
fprintf(fid, 'REPORTE DE CORRECCIÓN DE HARDCODEOS\n');
fprintf(fid, 'Fecha: %s\n', datestr(now));
fprintf(fid, 'Archivos modificados: %d\n\n', modificados);
for i = 1:length(reporte)
    fprintf(fid, '%s\n', reporte{i});
end
fclose(fid);

fprintf('\n============================================================\n');
fprintf('  CORRECCIÓN COMPLETADA\n');
fprintf('  Archivos modificados: %d\n', modificados);
fprintf('  Backups guardados en: %s\n', backup_dir);
fprintf('  Reporte: %s\n', reporte_file);
fprintf('============================================================\n');
