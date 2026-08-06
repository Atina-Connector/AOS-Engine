function AOS_menu_formatos_externos()
  while true
    fprintf('\n--- FORMATOS EXTERNOS Y PLANILLAS ---\n');
    fprintf('1 - Importar pozos desde CSV\n');
    fprintf('2 - Importar desde Prosper [ADAPTADOR PLANIFICADO]\n');
    fprintf('3 - Importar desde Pipesim [ADAPTADOR PLANIFICADO]\n');
    fprintf('4 - Importar desde WellFlo [ADAPTADOR PLANIFICADO]\n');
    fprintf('5 - Importar survey ASCII [PLANIFICADO]\n');
    fprintf('6 - Exportar hacia formatos externos [PLANIFICADO]\n');
    fprintf('7 - CAD 2D: DXF / LibreCAD [PLANIFICADO]\n');
    fprintf('8 - CAD 3D: STEP / FreeCAD [PLANIFICADO]\n');
    fprintf('9 - Topologia AOS (.aostopo / JSON) [PLANIFICADO]\n');
    fprintf('0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, importar_pozos;
      case {2,3,4,5,6}, fprintf('Adaptador instalado en el menu; implementacion pendiente de contrato del formato.\n');
      case 7, AOS_menu_cad_topologia();
      case 8, AOS_menu_cad_topologia();
      case 9, aos_modulo_no_disponible('CAD_TOPO','Intercambio de topologia AOS');
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction
