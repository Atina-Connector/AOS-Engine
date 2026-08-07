function ok = test_aos_galeria_mandriles_r2()
% TEST_AOS_GALERIA_MANDRILES_R2 Verifica galeria .aosdat sin activar caso.
  iniciar_aos(true);ok=false;
  root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
  archivo=fullfile(root,'datos','ejemplos','catalogos','AOS_GALERIA_MANDRILES_COMPLETA.aosdat');
  cfg=importar_aosdat(archivo,struct('activar_caso',false,'imprimir_resumen',false,'normalizar',false));
  assert(strcmp(cfg.aosdat_tipo,'CASO_CON_CATALOGOS') || strcmp(cfg.aosdat_tipo,'CATALOGO'));
  assert(isfield(cfg,'mandriles_galeria'));
  [g,fuente,avisos]=mandriles_cargar_galeria(cfg); %#ok<ASGLU>
  assert(numel(g)==24);
  assert(strcmp(fuente,'AOSDAT_MANDRILES_GALERIA'));
  assert(all([g.rating_bar]>0));
  assert(sum([g.habilitado])==23);
  assert(~g(24).habilitado && g(24).stock==0);
  assert(strcmp(g(24).id,'AOS_SPARE_DISABLED'));
  ok=true;fprintf('RESULTADO: test_aos_galeria_mandriles_r2 APROBADO\n');
endfunction
