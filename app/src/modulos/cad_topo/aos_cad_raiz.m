function root = aos_cad_raiz()
% AOS_CAD_RAIZ Raiz de instalacion AOS (carpeta con AOS.m).
% Modulo: src/modulos/cad_topo (no forma parte del motor cientifico).
% mfilename -> .../src/modulos/cad_topo/este.m  => 4 fileparts => raiz AOS
  root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
endfunction
