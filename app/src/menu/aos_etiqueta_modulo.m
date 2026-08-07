function txt = aos_etiqueta_modulo(id)
  m = aos_modulo_obtener(id);
  if isempty(fieldnames(m))
    txt = '[NO REGISTRADO]';
    return;
  endif
  txt = ['[', upper(m.estado), ']'];
  if m.propietario
    if strcmpi(id,'GL_JGL')
      txt = [txt, ' [JGL PROPIETARIO AESIR]'];
    else
      txt = [txt, ' [PROPIETARIO AESIR]'];
    endif
  endif
endfunction
