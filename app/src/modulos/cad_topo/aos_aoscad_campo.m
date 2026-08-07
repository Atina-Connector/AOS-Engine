function c = aos_aoscad_campo(valor, unidad, origen, usuario_o_proceso, advertencia)
% AOS_AOSCAD_CAMPO Campo editable con trazabilidad AOSCAD-0.0.1-DEV1.
  if nargin < 1, valor = []; endif
  if nargin < 2 || isempty(unidad), unidad = ''; endif
  if nargin < 3 || isempty(origen), origen = 'DEFAULT_MODULO'; endif
  if nargin < 4 || isempty(usuario_o_proceso), usuario_o_proceso = 'AOSCAD_OCTAVE'; endif
  if nargin < 5, advertencia = ''; endif
  c = struct();
  c.valor_original = valor;
  c.valor_editado = [];
  c.unidad = char(unidad);
  c.origen = char(origen);
  c.fecha = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  c.usuario_o_proceso = char(usuario_o_proceso);
  c.estado_de_validacion = 'PENDIENTE';
  c.advertencia = char(advertencia);
endfunction
