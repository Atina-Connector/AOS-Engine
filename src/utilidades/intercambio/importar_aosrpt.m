function importar_aosrpt(archivo)
% AOS 0.1.0: lectura formateada de tablas de sensibilidad.
  % Importa y visualiza un reporte .aosrpt.
  % Busca en: intercambio/reportes/recibidos/
  % Si no se proporciona archivo, abre el diálogo de selección.
  % Muestra el reporte formateado en consola y pregunta si se desea
  % cargar la configuración del pozo para simular.

  % --- Carpeta de búsqueda ---
  carpeta_busqueda = 'intercambio/reportes/recibidos';
  if ~exist(carpeta_busqueda, 'dir')
      mkdir(carpeta_busqueda);
  end

if nargin < 1 || isempty(archivo)
    % Preguntar si se quiere buscar en todo el sistema
    fprintf('\n--- SELECCIÓN DE REPORTE .aosrpt ---\n');
    fprintf(' 1 - Buscar en carpeta estándar (intercambio/reportes/recibidos/)\n');
    fprintf(' 2 - Navegar manualmente (buscar en cualquier carpeta)\n');
    opcion = input('Seleccione una opción (1-2): ');

    if opcion == 2
        % --- Navegación manual (uigetfile / zenity) ---
        origen = '';
        if isunix
            [status, ~] = system('which zenity');
            if status == 0
                [status, ruta_arch] = system('zenity --file-selection --title="Seleccione un archivo .aosrpt" --file-filter="*.aosrpt" 2>/dev/null');
                if status == 0 && ~isempty(ruta_arch)
                    origen = strtrim(ruta_arch);
                end
            end
        end
        if isempty(origen)
            try
                [nombre, ruta] = uigetfile('*.aosrpt', 'Seleccione un archivo .aosrpt');
                if ischar(nombre) && ~isempty(nombre)
                    if isempty(ruta)
                        origen = fullfile(pwd, nombre);
                    else
                        origen = fullfile(ruta, nombre);
                    end
                end
            catch
                % Si uigetfile falla (Octave sin GUI), usar método alternativo
                fprintf('No se pudo abrir el selector de archivos. Usando búsqueda estándar.\n');
                opcion = 1;
            end
        end
        if ~isempty(origen)
            archivo = origen;
            fprintf('Archivo seleccionado: %s\n', archivo);
        else
            fprintf('No se seleccionó ningún archivo. Importación cancelada.\n');
            return;
        end
    end

    % Si opcion == 1 o si la navegación manual falló, usar carpeta estándar
    if opcion == 1 || isempty(origen)
        if ~exist(carpeta_busqueda, 'dir')
            mkdir(carpeta_busqueda);
        end
        archivos = dir(fullfile(carpeta_busqueda, '*.aosrpt'));
        if isempty(archivos)
            fprintf('No se encontraron reportes .aosrpt en %s.\n', carpeta_busqueda);
            return;
        end
        fprintf('\n--- REPORTES .aosrpt DISPONIBLES ---\n');
        for k = 1:length(archivos)
            fprintf('  %d - %s\n', k, archivos(k).name);
        end
        fprintf('  0 - Cancelar\n');
        op = input('Seleccione un reporte (número): ');
        if ~isempty(op) && op >= 1 && op <= length(archivos)
            archivo = fullfile(carpeta_busqueda, archivos(op).name);
        else
            fprintf('Visualización cancelada.\n');
            return;
        end
    end
