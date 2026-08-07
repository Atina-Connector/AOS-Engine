function txt = aos_suite_etiqueta_producto(id)
% AOS_SUITE_ETIQUETA_PRODUCTO Estado y version para el menu principal.
  p = aos_suite_producto_obtener(id);
  if isempty(fieldnames(p))
    txt = '[NO REGISTRADO]';
    return;
  endif
  txt = sprintf('[%s | %s]', upper(p.estado), p.version);
  if ~p.disponible
    txt = [txt, ' [ENTRADA NO DISPONIBLE]'];
  endif
endfunction
