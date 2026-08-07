function AOS_menu_aosbck(varargin)
% AOS_MENU_AOSBCK Punto publico para el servicio AOSBCK.
  raiz=fileparts(fileparts(mfilename('fullpath')));
  servicio=fullfile(raiz,'services','aosbck');
  if exist(servicio,'dir')==7,addpath(servicio,'-begin');endif
  AOS_menu_aosbck_servicio(varargin{:});
endfunction
