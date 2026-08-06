% diagnosticar_rutas_archivos.m
% Recorre archivos .m del proyecto y detecta referencias heredadas a rutas
% de configuracion ya migradas a la estructura actual de AOS.
%
% Ejecutar desde la raiz de AOS: diagnosticar_rutas_archivos

iniciar_aos;

% --- Mapeo de rutas heredadas -> rutas actuales ---
% Se construye la ruta heredada por partes para evitar que quede como ruta
% operativa copiable dentro del codigo limpio.
ruta_gl_heredada = ['config/GL' '_JGL/'];
ruta_gl_actual = 'config/GL/';

mapeo = {
    {[ruta_gl_heredada 'config_jgl.txt'],                   [ruta_gl_actual 'config_jgl.txt']}
    {[ruta_gl_heredada 'inyeccion.txt'],                    [ruta_gl_actual 'inyeccion.txt']}
    {[ruta_gl_heredada 'valvulas.txt'],                     [ruta_gl_actual 'valvulas.txt']}
    {[ruta_gl_heredada 'chokes_std.txt'],                   [ruta_gl_actual 'chokes_std.txt']}
    {[ruta_gl_heredada 'survey.txt'],                       [ruta_gl_actual 'survey.txt']}
    {[ruta_gl_heredada 'config_mandriles.txt'],             [ruta_gl_actual 'config_mandriles.txt']}
    {[ruta_gl_heredada 'Calibracion_Coeficientes_JGL.txt'], [ruta_gl_actual 'Calibracion_Coeficientes_JGL.txt']}
};

% --- Directorios reales donde buscar archivos .m ---
dirs_a_escanear = {
    '.', ...
    'src', 'src/core/GL', 'src/core/BES', 'src/core/BM', ...
    'src/core/common/pvt', 'src/core/common/ipr', 'src/core/common/vlp', ...
    'src/menu', 'src/sensibilidad', ...
    'src/utilidades/bombeo_mecanico', 'src/utilidades/config', ...
    'src/utilidades/diagnostico', 'src/utilidades/graficos', ...
    'src/utilidades/intercambio', 'src/utilidades/nodal', 'src/utilidades/varios', ...
    'src/geologia', 'src/geologia/punzados', 'src/crypto', 'src/diagnosticos'
};

fprintf('\n============================================================\n');
fprintf('  DIAGNOSTICO DE RUTAS DE ARCHIVOS\n');
fprintf('  Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('============================================================\n\n');

problemas = 0;
corregidos = 0;

for d = 1:length(dirs_a_escanear)
    if ~exist(dirs_a_escanear{d}, 'dir'), continue; end
    archivos_m = dir(fullfile(dirs_a_escanear{d}, '*.m'));
    for k = 1:length(archivos_m)
        archivo = fullfile(dirs_a_escanear{d}, archivos_m(k).name);
        contenido = fileread(archivo);
        modificado = false;
        for r = 1:size(mapeo, 1)
            ruta_vieja = mapeo{r}{1};
            ruta_nueva = mapeo{r}{2};
            if ~isempty(strfind(contenido, ruta_vieja))
                fprintf('Detectada ruta heredada en %s: %s -> %s\n', archivo, ruta_vieja, ruta_nueva);
                contenido = strrep(contenido, ruta_vieja, ruta_nueva);
                modificado = true;
                problemas = problemas + 1;
            end
        end
        if modificado
            fid = fopen(archivo, 'w');
            fwrite(fid, contenido);
            fclose(fid);
            fprintf('   Corregido automaticamente.\n');
            corregidos = corregidos + 1;
        end
    end
end

fprintf('\n------------------------------------------------------------\n');
fprintf('  Problemas encontrados: %d\n', problemas);
fprintf('  Correcciones automaticas: %d\n', corregidos);
fprintf('------------------------------------------------------------\n');