end

  % --- Detectar proteccion automaticamente, independiente de globals ---
  archivo_descifrado = archivo;
  if aos_archivo_codificado(archivo)
      fprintf('Archivo codificado detectado.\n');
      id_remitente = pedir_id_importacion('ID del remitente (10 digitos): ');
      id_propio = pedir_id_importacion('Su ID AOS/receptor (10 digitos): ');
      archivo_descifrado = [tempname(), '.aosrpt'];
      aos_decrypt(archivo, id_remitente, id_propio, archivo_descifrado);
      fprintf('Archivo descifrado temporalmente.\n');
  end

  % --- Leer y mostrar el reporte ---
  if exist(archivo_descifrado, 'file') ~= 2
      fprintf('Error: No se encuentra el archivo %s\n', archivo_descifrado);
      return;
  end

  fid = fopen(archivo_descifrado, 'r');
  if fid == -1
      fprintf('Error: No se pudo abrir el archivo.\n');
      return;
  end

  contenido = {};
  while ~feof(fid)
      contenido{end+1} = fgetl(fid);
  end
  fclose(fid);

  % Identificar el SLA antes de reconstruir profundidades.
  sistema_reporte = 'GENERAL';
  for ii = 1:length(contenido)
      linea_sis = contenido{ii};
      if aos_starts_with(linea_sis, 'sistema=')
          partes_sis = strsplit(linea_sis, '=');
          if length(partes_sis) == 2
              sistema_reporte = upper(strtrim(partes_sis{2}));
          end
          break;
      end
  end

  % --- Mostrar reporte formateado ---
  fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
  fprintf('║           REPORTE AOS – SIMULACIÓN DE POZO                   ║\n');
  fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

  seccion_mostrar = '';
  for i = 1:length(contenido)
      linea = contenido{i};
      linea_trim_mostrar = strtrim(linea);
      if ~isempty(linea_trim_mostrar) && linea_trim_mostrar(1) == '['
          seccion_mostrar = upper(regexprep(linea_trim_mostrar,'^\[|\]$',''));
      endif
      if aos_starts_with(linea, '[AOS_REPORT]')
          fprintf('📋 --- ENCABEZADO ---\n');
      elseif aos_starts_with(linea, '[CONFIG_ACTIVA]')
          fprintf('\n⚙️ --- CONFIGURACIÓN ACTIVA ---\n');
      elseif aos_starts_with(linea, '[PARAMETROS]')
          fprintf('\n📊 --- PARÁMETROS DEL POZO ---\n');
      elseif aos_starts_with(linea, '[RESULTADOS]')
          fprintf('\n📈 --- RESULTADOS ---\n');
      elseif aos_starts_with(linea, '[DIAGNOSTICO]')
          fprintf('\n🔍 --- DIAGNÓSTICO ---\n');
      elseif aos_starts_with(linea, '[EFICIENCIA]')
          fprintf('\n⚡ --- EFICIENCIA ENERGÉTICA ---\n');
      elseif aos_starts_with(linea, '[GEOLOGIA]')
          fprintf('\n🪨 --- INTEGRIDAD DE FORMACIÓN ---\n');
      elseif aos_starts_with(linea, '[VIEWER_CONTEXT]')
          fprintf('\n🧭 --- CONTEXTO AOS VIEWER ---\n');
      elseif aos_starts_with(linea, '[SURVEY]')
          fprintf('\n📐 --- SURVEY ---\n');
      elseif aos_starts_with(linea, '[TUBING_PROFILE]')
          fprintf('\n🛢️ --- PERFIL DE TUBING ---\n');
      elseif aos_starts_with(linea, '[PERFORATIONS]')
          fprintf('\n🎯 --- PUNZADOS ---\n');
      elseif aos_starts_with(linea, '[DOWNHOLE_EQUIPMENT]')
          fprintf('\n⚙️ --- EQUIPO DE FONDO ---\n');
      elseif aos_starts_with(linea, '[SENSITIVITY_SUMMARY]')
          fprintf('\n--- RESUMEN DE SENSIBILIDAD ---\n');
      elseif aos_starts_with(linea, '[SENSITIVITY_GAIN_SUMMARY]')
          fprintf('\n--- RESUMEN DE GANANCIAS ---\n');
      elseif aos_starts_with(linea, '[SENSITIVITY_TABLE]')
          fprintf('\n--- TABLA PUNTO A PUNTO (ver tabla formateada al final) ---\n');
      elseif aos_starts_with(linea, '[SENSITIVITY_DATA]')
          fprintf('\n--- DATOS VECTORIALES DE COMPATIBILIDAD ---\n');
      elseif aos_starts_with(linea, '[SENSITIVITY_TABLE_TEXT]')
          fprintf('\n--- TABLA DE COMPATIBILIDAD ---\n');
      elseif ~aos_ocultar_detalle_reporte_local(seccion_mostrar) && ...
             ~isempty(linea) && linea(1) ~= '#' && ~isempty(strfind(linea, '='))
          partes = strsplit(linea, '=');
          if length(partes) == 2
              campo = strtrim(partes{1});
              valor = strtrim(partes{2});
              fprintf('  %-25s : %s\n', campo, valor);
          end
      end
  end

  mostrar_tabla_sensibilidad_local(contenido);
  if exist('aos_report_print_native_tables','file') == 2
    try
      aos_report_print_native_tables(contenido);
    catch err_tablas
      fprintf(2,'Aviso: no se pudieron presentar las tablas nativas: %s\n',err_tablas.message);
    end_try_catch
  endif

  fprintf('\n═══════════════════════════════════════════════════════════════\n');

  % --- Preguntar si desea cargar la configuracion ---
  cargar = aos_preguntar_sn( ...
    'Cargar la configuracion de este reporte para simular? (s/n) [n]: ', false);
  if cargar
      global CONFIG_ACTIVA;
      CONFIG_ACTIVA = struct();

      % Capturar primero las entradas efectivas, incluso si estan en RESULTADOS/AUDIT.
      qiny_importado = leer_qiny_reporte_local(contenido);

      seccion_carga = '';
      for i = 1:length(contenido)
          linea = contenido{i};
          linea_trim = strtrim(linea);
          if ~isempty(linea_trim) && linea_trim(1) == '['
              seccion_carga = upper(regexprep(linea_trim,'^\[|\]$',''));
              continue;
          end
          if aos_seccion_no_config_local(seccion_carga)
              continue;
          end
          if ~isempty(strfind(linea, '=')) && ...
             ~aos_starts_with(linea, '[') && ...
             ~aos_starts_with(linea, 'version') && ...
             ~aos_starts_with(linea, 'fecha') && ...
             ~aos_starts_with(linea, 'sistema') && ...
             ~aos_starts_with(linea, 'secciones')
              partes = strsplit(linea, '=');
              if length(partes) == 2
                  campo_rep = strtrim(partes{1});
                  valor_str = strtrim(partes{2});
                  valor = aos_parse_valor(valor_str);
                  [CONFIG_ACTIVA, asignado, aviso] = asignar_campo_reporte_local( ...
                    CONFIG_ACTIVA, campo_rep, valor, sistema_reporte);
                  if ~asignado && ~isempty(aviso)
                    fprintf('Aviso al reconstruir %s: %s\n', campo_rep, aviso);
                  endif
              end
          end
      end

      % La corrida efectiva tiene prioridad sobre la configuracion base.
      if qiny_importado.encontrado
          CONFIG_ACTIVA = aos_set_qiny(CONFIG_ACTIVA, qiny_importado.q_sm3d, qiny_importado.modo);
          CONFIG_ACTIVA.Qiny_efectivo_Sm3_d = qiny_importado.q_sm3d;
          CONFIG_ACTIVA.Qiny_origen = qiny_importado.fuente;
          CONFIG_ACTIVA.Qiny_importado_aosrpt = true;
      endif

      % Reconstruir survey embebido para que el .aosrpt sea autosuficiente.
      [survey_emb, punz_emb] = leer_contexto_viewer(contenido);
      if ~isempty(survey_emb), CONFIG_ACTIVA.survey = survey_emb; end
      if ~isempty(punz_emb), CONFIG_ACTIVA.punzados = punz_emb; end

      % Completar campos esenciales con valores por defecto
      if ~isfield(CONFIG_ACTIVA, 'D_res'), CONFIG_ACTIVA.D_res = 3000; end
      if ~isfield(CONFIG_ACTIVA, 'diam_tbg'), CONFIG_ACTIVA.diam_tbg = 0.062; end
      if ~isfield(CONFIG_ACTIVA, 'rho_o'), CONFIG_ACTIVA.rho_o = 850; end
      if ~isfield(CONFIG_ACTIVA, 'rho_w'), CONFIG_ACTIVA.rho_w = 1000; end
      if ~isfield(CONFIG_ACTIVA, 'rho_g_std'), CONFIG_ACTIVA.rho_g_std = 0.80; end
      if ~isfield(CONFIG_ACTIVA, 'API'), CONFIG_ACTIVA.API = 35; end
      if ~isfield(CONFIG_ACTIVA, 'gamma_g'), CONFIG_ACTIVA.gamma_g = 0.7; end
      if ~isfield(CONFIG_ACTIVA, 'R_gas'), CONFIG_ACTIVA.R_gas = 519.6; end
      if ~isfield(CONFIG_ACTIVA, 'T_sup'), CONFIG_ACTIVA.T_sup = 298.15; end
      if ~isfield(CONFIG_ACTIVA, 'T_fondo'), CONFIG_ACTIVA.T_fondo = 358.15; end
      if ~isfield(CONFIG_ACTIVA, 'D_tubing'), CONFIG_ACTIVA.D_tubing = CONFIG_ACTIVA.D_res; end

      if any(strcmp(sistema_reporte, {'GL','JGL','BES','BM'}))
          CONFIG_ACTIVA = aos_sincronizar_config(CONFIG_ACTIVA, sistema_reporte);
      else
          CONFIG_ACTIVA = aos_sincronizar_config(CONFIG_ACTIVA, 'GENERAL');
      end
      fprintf('Configuracion cargada para SLA %s. Puede simular con los datos del reporte.\n', sistema_reporte);
      [qchk,mchk,fchk]=aos_resolver_qiny_configurado(CONFIG_ACTIVA);
      if ~isempty(qchk)
          fprintf('Qiny efectivo restaurado : %.0f Sm3/d\n',qchk*86400);
          fprintf('Modo Qiny                 : %s\n',mchk);
          fprintf('Origen Qiny               : %s\n',fchk);
      elseif strcmpi(mchk,'automatico')
          fprintf('Modo Qiny                 : automatico (sin valor fijo)\n');
      else
          fprintf('Aviso: el reporte no contiene un Qiny escalar reproducible.\n');
      endif
  end

  % --- Limpiar archivo temporal si se descifró ---
  if ~strcmp(archivo_descifrado, archivo)
      delete(archivo_descifrado);
  end
