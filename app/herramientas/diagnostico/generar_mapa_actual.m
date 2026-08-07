% generar_mapa_actual.m
% Escanea el proyecto y genera un mapa de archivos .m con sus rutas actuales.

fprintf('\n============================================================\n');
fprintf('  GENERANDO MAPA ACTUAL DE ARCHIVOS .m\n');
fprintf('  Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

% Directorios a escanear (los que existen actualmente)
dirs = {
    '.'
    'src'
    'src/core'
    'src/core/GL'
    'src/core/BES'
    'src/core/BM'
    'src/core/common'
    'src/core/common/pvt'
    'src/core/common/ipr'
    'src/core/common/vlp'
    'src/menu'
    'src/utilidades'
    'src/utilidades/bombeo_mecanico'
    'src/utilidades/config'
    'src/utilidades/diagnostico'
    'src/utilidades/graficos'
    'src/utilidades/intercambio'
    'src/utilidades/nodal'
    'src/utilidades/varios'
    'src/sensibilidad'
    'src/geologia'
    'src/geologia/punzados'
    'src/crypto'
    'src/diagnosticos'
};

archivos_encontrados = {};
for d = 1:length(dirs)
    if ~exist(dirs{d}, 'dir')
        continue;
    end
    list = dir(fullfile(dirs{d}, '*.m'));
    for k = 1:length(list)
        archivos_encontrados{end+1} = fullfile(dirs{d}, list(k).name);
    end
end

% Escribir mapa
fid = fopen('mapa_actual.txt', 'w');
for i = 1:length(archivos_encontrados)
    fprintf(fid, '%s\n', archivos_encontrados{i});
end
fclose(fid);

fprintf('  ✅ Mapa generado: mapa_actual.txt (%d archivos)\n', length(archivos_encontrados));
fprintf('============================================================\n');
