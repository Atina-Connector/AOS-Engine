function intervalos = aos_obtener_punzados_activos(geol, param)
% Devuelve solo intervalos activos preservando todos sus metadatos.
  intervalos=aos_punzados_normalizar(struct('tramos',struct([])));
  global CONFIG_ACTIVA geologia;
  candidatos={};
  if nargin>=1&&isstruct(geol)&&isfield(geol,'intervalos')
    candidatos{end+1}=geol.intervalos;
  endif
  if nargin>=2&&isstruct(param)
    if isfield(param,'punzados'),candidatos{end+1}=param.punzados;endif
    if isfield(param,'geologia')&&isstruct(param.geologia)&& ...
       isfield(param.geologia,'intervalos')
      candidatos{end+1}=param.geologia.intervalos;
    endif
  endif
  if isstruct(CONFIG_ACTIVA)
    if isfield(CONFIG_ACTIVA,'punzados'),candidatos{end+1}=CONFIG_ACTIVA.punzados;endif
    if isfield(CONFIG_ACTIVA,'geologia')&&isstruct(CONFIG_ACTIVA.geologia)&& ...
       isfield(CONFIG_ACTIVA.geologia,'intervalos')
      candidatos{end+1}=CONFIG_ACTIVA.geologia.intervalos;
    endif
  endif
  if isstruct(geologia)&&isfield(geologia,'intervalos')
    candidatos{end+1}=geologia.intervalos;
  endif
  for i=1:numel(candidatos)
    [p,~]=aos_punzados_normalizar(candidatos{i});
    if isempty(p.tramos),continue;endif
    mask=[p.tramos.activo];
    p.tramos=p.tramos(mask);
    [intervalos,~]=aos_punzados_normalizar(p);
    return;
  endfor
endfunction
