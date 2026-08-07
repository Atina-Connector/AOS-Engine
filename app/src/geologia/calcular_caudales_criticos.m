function criticos = calcular_caudales_criticos(geol, Ql, param_sim, intervalos)
  % calcular_caudales_criticos – Calcula los caudales máximos seguros
  % según modelos de la industria: Mohr‑Coulomb (arenamiento),
  % Craft & Hawkins (conificación) y API RP 14E (erosión en la formación).
  %
  % Entradas:
  %   geol      : estructura con parámetros geomecánicos (cargada con cargar_geologia)
  %   Ql        : caudal de líquido actual (m³/s), opcional para presión dinámica
  %   param_sim : estructura de parámetros de simulación (P_res, IP), opcional
  %   intervalos: (opcional) estructura con datos de punzados, mismo formato
  %               que la generada por cargar_intervalos_punzados.
  %               Si no se proporciona, se busca en geol.intervalos.
  %               Si aún así no existe, se ofrece cargarlos interactivamente
  %               o usar el cálculo simplificado (menos preciso).
  %
  % Salida:
  %   criticos : estructura con los siguientes campos (todos en m³/s):
  %       Q_arena      : caudal crítico de producción de arena
  %       Q_conifica   : caudal crítico de conificación de agua
  %       Q_erosion    : caudal crítico por erosión en la formación
  %       Q_seguro     : el más restrictivo de los tres dividido por factor_seguridad

  addpath(fullfile(fileparts(mfilename('fullpath')), 'modelos'));
  criticos = struct();
  criticos.confianza_geologica = aos_evaluar_confianza_geologica(geol);

  % --- 1. Caudal crítico de arenamiento (Mohr‑Coulomb simplificado) ---
  phi = geol.angulo_friccion_rad;
  coh = geol.cohesion;
  Sv  = geol.esfuerzo_vertical;
  Sh  = geol.esfuerzo_h_min;

  % Presión de poro dinámica (vinculada a la depletación)
  if nargin > 2 && ~isempty(param_sim) && isfield(param_sim, 'P_res') && isfield(param_sim, 'IP')
      P_res_sim = param_sim.P_res;
      IP_sim    = param_sim.IP;
      if nargin > 1 && ~isempty(Ql) && Ql > 0
          P_poro = P_res_sim - Ql / IP_sim;   % drawdown dinámico
      else
          P_poro = P_res_sim;
      end
  elseif isfield(geol, 'P_res')
      P_poro = geol.P_res;
  else
      P_poro = Sv * 0.9;   % estimación como último recurso
  end

  num = 3*Sh - Sv - 2*coh*cos(phi) - P_poro*(1 - sin(phi));
  den = 1 + sin(phi);
  if den > 1e-12
      delta_P_arena = num / den;
  else
      delta_P_arena = 0;
  end
  if delta_P_arena < 0
      delta_P_arena = 0;
  end

  if nargin > 2 && ~isempty(param_sim) && isfield(param_sim, 'IP')
      IP = param_sim.IP;
  elseif isfield(geol, 'IP')
      IP = geol.IP;
  else
      k_h = geol.permeabilidad_h;
      h   = geol.espesor_zona_petrolera;
      mu  = geol.mu_petroleo;
      Bo  = geol.B_o;
      re  = geol.radio_drenaje;
      rw  = geol.radio_pozo;
      IP = (2 * pi * k_h * h) / (mu * Bo * (log(re/rw) - 0.75 + geol.skin_factor));
  end
  criticos.Q_arena = IP * delta_P_arena;   % m³/s

  % --- 2. Conificacion de agua: modelo especifico o screening generico ---
  % Solo se considera limite vinculante cuando existen datos suficientes
  % del contacto/acuifero y anisotropia. En caso contrario se construye un
  % escenario generico orientativo que NO participa del caudal seguro.
  datos_cono_completos = false;
  if isfield(geol,'distancia_contacto_agua_m') && isfield(geol,'kv_kh')
      datos_cono_completos = isnumeric(geol.distancia_contacto_agua_m) && ...
          isfinite(geol.distancia_contacto_agua_m) && geol.distancia_contacto_agua_m > 0 && ...
          isnumeric(geol.kv_kh) && isfinite(geol.kv_kh) && geol.kv_kh > 0;
  end
  if datos_cono_completos
      drho = geol.rho_agua - geol.rho_petroleo;
      hp = min(geol.altura_perforados, geol.espesor_zona_petrolera*0.999);
      h = geol.espesor_zona_petrolera;
      num_cono = pi * geol.permeabilidad_h * drho * 9.81 * max(h^2-hp^2,0);
      den_cono = geol.mu_petroleo * geol.B_o * max(log(geol.radio_drenaje/geol.radio_pozo),0.1) * 2;
      criticos.Q_conifica = max(num_cono/max(den_cono,1e-30),0);
      criticos.conificacion_estado = 'ESPECIFICA_EVALUABLE';
      criticos.conificacion_vinculante = true;
  else
      criticos.Q_conifica = NaN;
      criticos.conificacion_generica = aos_conificacion_generica(geol, Ql);
      criticos.conificacion_estado = criticos.conificacion_generica.estado;
      criticos.conificacion_vinculante = false;
  end

  % --- 3. Resolver punzados y distribuir produccion ---
  addpath(fullfile(fileparts(mfilename('fullpath')), 'punzados'));
  if nargin<4||isempty(intervalos)
      intervalos=aos_obtener_punzados_activos(geol,param_sim);
  else
      [intervalos,~]=aos_punzados_normalizar(intervalos);
      if ~isempty(intervalos.tramos)
          intervalos.tramos=intervalos.tramos([intervalos.tramos.activo]);
      endif
  endif

  if isempty(intervalos.tramos)
      fprintf('\n--- DATOS DE PUNZADOS ---\n');
      fprintf('No hay intervalos activos. Puede configurarlos sin Survey ni geologia.\n');
      fprintf(' 1 - Abrir gestor transversal de punzados\n');
      fprintf(' 2 - Usar calculo simplificado de la cara del pozo\n');
      fprintf(' 0 - Cancelar el calculo\n');
      op=aos_leer_opcion('Seleccione [0-2]: ',2);
      if op==1
          [~,info_pz]=aos_punzados_administrar(struct('origen','CAUDALES_CRITICOS'));
          if info_pz.guardado
              intervalos=aos_obtener_punzados_activos(geol,param_sim);
          endif
      elseif op==0
          error('Calculo cancelado: no se definieron punzados.');
      endif
  endif

  distribucion=[];
  if ~isempty(intervalos.tramos)
      try
          distribucion=aos_distribuir_produccion_punzados(Ql,geol,intervalos,param_sim);
      catch err_dist
          warning('No se pudo distribuir produccion por punzados: %s',err_dist.message);
      end_try_catch
  endif

  % --- 4. Caudal critico por erosion en la formacion ---
  if ~isempty(intervalos.tramos)
      criticos.Q_erosion=calcular_erosion_punzados(geol,intervalos);
      if nargin>1&&~isempty(Ql)
          try
              criticos.distribucion_punzados= ...
                aos_distribuir_produccion_punzados(Ql,geol,intervalos,param_sim);
          catch err_dist
              criticos.distribucion_punzados_error=err_dist.message;
          end_try_catch
      endif
  else
      warning(['Usando calculo simplificado de erosion. ', ...
        'Considere configurar intervalos de punzados.']);
      C_erosion=120;
      rho_l=geol.rho_petroleo;
      rho_lbm=rho_l*0.062428;
      Ve_m_s=(C_erosion/sqrt(max(rho_lbm,1e-12)))*0.3048;
      A_cara=pi*(2*geol.radio_pozo)*geol.altura_perforados;
      criticos.Q_erosion=A_cara*Ve_m_s;
  endif

  % --- 5. Limites distribuidos por intervalo ---
  % Los limites globales se reparten con la misma transmisibilidad relativa.
  % Esto evita evaluar todo el caudal como si ingresara por un solo tiro.
  if ~isempty(distribucion)
      for ii = 1:length(distribucion.tramos)
          f = distribucion.tramos(ii).fraccion_aporte;
          distribucion.tramos(ii).Q_arena_lim_m3d = criticos.Q_arena * 86400 * f;
          if criticos.conificacion_vinculante
              distribucion.tramos(ii).Q_conifica_lim_m3d = criticos.Q_conifica * 86400 * f;
          else
              distribucion.tramos(ii).Q_conifica_lim_m3d = NaN;
          end
          % Erosion se calcula por area real de cada grupo de tiros.
          tr = intervalos.tramos(ii);
          dpunz = 0.010;
          if isfield(tr,'diametro_punzado_m') && ~isempty(tr.diametro_punzado_m), dpunz=tr.diametro_punzado_m; end
          rho_lbm = geol.rho_petroleo * 0.062428;
          vcrit = (120 / sqrt(max(rho_lbm,1e-12))) * 0.3048;
          qeros_i = distribucion.tramos(ii).n_tiros * pi*(dpunz/2)^2 * vcrit * 86400;
          distribucion.tramos(ii).Q_erosion_lim_m3d = qeros_i;
          distribucion.tramos(ii).margen_arena_pct = 100*(1-distribucion.tramos(ii).Ql_m3d/max(distribucion.tramos(ii).Q_arena_lim_m3d,1e-12));
          if criticos.conificacion_vinculante
              distribucion.tramos(ii).margen_conifica_pct = 100*(1-distribucion.tramos(ii).Ql_m3d/max(distribucion.tramos(ii).Q_conifica_lim_m3d,1e-12));
          else
              distribucion.tramos(ii).margen_conifica_pct = NaN;
          end
          distribucion.tramos(ii).margen_erosion_pct = 100*(1-distribucion.tramos(ii).Ql_m3d/max(qeros_i,1e-12));
      end
      criticos.distribucion_punzados = distribucion;
  end

  % --- 6. Caudal seguro provisional ---
  % Un mecanismo generico/no evaluable nunca equivale a cero y no participa
  % del minimo operativo. Se conserva como screening orientativo.
  limites = [criticos.Q_arena, criticos.Q_erosion];
  nombres = {'ARENAMIENTO','EROSION'};
  if criticos.conificacion_vinculante && isfinite(criticos.Q_conifica)
      limites(end+1)=criticos.Q_conifica; nombres{end+1}='CONIFICACION';
  end
  [Q_min,idx]=min(limites);
  criticos.Q_seguro = Q_min / geol.factor_seguridad;
  criticos.mecanismo_vinculante = nombres{idx};
  criticos.Q_seguro_provisional = ~criticos.confianza_geologica.uso_operativo || ~criticos.conificacion_vinculante;
  criticos.recomendar_choke = criticos.confianza_geologica.uso_operativo && criticos.conificacion_vinculante;
end
