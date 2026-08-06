function aos_cad_hidraulica_menu()
% Submenu visible del nucleo hidraulico AOSCAD.
  while true
    mostrar_estado_local();
    fprintf('\n--- SIMULACION HIDRAULICA AOSCAD 0.0.1 DEV1 R9.1 ---\n');
    fprintf(' 1 - Preparar/actualizar modelo hidraulico desde DXF activo\n');
    fprintf(' 2 - SELECCIONAR DOMINIO: inicio, fin, camino o anillo\n');
    fprintf(' 3 - Configurar solver y fluido\n');
    fprintf(' 4 - Ver configuracion efectiva y modelos disponibles\n');
    fprintf(' 5 - Validar dominio/red y condiciones de borde\n');
    fprintf(' 6 - Ejecutar simulacion hidraulica\n');
    fprintf(' 7 - Ver resumen de resultados\n');
    fprintf(' 8 - Ver tabla de resultados nodales\n');
    fprintf(' 9 - Ver tabla de resultados por tramo\n');
    fprintf('10 - Ver todas las tablas hidraulicas\n');
    fprintf('11 - Colorear resultados sobre el modelo\n');
    fprintf('12 - Guardar .aoscad simple\n');
    fprintf('13 - Guardar .aoscad enriquecido\n');
    fprintf('14 - Flujo completo: simular + guardar simple y enriquecido\n');
    fprintf('15 - Ejecutar selftest hidraulico DXF\n');
    fprintf('16 - Ejecutar selftest dominio selectivo\n');
    fprintf('17 - Ejecutar simulacion hidraulica DEMO heredada\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, try_local(@() aos_cad_hidraulica_preparar_modelo(false));
      case 2, try_local(@() aos_cad_hidraulica_dominio_menu());
      case 3, try_local(@() aos_cad_hidraulica_configurar());
      case 4, try_local(@() aos_cad_hidraulica_mostrar_config());
      case 5, try_local(@() aos_cad_hidraulica_dominio_validar(false));
      case 6, try_local(@() aos_cad_hidraulica_ejecutar(false));
      case 7, try_local(@() aos_cad_hidraulica_mostrar_resultados('RESUMEN'));
      case 8, try_local(@() aos_cad_hidraulica_mostrar_resultados('NODOS'));
      case 9, try_local(@() aos_cad_hidraulica_mostrar_resultados('TRAMOS'));
      case 10, try_local(@() aos_cad_hidraulica_mostrar_resultados('TODO'));
      case 11, try_local(@() aos_cad_visor_2d(true, false));
      case 12, try_local(@() aos_aoscad_escribir([], 'SIMPLE', false));
      case 13, try_local(@() aos_cad_hidraulica_guardar_enriquecido());
      case 14, try_local(@() aos_cad_hidraulica_flujo_completo());
      case 15, try_local(@() ejecutar_selftest_local());
      case 16, try_local(@() ejecutar_selftest_dominio_local());
      case 17, try_local(@() aos_cad_eval_hidraulica_demo(false));
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_estado_local()
  global CONFIG_ACTIVA;
  dxf = 'NO CARGADO'; estado = 'SIN MODELO'; dominio = 'RED COMPLETA';
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) && ...
      isfield(CONFIG_ACTIVA, 'cad_topologia')
    cad = CONFIG_ACTIVA.cad_topologia;
    if isfield(cad, 'dxf_archivo') && ~isempty(cad.dxf_archivo)
      dxf = char(cad.dxf_archivo);
    elseif isfield(cad, 'archivo_dxf') && ~isempty(cad.archivo_dxf)
      dxf = char(cad.archivo_dxf);
    endif
    if isfield(cad, 'modelo_aoscad') && isstruct(cad.modelo_aoscad)
      modelo = cad.modelo_aoscad;
      [d, ~] = aos_cad_hidraulica_dominio_activo(modelo);
      if ~isempty(d)
        dominio = sprintf('%s | %s -> %s | %s', char(d.id), char(d.nodo_inicio), ...
          char(d.nodo_fin), char(d.tipo));
      endif
      if isfield(modelo, 'simulacion') && isstruct(modelo.simulacion) && ...
          isfield(modelo.simulacion, 'estado') && ~isempty(modelo.simulacion.estado)
        estado = char(modelo.simulacion.estado);
      else
        estado = 'MODELO PREPARADO / SIN CORRIDA';
      endif
    endif
  endif
  fprintf('\nEstado DXF : %s\n', dxf);
  fprintf('Dominio    : %s\n', dominio);
  fprintf('Estado HID : %s\n', estado);
endfunction

function ejecutar_selftest_local()
  ok = test_aos_cad_hidraulica_dxf();
  if ~ok, error('El selftest hidraulico DXF no fue aprobado.'); endif
endfunction
function ejecutar_selftest_dominio_local()
  ok = test_aos_cad_dominio_hidraulico();
  if ~ok, error('El selftest de dominio hidraulico no fue aprobado.'); endif
endfunction
function try_local(fn)
  try, fn(); catch err, fprintf(2, 'Error HIDRAULICA AOSCAD: %s\n', err.message); end_try_catch
endfunction
