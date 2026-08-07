function s = aos_solvers_registro()
% AOS_SOLVERS_REGISTRO Catalogo cientifico transversal AOS 0.2.0 DEV1.
  s = repmat(item_local('', '', '', '', '', '', '', '', ''), 0, 1);
  s(end+1)=item_local('HYD_DARCY','Darcy-Weisbach monofasico','HYDRAULIC','BETA','1.0','aos_cad_hidraulica_evaluar_monofasico','NETWORKS','','Redes abiertas y tramos.');
  s(end+1)=item_local('HYD_HB','Hagedorn-Brown','HYDRAULIC','BETA','1.0','vlp_HB_full','SLA','','Flujo multifasico vertical/desviado.');
  s(end+1)=item_local('HYD_DR','Duns & Ros','HYDRAULIC','BETA','1.0','vlp_duns_ros','SLA','','Flujo multifasico.');
  s(end+1)=item_local('HYD_SIMPLE','VLP simplificado corregido','HYDRAULIC','BETA','1.0','vlp_simplified_corregida','SLA','','Exploracion y comparacion.');
  s(end+1)=item_local('HYD_TREE','Red abierta tipo arbol','HYDRAULIC','DEV1','0.0.1','aos_cad_hidraulica_resolver','NETWORKS','test_aos_cad_hidraulica_dxf','Una fuente de presion y demandas.');
  s(end+1)=item_local('HYD_DOMAIN','Camino hidraulico seleccionado','HYDRAULIC','DEV1','0.0.1','aos_cad_hidraulica_dominio_filtrar_modelo','NETWORKS','test_aos_cad_dominio_hidraulico','Nodo inicial, final y camino.');
  s(end+1)=item_local('HYD_LOOP','Anillos tipo Kirchhoff','HYDRAULIC','DESARROLLO','0.0.1-R16','aos_cad_hidraulica_resolver_lazos','NETWORKS','test_hyd_loop_selftest','Balance nodal y de lazos; candidato R16 no promovido a BETA.');
  s(end+1)=item_local('ELEC_PM','Motor de imanes permanentes','ELECTRICAL','BETA','1.0','aos_motor_pm_evaluar','ELECTRICAL','','Nucleo BES/CGF.');
  s(end+1)=item_local('ELEC_CABLE','Cable electrico de fondo','ELECTRICAL','BETA','1.0','aos_cable_evaluar','ELECTRICAL','','Caida y termica.');
  s(end+1)=item_local('ELEC_VSD','Variador de velocidad','ELECTRICAL','BETA','1.0','aos_vsd_evaluar','ELECTRICAL','','Potencia y frecuencia.');
  s(end+1)=item_local('ELEC_LOADFLOW','Flujo de carga de red','ELECTRICAL','ROADMAP','0.2.x','','ELECTRICAL','','Presiones analogas: nodos, ramas y cargas.');
  s(end+1)=item_local('MECH_GIBBS1','Gibbs Foundation 1','MECHANICAL','OPERATIVO','18','gibbs18_run_case','SLA','','Bombeo mecanico.');
  s(end+1)=item_local('MECH_GIBBS2','Gibbs Foundation 2','MECHANICAL','BETA','2','gibbs2_run_case','SLA','','Dinamico/cuasiestatico y amortiguamiento.');
  s(end+1)=item_local('MECH_GIBBS3','Gibbs Foundation 3','MECHANICAL','BETA','3.3','gibbs3_run_case','SLA','test_gf3_signo_tuberia_libre_hf3_3','Sarta, barras, spacing y signo fisico de tubing libre.');
  s(end+1)=item_local('THERM_DOWNHOLE','Termica de fondo','THERMAL','BETA','1.0','aos_termica_fondo','ELECTRICAL','','Motor y cable.');
  s(end+1)=item_local('THERM_COUPLED','Termo-hidraulico acoplado','THERMAL','ROADMAP','0.2.x','','GLOBAL','','Acople P-T y propiedades.');
  s(end+1)=item_local('GEO_CONING','Conificacion generica','GEOLOGICAL','BETA','1.0','aos_conificacion_generica','GEOLOGY','','Screening geologico.');
  s(end+1)=item_local('GEO_CRITICAL','Caudales criticos geologicos','GEOLOGICAL','BETA','1.0','calcular_caudales_criticos','GEOLOGY','','Arena, conificacion y erosion.');
  s(end+1)=item_local('GEO_GRID','Grillas y superficies','GEOLOGICAL','ROADMAP','0.2.x','','GEOLOGY','','Modelo espacial.');
  s(end+1)=item_local('RES_IPR','IPR Linear/Vogel/Fetkovich','RESERVOIR','BETA','1.0','ipr','SLA','','Afluencia de reservorio.');
  s(end+1)=item_local('RES_BALANCE','Balance de materiales','RESERVOIR','ROADMAP','0.2.x','','GEOLOGY','','Modelo tanque.');
  s(end+1)=item_local('PROD_JGL_ITER','JGL iterativo','PRODUCTION','BETA','1.0','jgl_solver_iterativo','SLA','','Referencia fisica.');
  s(end+1)=item_local('PROD_JGL_DIRECT','JGL directo','PRODUCTION','BETA','1.0','jgl_solver_directo','SLA','','Exploracion.');
  s(end+1)=item_local('PROD_BES2','BES V2','PRODUCTION','BETA','2','bes2_solver','SLA','','Solver BES foundation.');
  s(end+1)=item_local('PROD_BES3','BES3','PRODUCTION','DESARROLLO','3','bes3_solver','SLA','bes3_selftest','Recirculacion, capilar y flujo natural.');
  s(end+1)=item_local('PROD_CGF','Compresion de Gas en Fondo','PRODUCTION','BETA','1','cgf_solver','SLA','','Compresor axial PM.');
  s(end+1)=item_local('MULTI_GLOBAL','Acople multifisico global','MULTIPHYSICS','ROADMAP','0.2.x','','GLOBAL','','Orquestacion de solvers.');
  s(end+1)=item_local('GRAPH_PATH','Busqueda de caminos','NETWORK_GRAPH','DEV1','0.0.1','aos_cad_hidraulica_encontrar_caminos','NETWORKS','','Caminos simples y alternativos.');
  s(end+1)=item_local('GRAPH_LOOP','Deteccion y resolucion de lazos','NETWORK_GRAPH','DESARROLLO','0.0.1-R16','aos_cad_hidraulica_lazos_base','NETWORKS','test_aos_cad_red_lazos','Anillos y ciclos; candidato R16 no promovido a BETA.');
  s(end+1)=item_local('OPT_SENS','Sensibilidades AOS','OPTIMIZATION','BETA','1.0','menu_sensibilidad','SLA','','Barridos y comparacion.');
  s(end+1)=item_local('OPT_GLOBAL','Optimizacion global de campo','OPTIMIZATION','ROADMAP','0.2.x','','GLOBAL','','Restricciones y objetivos.');
  s(end+1)=item_local('ECON_NPV','VAN, TIR y payback','ECONOMICS','ROADMAP','0.3.x','','MAINTENANCE','','Evaluacion economica.');
  s(end+1)=item_local('REL_PULLING','Scoring de pulling','RELIABILITY','ROADMAP','0.3.x','','MAINTENANCE','','Score 0-100 y reglas obligatorias.');
  s(end+1)=item_local('FLUID_PVT','PVT Black Oil comun','FLUIDS','BETA','1.0','pvt_calcular','FLUIDS','','Propiedades reutilizadas por SLA y redes.');
  s(end+1)=item_local('FLUID_GAS','Propiedades de gas','FLUIDS','BETA','1.0','aos_gas_props','FLUIDS','','Gas seco y mezclas simplificadas.');
endfunction

function x=item_local(id,nombre,disciplina,estado,version,entrada,owner,selftest,descripcion)
  disponible = isempty(entrada) || exist(entrada,'file')==2;
  x=struct('id',id,'nombre',nombre,'disciplina',disciplina,'estado',estado, ...
    'version',version,'entrada',entrada,'owner',owner,'selftest',selftest, ...
    'descripcion',descripcion,'disponible',logical(disponible));
endfunction
