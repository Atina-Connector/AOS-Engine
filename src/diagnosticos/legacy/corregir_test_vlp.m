% corregir_test_vlp.m - Corrige el test para que encuentre los helpers

archivo_test = 'src/tests/test_vlp_corregido.m';
if exist(archivo_test, 'file')
    contenido = fileread(archivo_test);
    % Reemplazar las líneas de addpath por una versión robusta
    nuevo_contenido = regexprep(contenido, ...
        'addpath\(fullfile\(AOS_ROOT, .*?\)\);', ...
        'addpath(fullfile(AOS_ROOT, ''src'', ''core'', ''common'', ''vlp''), ''-begin'');');
    % Guardar
    fid = fopen(archivo_test, 'w');
    fwrite(fid, nuevo_contenido);
    fclose(fid);
    fprintf('✅ Test corregido.\n');
else
    fprintf('❌ No se encontró el test.\n');
end
