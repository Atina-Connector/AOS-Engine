function aos_cad_registrar_mtime(archivo)
% AOS_CAD_REGISTRAR_MTIME Guarda mtime DXF o STEP en CONFIG_ACTIVA.cad_topologia.
  global CONFIG_ACTIVA;
  if nargin < 1 || isempty(archivo), return; endif
  if exist(archivo, 'file') ~= 2, return; endif
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif
  archivo = char(archivo);
  [~, ~, ext] = fileparts(archivo);
  ext = lower(ext);
  mt = aos_cad_mtime(archivo);
  txt = datestr(mt, 'yyyy-mm-dd HH:MM:SS');
  if strcmp(ext, '.step') || strcmp(ext, '.stp')
    CONFIG_ACTIVA.cad_topologia.step_archivo = archivo;
    CONFIG_ACTIVA.cad_topologia.step_mtime = mt;
    CONFIG_ACTIVA.cad_topologia.step_mtime_texto = txt;
  else
    CONFIG_ACTIVA.cad_topologia.dxf_archivo = archivo;
    CONFIG_ACTIVA.cad_topologia.dxf_mtime = mt;
    CONFIG_ACTIVA.cad_topologia.dxf_mtime_texto = txt;
  endif
endfunction
