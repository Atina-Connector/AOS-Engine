function modulo = aos_modulo_obtener(id)
  modulo = struct();
  mods = aos_registro_modulos();
  for i = 1:numel(mods)
    if strcmpi(mods(i).id, id)
      modulo = mods(i);
      return;
    endif
  endfor
endfunction
