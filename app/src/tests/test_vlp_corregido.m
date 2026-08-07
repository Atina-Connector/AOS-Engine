% test_vlp_corregido.m
% Prueba rápida de los nuevos motores VLP corregidos.
% Ejecutar desde la raíz de AOS o adaptar AOS_ROOT.

clear; clc;
% --- Ajustar path de forma robusta ---
script_dir = fileparts(mfilename('fullpath'));  % src/tests/
AOS_ROOT = fileparts(fileparts(script_dir));   % raíz del proyecto
addpath(fullfile(AOS_ROOT, 'src'), '-begin');
iniciar_aos(true);
cd(AOS_ROOT);

% --- Parámetros tipo caso base ---
param.P_wh = 6e5;
param.WC = 0.94;
param.GLR = 80;
param.rho_o = 900;
param.rho_w = 1000;
param.rho_g_std = 0.80;
param.diam_tbg = 0.062;
param.T_sup = 298.15;
param.T_fondo = 358.15;
param.API = 25.0;
param.gamma_g = 0.7;
param.factor_VLP = 1.0;

% --- Survey ---
survey_file = fullfile(AOS_ROOT, 'config', 'GL', 'survey.txt');
if exist('load_survey', 'file') == 2 && exist(survey_file, 'file') == 2
  survey = load_survey(survey_file);
else
  survey = aos_vlp_normalizar_survey([], aos_vlp_parametros(param), 3044);
end
param.survey = survey;

% --- Caudales de prueba ---
Ql = 0.0010;       % m3/s líquido estándar
Qg = Ql * param.GLR; % m3/s gas estándar total aproximado
profundidad_MD = 2700;

param.modelo_VLP = 'HB';
P_HB = compute_P_req(param, Ql, Qg, profundidad_MD);
[P_HB_end, MD_HB, Perfil_HB] = vlp_HB_full(param, survey, Ql, Qg);

param.modelo_VLP = 'DR';
P_DR = compute_P_req(param, Ql, Qg, profundidad_MD);
[P_DR_end, MD_DR, Perfil_DR] = vlp_duns_ros(param, survey, Ql, Qg);

param.modelo_VLP = 'simplified';
P_SIM = compute_P_req(param, Ql, Qg, profundidad_MD);

fprintf('\n--- Prueba VLP corregida ---\n');
fprintf('P_req HB  @ %.1f m MD = %.2f bar\n', profundidad_MD, P_HB/1e5);
fprintf('P_req DR  @ %.1f m MD = %.2f bar\n', profundidad_MD, P_DR/1e5);
fprintf('P_req SIM @ %.1f m MD = %.2f bar\n', profundidad_MD, P_SIM/1e5);
fprintf('P_end HB survey = %.2f bar\n', P_HB_end/1e5);
fprintf('P_end DR survey = %.2f bar\n', P_DR_end/1e5);

figure;
plot(Perfil_HB/1e5, MD_HB, 'LineWidth', 1.5); hold on;
plot(Perfil_DR/1e5, MD_DR, 'LineWidth', 1.5);
set(gca, 'YDir', 'reverse'); grid on;
xlabel('Presión [bar]'); ylabel('MD [m]');
title('Comparación VLP corregida');
legend('HB corregido', 'Duns & Ros corregido', 'Location', 'northeast');
