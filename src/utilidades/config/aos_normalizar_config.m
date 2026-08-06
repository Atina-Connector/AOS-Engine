function [cfg, reporte] = aos_normalizar_config(cfg, modulo)
% AOS_NORMALIZAR_CONFIG Guardia transversal de configuracion AOS.
% Preserva todos los campos del .aosdat, resuelve aliases metricos y evita
% errores por estructuras corruptas sin modificar resultados fisicos.

  if nargin < 1 || ~isstruct(cfg), cfg = struct(); end
  if nargin < 2 || isempty(modulo), modulo = 'GENERAL'; end

  reporte = struct('modulo', modulo, 'avisos', {{}});

  if ~isfield(cfg,'aos_T_fondo_original_presente')
      cfg.aos_T_fondo_original_presente = isfield(cfg,'T_fondo') || ...
          isfield(cfg,'T_fondo_C') || isfield(cfg,'temperatura_fondo_C');
  end

  % Una configuracion ya normalizada puede contener cambios de menu, solver o
  % sensibilidad. En ese caso los campos canonicos son la fuente de verdad y
  % los aliases del .aosdat solo se conservan como metadata/unidades.
  preservar_runtime = bandera_verdadera(cfg, 'aos_config_normalizada');
  snap_runtime = struct();
  if preservar_runtime
      snap_runtime = aos_capturar_canonicos_runtime(cfg);
  end

  % Primero interpretar campos explicitos del .aosdat. Esto solo puede poblar
  % canonicos en la primera carga. En normalizaciones posteriores se restauran
  % inmediatamente las ediciones activas.
  try
      cfg = aos_aplicar_aliases_aosdat(cfg);
      if preservar_runtime
          cfg = aos_restaurar_canonicos_runtime(cfg, snap_runtime);
          cfg = restaurar_politicas_runtime(cfg, snap_runtime);
      end
  catch err
      reporte.avisos{end+1} = ['Aliases .aosdat incompletos: ', err.message];
      if preservar_runtime
          cfg = aos_restaurar_canonicos_runtime(cfg, snap_runtime);
          cfg = restaurar_politicas_runtime(cfg, snap_runtime);
      end
  end

  % Solo los grupos que el codigo indexa siempre como estructuras se crean
  % de manera obligatoria. Survey/geologia/punzados son opcionales: dejarlos
  % ausentes evita que un struct vacio sea confundido con datos cargados.
  grupos_requeridos = {'pozo','tubing','casing','fluidos','gl','bes','bm','int1'};
  for i = 1:length(grupos_requeridos)
      g = grupos_requeridos{i};
      if isfield(cfg, g)
          if isempty(cfg.(g))
              cfg.(g) = struct();
          elseif ~isstruct(cfg.(g))
              valor_original = cfg.(g);
              cfg.(g) = struct();
              campo_original = ['valor_original_', g];
              cfg.(campo_original) = valor_original;
              reporte.avisos{end+1} = sprintf('Campo %s no era estructura; preservado como %s.', g, campo_original);
          end
      else
          cfg.(g) = struct();
      end
  end

  grupos_opcionales = {'survey','geologia','punzados','estado_mecanico','benchmark_prosper','calibracion','jgl'};
  for i = 1:length(grupos_opcionales)
      g = grupos_opcionales{i};
      if isfield(cfg, g) && ~isempty(cfg.(g)) && ~isstruct(cfg.(g))
          campo_original = ['valor_original_', g];
          cfg.(campo_original) = cfg.(g);
          cfg.(g) = [];
          reporte.avisos{end+1} = sprintf('Campo opcional %s no era estructura; preservado como %s.', g, campo_original);
      end
  end

  % Defaults internos. La interfaz nunca pide Pa al usuario.
  cfg = set_default(cfg, 'P_res', 200e5);
  cfg = set_default(cfg, 'IP', 1 / 86400 / 1e5);
  cfg = set_default(cfg, 'WC', 0.50);
  cfg = set_default(cfg, 'GLR', 80);
  cfg = set_default(cfg, 'P_wh', 10e5);
  cfg = set_default(cfg, 'P_iny_sup', 0);
  cfg = set_default(cfg, 'D_bomba', 1500);
  cfg = set_default(cfg, 'D_iny', cfg.D_bomba);
  cfg = set_default(cfg, 'D_levantamiento', cfg.D_iny);
  cfg = set_default(cfg, 'D_res', cfg.D_bomba);
  cfg = set_default(cfg, 'API', 35);
  cfg = set_default(cfg, 'gamma_g', 0.7);
  cfg = set_default(cfg, 'T_sup', 298.15);
  cfg = set_default(cfg, 'T_fondo', 358.15);
  cfg = set_default(cfg, 'diam_tbg', 0.062);
  cfg = set_default(cfg, 'rho_o', 850);
  cfg = set_default(cfg, 'rho_w', 1000);
  cfg = set_default(cfg, 'rho_g_std', 0.8);
  cfg = set_default(cfg, 'R_gas', 519.6);
  cfg = set_default(cfg, 'modelo_IPR', 'linear');
  cfg = set_default(cfg, 'modelo_VLP', 'HB');
  cfg = set_default(cfg, 'factor_VLP', 1.0);
  cfg = set_default(cfg, 'factor_IP_residual', 1.0);

  % Presion de burbuja canonica en Pa. En runtime no volver a leer P_b_bar
  % porque puede contener el valor original del .aosdat.
  if preservar_runtime && isfield(cfg, 'P_b') && ~isempty(cfg.P_b)
      cfg.P_b = aos_presion_burbuja_pa(cfg.P_b, 100);
  elseif isfield(cfg, 'P_b_bar') && is_numeric_scalar(cfg.P_b_bar)
      cfg.P_b = cfg.P_b_bar * 1e5;
  elseif isfield(cfg, 'P_b') && ~isempty(cfg.P_b)
      cfg.P_b = aos_presion_burbuja_pa(cfg.P_b, 100);
  else
      cfg.P_b = 100e5;
  end

  % Estructuras comunes usadas por los motores existentes.
  cfg.pozo.D_res = getnum(cfg, 'D_res', cfg.D_res);
  cfg.pozo.D_packer = getnum(cfg, 'D_packer', getnum(cfg, 'D_iny', cfg.D_iny));
  cfg.pozo.D_tubing = getnum(cfg, 'D_tubing', max(cfg.pozo.D_packer - 50, 0));
  cfg.pozo.D_iny = getnum(cfg, 'D_iny', cfg.D_iny);

  cfg.tubing.ID = getnum(cfg, 'diam_tbg', cfg.diam_tbg);
  cfg.tubing.OD = getnum(cfg, 'OD_tbg', getnum_nested(cfg.tubing, 'OD', 0.073));
  cfg.casing.ID = getnum(cfg, 'ID_csg', getnum_nested(cfg.casing, 'ID', 0.100));

  cfg.fluidos.rho_o = getnum(cfg, 'rho_o', cfg.rho_o);
  cfg.fluidos.rho_w = getnum(cfg, 'rho_w', cfg.rho_w);
  cfg.fluidos.rho_g_std = getnum(cfg, 'rho_g_std', cfg.rho_g_std);
  cfg.fluidos.WC = getnum(cfg, 'WC', cfg.WC);
  cfg.fluidos.GLR = getnum(cfg, 'GLR', cfg.GLR);
  cfg.fluidos.API = getnum(cfg, 'API', cfg.API);
  cfg.fluidos.gamma_g = getnum(cfg, 'gamma_g', cfg.gamma_g);
  cfg.fluidos.P_b = getnum(cfg, 'P_b', cfg.P_b);

  cfg.gl.P_iny_sup = getnum(cfg, 'P_iny_sup', cfg.P_iny_sup);
  cfg.gl.D_valvula = getnum(cfg, 'D_iny', getnum(cfg, 'D_bomba', cfg.D_bomba));
  cfg.gl.gamma_g = getnum(cfg, 'gamma_g', cfg.gamma_g);
  cfg.gl.R_gas = getnum(cfg, 'R_gas', cfg.R_gas);
  if isfield(cfg, 'Q_iny') && is_numeric_scalar(cfg.Q_iny), cfg.gl.Q_iny = cfg.Q_iny; end

  cfg.int1.tope = getnum(cfg, 'int1_tope', getnum_nested(cfg.int1, 'tope', cfg.D_res));
  cfg.int1.base = getnum(cfg, 'int1_base', getnum_nested(cfg.int1, 'base', cfg.D_res + 100));
  cfg.int1.P_res = getnum(cfg, 'P_res', getnum_nested(cfg.int1, 'P_res', cfg.P_res));
  cfg.int1.IP = getnum(cfg, 'IP', getnum_nested(cfg.int1, 'IP', cfg.IP));

  % Punzados independientes: se normalizan sin exigir Survey ni geologia.
  fuente_pz=struct('tramos',struct([]));
  if isfield(cfg,'punzados')
      fuente_pz=cfg.punzados;
  elseif isfield(cfg,'geologia') && isstruct(cfg.geologia) && ...
         isfield(cfg.geologia,'intervalos')
      fuente_pz=cfg.geologia.intervalos;
  endif
  [cfg.punzados, avisos_pz]=aos_punzados_normalizar(fuente_pz, ...
    struct('origen','NORMALIZAR_CONFIG'));
  reporte.avisos=[reporte.avisos,avisos_pz];

  % Solo una geologia real recibe los intervalos. Nunca se fabrican
  % propiedades geologicas por el solo hecho de tener punzados.
  if isfield(cfg,'geologia') && isstruct(cfg.geologia) && ...
     ~isempty(fieldnames(cfg.geologia))
      cfg.geologia.intervalos=cfg.punzados;
      try
          cfg.geologia=aos_normalizar_geologia(cfg.geologia,cfg);
          cfg.punzados=cfg.geologia.intervalos;
      catch err
          reporte.avisos{end+1}=['Geologia no normalizada: ',err.message];
      end_try_catch
  endif

  % Profundidades por familia de modulo. GL/JGL consumen D_iny; BES/BM
  % conservan D_bomba. Esto evita que un alias de inyeccion pise la bomba.
  m = upper(strtrim(modulo));
  if any(strcmp(m, {'GL','JGL'}))
      cfg = aos_set_profundidad(cfg, m, getnum(cfg, 'D_iny', cfg.D_bomba));
  elseif any(strcmp(m, {'BES','BM'}))
      if isfield(cfg, 'D_bomba') && is_numeric_scalar(cfg.D_bomba)
          cfg = aos_set_profundidad(cfg, m, cfg.D_bomba);
      end
  end

  % Defaults especificos sin pisar datos importados.
  if strcmp(m, 'BES')
      cfg = set_default(cfg, 'curva_bomba_file', 'config/BES/curva_bomba.txt');
      cfg = set_default(cfg, 'frecuencia', 60);
      cfg = set_default(cfg, 'frecuencia_base', 60);
      cfg = set_default(cfg, 'num_etapas', 100);
  elseif strcmp(m, 'BM')
      cfg = set_default(cfg, 'D_bomba_mm', 32);
      cfg = set_default(cfg, 'S_carrera', 1.5);
      cfg = set_default(cfg, 'N_velocidad', 6);
      cfg = set_default(cfg, 'eta_vol', 0.80);
      cfg = set_default(cfg, 'tuberia_anclada', 1);
      cfg = set_default(cfg, 'OD_tuberia_mm', 73.0);
      cfg = set_default(cfg, 'ID_tuberia_mm', 62.0);
      cfg = set_default(cfg, 'E_tuberia_Pa', 207e9);
      cfg = set_default(cfg, 'longitud_piston_m', 1.20);
      cfg = set_default(cfg, 'holgura_radial_mm', 0.075);
      [cfg, info_bm_fluido] = aos_bm_propiedades_fluido(cfg);
      if isfield(info_bm_fluido,'avisos')
          for ia=1:numel(info_bm_fluido.avisos)
              reporte.avisos{end+1}=info_bm_fluido.avisos{ia};
          end
      end
      cfg.bm.D_bomba_mm = getnum(cfg, 'D_bomba_mm', 32);
      cfg.bm.S_carrera = getnum(cfg, 'S_carrera', 1.5);
      cfg.bm.N_velocidad = getnum(cfg, 'N_velocidad', 6);
      cfg.bm.tuberia_anclada = getnum(cfg, 'tuberia_anclada', 1);
      cfg.bm.OD_tuberia_mm = getnum(cfg, 'OD_tuberia_mm', 73.0);
      cfg.bm.ID_tuberia_mm = getnum(cfg, 'ID_tuberia_mm', 62.0);
      cfg.bm.E_tuberia_Pa = getnum(cfg, 'E_tuberia_Pa', 207e9);
      cfg.bm.longitud_piston_m = getnum(cfg, 'longitud_piston_m', 1.20);
      cfg.bm.holgura_radial_mm = getnum(cfg, 'holgura_radial_mm', 0.075);
      cfg.bm.temperatura_fondo_C = getnum(cfg, 'temperatura_fondo_C', 60.0);
      cfg.bm.viscosidad_fluido_cP = getnum(cfg, 'viscosidad_fluido_cP', 1.0);
  end

  % Publicar aliases desde los canonicos activos. La direccion inversa queda
  % limitada a la primera importacion del .aosdat.
  try
      cfg = aos_sincronizar_aliases_canonicos(cfg);
  catch err
      reporte.avisos{end+1} = ['No se pudieron sincronizar aliases canonicos: ', err.message];
  end

  cfg.aos_config_normalizada = true;
  cfg.aos_config_normalizada_modulo = modulo;
