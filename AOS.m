% AOS.m - Lanzador principal de AOS Suite 0.2.0 DEV1
% Edicion: baseline modular de desarrollo distribuido.
% Plataforma oficial: GNU Octave.

root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'src'), '-begin');
% Modo CLI/headless para Docker.
aos_headless = strcmpi(getenv("AOS_HEADLESS"), "1");
if (aos_headless)
  set(0, "defaultfigurevisible", "off");
endif
cd(root_dir);
iniciar_aos();
AOS_app();
