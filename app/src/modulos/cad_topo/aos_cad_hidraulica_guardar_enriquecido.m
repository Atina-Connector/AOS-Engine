function ruta = aos_cad_hidraulica_guardar_enriquecido()
% Guarda el mismo modelo reproducible con perfil ENRIQUECIDO para Viewer.
% aos_aoscad_escribir regenera recursos_visuales si faltan u obsoletos.
% Los PNG son secundarios/regenerables; no sustituyen tablas ni resultados.
  root = aos_cad_raiz();
  outdir = fullfile(root, 'intercambio', 'cad', 'aoscad');
  if exist(outdir, 'dir') ~= 7, mkdir(outdir); endif
  ruta = fullfile(outdir, sprintf('corrida_%s_ENRIQUECIDO.aoscad', ...
                                  datestr(now, 'yyyymmdd_HHMMSS')));
  ruta = aos_aoscad_escribir(ruta, 'ENRIQUECIDO', false);
endfunction
