function aos_modulo_no_disponible(id, accion)
% Muestra un estado honesto y los datos importados sin simular una funcion inexistente.
  if nargin < 2 || isempty(accion), accion = 'Funcion seleccionada'; endif
  m = aos_modulo_obtener(id);
  fprintf('\n============================================================\n');
  if isempty(fieldnames(m))
    fprintf('MODULO NO REGISTRADO: %s\n', id);
  else
    fprintf('%s\n', upper(m.nombre));
    fprintf('Estado                 : %s\n', m.estado);
    fprintf('Version de contrato    : %s\n', m.version);
    if isfield(m,'fase_objetivo'), fprintf('Fase objetivo          : %s\n',m.fase_objetivo); endif
    fprintf('Propietario AESIR      : %s\n', si_no_local(m.propietario));
    fprintf('Accion                  : %s\n', accion);
    fprintf('Descripcion             : %s\n', m.descripcion);
  endif
  fprintf('Interfaz de menu       : instalada\n');
  fprintf('Importacion AOSDAT     : habilitada e indiferenciada\n');
  fprintf('Solver fisico          : no publicado para esta accion\n');
  mostrar_datos_local(id);
  fprintf('============================================================\n');
endfunction

function mostrar_datos_local(id)
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('Datos activos           : no hay caso cargado\n');
    return;
  endif
  aliases = aliases_local(id);
  for i = 1:numel(aliases)
    campo = aliases{i};
    if isfield(CONFIG_ACTIVA, campo)
      v = CONFIG_ACTIVA.(campo);
      if isstruct(v)
        fprintf('Datos activos           : seccion %s cargada (%d campos)\n', campo, numel(fieldnames(v)));
      else
        fprintf('Datos activos           : campo %s cargado\n', campo);
      endif
      return;
    endif
  endfor
  fprintf('Datos activos           : el AOSDAT no contiene una seccion reconocida para %s\n', id);
endfunction

function a = aliases_local(id)
  switch upper(id)
    case 'LDL', a = {'ldl','pcp_ldl'};
    case 'PCP', a = {'pcp'};
    case 'INYECTORES', a = {'inyectores','pozos_inyectores','inyeccion_agua','inyeccion_gas','inyeccion_polimeros'};
    case 'MALLAS', a = {'mallas','malla','niveles'};
    case 'BATERIAS', a = {'baterias','instalaciones'};
    case 'FLUIDOS', a = {'fluidos','aseguramiento_flujo'};
    case 'RED_ELECTRICA', a = {'red_electrica','redes_electricas'};
    case 'ARRANQUE', a = {'arranque','secuencia_arranque'};
    case 'SCADA', a = {'scada'};
    case 'CAD_TOPO', a = {'cad_topologia','cad','dxf','step','topologia','topografia'};
    case {'ENVIRONMENTAL','AMBIENTAL'}, a = {'environmental','ambiental','gestion_ambiental','hse','emisiones'};
    case 'INTEGRIDAD', a = {'integridad','confiabilidad','corrosion','inspecciones'};
    case 'PULLING', a = {'mantenimiento','pulling','intervenciones','workover'};
    case 'ECONOMIA', a = {'economia','optimizacion','capex_opex'};
    otherwise, a = {lower(id)};
  endswitch
endfunction

function s = si_no_local(v)
  if v, s = 'SI'; else, s = 'NO'; endif
endfunction
