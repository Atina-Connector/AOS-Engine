function ok = DIAGNOSTICAR_SOMBRA_AOSCAD()
% Diagnostica la ruta realmente ejecutada por Octave para el lanzador CAD.
% Incluye unicidad Sprint 5/6/7 via aos_cad_verificar_rutas_unicas.
  root = fileparts(mfilename('fullpath'));
  addpath(fullfile(root, 'src'), '-begin');
  iniciar_aos(true);
  clear aos_cad_abrir_externo aos_cad_abrir_externo_impl;
  clear aos_cad_invalidar_simulacion aos_cad_sincronizar_2d_3d;
  clear aos_cad_dxf_copia_edicion aos_aoscad_generar_recursos_visuales;
  rehash();
  fprintf('\n--- DIAGNOSTICO DE RUTAS AOSCAD (R16 / Sprint7) ---\n');
  ok = aos_cad_verificar_rutas_unicas(true);
  fprintf('Localizador: %s\n', which('aos_cad_localizar_programa'));
  fprintf('Lanzador   : %s\n', which('aos_cad_abrir_externo'));
  fprintf('Implement. : %s\n', which('aos_cad_abrir_externo_impl'));
  fprintf('Invalidar  : %s\n', which('aos_cad_invalidar_simulacion'));
  fprintf('Sync 2D/3D : %s\n', which('aos_cad_sincronizar_2d_3d'));
  fprintf('DXF copia  : %s\n', which('aos_cad_dxf_copia_edicion'));
  fprintf('Recursos   : %s\n', which('aos_aoscad_generar_recursos_visuales'));
endfunction