end


function [cfg, asignado, aviso] = asignar_campo_reporte_local(cfg, campo, valor, sistema)
  asignado = false;
  aviso = '';
  campos_numericos = {'WC_fraccion','P_res_bar','IP_m3dbar','IP_m3_d_bar', ...
    'P_wh_bar','P_iny_bar','P_iny_sup_bar','GLR_sm3m3', ...
    'GLR_Sm3_m3_liquido','D_valv_m','D_iny_m','D_bomba_m', ...
    'Qiny_Sm3_d','Qiny_efectivo_Sm3_d','Qiny_efectivo_VLP_Sm3_d', ...
    'Qiny_usado_Sm3_d','Qiny_corrida_Sm3_d','caudal_gas_inyectado_Sm3_d'};

  if any(strcmp(campo, campos_numericos))
    [numero, ok_num] = aos_numero_seguro(valor, NaN);
    if ~ok_num || ~isfinite(numero)
      aviso = 'se esperaba un escalar numerico finito; el campo fue omitido';
      return;
    endif
    switch campo
      case 'WC_fraccion', cfg.WC = numero;
      case 'P_res_bar', cfg.P_res = numero * 1e5;
      case {'IP_m3dbar','IP_m3_d_bar'}, cfg.IP = numero / 86400 / 1e5;
      case 'P_wh_bar', cfg.P_wh = numero * 1e5;
      case {'P_iny_bar','P_iny_sup_bar'}, cfg.P_iny_sup = numero * 1e5;
      case {'GLR_sm3m3','GLR_Sm3_m3_liquido'}, cfg.GLR = numero;
      case {'D_valv_m','D_iny_m'}, cfg = aos_set_profundidad(cfg, 'GL', numero);
      case 'D_bomba_m'
        if strcmpi(sistema, 'BM'), cfg = aos_set_profundidad(cfg, 'BM', numero);
        else, cfg = aos_set_profundidad(cfg, 'BES', numero); endif
      otherwise
        cfg = aos_set_qiny(cfg, numero, 'fijo');
    endswitch
    asignado = true;
    return;
  endif

  if any(strcmp(campo, {'modo_Qiny','Qiny_modo','modo_qiny','qiny_modo'}))
    [texto, ok_txt] = aos_texto_seguro(valor, '');
    if ~ok_txt
      aviso = 'modo Qiny no textual; el campo fue omitido';
      return;
    endif
    cfg.qiny_modo = lower(strtrim(texto));
    asignado = true;
    return;
  endif

  if strcmp(campo, 'nombre_pozo')
    [texto, ok_txt] = aos_texto_seguro(valor, '');
    if ~ok_txt
      aviso = 'nombre de pozo no textual; el campo fue omitido';
      return;
    endif
    cfg.nombre_pozo = texto;
    asignado = true;
    return;
  endif

  if isempty(regexp(campo, '^[A-Za-z][A-Za-z0-9_]*$', 'once'))
    aviso = 'nombre de campo no valido para una estructura GNU Octave';
    return;
  endif
  cfg.(campo) = valor;
  asignado = true;
