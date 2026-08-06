function out = aosbck_estado(accion, valor)
% AOSBCK_ESTADO Estado de sesion del componente AOSBCK activo.
  global AOSBCK_ACTIVO;
  if nargin < 1 || isempty(accion), accion = 'GET'; endif
  accion = upper(char(accion));
  switch accion
    case 'GET'
      if isempty(AOSBCK_ACTIVO) || ~isstruct(AOSBCK_ACTIVO)
        AOSBCK_ACTIVO = struct('paquete','', 'manifest',struct(), ...
          'step_extraido','', 'carpeta_temporal','');
      endif
    case 'SET'
      if nargin < 2 || ~isstruct(valor), error('AOSBCK: SET requiere un struct.'); endif
      AOSBCK_ACTIVO = valor;
    case 'CLEAR'
      if ~isempty(AOSBCK_ACTIVO) && isstruct(AOSBCK_ACTIVO) && ...
          isfield(AOSBCK_ACTIVO,'carpeta_temporal') && ...
          exist(AOSBCK_ACTIVO.carpeta_temporal,'dir') == 7
        try, aos_rmdir_seguro(AOSBCK_ACTIVO.carpeta_temporal, tempdir()); catch, end_try_catch
      endif
      AOSBCK_ACTIVO = struct('paquete','', 'manifest',struct(), ...
        'step_extraido','', 'carpeta_temporal','');
    otherwise
      error('AOSBCK: accion de estado no valida: %s', accion);
  endswitch
  out = AOSBCK_ACTIVO;
endfunction
