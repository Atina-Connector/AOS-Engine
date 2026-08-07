% importar_pozos.m – Importación interactiva de pozos desde CSV
% 1. Lista archivos CSV en intercambio/pozos/recibidos/ y datos/ejemplos/.
% 2. Permite elegir uno por número
% 3. Muestra los nombres de los pozos dentro del archivo seleccionado
% 4. Pregunta si se desea importar todos los pozos o uno específico (por número de pozo)
% 5. Ejecuta GL_sim para cada pozo seleccionado y compara con los valores reportados
% 6. Muestra tabla comparativa y guarda reporte en datos/reportes/Reporte_Importacion.txt

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(fileparts(script_dir)));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

% --- Carpetas de importación ---
% config/ se reserva para defaults y catalogos. Los archivos operativos
% entran por intercambio/ o por datos/ejemplos/.
carpetas_csv = {
    'intercambio/pozos/recibidos'
    'datos/ejemplos'
    'datos/ejemplos/importados_legacy'
    'config/importados'   % legacy
};

archivos_csv = {};
for c = 1:length(carpetas_csv)
    carpeta = carpetas_csv{c};
    if exist(carpeta, 'dir')
        lista = dir(fullfile(carpeta, '*.csv'));
        for k = 1:length(lista)
            archivos_csv{end+1} = fullfile(carpeta, lista(k).name);
        end
    end
end

if isempty(archivos_csv)
    fprintf('No se encontraron archivos CSV en intercambio/pozos/recibidos/ ni datos/ejemplos/.\n');
    fprintf('Coloque el CSV en intercambio/pozos/recibidos/ y vuelva a ejecutar esta opción.\n');
    return;
end

fprintf('\n--- ARCHIVOS CSV DISPONIBLES ---\n');
for k = 1:length(archivos_csv)
    fprintf('  %d - %s\n', k, archivos_csv{k});
end
fprintf('  0 - Cancelar\n');

op_archivo = input('Seleccione el archivo a importar (número): ');
if isempty(op_archivo) || op_archivo < 1 || op_archivo > length(archivos_csv)
    fprintf('Importación cancelada.\n');
    return;
end

archivo_csv = archivos_csv{op_archivo};
[~, archivo_csv_nombre, archivo_csv_ext] = fileparts(archivo_csv);
archivo_csv_mostrar = [archivo_csv_nombre, archivo_csv_ext];

% --- Leer archivo y extraer nombres de pozos ---
fid = fopen(archivo_csv, 'r');
if fid == -1
    error('No se pudo abrir el archivo %s', archivo_csv);
end
fgetl(fid);  % ignorar primera línea (encabezado)

nombres_pozos = {};
pozos_lineas = {};
while ~feof(fid)
    linea = fgetl(fid);
    if ~isempty(strtrim(linea))
        pozos_lineas{end+1} = linea;
        partes = strsplit(linea, ',');
        nombres_pozos{end+1} = strtrim(partes{1});
    end
end
fclose(fid);

n_pozos = length(pozos_lineas);
if n_pozos == 0
    fprintf('El archivo no contiene pozos (solo encabezado).\n');
    return;
end

% --- Mostrar listado de pozos ---
fprintf('\n--- POZOS EN %s ---\n', archivo_csv_mostrar);
for k = 1:n_pozos
    fprintf('  %d - %s\n', k, nombres_pozos{k});
end
fprintf('  T - Todos\n');
fprintf('  0 - Cancelar\n');

op_pozo = input('Seleccione el pozo a importar: ', 's');

if strcmpi(op_pozo, 'T')
    indices = 1:n_pozos;
    fprintf('Importando todos los pozos...\n');
else
    idx = str2double(op_pozo);
    if isnan(idx) || idx < 1 || idx > n_pozos
        fprintf('Selección inválida. Importación cancelada.\n');
        return;
    end
    indices = idx;
    fprintf('Importando pozo: %s\n', nombres_pozos{idx});
end

% --- Procesar pozos seleccionados ---
resultados = {};

