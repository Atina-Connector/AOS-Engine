function AOS_menu_aosbck_servicio(origen)
% AOS_MENU_AOSBCK Gestion de componentes STEP instanciables.
  if nargin<1||isempty(origen),origen='GENERAL';endif
  while true
    e=aosbck_estado('GET'); activo='NINGUNO';if ~isempty(e.paquete),activo=e.manifest.component.component_id;endif
    fprintf('\n--- AOSBCK COMPONENT BLOCKS R1 [%s] ---\n',upper(origen));fprintf('Activo: %s\n',activo);
    fprintf(' 1 - Crear .aosbck desde STEP\n');
    fprintf(' 2 - Abrir .aosbck existente\n');
    fprintf(' 3 - Ver ficha e instancias\n');
    fprintf(' 4 - Agregar instancia por Survey / MD\n');
    fprintf(' 5 - Tocar nodo AOSCAD y vincular instancia\n');
    fprintf(' 6 - Agregar instancia por coordenadas XYZ\n');
    fprintf(' 7 - Visualizar componente o instancia en FreeCAD\n');
    fprintf(' 8 - Definir puerto de conexion [BETA]\n');
    fprintf(' 9 - Validar paquete activo\n');
    fprintf('10 - Ver contrato AOSBCK y arquitectura\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, aosbck_crear_interactivo();
      case 2, aosbck_abrir([],false);
      case 3, aosbck_listar();
      case 4, instancia_survey_local();
      case 5, instancia_aoscad_local();
      case 6, instancia_xyz_local();
      case 7, aosbck_visualizar();
      case 8, puerto_local();
      case 9, e=aosbck_estado('GET');if isempty(e.paquete),fprintf('No hay paquete activo.\n');else,aosbck_validar(e.manifest,e.carpeta_temporal,true);endif
      case 10, contrato_local();
      case 0, break;
      otherwise,fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function instancia_survey_local()
  md=input('MD [m]: ');roll=input('Rotacion axial [deg, 0]: ');if isempty(roll),roll=0;endif
  p=aosbck_ubicacion_survey(md,roll,'');datos=datos_instancia_local();id=strtrim(input('Instance ID [automatico]: ','s'));aosbck_agregar_instancia(p,datos,id,false);
endfunction
function instancia_aoscad_local()
  idn=aosbck_seleccionar_nodo_aoscad('GRAFICO');roll=input('Rotacion axial [deg, 0]: ');if isempty(roll),roll=0;endif
  p=aosbck_ubicacion_aoscad(idn,roll);datos=datos_instancia_local();id=strtrim(input('Instance ID [automatico]: ','s'));aosbck_agregar_instancia(p,datos,id,false);
endfunction
function instancia_xyz_local()
  x=input('X [m]: ');y=input('Y [m]: ');z=input('Z [m]: ');az=input('Azimut [deg, 0]: ');if isempty(az),az=0;endif
  inc=input('Inclinacion [deg, 0]: ');if isempty(inc),inc=0;endif;roll=input('Roll [deg, 0]: ');if isempty(roll),roll=0;endif
  p=struct('source','XYZ_MANUAL','position_m',[x y z],'coordinate_convention','RIGHT_HANDED_Z_UP', ...
    'inclination_deg',inc,'azimuth_deg',az,'roll_deg',roll,'orientation_quaternion_wxyz',aosbck_quaternion_zyx(az,inc,roll),'source_reference','USER_INPUT');
  datos=datos_instancia_local();id=strtrim(input('Instance ID [automatico]: ','s'));aosbck_agregar_instancia(p,datos,id,false);
endfunction
function d=datos_instancia_local()
  d=struct();d.serial_number=strtrim(input('Numero de serie [opcional]: ','s'));d.lot_number=strtrim(input('Lote [opcional]: ','s'));
  d.installation_date=strtrim(input('Fecha instalacion [opcional]: ','s'));d.status=strtrim(input('Estado [INSTALLED]: ','s'));if isempty(d.status),d.status='INSTALLED';endif
  d.notes=strtrim(input('Observaciones [opcional]: ','s'));
endfunction
function puerto_local()
  d=struct();d.port_id=strtrim(input('Puerto ID [automatico]: ','s'));d.type=strtrim(input('Tipo FLUID/ELECTRICAL/MECHANICAL [FLUID]: ','s'));if isempty(d.type),d.type='FLUID';endif
  d.nominal_size=strtrim(input('Tamano nominal: ','s'));d.connection_standard=strtrim(input('Norma/conexion: ','s'));aosbck_agregar_puerto(d,false);
endfunction
function contrato_local()
  fprintf('\nSTEP = geometria neutra de origen.\n');fprintf('AOSBCK = componente reutilizable: una geometria, metadatos, puertos e instancias.\n');
  fprintf('Survey o AOSCAD = fuente de ubicacion. AOS 3D Core = visualizacion bajo demanda.\n');
  fprintf('Las 200 cuplas iguales comparten un STEP y conservan 200 instance_id.\n');
  fprintf('El ensamblaje 3D completo permanece en roadmap; R1 no duplica ni carga todos los solidos.\n');
endfunction
