function aos_cad_hidraulica_dominio_menu()
% Submenu de seleccion de camino/subred entre nodos del DXF.
  while true
    fprintf('\n--- DOMINIO HIDRAULICO SELECTIVO R9 ---\n');
    fprintf(' 1 - Seleccionar inicio y fin tocando el plano\n');
    fprintf(' 2 - Seleccionar inicio y fin por ID de nodo\n');
    fprintf(' 3 - Definir/editar condiciones de los extremos\n');
    fprintf(' 4 - Ver dominio activo y tabla de tramos\n');
    fprintf(' 5 - Visualizar dominio sobre la red completa\n');
    fprintf(' 6 - Validar dominio para el solver\n');
    fprintf(' 7 - Desactivar dominio y volver a red completa\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        try_local(@() aos_cad_hidraulica_dominio_seleccionar('GRAFICO', false));
      case 2
        try_local(@() aos_cad_hidraulica_dominio_seleccionar('TEXTO', false));
      case 3
        try_local(@() definir_condiciones_menu_local());
      case 4
        try_local(@() aos_cad_hidraulica_dominio_mostrar(false));
      case 5
        try_local(@() visualizar_local());
      case 6
        try_local(@() aos_cad_hidraulica_dominio_validar(false));
      case 7
        try_local(@() aos_cad_hidraulica_dominio_limpiar(false));
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function definir_condiciones_menu_local()
% Elige el modo antes de pedir valores. Sin fisica en el menu.
  fprintf('\n--- MODO DE CONDICIONES DE EXTREMOS ---\n');
  fprintf('Cada modo fija que se conoce y que resuelve el solver:\n');
  fprintf(' 1 - P_INICIO_Q_FIN  | conocidas: P inicio, Q fin     | incognita: P a lo largo\n');
  fprintf(' 2 - Q_INICIO_P_FIN  | conocidas: Q inicio, P fin     | incognita: P a lo largo\n');
  fprintf(' 3 - P_INICIO_P_FIN  | conocidas: P inicio y P fin    | incognita: Q (biseccion)\n');
  fprintf('     (P-P solo en SELECTED_PATH / camino simple)\n');
  texto = input('Seleccione modo [1]: ', 's');
  if isempty(strtrim(texto))
    modo = 'P_INICIO_Q_FIN';
  else
    op = round(str2double(texto));
    if op == 2
      modo = 'Q_INICIO_P_FIN';
    elseif op == 3
      modo = 'P_INICIO_P_FIN';
    else
      modo = 'P_INICIO_Q_FIN';
    endif
  endif
  aos_cad_hidraulica_dominio_definir_condiciones(modo, [], [], [], false);
endfunction

function visualizar_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA) || ...
      ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ...
      ~isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    error('No hay modelo activo.');
  endif
  [dominio, ~] = aos_cad_hidraulica_dominio_activo( ...
    CONFIG_ACTIVA.cad_topologia.modelo_aoscad);
  aos_cad_hidraulica_dominio_visualizar( ...
    dominio, 'AOSCAD - dominio hidraulico activo');
endfunction

function try_local(fn)
  try
    fn();
  catch err
    fprintf(2, 'Error DOMINIO AOSCAD: %s\n', err.message);
  end_try_catch
endfunction
