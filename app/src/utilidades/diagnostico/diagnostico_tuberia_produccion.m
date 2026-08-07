function diag = diagnostico_tuberia_produccion(param, sistema, Ql, Qiny, opciones)
  % diagnostico_tuberia_produccion.m
  % Modulo comun para diagnosticar la tuberia de produccion en AOS.
  %
  % Objetivo:
  %   Usar UN SOLO diagnostico de erosion, carga de liquido y regimen Taitel
  %   para JGL, GL convencional, BES, Bombeo Mecanico y sistemas futuros.
  %
  % Formas de uso compatibles con Octave:
  %   diag = diagnostico_tuberia_produccion(param, 'JGL', Ql, Qiny)
  %   diag = diagnostico_tuberia_produccion(param, 'BES', Ql, 0, opciones)
  %   resultados.Ql = Ql; resultados.Qiny = Qiny; resultados.Qgas_total = Qg;
  %   diag = diagnostico_tuberia_produccion(param, 'NUEVO', resultados)
  %
  % Unidades esperadas:
  %   Ql, Qiny, Qgas_total : m3/s a condiciones estandar cuando corresponda.
  %   Presiones            : Pa.
  %   Temperaturas         : K.
  %   Profundidades        : m MD/TVD.

  if nargin < 1 || isempty(param)
      error('diagnostico_tuberia_produccion requiere una estructura param.');
  end
  if nargin < 2 || isempty(sistema)
      sistema = 'AOS';
  end
  if nargin < 5 || isempty(opciones)
      opciones = struct();
  end

  % Permite pasar un struct de resultados como tercer argumento.
  if nargin >= 3 && isstruct(Ql)
      resultados = Ql;
      if nargin >= 4 && isstruct(Qiny)
          opciones = unir_structs(opciones, Qiny);
      end
      Ql = leer_num(resultados, {'Ql','Q_liq','Qliq','Q_liquido'}, leer_num(param, {'Ql','Q_liq','Qliq'}, 0));
      Qiny = leer_num(resultados, {'Qiny','Q_iny','Qgas_iny','Qgas_inyectado'}, leer_num(param, {'Qiny','Q_iny','Qiny_plot'}, 0));
      if ~isfield(opciones, 'Qgas_total_std')
          opciones.Qgas_total_std = leer_num(resultados, {'Qgas_total','Qg_total','Qgas_total_std','Q_total_gas'}, NaN);
      end
  else
      if nargin < 3 || isempty(Ql)
          Ql = leer_num(param, {'Ql','Q_liq','Qliq'}, 0);
      end
      if nargin < 4 || isempty(Qiny)
          Qiny = leer_num(param, {'Qiny','Q_iny','Qiny_plot'}, 0);
      end
  end

  if ~isfield(opciones, 'graficar'), opciones.graficar = true; end
  if ~isfield(opciones, 'detalle'), opciones.detalle = true; end
  if ~isfield(opciones, 'mostrar_tabla'), opciones.mostrar_tabla = opciones.detalle; end
  if ~isfield(opciones, 'max_filas_tabla'), opciones.max_filas_tabla = 30; end

  diag = struct();
  fprintf('\n--- DIAGNOSTICO COMUN DE TUBERIA (%s) ---\n', sistema);

  % Resolver survey. Si el .aosdat trae solo 2 puntos, obtener_survey intenta
  % reemplazarlo por un survey completo del proyecto.
  survey = obtener_survey(param);
  if isempty(survey) || ~isstruct(survey) || ~isfield(survey, 'MD') || isempty(survey.MD)
      fprintf('No se genero diagnostico: no hay survey disponible.\n');
      return;
  end
  param.survey = survey;

  perfil = calcular_perfil_tuberia_produccion(param, survey, Ql, Qiny, opciones);

  diag.sistema = sistema;
  diag.param = param;
  diag.survey = survey;
  diag.perfil = perfil;
  diag.alerta = perfil.alerta;
  diag.regimenes = perfil.regimenes;
  diag.V_real = perfil.Vsg;          % compatibilidad: velocidad superficial de gas
  diag.Vmix = perfil.Vmix;
  diag.V_eros = perfil.V_eros;
  diag.V_carga = perfil.V_carga;
  diag.Qgas_form_std = perfil.Qgas_form_std;
  diag.Qgas_iny_std = perfil.Qiny_std;
  diag.Qgas_total_std = perfil.Qgas_total_std;
  diag.Qgas_profile_std = perfil.Qgas_profile_std;

  global ULTIMO_DIAG_TUBERIA;
  ULTIMO_DIAG_TUBERIA = diag;

  imprimir_resumen_tuberia(perfil, sistema);

  if opciones.mostrar_tabla
      imprimir_tabla_tuberia(perfil, opciones.max_filas_tabla);
  end

  if opciones.graficar
      try
          plot_erosion_taitel(diag);
          drawnow;
      catch err
          fprintf('No se pudo graficar erosion/Taitel: %s\n', err.message);
      end
  end

  fprintf('------------------------------------------\n');
end

