function intervalos = cargar_intervalos_punzados(opciones)
% CARGAR_INTERVALOS_PUNZADOS Compatibilidad con el gestor transversal HF3.
% Sin argumentos abre el editor sobre un conjunto vacio y devuelve solo los
% cambios confirmados. No modifica CONFIG_ACTIVA ni exige geologia o Survey.
  if nargin < 1 || ~isstruct(opciones), opciones=struct(); endif
  opciones.guardar_global=false;
  if ~isfield(opciones,'punzados_base')
    opciones.punzados_base=struct('tramos',struct([]));
  endif
  if ~isfield(opciones,'origen'), opciones.origen='CARGA_MANUAL'; endif
  [intervalos,info]=aos_punzados_administrar(opciones);
  if ~info.guardado
    intervalos=aos_punzados_normalizar(struct('tramos',struct([])));
  endif
endfunction
