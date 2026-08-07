function AOS_menu_gestion_caso(contexto)
% AOS_MENU_GESTION_CASO Entrada transversal para abrir, importar y configurar.
% Restaura la gestion de casos disponible antes de la division por workbenches.
  if nargin < 1 || isempty(contexto), contexto = 'SUITE'; endif
  contexto = upper(char(contexto));
  while true
    imprimir_estado_local(contexto);
    fprintf('\n--- GESTION DEL CASO / IMPORTAR / CONFIGURAR ---\n');
    fprintf(' 1 - Importar modelo AOS (.aosdat) y dejarlo activo\n');
    fprintf(' 2 - Abrir reporte AOS (.aosrpt), visualizar o reconstruir caso\n');
    fprintf(' 3 - Exportar configuracion activa a .aosdat\n');
    fprintf(' 4 - Abrir/importar proyecto CAD: .aoscad, DXF, STEP o AOSBCK\n');
    fprintf(' 5 - Configuracion general y configuracion efectiva del caso\n');
    fprintf(' 6 - Survey, punzados, geologia y estado mecanico\n');
    fprintf(' 7 - Catalogos base, permanentes y embebidos en .aosdat\n');
    fprintf(' 8 - Galerias: mandriles .aosdat y galerias CAD/DXF\n');
    fprintf(' 9 - Formatos externos y planillas\n');
    fprintf('10 - Reportes y AOS Viewer\n');
    fprintf('11 - Ver resumen completo del caso activo\n');
    fprintf('12 - Descartar caso y resultados activos de memoria\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1
        try_local(@() importar_aosdat());
      case 2
        try_local(@() importar_aosrpt());
      case 3
        exportar_activo_local();
      case 4
        menu_cad_local();
      case 5
        AOS_menu_configuracion();
      case 6
        AOS_menu_datos_pozo();
      case 7
        AOS_menu_catalogos();
      case 8
        AOS_menu_galerias();
      case 9
        AOS_menu_formatos_externos();
      case 10
        AOS_menu_reportes();
      case 11
        mostrar_activo_local();
      case 12
        descartar_local();
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function imprimir_estado_local(contexto)
  global CONFIG_ACTIVA AOSDAT_ACTIVO;
  fprintf('\nContexto      : %s\n', contexto);
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('Caso activo    : NINGUNO\n');
    fprintf('Estado         : SIN CONFIGURACION\n');
    return;
  endif
  nombre = obtener_texto_local(CONFIG_ACTIVA, ...
    {'nombre_pozo','pozo_nombre','well_name','nombre','id_pozo', ...
     'valor_original_pozo','archivo_aosdat','aosdat_archivo','pozo'}, ...
    'CASO_SIN_NOMBRE');
  fprintf('Caso activo    : %s\n', nombre);
  [origen, origen_ok] = aos_texto_seguro(AOSDAT_ACTIVO, 'MEMORIA / OTRO FORMATO');
  if ~origen_ok, origen = 'MEMORIA / OTRO FORMATO'; endif
  fprintf('Origen         : %s\n', origen);
  fprintf('Campos         : %d\n', numel(fieldnames(CONFIG_ACTIVA)));
  if isfield(CONFIG_ACTIVA,'aosdat_sections') && isstruct(CONFIG_ACTIVA.aosdat_sections)
    fprintf('Secciones      : %d\n', numel(fieldnames(CONFIG_ACTIVA.aosdat_sections)));
  endif
endfunction

function exportar_activo_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('No hay configuracion activa para exportar.\n');
    return;
  endif
  try_local(@() exportar_aosdat(CONFIG_ACTIVA));
endfunction

function menu_cad_local()
  while true
    fprintf('\n--- ABRIR / IMPORTAR CAD Y 3D ---\n');
    fprintf(' 1 - Abrir .aoscad en AOS Suite\n');
    fprintf(' 2 - Importar DXF\n');
    fprintf(' 3 - Importar STEP\n');
    fprintf(' 4 - Abrir o administrar componente .aosbck\n');
    fprintf(' 5 - Abrir banco AOS CAD completo\n');
    fprintf(' 6 - Galerias CAD / DXF\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione: ',[]);
    switch op
      case 1, try_local(@() aos_aoscad_abrir_en_suite([], false));
      case 2, try_local(@() aos_cad_importar_dxf());
      case 3, try_local(@() aos_cad_importar_step());
      case 4, AOS_menu_aosbck('DATA');
      case 5, AOS_menu_cad_topologia();
      case 6, AOS_menu_galerias();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_activo_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('No hay un caso activo.\n');
    return;
  endif
  try
    CONFIG_ACTIVA = aos_normalizar_config(CONFIG_ACTIVA, 'GENERAL');
  catch err
    fprintf('Aviso de normalizacion: %s\n',err.message);
  end_try_catch
  try
    aos_menu_imprimir_resumen_config(CONFIG_ACTIVA,AOSDAT_ACTIVO,geologia);
  catch
    disp(CONFIG_ACTIVA);
  end_try_catch
endfunction

function descartar_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  if ~aos_preguntar_sn('Descartar caso y resultados de memoria? (s/n) [n]: ',false), return; endif
  CONFIG_ACTIVA=[]; AOSDAT_ACTIVO=''; geologia=[];
  ULTIMO_QL=[]; ULTIMO_QO=[]; ULTIMO_QINY=[]; ULTIMO_TIPO=[]; ULTIMO_PARAM=[];
  fprintf('Memoria activa limpiada. No se eliminaron archivos.\n');
endfunction

function txt=obtener_texto_local(s,campos,def)
  txt=def;
  if ~isstruct(s), return; endif
  for i=1:numel(campos)
    campo=campos{i};
    if isfield(s,campo) && ~isempty(s.(campo))
      [candidato,encontrado]=aos_texto_seguro(s.(campo),'');
      if encontrado
        txt=candidato;
        return;
      endif
    endif
  endfor
endfunction

function try_local(fn)
  try
    fn();
  catch err
    fprintf(2,'Error en gestion del caso: %s\n',err.message);
  end_try_catch
endfunction
