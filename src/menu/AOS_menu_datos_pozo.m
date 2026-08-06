function AOS_menu_datos_pozo()
% Menu transversal para Survey, punzados, geologia y completacion.
% HF3 restaura el gestor CRUD de punzados como funcion independiente:
% puede usarse sin Survey y sin geologia activa.
  while true
    [survey, punzados, info] = aos_obtener_geometria_activa();
    imprimir_cabecera_local(survey, punzados, info);

    fprintf(' 1 - Visualizar estado mecanico integral\n');
    fprintf(' 2 - Visualizar survey 2D (MD / TVD)\n');
    fprintf(' 3 - Visualizar trayectoria 3D\n');
    fprintf(' 4 - ADMINISTRAR / GENERAR PUNZADOS [TRANSVERSAL]\n');
    fprintf(' 5 - Visualizar punzados\n');
    fprintf(' 6 - Ver tabla del survey\n');
    fprintf(' 7 - Ver tabla completa de punzados\n');
    fprintf(' 8 - Validar profundidades MD / TVD y punzados\n');
    fprintf(' 9 - Exportar geometria del pozo\n');
    fprintf('10 - Administrar geologia activa\n');
    fprintf('11 - Validar y normalizar configuracion activa\n');
    fprintf(' 0 - Volver\n');

    op = aos_leer_opcion('Seleccione [0-11]: ', []);
    switch op
      case 1
        aos_visualizar_geometria_pozo('integral', survey, punzados, info);
      case 2
        aos_visualizar_geometria_pozo('survey2d', survey, punzados, info);
      case 3
        aos_visualizar_geometria_pozo('survey3d', survey, punzados, info);
      case 4
        aos_punzados_administrar(struct('origen','MENU_DATOS_POZO'));
      case 5
        aos_visualizar_geometria_pozo('punzados', survey, punzados, info);
      case 6
        aos_visualizar_geometria_pozo('tabla_survey', survey, punzados, info);
      case 7
        aos_visualizar_geometria_pozo('tabla_punzados', survey, punzados, info);
      case 8
        resultado = aos_validar_geometria_pozo(survey, punzados, true);
        if resultado.ok
          fprintf('\nVALIDACION GEOMETRICA: APROBADA.\n');
        else
          fprintf('\nVALIDACION GEOMETRICA: REQUIERE REVISION.\n');
        endif
      case 9
        aos_exportar_geometria_pozo(survey, punzados, info);
      case 10
        cargar_editar_geologia_local();
      case 11
        normalizar_configuracion_local();
      case 0
        break;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function imprimir_cabecera_local(survey, punzados, info)
  [punzados, ~] = aos_punzados_normalizar(punzados);
  fprintf('\n--- POZO: SURVEY, PUNZADOS Y COMPLETACION ---\n');
  if isfield(info, 'pozo') && ~isempty(info.pozo)
    fprintf('Pozo                    : %s\n', info.pozo);
  endif
  if isempty(survey)
    fprintf('Survey                  : NO CARGADO\n');
  else
    fprintf('Survey                  : %d puntos | MD %.1f a %.1f m | TVD %.1f a %.1f m\n', ...
            numel(survey.MD), min(survey.MD), max(survey.MD), ...
            min(survey.TVD), max(survey.TVD));
  endif
  if isempty(punzados.tramos)
    fprintf('Punzados                : NO CARGADOS (pueden configurarse manualmente)\n');
  else
    fprintf('Punzados                : %d intervalos (%d activos) | MD %.1f a %.1f m\n', ...
            numel(punzados.tramos), punzados.n_activos, ...
            min([punzados.tramos.MD_desde]), max([punzados.tramos.MD_hasta]));
  endif
  if isfield(info, 'origen_survey')
    fprintf('Origen survey           : %s\n', info.origen_survey);
  endif
  if isfield(info, 'origen_punzados')
    fprintf('Origen punzados         : %s\n', info.origen_punzados);
  endif
  if isempty(survey) && isempty(punzados.tramos)
    fprintf('Accion sugerida         : importar un .aosdat o generar punzados manualmente.\n');
  elseif isempty(survey) && ~isempty(punzados.tramos)
    fprintf('Aviso                    : punzados en MD; TVD no disponible sin Survey.\n');
  endif
  fprintf('\n');
endfunction

function cargar_editar_geologia_local()
  if exist('aos_geologia_administrar','file')==2
    aos_geologia_administrar();
  else
    fprintf('La administracion transaccional de geologia no esta disponible.\n');
  endif
endfunction

function normalizar_configuracion_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('No hay configuracion activa. Importe un .aosdat primero.\n');
    return;
  endif
  try
    CONFIG_ACTIVA = aos_normalizar_config(CONFIG_ACTIVA, 'GENERAL');
    if exist('aos_sincronizar_geologia_activa', 'file') == 2
      aos_sincronizar_geologia_activa();
    endif
    fprintf('Configuracion normalizada correctamente.\n');
  catch err
    fprintf('ERROR de validacion: %s\n', err.message);
  end_try_catch
endfunction