endfunction


function [survey,punzados]=leer_contexto_viewer(contenido)
  survey=[];punzados=[];seccion='';md=[];tvd=[];inc=[];azi=[];idt=[];idc=[];rug=[];perfs=[];
  for i=1:length(contenido)
    ln=strtrim(contenido{i});
    if strcmp(ln,'[SURVEY]'),seccion='SURVEY';continue;end
    if strcmp(ln,'[PERFORATIONS]'),seccion='PERF';continue;end
    if ~isempty(ln)&&ln(1)=='[',seccion='';continue;end
    if isempty(ln)||~isempty(strfind(ln,'=')),continue;end
    [vals, ok_vals] = aos_vector_seguro(ln, []);
    if ~ok_vals, vals = []; endif
    if strcmp(seccion,'SURVEY')&&numel(vals)>=8
      md(end+1,1)=vals(2);tvd(end+1,1)=vals(3);inc(end+1,1)=vals(4);azi(end+1,1)=vals(5);idt(end+1,1)=vals(6);idc(end+1,1)=vals(7);rug(end+1,1)=vals(8);
    elseif strcmp(seccion,'PERF')&&numel(vals)>=3
      perfs(end+1,:)=[vals(2) vals(3)];
    end
  end
  if ~isempty(md),survey=struct('MD',md,'TVD',tvd,'inclinacion',inc,'azimut',azi,'ID_tubing',idt,'ID_casing',idc,'rugosidad',rug);end
  punzados=perfs;
