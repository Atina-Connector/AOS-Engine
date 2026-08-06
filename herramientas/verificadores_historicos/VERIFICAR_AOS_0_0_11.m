% Verificaciones de AOS 0.0.11 Benchmark Ready.
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'src'), '-begin');
cd(root_dir);
iniciar_aos;

fprintf('\n=== VERIFICACION AOS 0.0.11 BENCHMARK READY ===\n');
ok_import = test_aosdat_supati_001();
ok_roundtrip = test_aosdat_roundtrip_001();
ok_units = test_unidades_aos_001();
ok_legacy = test_aosdat_legacy_compat_001();
ok_plot = test_plot_survey_punzados_001();

if ok_import && ok_roundtrip && ok_units && ok_legacy
    fprintf('\nVerificacion de datos completada correctamente.\n');
else
    error('Fallo una verificacion de datos AOS 0.0.11.');
end
if ~ok_plot
    fprintf('El test grafico fue omitido o no disponible; revise el toolkit grafico de Octave.\n');
end