end

function cfg = set_default(cfg, campo, valor)
  if ~isfield(cfg, campo) || isempty(cfg.(campo))
      cfg.(campo) = valor;
  end
end

function tf = is_numeric_scalar(x)
  tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

function v = getnum(cfg, campo, defecto)
  v = defecto;
  if isfield(cfg, campo)
      x = cfg.(campo);
      if is_numeric_scalar(x)
          v = x;
      elseif ischar(x)
          y = str2double(x);
          if ~isnan(y), v = y; end
      end
  end
end

function v = getnum_nested(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo) && is_numeric_scalar(s.(campo))
      v = s.(campo);
  end
end

function tf = bandera_verdadera(s, campo)
  tf = false;
  if ~isstruct(s) || ~isfield(s,campo) || isempty(s.(campo)), return; end
  v = s.(campo);
  if islogical(v) || isnumeric(v)
      tf = isfinite(double(v(1))) && double(v(1)) ~= 0;
  elseif ischar(v)
      t = lower(strtrim(v));
      tf = any(strcmp(t, {'1','true','si','s','yes','y'}));
  end
end
function cfg = restaurar_politicas_runtime(cfg, snap)
  % Algunos modos se expresan justamente por la ausencia de un campo. Los
  % aliases importados no deben recrearlo durante una normalizacion runtime.
  if isstruct(snap) && isfield(snap,'qiny_modo') && ischar(snap.qiny_modo) && ...
     strcmpi(strtrim(snap.qiny_modo),'automatico')
      cfg = aos_set_qiny(cfg, 0, 'automatico');
  end
end

