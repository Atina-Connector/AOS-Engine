function ok = test_aos_gestion_caso_sin_nombre_r2_hf1()
% TEST_AOS_GESTION_CASO_SIN_NOMBRE_R2_HF1 Regresion del menu transversal.
% Reproduce la configuracion base sin nombre, donde cfg.pozo es una
% estructura obligatoria. El menu no debe intentar num2str(struct()).

  ok = false;

  cfg = aos_normalizar_config(struct(), 'GENERAL');
  assert(isfield(cfg, 'pozo') && isstruct(cfg.pozo));

  nombre = nombre_local(cfg, 'CASO_SIN_NOMBRE');
  assert(strcmp(nombre, 'CASO_SIN_NOMBRE'));

  cfg_legacy = aos_normalizar_config(struct('pozo', 'POZO_LEGACY'), 'GENERAL');
  nombre_legacy = nombre_local(cfg_legacy, 'CASO_SIN_NOMBRE');
  assert(strcmp(nombre_legacy, 'POZO_LEGACY'));

  [txt, encontrado] = aos_texto_seguro(struct('nombre', 'POZO_ESTRUCTURA'), '');
  assert(encontrado && strcmp(txt, 'POZO_ESTRUCTURA'));

  [txt, encontrado] = aos_texto_seguro({42}, '');
  assert(encontrado && strcmp(txt, '42'));

  [txt, encontrado] = aos_texto_seguro(struct(), 'DEFECTO');
  assert(~encontrado && strcmp(txt, 'DEFECTO'));

  ruta_menu = which('AOS_menu_gestion_caso');
  assert(~isempty(ruta_menu));
  fuente = fileread(ruta_menu);
  assert(~isempty(strfind(fuente, 'aos_texto_seguro')));
  assert(isempty(strfind(fuente, 'txt=num2str(v)')));

  fprintf('RESULTADO: test_aos_gestion_caso_sin_nombre_r2_hf1 APROBADO\n');
  ok = true;
endfunction

function nombre = nombre_local(cfg, defecto)
  nombre = defecto;
  campos = {'nombre_pozo','pozo_nombre','well_name','nombre','id_pozo', ...
    'valor_original_pozo','archivo_aosdat','aosdat_archivo','pozo'};
  for i = 1:numel(campos)
    campo = campos{i};
    if isfield(cfg, campo) && ~isempty(cfg.(campo))
      [candidato, encontrado] = aos_texto_seguro(cfg.(campo), '');
      if encontrado
        nombre = candidato;
        return;
      endif
    endif
  endfor
endfunction
