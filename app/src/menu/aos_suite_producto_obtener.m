function producto = aos_suite_producto_obtener(id)
% AOS_SUITE_PRODUCTO_OBTENER Devuelve un producto por ID.
  producto = struct();
  lista = aos_suite_registro_productos();
  for i = 1:numel(lista)
    if strcmpi(lista(i).id, id)
      producto = lista(i);
      return;
    endif
  endfor
endfunction
