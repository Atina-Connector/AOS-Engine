function modelo = aos_cad_hidraulica_invalidar_por_dominio(modelo, accion, detalle)
% Invalida resultados al cambiar dominio o condiciones de sus extremos.
  if nargin < 2 || isempty(accion), accion = 'CAMBIO_DOMINIO_HIDRAULICO'; endif
  if nargin < 3, detalle = ''; endif
  evento = struct();
  evento.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  evento.proceso = 'AOS_SUITE_OCTAVE';
  evento.accion = char(accion);
  evento.detalle = char(detalle);
  evento.resultados_invalidados = true;
  if ~isfield(modelo, 'historial_edicion') || isempty(modelo.historial_edicion)
    modelo.historial_edicion = {evento};
  elseif iscell(modelo.historial_edicion)
    modelo.historial_edicion{end+1} = evento;
  else
    modelo.historial_edicion = {modelo.historial_edicion, evento};
  endif

  if ~isfield(modelo, 'simulacion') || ~isstruct(modelo.simulacion), modelo.simulacion = struct(); endif
  modelo.simulacion.motor = '';
  modelo.simulacion.estado = 'INVALIDADA_POR_EDICION';
  modelo.simulacion.corrida_id = '';
  modelo.simulacion.fecha = '';
  modelo.simulacion.advertencias = {'RESULTADOS_INVALIDADOS_POR_CAMBIO_DE_DOMINIO'};
  modelo.tablas_resultados = struct('nodos', {{}}, 'tramos', {{}}, 'resumen', {{}});
  if ~isfield(modelo, 'validaciones') || ~isstruct(modelo.validaciones), modelo.validaciones = struct(); endif
  modelo.validaciones.estado = 'PENDIENTE';
  modelo.validaciones.items = {struct('codigo', 'RECALCULO_DOMINIO_REQUERIDO', ...
    'mensaje', 'Cambio el dominio hidraulico o sus condiciones de borde; recalcule.', ...
    'severidad', 'ADVERTENCIA')};
  if isfield(modelo, 'info') && isstruct(modelo.info)
    modelo.info.modificado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  endif
endfunction