end

function mostrar_tabla_sensibilidad_local(contenido)
  [nombres, unidades, filas] = leer_tabla_sensibilidad_local(contenido);
  if isempty(nombres) || isempty(filas)
    mostrar_tabla_texto_compat_local(contenido);
    return;
  endif

  idx = seleccionar_columnas_tabla_local(nombres, 10);
  if isempty(idx)
    return;
  endif

  fprintf('\n=== TABLA PUNTO A PUNTO DE SENSIBILIDAD ===\n');
  anchos = zeros(1,numel(idx));
  encabezados = cell(1,numel(idx));
  unidades_sel = cell(1,numel(idx));
  for j = 1:numel(idx)
    encabezados{j} = abreviar_tabla_local(nombres{idx(j)},18);
    if numel(unidades) >= idx(j)
      unidades_sel{j} = abreviar_tabla_local(unidades{idx(j)},18);
    else
      unidades_sel{j} = '-';
    endif
    anchos(j) = max([7,numel(encabezados{j}),numel(unidades_sel{j})]);
    for i = 1:size(filas,1)
      anchos(j) = min(18,max(anchos(j),numel(abreviar_tabla_local(filas{i,idx(j)},18))));
    endfor
  endfor
  fprintf('%s\n', unir_tabla_local(encabezados,anchos));
  fprintf('%s\n', unir_tabla_local(unidades_sel,anchos));
  fprintf('%s\n', repmat('-',1,numel(unir_tabla_local(encabezados,anchos))));
  for i = 1:size(filas,1)
    fila = cell(1,numel(idx));
    for j = 1:numel(idx)
      fila{j} = filas{i,idx(j)};
    endfor
    fprintf('%s\n', unir_tabla_local(fila,anchos));
  endfor
  fprintf('Total de puntos: %d. La matriz completa permanece dentro del .aosrpt.\n',size(filas,1));
  mostrar_resumen_ganancias_local(contenido);
