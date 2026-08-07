% Carga directa del pozo testigo AOS-001 (Supati X1 ST).
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'src'), '-begin');
cd(root_dir);
iniciar_aos;
archivo = fullfile(root_dir, 'datos', 'ejemplos', 'benchmarks', ...
                   'SUPATI_X1_ST_BENCHMARK_AOS_001.aosdat');
config_supati = importar_aosdat(archivo); %#ok<NASGU>
fprintf('\nBenchmark Supati AOS-001 cargado. Ejecute AOS para simular.\n');