function imprimir_resumen_tuberia(perfil, sistema)
  fprintf('Sistema evaluado : %s\n', sistema);
  fprintf('Survey usado     : %d puntos, MD %.1f - %.1f m, TVD %.1f - %.1f m\n', ...
          length(perfil.MD), min(perfil.MD), max(perfil.MD), min(perfil.TVD), max(perfil.TVD));
  if perfil.survey_simplificado
      fprintf('Aviso: el survey usado tiene pocos puntos; el diagnostico sera menos detallado.\n');
  end
  if isfinite(perfil.D_inyeccion) && perfil.Qiny_std > 0
      fprintf('Prof. iny/levant.: %.1f m MD. El gas inyectado se aplica por encima de esa profundidad.\n', perfil.D_inyeccion);
  elseif perfil.Qiny_std > 0
      fprintf('Prof. iny/levant.: no definida. El gas inyectado se aplica a toda la tuberia.\n');
  end

  fprintf('Liquido total    : %s\n', aos_formato_caudal_liquido(perfil.Ql));
  fprintf('Gas formacion    : %s\n', aos_formato_caudal_gas(perfil.Qgas_form_std));
  fprintf('Gas inyectado    : %s\n', aos_formato_caudal_gas(perfil.Qiny_std));
  fprintf('Gas total sup.   : %s\n', aos_formato_caudal_gas(perfil.Qgas_total_std));

  [uso_erosion, idxe] = max(perfil.ratio_erosion);
  [margen_carga, idxc] = min(perfil.ratio_carga);
  fprintf('Uso max. erosion : %.2f x limite en MD %.1f m\n', uso_erosion, perfil.MD(idxe));
  fprintf('Margen min. carga: %.2f x Turner en MD %.1f m\n', margen_carga, perfil.MD(idxc));
  if isfield(perfil, 'criterio_regimen')
      fprintf('Regimen flujo    : %s\n', perfil.criterio_regimen);
  else
      fprintf('Regimen flujo    : Taitel-Dukler simplificado orientativo\n');
  end

  if ~isempty(perfil.alerta.erosion)
      fprintf('*** ALERTA: velocidad erosiva excedida en %s ***\n', rango_md(perfil.MD, perfil.alerta.erosion));
  else
      fprintf('Velocidad dentro del limite erosivo API RP 14E simplificado.\n');
  end

  if ~isempty(perfil.alerta.carga)
      fprintf('*** ALERTA: riesgo de carga de liquido en %s ***\n', rango_md(perfil.MD, perfil.alerta.carga));
  else
      fprintf('Velocidad de gas suficiente contra carga liquida segun Turner simplificado.\n');
  end

  if ~isempty(perfil.alerta.slug)
      fprintf('Aviso: regimen SLUG/SLUG SEVERO detectado en %s segun criterio simplificado.\n', rango_md(perfil.MD, perfil.alerta.slug));
  end
  if ~isempty(perfil.alerta.transicion)
      fprintf('Aviso: regimen de TRANSICION detectado en %s segun criterio simplificado.\n', rango_md(perfil.MD, perfil.alerta.transicion));
  end

  fprintf('Regimen dominante: %s\n', regimen_dominante(perfil.regimenes));
end

function imprimir_tabla_tuberia(perfil, max_filas)
  n = length(perfil.MD);
  if n == 0, return; end
  if nargin < 2 || isempty(max_filas), max_filas = 30; end
  if n <= max_filas
      idx = 1:n;
      fprintf('\nDetalle por punto del survey:\n');
  else
      idx = unique(round(linspace(1, n, max_filas)));
      fprintf('\nDetalle por punto del survey (muestra %d de %d puntos):\n', length(idx), n);
  end
  fprintf('  MD(m) TVD(m) Inc(deg) ID(m) Qg(Sm3/d) Vsg  Vsl  Vmix  Veros Vcarga Eros Carga Regimen\n');
  fprintf(' ------ ------ -------- ----- --------- ---- ---- ----- ----- ------ ---- ----- -------\n');
  for k = 1:length(idx)
      i = idx(k);
      reg = perfil.regimenes{i};
      fprintf('%7.0f %6.0f %8.1f %5.3f %9.0f %4.2f %4.2f %5.2f %5.2f %6.2f %4.2f %5.2f %s\n', ...
          perfil.MD(i), perfil.TVD(i), perfil.inclinacion(i), perfil.ID(i), ...
          aos_m3s_a_sm3d(perfil.Qgas_profile_std(i)), perfil.Vsg(i), perfil.Vsl(i), perfil.Vmix(i), ...
          perfil.V_eros(i), perfil.V_carga(i), perfil.ratio_erosion(i), perfil.ratio_carga(i), reg);
  end
end

function s = rango_md(MD, idx)
  if isempty(idx)
      s = '(sin puntos)';
      return;
  end
  vals = MD(idx);
  if length(vals) == 1
      s = sprintf('MD %.1f m', vals(1));
  else
      s = sprintf('MD %.1f - %.1f m (%d puntos)', min(vals), max(vals), length(vals));
  end
end

function nombre = regimen_dominante(regimenes)
  if isempty(regimenes)
      nombre = 'desconocido';
      return;
  end
  candidatos = {'burbuja','slug','slug_severo','transicion','niebla','desconocido'};
  conteos = zeros(size(candidatos));
  for i = 1:length(candidatos)
      conteos(i) = sum(strcmp(regimenes, candidatos{i}));
  end
  [~, idx] = max(conteos);
  nombre = candidatos{idx};
end

function y = convertir_m3s_a_mmscfd(q)
  y = q * 86400 / 0.0283168 / 1e6;
end

function v = leer_num(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
      nombre = nombres{k};
      if isfield(s, nombre)
          tmp = s.(nombre);
          if isnumeric(tmp) && ~isempty(tmp)
              v = tmp(1);
              return;
          end
      end
  end
end

function out = unir_structs(a, b)
  out = a;
  if ~isstruct(b), return; end
  campos = fieldnames(b);
  for i = 1:length(campos)
      out.(campos{i}) = b.(campos{i});
  end
end