endfunction

function [nombres,unidades,filas] = leer_tabla_sensibilidad_local(contenido)
  nombres = {}; unidades = {}; filas = {};
  seccion = ''; leyendo = false;
  for i = 1:numel(contenido)
    ln = strtrim(contenido{i});
    if strcmpi(ln,'[SENSITIVITY_TABLE]')
      seccion = 'TABLA'; leyendo = false; continue;
    endif
    if ~isempty(ln) && ln(1) == '['
      if strcmp(seccion,'TABLA'), break; endif
      continue;
    endif
    if ~strcmp(seccion,'TABLA') || isempty(ln), continue; endif
    if aos_starts_with(ln,'columns=')
      nombres = csv_parse_local(ln(numel('columns=')+1:end));
    elseif aos_starts_with(ln,'units=')
      unidades = csv_parse_local(ln(numel('units=')+1:end));
    elseif strcmpi(ln,'data_begin=1')
      leyendo = true;
    elseif strcmpi(ln,'data_end=1')
      break;
    elseif leyendo
      r = csv_parse_local(ln);
      if ~isempty(nombres)
        if numel(r) < numel(nombres)
          r(end+1:numel(nombres)) = {''};
        elseif numel(r) > numel(nombres)
          r = r(1:numel(nombres));
        endif
        filas(end+1,1:numel(nombres)) = r;
      endif
    endif
  endfor
endfunction

function campos = csv_parse_local(linea)
  campos = {}; actual = ''; en_comillas = false; i = 1;
  while i <= numel(linea)
    ch = linea(i);
    if ch == '"'
      if en_comillas && i < numel(linea) && linea(i+1) == '"'
        actual(end+1) = '"'; i = i + 1;
      else
        en_comillas = ~en_comillas;
      endif
    elseif ch == ',' && ~en_comillas
      campos{end+1} = strtrim(actual); actual = '';
    else
      actual(end+1) = ch;
    endif
    i = i + 1;
  endwhile
  campos{end+1} = strtrim(actual);
endfunction

function idx = seleccionar_columnas_tabla_local(nombres,maxn)
  prioridad = {'Qiny','Piny','Pwh','Profundidad_inyeccion','Frecuencia','Parametro', ...
    'Ql_JGL_m3d','Ganancia_Ql_JGL_pct','Qo_JGL_m3d','Ganancia_Qo_JGL_pct', ...
    'Ql_GL_m3d','Ganancia_Ql_GL_pct','Qo_GL_m3d','Ganancia_Qo_GL_pct', ...
    'Ql_m3d','Ganancia_Ql_pct','Qo_m3d','Ganancia_Qo_pct', ...
    'DeltaP_JGL_bar','DeltaP_bar','Iteraciones_JGL','iteraciones', ...
    'Estado_JGL','Estado_GL','Estado','Aceptado','Confianza'};
  idx = [];
  for i = 1:numel(prioridad)
    j = find(strcmp(nombres,prioridad{i}),1);
    if ~isempty(j) && ~any(idx == j), idx(end+1) = j; endif
    if numel(idx) >= maxn, break; endif
  endfor
  if isempty(idx), idx = 1:min(maxn,numel(nombres)); endif
