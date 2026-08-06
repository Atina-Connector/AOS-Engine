function AOS_catalogos_listar_tipo(tipo)
% Lista los catalogos de texto existentes sin modificar archivos.
if nargin < 1, tipo = 'TODOS'; end
fprintf('\nCatalogos encontrados:\n');
contador = 0;

if any(strcmpi(tipo, {'TODOS','GL','JGL'}))
    contador = contador + listar_archivos(fullfile('config','GL'), 'GL/JGL', {'valvulas.txt','config_mandriles.txt','chokes_std.txt'});
end
if any(strcmpi(tipo, {'TODOS','BES'}))
    contador = contador + listar_patron(fullfile('config','BES','catalogo'), '*.txt', 'BES');
    contador = contador + listar_archivos(fullfile('config','BES'), 'BES', {'curva_bomba.txt'});
end
if any(strcmpi(tipo, {'TODOS','BM'}))
    contador = contador + listar_patron(fullfile('config','BM'), '*.txt', 'BM');
end

if contador == 0
    fprintf('  No se encontraron catalogos para el grupo solicitado.\n');
else
    fprintf('Total listado: %d archivo(s).\n', contador);
end
end

function n = listar_archivos(carpeta, etiqueta, nombres)
n = 0;
for i = 1:numel(nombres)
    ruta = fullfile(carpeta, nombres{i});
    if exist(ruta, 'file') == 2
        info = dir(ruta);
        fprintf('  [%s] %s (%d bytes)\n', etiqueta, ruta, info.bytes);
        n = n + 1;
    end
end
end

function n = listar_patron(carpeta, patron, etiqueta)
n = 0;
if exist(carpeta, 'dir') ~= 7, return; end
archivos = dir(fullfile(carpeta, patron));
for i = 1:numel(archivos)
    if ~archivos(i).isdir
        ruta = fullfile(carpeta, archivos(i).name);
        fprintf('  [%s] %s (%d bytes)\n', etiqueta, ruta, archivos(i).bytes);
        n = n + 1;
    end
end
end
