function raiz = aosbck_raiz()
% AOSBCK_RAIZ Devuelve la raiz de la distribucion AOS activa.
  raiz = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
endfunction
