function info = aos_invalidar_resultados(motivo)
% AOS_INVALIDAR_RESULTADOS Invalida resultados transversales del caso.
% No altera entradas fisicas. Limpia resultados y sensibilidades globales,
% marca CONFIG_ACTIVA como obsoleta y registra el motivo.

  if nargin < 1 || isempty(motivo), motivo='Cambio en datos del caso'; endif
  [motivo,okmot]=aos_texto_seguro(motivo,'Cambio en datos del caso');
  if ~okmot,motivo='Cambio en datos del caso';endif

  global CONFIG_ACTIVA;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  global BES2_ULTIMO_RESULTADO BES3_ULTIMO_RESULTADO;
  global CGF_ULTIMO_RESULTADO EGF_ULTIMO_RESULTADO;
  global BES2_ULTIMA_SENSIBILIDAD BES3_ULTIMA_SENSIBILIDAD;
  global CGF_ULTIMA_SENSIBILIDAD EGF_ULTIMA_SENSIBILIDAD;
  global ULTIMO_DIAG_TUBERIA AOS_ULTIMO_DIAGNOSTICO_BES;

  ULTIMO_QL=[];ULTIMO_QO=[];ULTIMO_QINY=[];ULTIMO_TIPO=[];ULTIMO_PARAM=[];
  BES2_ULTIMO_RESULTADO=[];BES3_ULTIMO_RESULTADO=[];
  CGF_ULTIMO_RESULTADO=[];EGF_ULTIMO_RESULTADO=[];
  BES2_ULTIMA_SENSIBILIDAD=[];BES3_ULTIMA_SENSIBILIDAD=[];
  CGF_ULTIMA_SENSIBILIDAD=[];EGF_ULTIMA_SENSIBILIDAD=[];
  ULTIMO_DIAG_TUBERIA=[];AOS_ULTIMO_DIAGNOSTICO_BES=[];

  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA),CONFIG_ACTIVA=struct();endif
  CONFIG_ACTIVA.aos_estado_resultados='RESULTADOS_OBSOLETOS';
  CONFIG_ACTIVA.aos_motivo_invalidacion=motivo;
  CONFIG_ACTIVA.aos_fecha_invalidacion=datestr(now,'yyyy-mm-dd HH:MM:SS');

  nombres_base={'GF3_ULTIMO_RESULTADO','GF3_ULTIMO_REPORTE','ULTIMO_GIBBS2', ...
    'ULTIMO_GIBBS18','ULTIMO_GIBBS_LAB','ULTIMA_SENSIBILIDAD', ...
    'ULTIMO_RESULTADO_SENSIBILIDAD','AOS_ULTIMA_SENSIBILIDAD'};
  for i=1:numel(nombres_base)
    try,evalin('base',sprintf('clear %s',nombres_base{i}));catch,end_try_catch
  endfor

  info=struct('ok',true,'motivo',motivo, ...
    'fecha',CONFIG_ACTIVA.aos_fecha_invalidacion);
endfunction
