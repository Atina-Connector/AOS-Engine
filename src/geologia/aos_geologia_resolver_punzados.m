function [candidata, info] = aos_geologia_resolver_punzados(actual, candidata, modo)
% AOS_GEOLOGIA_RESOLVER_PUNZADOS Aplica una politica explicita sin perder metadatos.
% Modos: CONSERVAR_ACTUALES, USAR_NUEVOS, FUSIONAR, ELIMINAR.
  if nargin < 1 || ~isstruct(actual), actual=struct(); endif
  if nargin < 2 || ~isstruct(candidata), candidata=struct(); endif
  if nargin < 3, modo='CONSERVAR_ACTUALES'; endif
  [modo,ok]=aos_texto_seguro(modo,'CONSERVAR_ACTUALES');
  if ~ok, modo='CONSERVAR_ACTUALES'; endif
  modo=upper(strtrim(modo));

  pa=obtener_local(actual);
  pn=obtener_local(candidata);
  info=struct('modo',modo,'n_actuales',numel(pa.tramos), ...
    'n_nuevos',numel(pn.tramos),'n_salida',0,'n_finales',0, ...
    'avisos',{{}});

  switch modo
    case 'CONSERVAR_ACTUALES'
      final=pa;
    case 'USAR_NUEVOS'
      final=pn;
    case 'FUSIONAR'
      [final,opinfo]=aos_punzados_operacion(pa,'FUSIONAR',pn);
      info.avisos=opinfo.avisos;
    case 'ELIMINAR'
      final=aos_punzados_normalizar(struct('tramos',struct([])));
    otherwise
      error('Politica de punzados no reconocida: %s',modo);
  endswitch

  candidata.intervalos=final;
  info.n_salida=numel(final.tramos);
  info.n_finales=info.n_salida;
endfunction

function p=obtener_local(g)
  p=struct('tramos',struct([]));
  if isstruct(g)&&isfield(g,'intervalos')
    p=g.intervalos;
  endif
  [p,~]=aos_punzados_normalizar(p);
endfunction
