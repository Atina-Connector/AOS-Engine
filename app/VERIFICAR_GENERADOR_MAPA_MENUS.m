function ok = VERIFICAR_GENERADOR_MAPA_MENUS()
% VERIFICAR_GENERADOR_MAPA_MENUS Comprueba instalacion sin pedir datos.
  raiz = fileparts(mfilename('fullpath'));
  addpath(fullfile(raiz, 'src', 'tools', 'menu_map'), '-begin');
  requeridos = {
    fullfile(raiz, 'GENERAR_MAPA_DEPENDENCIAS_MENUS.m'),
    fullfile(raiz, 'src', 'tools', 'menu_map', 'aos_generar_mapa_menus.m')
  };
  ok = true;
  for i = 1:numel(requeridos)
    if exist(requeridos{i}, 'file') ~= 2
      fprintf('FALTA: %s\n', requeridos{i});
      ok = false;
    endif
  endfor
  if ~ok
    error('El generador de mapa de menus no esta completo.');
  endif

  salida = fullfile(raiz, 'datos', 'interfaz', 'verificacion');
  r = aos_generar_mapa_menus(raiz, salida, 'both');
  ok = r.total_menus > 0 && exist(r.archivo_json, 'file') == 2 && ...
       exist(r.archivo_txt, 'file') == 2 && exist(r.archivo_md, 'file') == 2;
  if ok
    fprintf('VERIFICACION OK: %d menus, %d opciones, %d dependencias.\n', ...
            r.total_menus, r.total_opciones, r.total_dependencias);
    fprintf('Informes de prueba: %s y %s\n', r.archivo_txt, r.archivo_md);
  else
    error('El generador se ejecuto pero no produjo un manifiesto valido.');
  endif
endfunction
