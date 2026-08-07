function [modo,max_iter] = jgl_menu_aproximacion(defecto,max_def)
% JGL_MENU_APROXIMACION Seleccion efectiva del metodo de sensibilidad.
% Respeta el argumento por defecto y las preferencias generales cuando no
% se proporciona uno. GNU Octave es el entorno objetivo.
  prefs=struct();
  try
    prefs=aos_preferencias_usuario('cargar');
  catch
    prefs=struct();
  end_try_catch
  if nargin<1||isempty(defecto)
    defecto='abreviado';
    if isfield(prefs,'solver')&&isfield(prefs.solver,'modo_jgl')
      defecto=lower(prefs.solver.modo_jgl);
    endif
    if isfield(prefs,'sensibilidades')&&isfield(prefs.sensibilidades,'modo_abreviado')&&prefs.sensibilidades.modo_abreviado
      defecto='abreviado';
    endif
  endif
  if nargin<2||isempty(max_def)
    max_def=10;
    if isfield(prefs,'solver')&&isfield(prefs.solver,'max_iter_jgl')&&isfinite(prefs.solver.max_iter_jgl)
      max_def=round(prefs.solver.max_iter_jgl);
    endif
  endif
  opdef=opcion_local(defecto);
  fprintf('\n--- APROXIMACION JGL PARA SENSIBILIDAD ---\n');
  fprintf('1 - Preciso iterativo en todos los puntos\n');
  fprintf('2 - Simple/directo en todos los puntos\n');
  fprintf('3 - Automatico seguro: iterativo uniforme en todos los puntos [FINAL]\n');
  fprintf('4 - Abreviado: directo uniforme reducido [PRELIMINAR, SIN OPTIMO]\n');
  if exist('aos_leer_opcion','file')==2
    op=aos_leer_opcion(sprintf('Seleccione aproximacion [%d]: ',opdef),opdef);
  else
    txt=strtrim(input(sprintf('Seleccione aproximacion [%d]: ',opdef),'s'));
    if isempty(txt),op=opdef;else,op=str2double(txt);endif
  endif
  if op==1
    modo='iterativo';
  elseif op==2
    modo='directo';
  elseif op==3
    modo='automatico';
  else
    modo='abreviado';
  endif
  max_iter=max(1,round(max_def));
  if any(strcmp(modo,{'iterativo','automatico','abreviado'}))
    txt=strtrim(input(sprintf('Maximo de iteraciones del solver preciso [%d]: ',max_iter),'s'));
    if ~isempty(txt)
      v=str2double(txt);
      if isfinite(v),max_iter=max(3,min(100,round(v)));endif
    endif
  endif
endfunction

function op=opcion_local(modo)
  modo=lower(strtrim(modo));
  if strcmp(modo,'iterativo')
    op=1;
  elseif strcmp(modo,'directo')||strcmp(modo,'simple')
    op=2;
  elseif strcmp(modo,'automatico')||strcmp(modo,'hibrido')
    op=3;
  else
    op=4;
  endif
endfunction
