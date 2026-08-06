function ok = aos_cad_abrir_externo(varargin)
% AOS_CAD_ABRIR_EXTERNO Punto publico unico para abrir DXF/STEP.
% La implementacion reside en src/modulos/cad_topo para evitar que una
% copia heredada del menu oculte el lanzador Flatpak detectado por AOSCAD.
  if exist('aos_cad_abrir_externo_impl', 'file') ~= 2
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    modulo = fullfile(root, 'src', 'modulos', 'cad_topo');
    if exist(modulo, 'dir') == 7
      addpath(modulo, '-begin');
      rehash();
    endif
  endif
  if exist('aos_cad_abrir_externo_impl', 'file') ~= 2
    error(['No se encontro aos_cad_abrir_externo_impl.m. ' ...
           'La instalacion AOSCAD esta incompleta.']);
  endif
  ok = aos_cad_abrir_externo_impl(varargin{:});
endfunction
