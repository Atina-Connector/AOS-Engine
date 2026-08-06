% AOS.m - Lanzador principal de AOS Suite 0.2.0 DEV1
% Edicion: baseline modular de desarrollo distribuido.
% Plataforma oficial: GNU Octave.

root_dir = fileparts(mfilename("fullpath"));
addpath(fullfile(root_dir, "src"), "-begin");
cd(root_dir);

aos_headless = strcmpi(getenv("AOS_HEADLESS"), "1");

if (aos_headless)
  set(0, "defaultfigurevisible", "off");
endif

graphics_mode = lower(strtrim(getenv("AOS_GRAPHICS_MODE")));

if (strcmpi(graphics_mode, "file"))
  set(0, "defaultfigurevisible", "off");
endif

iniciar_aos();
AOS_app();