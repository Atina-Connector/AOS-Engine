function modulos = aos_registro_modulos()
% AOS_REGISTRO_MODULOS Registro central de capacidades presentes y futuras.
  modulos = repmat(modulo_local('', '', '', '', false, '', '', '', ''), 0, 1);
  modulos(end+1)=modulo_local('GL_JGL','Gas Lift / Jet Gas Lift','SLA','OPERATIVO',true,'AOS_menu_GL_JGL','GL convencional y JGL propietario AESIR.','0.1.9','PRODUCCION');
  modulos(end+1)=modulo_local('BES','Bombeo Electrosumergible','SLA','DESARROLLO',false,'AOS_menu_BES','BES1, BES2 y BES3.','0.2.x','PRODUCCION');
  modulos(end+1)=modulo_local('BM','Bombeo Mecanico','SLA','OPERATIVO',false,'AOS_menu_BM','Gibbs Foundation 1/2/3.','0.1.9','PRODUCCION');
  modulos(end+1)=modulo_local('PCP','Bombeo por Cavidades Progresivas','SLA','DESARROLLO',false,'AOS_menu_PCP','Arquitectura PCP y LDL.','0.3.x','PRODUCCION');
  modulos(end+1)=modulo_local('LDL','LDL','SLA','DESARROLLO',true,'AOS_menu_LDL','Presion y temperatura de fondo sin sensores.','0.3.x','PRODUCCION');
  modulos(end+1)=modulo_local('CGF','Compresion de Gas en Fondo','SLA','BETA',true,'AOS_menu_CGF','Compresor axial y nucleo electrico.','0.2.x','PRODUCCION');
  modulos(end+1)=modulo_local('EGF','Eductor Gas-Gas de Fondo','SLA','PLANIFICADO',true,'AOS_menu_EGF','Eductor gas-gas.','0.3.x','PRODUCCION');
  modulos(end+1)=modulo_local('WELLS','Pozos, completacion y estado mecanico','WELLS','BETA_ROADMAP',false,'AOS_menu_wells','Survey, punzados, integridad y componentes 3D.','0.2.x','WELLS');
  modulos(end+1)=modulo_local('CAD_TOPO','CAD, topografia y topologia','CAD','DEV1_R16_CANDIDATO',false,'AOS_menu_cad_topologia','DXF, STEP, topologia, lazos, 2D/3D y .aoscad.','0.2.0','INGENIERIA');
  modulos(end+1)=modulo_local('CORE_3D','AOS 3D Core','SERVICE','ACTIVE_DEV1_CANDIDATE',false,'AOS_menu_3d_core','Escena federada, activos 3D, sincronizacion y recursos R16.','0.2.0','GEOMETRIA');
  modulos(end+1)=modulo_local('NETWORKS','Redes hidraulicas y de proceso','NETWORKS','BETA',false,'AOS_menu_networks','Red abierta, dominio selectivo y futuros lazos.','0.2.x','INFRAESTRUCTURA');
  modulos(end+1)=modulo_local('ELECTRICAL','Redes electricas','ELECTRICAL','ROADMAP_CORE_ACTIVE',false,'AOS_menu_electrical','Potencia, motores, cables, VSD y protecciones.','0.2.x','ENERGIA');
  modulos(end+1)=modulo_local('FACILITIES','Instalaciones de superficie','FACILITIES','PLANIFICADO',false,'AOS_menu_facilities','Baterias, planta, balances y restricciones.','0.2.x','INFRAESTRUCTURA');
  modulos(end+1)=modulo_local('GEOLOGY','Geologia y reservorio espacial','GEOLOGY','BETA_ROADMAP',false,'AOS_menu_geology','Geologia, capas, punzados y volumetria.','0.2.x','GEOLOGIA');
  modulos(end+1)=modulo_local('FLUIDOS','AOS Fluids','FLUIDS','BETA_TRANSVERSAL',false,'AOS_menu_fluidos','PVT y propiedades oficiales de fluidos.','0.2.x','FLUIDOS');
  modulos(end+1)=modulo_local('SCADA','SCADA y operacion','SCADA','BETA',false,'AOS_menu_scada','Bandejas, historiales, tags y calibracion.','0.2.x','DATOS');
  modulos(end+1)=modulo_local('ENVIRONMENTAL','AOS Environmental','ENVIRONMENTAL','ROADMAP_RUNTIME_SHELL',false,'AOS_menu_environmental','Emisiones, derrames, H2S, energia, riesgo y trazabilidad por asset_id.','0.3.x','AMBIENTE_HSE');
  modulos(end+1)=modulo_local('INTEGRIDAD','Integridad y confiabilidad','MAINTENANCE','PLANIFICADO',false,'AOS_menu_integridad_confiabilidad','Riesgo, criticidad y vida remanente.','0.3.x','ACTIVOS');
  modulos(end+1)=modulo_local('PULLING','Maintenance y Pulling Intelligence','MAINTENANCE','PLANIFICADO',true,'AOS_menu_mantenimiento_pulling','Scoring y recomendaciones trazables.','0.3.x','MANTENIMIENTO');
  modulos(end+1)=modulo_local('ECONOMIA','Economia y optimizacion','MAINTENANCE','PLANIFICADO',false,'AOS_menu_economia_optimizacion','CAPEX, OPEX, VAN, TIR y campanas.','0.3.x','ECONOMIA');
  modulos(end+1)=modulo_local('DATA','AOS Data','DATA','BETA',false,'AOS_menu_data','Contratos, catalogos e interoperabilidad.','0.2.x','DATOS');
  modulos(end+1)=modulo_local('SOLVERS','AOS Solvers','SOLVERS','TRANSVERSAL',false,'AOS_menu_solvers','Registro cientifico por disciplinas.','0.2.x','CIENCIA');
  modulos(end+1)=modulo_local('GLOBAL','AOS Global','GLOBAL','CONCEPTUAL',false,'AOS_menu_global','Orquestacion integrada del campo.','0.2.x','ORQUESTACION');
  modulos(end+1)=modulo_local('VIEWER','AOS Viewer','VIEWER','ALPHA',false,'AOS_menu_viewer','Visualizacion y distribucion de reportes.','0.2.x','VISUALIZACION');
  modulos(end+1)=modulo_local('INYECTORES','Pozos inyectores','LEGACY_CAPABILITY','PLANIFICADO',false,'AOS_menu_pozos_inyectores','Agua, gas y polimeros.','0.2.x','INYECCION');
  modulos(end+1)=modulo_local('MALLAS','Mallas y niveles','LEGACY_CAPABILITY','PLANIFICADO',false,'AOS_menu_mallas_niveles','Nodos, conexiones y elevaciones.','0.2.x','INFRAESTRUCTURA');
  modulos(end+1)=modulo_local('BATERIAS','Baterias e instalaciones','FACILITIES','PLANIFICADO',false,'AOS_menu_baterias','Separacion, almacenamiento y transferencia.','0.2.x','INFRAESTRUCTURA');
  modulos(end+1)=modulo_local('RED_ELECTRICA','Redes electricas','ELECTRICAL','PLANIFICADO',false,'AOS_menu_redes_electricas','Fuentes, alimentadores, cargas y protecciones.','0.2.x','ENERGIA');
  modulos(end+1)=modulo_local('ARRANQUE','Secuencia de arranque','FACILITIES','PLANIFICADO',false,'AOS_menu_secuencia_arranque','Secuencia integrada de arranque.','0.2.x','OPERACION');
  modulos(end+1)=modulo_local('AMBIENTAL','Gestion ambiental y HSE [alias historico]','ENVIRONMENTAL','COMPATIBILIDAD',false,'AOS_menu_gestion_ambiental','Alias historico; la autoridad funcional es AOS Environmental.','0.3.x','AMBIENTE_HSE');
  modulos(end+1)=modulo_local('INTEGRAL','Analisis integral del yacimiento','GLOBAL','PLANIFICADO',false,'AOS_menu_analisis_integral','Balance integral y escenarios.','0.2.x','ORQUESTACION');
  modulos(end+1)=modulo_local('ROADMAP','Roadmap y arquitectura','PLATAFORMA','OPERATIVO',false,'AOS_menu_roadmap','Gobierno de estados, hitos y dependencias.','0.1.9','GOBIERNO');
endfunction

function m=modulo_local(id,nombre,grupo,estado,propietario,entrada,descripcion,fase,dominio)
  m=struct('id',id,'nombre',nombre,'grupo',grupo,'estado',estado, ...
    'propietario',logical(propietario),'entrada',entrada,'descripcion',descripcion, ...
    'version','0.1.9','fase_objetivo',fase,'dominio',dominio);
endfunction
