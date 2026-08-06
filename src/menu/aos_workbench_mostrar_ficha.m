function aos_workbench_mostrar_ficha(id)
% AOS_WORKBENCH_MOSTRAR_FICHA Muestra contrato, estado y siguiente hito.
  p = aos_suite_producto_obtener(id);
  if isempty(fieldnames(p))
    fprintf('Banco de trabajo no registrado: %s\n', id);
    return;
  endif
  fprintf('\n============================================================\n');
  fprintf('%s\n', upper(p.nombre));
  fprintf('Version                 : %s\n', p.version);
  fprintf('Estado                  : %s\n', p.estado);
  fprintf('Grupo de cinta          : %s\n', p.ribbon_group);
  fprintf('Entrada                 : %s\n', p.entrada);
  fprintf('Disponible              : %s\n', si_no_local(p.disponible));
  fprintf('Descripcion             : %s\n', p.descripcion);
  mostrar_roadmap_local(id);
  fprintf('============================================================\n');
endfunction

function mostrar_roadmap_local(id)
  switch upper(id)
    case 'WELLS'
      fprintf('Hito actual             : survey, punzados y trayectoria 3D basica.\n');
      fprintf('Siguiente hito          : estado mecanico con componentes 3D vinculados.\n');
    case 'NETWORKS'
      fprintf('Hito actual             : red abierta y dominio hidraulico selectivo.\n');
      fprintf('Siguiente hito          : ramales, balances nodales y anillos tipo Kirchhoff.\n');
    case 'ELECTRICAL'
      fprintf('Hito actual             : nucleo motor/cable/VSD usado por BES y CGF.\n');
      fprintf('Siguiente hito          : red electrica y flujo de carga.\n');
    case 'FACILITIES'
      fprintf('Hito actual             : contratos de instalaciones y datos importados.\n');
      fprintf('Siguiente hito          : balances, capacidades y restricciones de planta.\n');
    case 'GEOLOGY'
      fprintf('Hito actual             : geologia manual, punzados y riesgo generico.\n');
      fprintf('Siguiente hito          : superficies, capas y modelo espacial.\n');
    case 'FLUIDS'
      fprintf('Hito actual             : PVT comun y propiedades basicas reutilizadas.\n');
      fprintf('Siguiente hito          : modelo de fluido persistente y calibrable.\n');
    case 'SCADA'
      fprintf('Hito actual             : bandejas AOSDAT y receptor por carpeta.\n');
      fprintf('Siguiente hito          : historiales, tags y calibracion trazable.\n');
    case 'ENVIRONMENTAL'
      fprintf('Hito actual             : entrypoint independiente y vinculacion por asset_id.\n');
      fprintf('Siguiente hito          : contratos de fuentes, eventos, mediciones, energia y riesgo.\n');
    case 'MAINTENANCE'
      fprintf('Hito actual             : contrato de scoring y recomendaciones.\n');
      fprintf('Siguiente hito          : Pulling Intelligence operativo.\n');
    case 'SOLVERS'
      fprintf('Hito actual             : registro por disciplina y benchmarks disponibles.\n');
      fprintf('Siguiente hito          : API estable de solver y orquestacion multifisica.\n');
    case 'GLOBAL'
      fprintf('Hito actual             : arquitectura conceptual y contratos.\n');
      fprintf('Siguiente hito          : acople pozo-red-instalaciones.\n');
    otherwise
      fprintf('Roadmap                 : consultar ROADMAP GENERAL DE AOS.\n');
  endswitch
endfunction

function s = si_no_local(v)
  if v, s = 'SI'; else, s = 'NO'; endif
endfunction
