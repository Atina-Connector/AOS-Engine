% generar_mapa_dependencias.m (CORREGIDO)
% Construye un mapa de dependencias entre archivos .m de AOS.
% Útil para saber qué funciones se verán afectadas al modificar un archivo.
% Ejecutar desde la raíz de AOS: generar_mapa_dependencias

iniciar_aos;

% Directorios donde buscar archivos .m (excluyendo historial diario y residuos de migración/)
dirs = {
    '.'
    'src'
    'src/core/GL'
    'src/core/BES'
    'src/core/BM'
    'src/core/common/pvt'
    'src/core/common/ipr'
    'src/core/common/vlp'
    'src/menu'
    'src/sensibilidad'
    'src/utilidades'
    'src/utilidades/bombeo_mecanico'
    'src/utilidades/config'
    'src/utilidades/diagnostico'
    'src/utilidades/graficos'
    'src/utilidades/intercambio'
    'src/utilidades/nodal'
    'src/utilidades/varios'
    'src/geologia'
    'src/geologia/punzados'
    'src/crypto'
    'src/diagnosticos'
};

% Obtener lista de todos los archivos .m en esos directorios
archivos = {};
for d = 1:length(dirs)
    if ~exist(dirs{d}, 'dir'), continue; end
    list = dir(fullfile(dirs{d}, '*.m'));
    for k = 1:length(list)
        archivos{end+1} = fullfile(dirs{d}, list(k).name);
    end
end

% Extraer nombres de funciones definidas (asumimos que cada archivo define una función del mismo nombre)
[~, nombres_definidos] = cellfun(@fileparts, archivos, 'UniformOutput', false);

% Mapa de dependencias: para cada archivo, qué funciones externas llama
dependencias = cell(length(archivos), 1);
usado_por = containers.Map();  % dado un nombre de función, lista de archivos que la llaman

for idx = 1:length(archivos)
    contenido = fileread(archivos{idx});
    % Buscar palabras que coincidan con nombres de funciones definidas
    deps = {};
    for f = 1:length(nombres_definidos)
        if f == idx, continue; end  % no cuenta como dependencia a sí mismo
        % Patrón corregido: nombre de función seguido de ( o de espacio+(
        patron = [nombres_definidos{f} '\s*\('];
        if ~isempty(regexp(contenido, patron, 'once'))
            deps{end+1} = nombres_definidos{f};
            % Registrar quién lo usa
            if ~usado_por.isKey(nombres_definidos{f})
                usado_por(nombres_definidos{f}) = {};
            end
            usado_por(nombres_definidos{f}) = [usado_por(nombres_definidos{f}), nombres_definidos{idx}];
        end
    end
    dependencias{idx} = deps;
end

% --- Reporte ---
fprintf('\n=========================================\n');
fprintf('  MAPA DE DEPENDENCIAS DE AOS\n');
fprintf('=========================================\n\n');

% 1. Funciones más críticas (más dependientes)
fprintf('--- Funciones más críticas (mayor número de dependientes) ---\n');
num_deps = cellfun(@length, dependencias);
% También considerar cuántos lo usan (para medir criticidad)
criticidad = zeros(size(num_deps));
for f = 1:length(nombres_definidos)
    if usado_por.isKey(nombres_definidos{f})
        criticidad(f) = length(usado_por(nombres_definidos{f}));
    end
end
[~, ord] = sort(criticidad, 'descend');
mostradas = 0;
for i = 1:min(10, length(ord))
    if criticidad(ord(i)) == 0, break; end
    fprintf('  %s (usado por %d módulos)\n', nombres_definidos{ord(i)}, criticidad(ord(i)));
    mostradas = mostradas + 1;
end
if mostradas == 0
    fprintf('  (Ninguna con dependencias internas)\n');
end

% 2. Funciones huérfanas (no son llamadas por nadie)
fprintf('\n--- Funciones huérfanas (no son llamadas por otros módulos) ---\n');
huerfanas = {};
for f = 1:length(nombres_definidos)
    if ~usado_por.isKey(nombres_definidos{f}) || isempty(usado_por(nombres_definidos{f}))
        huerfanas{end+1} = nombres_definidos{f};
    end
end
if ~isempty(huerfanas)
    fprintf('  ');
    fprintf('%s, ', huerfanas{1:min(5, end)});
    if length(huerfanas) > 5
        fprintf('... (%d más)', length(huerfanas)-5);
    end
    fprintf('\n');
else
    fprintf('  (Ninguna)\n');
end

% 3. Archivo de dependencias detallado
reporte_file = fullfile('diagnosticos', sprintf('mapa_dependencias_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
fid = fopen(reporte_file, 'w');
fprintf(fid, 'MAPA DE DEPENDENCIAS DE AOS\n');
fprintf(fid, 'Fecha: %s\n\n', datestr(now));
for idx = 1:length(archivos)
    fprintf(fid, '%s\n', archivos{idx});
    if isempty(dependencias{idx})
        fprintf(fid, '  (Sin dependencias internas)\n');
    else
        fprintf(fid, '  Depende de: %s\n', strjoin(dependencias{idx}, ', '));
    end
    % Quién lo usa
    if usado_por.isKey(nombres_definidos{idx}) && ~isempty(usado_por(nombres_definidos{idx}))
        fprintf(fid, '  Usado por: %s\n', strjoin(usado_por(nombres_definidos{idx}), ', '));
    else
        fprintf(fid, '  Usado por: (ninguno)\n');
    end
    fprintf(fid, '\n');
end
fclose(fid);

fprintf('\nReporte detallado guardado en: %s\n', reporte_file);
