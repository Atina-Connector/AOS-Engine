function exportar_aosdat(param, archivo_salida, secciones)
% EXPORTAR_AOSDAT Exporta un caso AOS completo en formato ultraliviano.
%
% AOS 0.0.11 Benchmark Ready
% - Unidades de archivo/interfaz: bar, m, m3/d, Sm3/d, mm y C.
% - Conserva parametros escalares adicionales del caso activo.
% - Exporta automaticamente geologia, survey, punzados, estado mecanico,
%   bombeo mecanico y benchmark cuando estan disponibles.
% - Compatible con GNU Octave; el nucleo puede continuar usando Pa y m3/s.

  if nargin < 1 || ~isstruct(param)
      error('exportar_aosdat requiere una configuracion valida.');
  end

  exportacion_interactiva = (nargin < 2 || isempty(archivo_salida));

  try
      param = aos_normalizar_config(param, 'GENERAL');
  catch err
      fprintf('ADVERTENCIA AOS: exportacion con normalizacion parcial: %s\n', err.message);
  end

  carpeta_destino = fullfile('intercambio', 'pozos', 'enviados');
  if exist(carpeta_destino, 'dir') ~= 7, mkdir(carpeta_destino); end

  if nargin < 2 || isempty(archivo_salida)
      global AOSDAT_ACTIVO;
      if ischar(AOSDAT_ACTIVO) && ~isempty(AOSDAT_ACTIVO)
          nombre_base = AOSDAT_ACTIVO;
      elseif isfield(param, 'nombre_pozo') && ischar(param.nombre_pozo)
          nombre_base = sanitizar_nombre_archivo(param.nombre_pozo);
      else
          nombre_base = 'pozo_AOS';
      end
      archivo_salida = fullfile(carpeta_destino, [nombre_base, '.aosdat']);
      fprintf('\nNombre propuesto: %s\n', archivo_salida);
      cambiar = aos_preguntar_sn('Desea cambiarlo? (s/n) [n]: ', false);
      if cambiar
          nuevo = input('Nuevo nombre (sin extension): ', 's');
          if ~isempty(strtrim(nuevo))
              archivo_salida = fullfile(carpeta_destino, [sanitizar_nombre_archivo(nuevo), '.aosdat']);
          end
      end
  else
      [ruta, nombre, ext] = fileparts(archivo_salida);
      if isempty(ext), ext = '.aosdat'; end
      if isempty(ruta), ruta = carpeta_destino; end
      if exist(ruta, 'dir') ~= 7, mkdir(ruta); end
      archivo_salida = fullfile(ruta, [nombre, ext]);
  end

  disponibles = detectar_secciones(param);
  if nargin < 3 || isempty(secciones)
      fprintf('\n--- SECCIONES A EXPORTAR ---\n');
      fprintf(' T - Caso completo (recomendado)\n');
      fprintf(' C - Solo configuracion\n');
      fprintf(' G - Configuracion + geologia + punzados\n');
      fprintf(' S - Configuracion + survey + punzados\n');
      op = input('Seleccione [T]: ', 's');
      if isempty(op), op = 'T'; end
      switch upper(strtrim(op))
          case 'C'
              secciones = {'CONFIG'};
          case 'G'
              secciones = interseccion_ordenada({'CONFIG','GEOLOGIA','PUNZADOS'}, disponibles);
          case 'S'
              secciones = interseccion_ordenada({'CONFIG','SURVEY','PUNZADOS'}, disponibles);
          otherwise
              secciones = disponibles;
      end
  elseif ischar(secciones)
      secciones = {upper(secciones)};
  end
  secciones = upper_cell(secciones);
  if ~any(strcmp(secciones, 'CONFIG')), secciones = [{'CONFIG'}, secciones]; end

  fid = fopen(archivo_salida, 'w');
  if fid == -1, error('No se pudo crear el archivo %s', archivo_salida); end
  limpieza = onCleanup(@() cerrar_si_abierto(fid)); %#ok<NASGU>

  % --- Cabecera ---
  fprintf(fid, '[AOS_DATA]\n');
  fprintf(fid, 'version=0.0.12\n');
  fprintf(fid, 'fecha=%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
  if isfield(param, 'nombre_pozo'), escribir_par(fid, 'pozo', param.nombre_pozo); end
  if isfield(param, 'descripcion'), escribir_par(fid, 'descripcion', param.descripcion); end
  fprintf(fid, 'unidades=metrico_con_imperial_de_referencia\n');
  fprintf(fid, 'secciones=%s\n', strjoin(secciones, ','));

  if any(strcmp(secciones, 'CONFIG'))
      escribir_config(fid, param);
  end
  if any(strcmp(secciones, 'GEOLOGIA'))
      geol = obtener_geologia(param);
      if ~isempty(fieldnames(geol)), escribir_geologia(fid, geol); end
  end
  if any(strcmp(secciones, 'SURVEY')) && isfield(param, 'survey') && es_survey(param.survey)
      escribir_survey(fid, param.survey);
  end
  if any(strcmp(secciones, 'PUNZADOS'))
      punz = obtener_punzados(param);
      if es_punzados(punz), escribir_punzados(fid, punz); end
  end
  if any(strcmp(secciones, 'ESTADO_MECANICO')) && isfield(param, 'estado_mecanico') && isstruct(param.estado_mecanico)
      escribir_struct_generico(fid, 'ESTADO_MECANICO', param.estado_mecanico, {});
  end
  if any(strcmp(secciones, 'BOMBEO_MECANICO'))
      escribir_bm(fid, param);
  end
  if any(strcmp(secciones, 'BENCHMARK_PROSPER')) && isfield(param, 'benchmark_prosper') && isstruct(param.benchmark_prosper)
      escribir_struct_generico(fid, 'BENCHMARK_PROSPER', param.benchmark_prosper, {});
  end

  % Preservar secciones futuras/desconocidas cargadas por el importador.
  if isfield(param, 'aosdat_sections') && isstruct(param.aosdat_sections)
      conocidas = {'aos_data','config','geologia','survey','punzados','punzados_meta','estado_mecanico','bombeo_mecanico','benchmark_prosper'};
      nombres = fieldnames(param.aosdat_sections);
      for i = 1:length(nombres)
          sec = nombres{i};
          if any(strcmp(sec, conocidas)), continue; end
          datos = param.aosdat_sections.(sec);
          if isstruct(datos) && ~isempty(fieldnames(datos))
              escribir_struct_generico(fid, upper(sec), datos, {});
          end
      end
  end

  fclose(fid);
  fid = -1;

  % La proteccion se pregunta para toda exportacion interactiva. Cuando el
  % exportador se invoca con ruta explicita (tests/API), no interrumpe el flujo.
  preguntar_crypto = (nargin < 2 || isempty(archivo_salida));
  % archivo_salida ya no esta vacio en este punto; detectar interactividad con
  % el argumento original preservado por la bandera creada al inicio.
  if exist('exportacion_interactiva', 'var'), preguntar_crypto = exportacion_interactiva; end
  [codificado, ~] = aos_finalizar_archivo_crypto(archivo_salida, preguntar_crypto);

  fprintf('\nArchivo .aosdat exportado: %s\n', archivo_salida);
  fprintf('   Secciones: %s\n', strjoin(secciones, ', '));
  fprintf('   Proteccion: %s\n', condicional_crypto(codificado));
  info = dir(archivo_salida);
  if ~isempty(info), fprintf('   Tamano: %.1f kB\n', info.bytes / 1024); end
end

function txt = condicional_crypto(codificado)
  if codificado, txt = 'CODIFICADO'; else, txt = 'TEXTO PLANO'; end
end

function secciones = detectar_secciones(param)
  secciones = {'CONFIG'};
  geol = obtener_geologia(param);
  if ~isempty(fieldnames(geol)), secciones{end+1} = 'GEOLOGIA'; end
  if isfield(param, 'survey') && es_survey(param.survey), secciones{end+1} = 'SURVEY'; end
  if es_punzados(obtener_punzados(param)), secciones{end+1} = 'PUNZADOS'; end
  if isfield(param, 'estado_mecanico') && isstruct(param.estado_mecanico) && ~isempty(fieldnames(param.estado_mecanico))
      secciones{end+1} = 'ESTADO_MECANICO';
  end
  campos_bm = {'D_bomba_mm','S_carrera','N_velocidad','eta_vol','usar_gibbs_BM'};
  for i = 1:length(campos_bm)
      if isfield(param, campos_bm{i})
          secciones{end+1} = 'BOMBEO_MECANICO';
          break;
      end
  end
  if isfield(param, 'benchmark_prosper') && isstruct(param.benchmark_prosper) && ~isempty(fieldnames(param.benchmark_prosper))
      secciones{end+1} = 'BENCHMARK_PROSPER';
  end
end

function escribir_config(fid, p)
  fprintf(fid, '\n[CONFIG]\n');
  emitidos = {};

  emitidos = escribir_si(fid, emitidos, 'nombre_pozo', leer(p, 'nombre_pozo', []));
  emitidos = escribir_si(fid, emitidos, 'P_res_bar', escala(leer(p, 'P_res', []), 1e-5));
  emitidos = escribir_si(fid, emitidos, 'P_b_bar', escala(leer(p, 'P_b', []), 1e-5));
  emitidos = escribir_si(fid, emitidos, 'IP_m3_d_bar', escala(leer(p, 'IP', []), 86400e5));
  emitidos = escribir_si(fid, emitidos, 'modelo_IPR', leer(p, 'modelo_IPR', []));
  emitidos = escribir_si(fid, emitidos, 'factor_IP_residual', leer(p, 'factor_IP_residual', []));

  emitidos = escribir_si(fid, emitidos, 'WC', leer(p, 'WC', []));
  emitidos = escribir_si(fid, emitidos, 'GLR', leer(p, 'GLR', []));
  emitidos = escribir_si(fid, emitidos, 'GLR_unidad', 'Sm3_m3_liquido');
  emitidos = escribir_si(fid, emitidos, 'GLR_base', 'liquido_total');
  emitidos = escribir_si(fid, emitidos, 'API', leer(p, 'API', []));
  emitidos = escribir_si(fid, emitidos, 'gamma_g', leer(p, 'gamma_g', []));
  emitidos = escribir_si(fid, emitidos, 'rho_o_kg_m3', leer(p, 'rho_o', []));
  emitidos = escribir_si(fid, emitidos, 'rho_w_kg_m3', leer(p, 'rho_w', []));
  emitidos = escribir_si(fid, emitidos, 'rho_g_std_kg_m3', leer(p, 'rho_g_std', []));
  emitidos = escribir_si(fid, emitidos, 'R_gas', leer(p, 'R_gas', []));
  emitidos = escribir_si(fid, emitidos, 'T_sup_C', desplazar(leer(p, 'T_sup', []), -273.15));
  emitidos = escribir_si(fid, emitidos, 'T_fondo_C', desplazar(leer(p, 'T_fondo', []), -273.15));

  emitidos = escribir_si(fid, emitidos, 'P_wh_bar', escala(leer(p, 'P_wh', []), 1e-5));
  emitidos = escribir_si(fid, emitidos, 'P_iny_sup_bar', escala(leer(p, 'P_iny_sup', []), 1e-5));
  emitidos = escribir_si(fid, emitidos, 'P_intake_min_bar', escala(leer(p, 'P_intake_min', []), 1e-5));
  [qiny, ~] = aos_qiny_configurada(p);
  if ~isempty(qiny), emitidos = escribir_si(fid, emitidos, 'Qiny_Sm3_d', aos_m3s_a_sm3d(qiny)); end

  % GL/JGL y BES/BM conservan profundidades independientes. No fabricar
  % una profundidad de inyeccion a partir de la profundidad de bomba.
  Diny = leer(p, 'D_iny', leer(p, 'D_levantamiento', []));
  Dbomba = leer(p, 'D_bomba', []);
  emitidos = escribir_si(fid, emitidos, 'D_iny_m', Diny);
  emitidos = escribir_si(fid, emitidos, 'D_levantamiento_m', leer(p, 'D_levantamiento', Diny));
  emitidos = escribir_si(fid, emitidos, 'D_bomba_m', Dbomba);
  emitidos = escribir_si(fid, emitidos, 'D_res_m', leer(p, 'D_res', []));
  emitidos = escribir_si(fid, emitidos, 'D_midperf_m', leer(p, 'D_midperf', []));
  emitidos = escribir_si(fid, emitidos, 'D_punzados_tope_m', leer(p, 'D_punzados_tope', []));
  emitidos = escribir_si(fid, emitidos, 'D_punzados_base_m', leer(p, 'D_punzados_base', []));

  emitidos = escribir_si(fid, emitidos, 'ID_tubing_m', leer(p, 'diam_tbg', []));
  emitidos = escribir_si(fid, emitidos, 'ID_casing_m', leer(p, 'ID_csg', []));
  emitidos = escribir_si(fid, emitidos, 'rugosidad_m', leer(p, 'rugosidad', []));
  emitidos = escribir_si(fid, emitidos, 'modelo_VLP', leer(p, 'modelo_VLP', []));
  emitidos = escribir_si(fid, emitidos, 'factor_VLP', leer(p, 'factor_VLP', []));

  emitidos = escribir_si(fid, emitidos, 'a_eductor', leer(p, 'a_eductor', []));
  emitidos = escribir_si(fid, emitidos, 'b_eductor', leer(p, 'b_eductor', []));
  emitidos = escribir_si(fid, emitidos, 'A_n_m2', leer(p, 'A_n', []));
  emitidos = escribir_si(fid, emitidos, 'd_t_m', leer(p, 'd_t', []));
  emitidos = escribir_si(fid, emitidos, 'eta_n', leer(p, 'eta_n', []));
  emitidos = escribir_si(fid, emitidos, 'eta_t', leer(p, 'eta_t', []));
  emitidos = escribir_si(fid, emitidos, 'eta_d', leer(p, 'eta_d', []));

  % Escalares adicionales: se conservan siempre que no sean internos,
  % estructuras, handles ni duplicados de los campos canonicos anteriores.
  excluir = {'P_res','P_b','IP','P_wh','P_iny_sup','P_intake_min','Q_iny', ...
             'D_iny','D_levantamiento','D_bomba','D_res','D_midperf','D_punzados_tope','D_punzados_base', ...
             'rho_o','rho_w','rho_g_std','T_sup','T_fondo','diam_tbg','ID_csg','rugosidad', ...
             'A_n','d_t','survey','geologia','punzados','estado_mecanico','benchmark_prosper', ...
             'aosdat_sections','aosdat_metadata','aosdat_archivo','archivo_aosdat','aosdat_lineas_leidas', ...
             'version','fecha','nombre','descripcion','pozo','tubing','casing','fluidos','gl','jgl','bes','bm','int1'};
  campos = fieldnames(p);
  for i = 1:length(campos)
      c = campos{i};
      if any(strcmp(c, excluir)) || any(strcmp(c, emitidos)) || strncmp(c, 'aos_', 4), continue; end
      v = p.(c);
      if es_escalar_exportable(v), escribir_par(fid, c, v); end
  end
end

function escribir_geologia(fid, g)
  fprintf(fid, '\n[GEOLOGIA]\n');
  emitidos = {};
  pares = {
      'nombre','nombre',1;
      'tipo_dato','tipo_dato',1;
      'confianza_geologia','confianza_geologia',1;
      'usar_para_calibracion_reservorio','usar_para_calibracion_reservorio',1;
      'ambiente','ambiente',1;
      'litologia','litologia',1;
      'analogia_regional','analogia_regional',1;
      'comentario','comentario',1;
      'tipo_formacion','tipo_formacion',1;
      'UCS_MPa','UCS',1e-6;
      'angulo_friccion_deg','angulo_friccion',1;
      'cohesion_MPa','cohesion',1e-6;
      'modulo_young_GPa','modulo_young',1e-9;
      'poisson','relacion_poisson',1;
      'esfuerzo_vertical_MPa','esfuerzo_vertical',1e-6;
      'esfuerzo_h_min_MPa','esfuerzo_h_min',1e-6;
      'esfuerzo_H_max_MPa','esfuerzo_H_max',1e-6;
      'porosidad_fraccion','porosidad',1;
      'permeabilidad_h_mD','permeabilidad_h',1/9.869233e-16;
      'permeabilidad_v_mD','permeabilidad_v',1/9.869233e-16;
      'radio_poro','radio_poro',1;
      'diametro_grano_medio','diametro_grano_medio',1;
      'espesor_bruto_m','espesor_zona_petrolera',1;
      'altura_perforados','altura_perforados',1;
      'radio_drenaje_m','radio_drenaje',1;
      'radio_pozo_m','radio_pozo',1;
      'skin_factor','skin_factor',1;
      'rho_petroleo','rho_petroleo',1;
      'rho_agua','rho_agua',1;
      'mu_petroleo','mu_petroleo',1;
      'B_o','B_o',1;
      'factor_seguridad','factor_seguridad',1
  };
  for i = 1:size(pares,1)
      salida = pares{i,1}; entrada = pares{i,2}; factor = pares{i,3};
      if isfield(g, entrada)
          v = g.(entrada);
          if isnumeric(v) && isscalar(v) && isfinite(v), v = v * factor; end
          if es_escalar_exportable(v)
              escribir_par(fid, salida, v);
              emitidos{end+1} = entrada;
          end
      end
  end
  excluir = [emitidos, {'intervalos','aos_campos_estimados','angulo_friccion_rad','P_res','IP'}];
  campos = fieldnames(g);
  for i = 1:length(campos)
      c = campos{i};
      if any(strcmp(c, excluir)) || strncmp(c, 'aos_', 4), continue; end
      if es_escalar_exportable(g.(c)), escribir_par(fid, c, g.(c)); end
  end
end

function escribir_survey(fid, s)
  fprintf(fid, '\n# Formato: MD_m,TVD_m,Inc_deg,Azi_deg,ID_tubing_m,ID_casing_m,rugosidad_m\n');
  fprintf(fid, '[SURVEY]\n');
  n = length(s.MD);
  tvd = vector_o_default(s, 'TVD', s.MD, n);
  inc = vector_o_default(s, 'inclinacion', zeros(n,1), n);
  azi = vector_o_default(s, 'azimut', zeros(n,1), n);
  idt = vector_o_default(s, 'ID_tubing', 0.062*ones(n,1), n);
  idc = vector_o_default(s, 'ID_casing', 0.100*ones(n,1), n);
  rug = vector_o_default(s, 'rugosidad', 4.57e-5*ones(n,1), n);
  for i = 1:n
      fprintf(fid, '%.3f,%.3f,%.3f,%.3f,%.6f,%.6f,%.8f\n', s.MD(i), tvd(i), inc(i), azi(i), idt(i), idc(i), rug(i));
  end
end

function escribir_punzados(fid, p)
  aos_punzados_escribir_aosdat(fid,p);
endfunction

function escribir_bm(fid, p)
  campos = {'D_bomba_mm','S_carrera','N_velocidad','eta_vol','eta_mecanica_BM','tipo_unidad', ...
            'modelo_unidad_BM','material_varillas','tuberia_anclada','usar_gibbs_BM','gibbs_n_t', ...
            'gibbs_n_ciclos','gibbs_n_nodos','gibbs_amortiguamiento','gibbs_metodo_forward', ...
            'slip_bomba','eficiencia_valvulas','friccion_bomba_N', ...
            'OD_tuberia_mm','ID_tuberia_mm','E_tuberia_Pa','longitud_piston_m', ...
            'holgura_radial_mm','temperatura_fondo_C','viscosidad_fluido_cP', ...
            'viscosidad_agua_cP','viscosidad_petroleo_estimado_cP','tipo_fluido_bm', ...
            'metodo_viscosidad','origen_viscosidad','origen_temperatura_fondo'};
  hay = false;
  for i = 1:length(campos)
      if isfield(p, campos{i})
          hay = true;
          break;
      end
  end
  if ~hay, return; end
  fprintf(fid, '\n[BOMBEO_MECANICO]\n');
  for i = 1:length(campos)
      c = campos{i};
      if isfield(p, c) && es_escalar_exportable(p.(c)), escribir_par(fid, c, p.(c)); end
  end
  if isfield(p, 'P_intake_min') && isnumeric(p.P_intake_min)
      escribir_par(fid, 'P_intake_min_bar', p.P_intake_min/1e5);
  end
end

function escribir_struct_generico(fid, nombre, s, excluir)
  if nargin < 4, excluir = {}; end
  fprintf(fid, '\n[%s]\n', upper(nombre));
  campos = fieldnames(s);
  for i = 1:length(campos)
      c = campos{i};
      if any(strcmp(c, excluir)), continue; end
      if es_escalar_exportable(s.(c)), escribir_par(fid, c, s.(c)); end
  end
end

function lista = escribir_si(fid, lista, campo, valor)
  if ~isempty(valor) && es_escalar_exportable(valor)
      escribir_par(fid, campo, valor);
      lista{end+1} = campo;
  end
end

function escribir_par(fid, campo, valor)
  campo = aos_sanitizar_campo(campo);
  if islogical(valor)
      if valor, txt = 'true'; else, txt = 'false'; end
  elseif isnumeric(valor) && isscalar(valor)
      if abs(valor) >= 1e6 || (abs(valor) > 0 && abs(valor) < 1e-5)
          txt = sprintf('%.10e', valor);
      else
          txt = sprintf('%.10g', valor);
      end
  elseif ischar(valor)
      txt = regexprep(valor, '[\r\n]+', ' ');
      txt = strrep(txt, '#', '-');
      txt = strtrim(txt);
  else
      return;
  end
  fprintf(fid, '%s=%s\n', campo, txt);
end

function geol = obtener_geologia(p)
  geol = struct();
  if isfield(p, 'geologia') && isstruct(p.geologia) && ~isempty(fieldnames(p.geologia))
      geol = p.geologia;
      return;
  end
  global geologia;
  if isstruct(geologia) && ~isempty(fieldnames(geologia)), geol = geologia; end
end

function pz = obtener_punzados(p)
  pz = [];
  if isfield(p, 'punzados') && es_punzados(p.punzados)
      pz = p.punzados;
      return;
  end
  geol = obtener_geologia(p);
  if isfield(geol, 'intervalos') && es_punzados(geol.intervalos), pz = geol.intervalos; end
end

function tf = es_punzados(p)
  tf = isstruct(p) && isfield(p, 'tramos') && ~isempty(p.tramos);
end

function tf = es_survey(s)
  tf = isstruct(s) && isfield(s, 'MD') && ~isempty(s.MD);
end

function tf = es_escalar_exportable(v)
  tf = (isnumeric(v) && isscalar(v) && isfinite(v)) || islogical(v) || ischar(v);
end

function v = leer(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && ~isempty(s.(campo)), v = s.(campo); end
end

function y = escala(x, factor)
  if isempty(x) || ~isnumeric(x) || ~isscalar(x) || ~isfinite(x), y = []; else, y = x*factor; end
end

function y = desplazar(x, delta)
  if isempty(x) || ~isnumeric(x) || ~isscalar(x) || ~isfinite(x), y = []; else, y = x+delta; end
end

function v = vector_o_default(s, campo, defecto, n)
  v = defecto(:);
  if isfield(s, campo) && isnumeric(s.(campo)) && length(s.(campo)) == n
      tmp = s.(campo);
      v = tmp(:);
  end
end

function out = interseccion_ordenada(preferidas, disponibles)
  out = {};
  for i = 1:length(preferidas)
      if any(strcmp(preferidas{i}, disponibles)), out{end+1} = preferidas{i}; end
  end
end

function out = upper_cell(c)
  out = cell(size(c));
  for i = 1:length(c), out{i} = upper(strtrim(c{i})); end
end

function nombre = sanitizar_nombre_archivo(nombre)
  if ~ischar(nombre), nombre = 'pozo_AOS'; end
  nombre = regexprep(strtrim(nombre), '[^A-Za-z0-9_-]+', '_');
  if isempty(nombre), nombre = 'pozo_AOS'; end
end

function cerrar_si_abierto(fid)
  if isnumeric(fid) && fid >= 0
      try, fclose(fid); catch, end
  end
end