endfunction

function mostrar_tabla_texto_compat_local(contenido)
  seccion = ''; encabezado = ''; unidades = ''; filas = {};
  for i = 1:numel(contenido)
    ln = strtrim(contenido{i});
    if strcmpi(ln,'[SENSITIVITY_TABLE_TEXT]'), seccion='TXT'; continue; endif
    if ~isempty(ln) && ln(1)=='['
      if strcmp(seccion,'TXT'), break; endif
      continue;
    endif
    if ~strcmp(seccion,'TXT'), continue; endif
    if aos_starts_with(ln,'encabezado='), encabezado=ln(numel('encabezado=')+1:end); endif
    if aos_starts_with(ln,'unidades='), unidades=ln(numel('unidades=')+1:end); endif
    if aos_starts_with(ln,'fila_')
      k=strfind(ln,'='); if ~isempty(k), filas{end+1}=ln(k(1)+1:end); endif
    endif
  endfor
  if isempty(encabezado), return; endif
  fprintf('\n=== TABLA PUNTO A PUNTO DE SENSIBILIDAD ===\n');
  fprintf('%s\n%s\n',encabezado,unidades);
  fprintf('%s\n',repmat('-',1,max(numel(encabezado),20)));
  for i=1:numel(filas),fprintf('%s\n',filas{i});endfor
  mostrar_resumen_ganancias_local(contenido);
endfunction

function mostrar_resumen_ganancias_local(contenido)
  seccion=''; lineas={};
  for i=1:numel(contenido)
    ln=strtrim(contenido{i});
    if strcmpi(ln,'[SENSITIVITY_GAIN_SUMMARY]'),seccion='GAIN';continue;endif
    if ~isempty(ln)&&ln(1)=='['
      if strcmp(seccion,'GAIN'),break;endif
      continue;
    endif
    if strcmp(seccion,'GAIN') && ~isempty(strfind(ln,'='))
      if ~isempty(strfind(ln,'referencia_')) || ~isempty(strfind(ln,'ganancia_max_pct')) || ...
         ~isempty(strfind(ln,'valor_base')) || ~isempty(strfind(ln,'variable_ganancia_max'))
        lineas{end+1}=ln;
      endif
    endif
  endfor
  if isempty(lineas),return;endif
  fprintf('\n--- GANANCIAS Y REFERENCIA ---\n');
  for i=1:numel(lineas)
    k=strfind(lineas{i},'=');
    fprintf('  %-38s : %s\n',strtrim(lineas{i}(1:k(1)-1)),strtrim(lineas{i}(k(1)+1:end)));
  endfor
endfunction

function s = unir_tabla_local(celdas,anchos)
  partes=cell(1,numel(celdas));
  for i=1:numel(celdas)
    txt=abreviar_tabla_local(celdas{i},anchos(i));
    partes{i}=sprintf(['%-' num2str(anchos(i)) 's'],txt);
  endfor
  s=strjoin(partes,' | ');
endfunction

function s = abreviar_tabla_local(s,n)
  if ~ischar(s),s='';endif
  s=regexprep(s,'[\r\n|]',' ');
  if numel(s)>n
    if n>3,s=[s(1:n-3) '...'];else,s=s(1:n);endif
  endif
endfunction

function tf = aos_ocultar_detalle_reporte_local(seccion)
  tf = false;
  if isempty(seccion), return; endif
  ocultas = {'SENSITIVITY_TABLE','SENSITIVITY_DATA','SENSITIVITY_TABLE_TEXT','GRAFICOS', ...
    'REPORT_COMPOSITION','TABLE_INDEX','TABLE_ARCHIVE_INDEX'};
  if aos_starts_with(seccion,'TABLE_') || aos_starts_with(seccion,'TABLE_ARCHIVE_') || ...
      aos_starts_with(seccion,'TABLE_PRESENTATION_')
    tf = true; return;
  endif
  for i=1:numel(ocultas)
    if strcmp(seccion,ocultas{i}),tf=true;return;endif
  endfor