for i = indices
    % Cada pozo parte de una estructura limpia; no heredar campos del caso
    % anterior durante una importacion por lote.
    param = struct();
    linea = pozos_lineas{i};
    celdas = strsplit(linea, ',');
    if length(celdas) < 15
        warning('Línea %d con menos columnas de las esperadas. Se omite.', i);
        continue;
    end

    d.pozo = strtrim(celdas{1});
    d.MD = str2double(celdas{2});
    d.TVD = str2double(celdas{3});
    d.P_res = str2double(celdas{4}) * 1e5;
    d.IP = str2double(celdas{5}) * 1.1574e-10;
    d.WC = str2double(celdas{6});
    d.GLR = str2double(celdas{7});
    d.P_wh = str2double(celdas{8}) * 1e5;
    d.P_iny_sup = str2double(celdas{9}) * 1e5;
    d.D_valv = str2double(celdas{10});
    d.d_orif = str2double(celdas{11}) / 1000;
    d.API = str2double(celdas{12});
    d.gamma_g = str2double(celdas{13});
    d.Ql_reportado = str2double(celdas{14});
    d.Qo_reportado = str2double(celdas{15});

    % Construir estructura para GL_sim
    param.P_res = d.P_res;
    param.IP = d.IP;
    param.D_res = d.MD;
    param = aos_set_profundidad(param, 'GL', d.D_valv);
    param.P_wh = d.P_wh;
    param.P_iny_sup = d.P_iny_sup;
    param.WC = d.WC;
    param.GLR = d.GLR;
    param.rho_o = 850;
    param.rho_w = 1000;
    param.rho_g_std = 0.80;
    param.diam_tbg = 0.062;
    param.T_sup = 298.15;
    param.T_fondo = 373.15;
    param.API = d.API;
    param.gamma_g = d.gamma_g;
    param.R_gas = 519.6;
    param.modelo_VLP = 'HB';
    param.modelo_IPR = 'Vogel';
    param.survey = [];

    % Calcular caudal de gas
    M_g = 0.016; Z = 0.85; R_gas = 8.314;
    T_prom = (param.T_sup + param.T_fondo) / 2;
    P_valv = d.P_iny_sup * exp(M_g * 9.81 * d.D_valv / (Z * R_gas * T_prom));
    T_valv = param.T_sup + (param.T_fondo - param.T_sup) * d.D_valv / max(d.MD, 1);
    delta_P_ap = 5e5;
    P_down = P_valv - delta_P_ap;
    kappa_TC = 1.30;  % exponente adiabatico; gamma_g es gravedad especifica
    Q_iny_masico = thornhill_craver(P_valv, P_down, T_valv, d.d_orif, param.R_gas, kappa_TC, 0.85);
    Q_iny = Q_iny_masico / param.rho_g_std;

    % Simular con profundidad y gas GL canonicos.
    param = aos_set_qiny(param, Q_iny * 86400, 'fijo');
    param = aos_sincronizar_config(param, 'GL');
    fprintf('Simulando pozo: %s ...\n', d.pozo);
    [Ql_sim, Qo_sim, ~, ~] = GL_sim(param, Q_iny);

    Ql_sim_m3d = Ql_sim * 86400;
    Qo_sim_m3d = Qo_sim * 86400;
    error_Ql = abs(Ql_sim_m3d - d.Ql_reportado) / max(d.Ql_reportado, 1e-6) * 100;
    error_Qo = abs(Qo_sim_m3d - d.Qo_reportado) / max(d.Qo_reportado, 1e-6) * 100;

    % Guardar resultados en el orden correcto para la tabla
    resultados{end+1,1} = d.pozo;
    resultados{end,2} = Ql_sim_m3d;          % Ql AOS
    resultados{end,3} = d.Ql_reportado;      % Ql Rep.
    resultados{end,4} = error_Ql;            % Error Ql%
    resultados{end,5} = Qo_sim_m3d;          % Qo AOS
    resultados{end,6} = d.Qo_reportado;      % Qo Rep.
    resultados{end,7} = error_Qo;            % Error Qo%
end

% --- Mostrar tabla en consola ---
if isempty(resultados)
    fprintf('No se procesó ningún pozo.\n');
    return;
end

fprintf('\n=========================================================================================\n');
fprintf('%-15s | %10s | %10s | %10s | %10s | %10s | %10s |\n', ...
    'Pozo', 'Ql AOS', 'Ql Rep.', 'Error Ql%', 'Qo AOS', 'Qo Rep.', 'Error Qo%');
fprintf('---------------------------------------------------------------------------------------------------\n');
for k = 1:size(resultados,1)
    fprintf('%-15s | %10.1f | %10.1f | %10.1f | %10.2f | %10.2f | %10.1f |\n', ...
        resultados{k,:});
end
fprintf('=========================================================================================\n');

% --- Exportar reporte a TXT ---
if ~exist('datos/reportes', 'dir'), mkdir('datos/reportes'); end
fid = fopen('datos/reportes/Reporte_Importacion.txt', 'w');
fprintf(fid, '=================================================================\n');
fprintf(fid, 'AOS – REPORTE DE IMPORTACIÓN DE POZOS\n');
fprintf(fid, 'Fecha: %s\n', datestr(now));
fprintf(fid, 'Archivo: %s\n', archivo_csv);
fprintf(fid, '=================================================================\n\n');
fprintf(fid, '%-15s | %10s | %10s | %10s | %10s | %10s | %10s |\n', ...
    'Pozo', 'Ql AOS', 'Ql Rep.', 'Error Ql%', 'Qo AOS', 'Qo Rep.', 'Error Qo%');
fprintf(fid, '---------------------------------------------------------------------------------------------------\n');
for k = 1:size(resultados,1)
    fprintf(fid, '%-15s | %10.1f | %10.1f | %10.1f | %10.2f | %10.2f | %10.1f |\n', ...
        resultados{k,:});
end
fprintf(fid, '=================================================================\n');
fclose(fid);
fprintf('\nReporte guardado en datos/reportes/Reporte_Importacion.txt\n');