endfunction

function tf = aos_seccion_no_config_local(seccion)
  tf = false;
  if isempty(seccion), return; endif
  prefijos = {'SENSITIVITY_','CLASSIFICATION_','GRAFICOS','GRAFICO_', ...
    'RESULTADOS','DIAGNOSTICO','EFICIENCIA','GEOLOGIA','VIEWER_CONTEXT', ...
    'SURVEY','TUBING_PROFILE','PERFORATIONS','DOWNHOLE_EQUIPMENT', ...
    'REPORT_','TABLE_','TABLE_ARCHIVE_','TABLE_PRESENTATION_'};
  for i=1:numel(prefijos)
    if aos_starts_with(seccion,prefijos{i}),tf=true;return;endif
  endfor
endfunction


function out=leer_qiny_reporte_local(contenido)
  out=struct('encontrado',false,'q_sm3d',NaN,'modo','fijo','fuente','','prioridad',-Inf);
  seccion='';
  for i=1:numel(contenido)
    ln=strtrim(contenido{i});
    if isempty(ln), continue; endif
    if ln(1)=='['
      seccion=upper(regexprep(ln,'^\[|\]$',''));
      continue;
    endif
    k=strfind(ln,'='); if isempty(k), continue; endif
    campo=strtrim(ln(1:k(1)-1)); valor=strtrim(ln(k(1)+1:end));
    if any(strcmpi(campo,{'modo_Qiny','Qiny_modo','modo_qiny','qiny_modo'}))
      if ~isempty(strfind(lower(valor),'auto')), out.modo='automatico'; else, out.modo='fijo'; endif
      continue;
    endif
    [ok,q_sm3d,prio]=interpretar_qiny_reporte_local(campo,valor,seccion);
    if ok && prio>out.prioridad
      out.encontrado=true; out.q_sm3d=q_sm3d; out.fuente=[seccion '.' campo]; out.prioridad=prio;
    endif
  endfor
  if out.encontrado, out.modo='fijo'; endif
endfunction

function [ok,q,prio]=interpretar_qiny_reporte_local(campo,valor,seccion)
  ok=false; q=NaN; prio=-Inf;
  [nums, ok_num] = aos_numero_seguro(valor, NaN);
  if ~ok_num || ~isfinite(nums) || nums < 0, return; endif
  c=lower(strtrim(campo)); sec=upper(strtrim(seccion));
  if any(strcmp(c,{'qiny_efectivo_sm3_d','qiny_efectivo_vlp_sm3_d','qiny_usado_sm3_d','qiny_corrida_sm3_d','caudal_gas_inyectado_sm3_d'}))
    q=nums; prio=100;
  elseif strcmp(c,'qiny_sm3_d') || strcmp(c,'qiny_sm3d') || strcmp(c,'q_iny_sm3_d') || strcmp(c,'qiny_solicitado_sm3_d')
    q=nums; prio=strcmp(sec,'RESULTADOS')*20 + 60;
  elseif strcmp(c,'qiny_mmscfd') || strcmp(c,'qiny_efectivo_mmscfd')
    q=nums*1e6*0.028316846592; prio=70;
  elseif any(strcmp(c,{'qiny','q_iny','qiny_efectivo','qiny_usado'}))
    % En reportes historicos estos campos SI estaban en m3/s estandar.
    q=nums*86400; prio=40;
  else
    return;
  endif
  ok=isfinite(q) && q>=0;
endfunction

function id = pedir_id_importacion(mensaje)
  while true
      id = strtrim(input(mensaje, 's'));
      if length(id) == 10 && all(id >= '0') && all(id <= '9'), return; end
      fprintf('El ID debe contener exactamente 10 digitos.\n');
  end
end
