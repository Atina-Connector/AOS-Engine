function BM_operativo_menu()
% BM_operativo_menu.m - Simulacion de Bombeo Mecanico (BM)
% Interfaz interactiva con diseno de varillas, cartas Gibbs por ecuacion de onda,
% diagnostico comun de tuberia y almacenamiento para .aosrpt.

script_dir = fileparts(mfilename('fullpath'));
AOS_root = fileparts(fileparts(script_dir));
addpath(fullfile(AOS_root, 'src'), '-begin');
addpath(script_dir, '-begin');
iniciar_aos;
cd(AOS_root);

% --- Submenu BM: simulacion operativa o laboratorio Gibbs ---
fprintf('\n--- BOMBEO MECANICO / GIBBS ---\n');
fprintf('  1 - Simular Bombeo Mecanico operativo\n');
fprintf('  2 - Laboratorio Gibbs experimental\n');
fprintf('  3 - BM Gibbs Solver Foundation v18 (Octave)\n');
fprintf('  0 - Volver\n');
op_bm = input('Seleccione una opcion: ');
if isempty(op_bm), op_bm = 1; end
if op_bm == 2
    gibbs_lab_menu;
    return;
elseif op_bm == 3
    gibbs18_menu;
    return;
elseif op_bm == 0
    return;
end

% --- Cargar configuracion base segun arquitectura AOS ---
[param, origen_config] = aos_config_base('BM');
param = aos_normalizar_config(param, 'BM');
fprintf('Usando %s.\n', origen_config);

% --- Defaults BM defensivos ---
if ~isfield(param, 'D_bomba_mm'), param.D_bomba_mm = 32; end
if ~isfield(param, 'S_carrera'),  param.S_carrera  = 1.5; end
if ~isfield(param, 'N_velocidad'),param.N_velocidad = 6; end
if ~isfield(param, 'eta_vol'),    param.eta_vol    = 0.80; end
if ~isfield(param, 'tipo_unidad'), param.tipo_unidad = 'Convencional'; end
if ~isfield(param, 'material_varillas'), param.material_varillas = 'Acero Grado D'; end
if ~isfield(param, 'tuberia_anclada'), param.tuberia_anclada = 1; end
if ~isfield(param, 'P_intake_min'), param.P_intake_min = 1e5; end
if ~isfield(param, 'eta_mecanica_BM'), param.eta_mecanica_BM = 0.75; end
param = aos_bm_propiedades_fluido(param);

% --- Seleccion de material de varillas ---
if exist('config/BM/materiales_varillas.txt', 'file')
    mats = cargar_materiales_varillas();
    fprintf('\n--- MATERIALES DE VARILLAS ---\n');
    for k = 1:length(mats)
        fprintf('  %d - %s (fatiga %.0f MPa, densidad %.0f kg/m3)\n', ...
            k, mats(k).nombre, mats(k).limite_fatiga_MPa, mats(k).densidad_kg_m3);
    end
    fprintf('  0 - Mantener actual [%s]\n', param.material_varillas);
    op_mat = input('Seleccione material: ');
    if ~isempty(op_mat) && op_mat > 0 && op_mat <= length(mats)
        param.material_varillas = mats(op_mat).nombre;
    end
else
    fprintf('Aviso: no se encontro config/BM/materiales_varillas.txt. Se usa %s.\n', param.material_varillas);
end
fprintf('Material seleccionado: %s\n', param.material_varillas);

% --- Seleccion de unidad de bombeo ---
if exist('config/BM/unidades.txt', 'file')
    catalogo = cargar_catalogo_bm();
    fprintf('\n--- UNIDADES DE BOMBEO DISPONIBLES ---\n');
    for k = 1:length(catalogo)
        fprintf('  %d - %s %s (carrera max %.1f m, SPM max %.0f, torque %.0f klb-in)\n', ...
            k, catalogo(k).modelo, catalogo(k).tipo, ...
            catalogo(k).carrera_max_m, catalogo(k).vel_max_gpm, catalogo(k).torque_max_klb_in);
    end
    fprintf('  0 - Mantener actual [%s]\n', param.tipo_unidad);
    op_unidad = input('Seleccione unidad: ');
    if ~isempty(op_unidad) && op_unidad > 0 && op_unidad <= length(catalogo)
        param.tipo_unidad = catalogo(op_unidad).tipo;
        param.modelo_unidad_BM = catalogo(op_unidad).modelo;
        param.torque_max_klb_in = catalogo(op_unidad).torque_max_klb_in;
        if param.S_carrera > catalogo(op_unidad).carrera_max_m
            fprintf('Aviso: carrera %.2f m excede maximo %.2f m. Ajustando.\n', ...
                param.S_carrera, catalogo(op_unidad).carrera_max_m);
            param.S_carrera = catalogo(op_unidad).carrera_max_m;
        end
        if param.N_velocidad > catalogo(op_unidad).vel_max_gpm
            fprintf('Aviso: velocidad %.0f golpes/min excede maximo %.0f. Ajustando.\n', ...
                param.N_velocidad, catalogo(op_unidad).vel_max_gpm);
            param.N_velocidad = catalogo(op_unidad).vel_max_gpm;
        end
        fprintf('Unidad seleccionada: %s (%s)\n', catalogo(op_unidad).modelo, catalogo(op_unidad).tipo);
    end
else
    fprintf('Aviso: no se encontro config/BM/unidades.txt. Se usa unidad por defecto.\n');
end

% --- Tuberia anclada/libre ---
param.tuberia_anclada = aos_preguntar_sn( ...
    sprintf('Tuberia anclada? (s/n) [%s]: ', aos_sn(param.tuberia_anclada)), ...
    logical(param.tuberia_anclada));
fprintf('Condicion de tuberia: %s.\n', aos_texto_anclada(param.tuberia_anclada));

% --- Menu de parametros ---
fprintf('\n--- PARAMETROS ACTUALES (BM) ---\n');
fprintf('IP                      : %.2f m3/d/bar\n', param.IP / 1.1574e-10);
fprintf('WC                      : %.2f\n', param.WC);
fprintf('P_wh                    : %s\n', aos_formato_presion(param.P_wh, 1));
fprintf('D_bomba                 : %s\n', aos_formato_longitud(param.D_bomba, 1));
fprintf('GLR                     : %.1f sm3/m3\n', param.GLR);
fprintf('Diametro bomba          : %.0f mm\n', param.D_bomba_mm);
fprintf('Carrera                 : %.2f m\n', param.S_carrera);
fprintf('Velocidad               : %.0f golpes/min\n', param.N_velocidad);
fprintf('Eficiencia volumetrica  : %.2f\n', param.eta_vol);
fprintf('Eficiencia mecanica     : %.2f\n', param.eta_mecanica_BM);
fprintf('P intake minima         : %.1f bar\n', param.P_intake_min / 1e5);
fprintf('Tipo de unidad          : %s\n', param.tipo_unidad);
fprintf('Material varillas       : %s\n', param.material_varillas);
fprintf('Tuberia                 : %s\n', aos_texto_anclada(param.tuberia_anclada));
fprintf('OD/ID tuberia           : %.1f / %.1f mm\n', param.OD_tuberia_mm, param.ID_tuberia_mm);
fprintf('Longitud piston         : %.3f m\n', param.longitud_piston_m);
fprintf('Holgura radial          : %.4f mm\n', param.holgura_radial_mm);
fprintf('Temperatura fondo       : %.1f C [%s]\n', param.temperatura_fondo_C, param.origen_temperatura_fondo);
fprintf('Viscosidad fluido       : %.3f cP [%s]\n', param.viscosidad_fluido_cP, param.origen_viscosidad);
fprintf('---------------------------------------\n');

if aos_preguntar_sn('Modificar los parametros? (s/n) [n]: ', false)
    val = input(sprintf('  IP (m3/d/bar) [%.2f]: ', param.IP / 1.1574e-10));
    if ~isempty(val), param.IP = val * 1.1574e-10; end
    val = input(sprintf('  WC (fraccion) [%.2f]: ', param.WC));
    if ~isempty(val), param.WC = val; end
    val = input(sprintf('  P_wh (bar) [%.1f]: ', param.P_wh / 1e5));
    if ~isempty(val), param.P_wh = val * 1e5; end
    val = input(sprintf('  D_bomba (m) [%.0f]: ', param.D_bomba));
    if ~isempty(val), param = aos_set_profundidad(param, 'BM', val); end
    val = input(sprintf('  GLR (sm3/m3) [%.1f]: ', param.GLR));
    if ~isempty(val), param.GLR = val; end
    val = input(sprintf('  Diametro bomba (mm) [%.0f]: ', param.D_bomba_mm));
    if ~isempty(val), param.D_bomba_mm = val; end
    val = input(sprintf('  Carrera (m) [%.2f]: ', param.S_carrera));
    if ~isempty(val), param.S_carrera = val; end
    val = input(sprintf('  Velocidad (golpes/min) [%.0f]: ', param.N_velocidad));
    if ~isempty(val), param.N_velocidad = val; end
    val = input(sprintf('  Eficiencia volumetrica [%.2f]: ', param.eta_vol));
    if ~isempty(val), param.eta_vol = val; end
    val = input(sprintf('  Eficiencia mecanica BM [%.2f]: ', param.eta_mecanica_BM));
    if ~isempty(val), param.eta_mecanica_BM = val; end
    val = input(sprintf('  P intake minima (bar) [%.1f]: ', param.P_intake_min/1e5));
    if ~isempty(val), param.P_intake_min = val * 1e5; end
    val = input(sprintf('  OD tuberia (mm) [%.1f]: ', param.OD_tuberia_mm));
    if ~isempty(val), param.OD_tuberia_mm = val; end
    val = input(sprintf('  ID tuberia (mm) [%.1f]: ', param.ID_tuberia_mm));
    if ~isempty(val), param.ID_tuberia_mm = val; end
    val = input(sprintf('  Modulo E tuberia (GPa) [%.1f]: ', param.E_tuberia_Pa/1e9));
    if ~isempty(val), param.E_tuberia_Pa = val*1e9; end
    val = input(sprintf('  Longitud piston (m) [%.3f]: ', param.longitud_piston_m));
    if ~isempty(val), param.longitud_piston_m = val; end
    val = input(sprintf('  Holgura RADIAL piston-barril (mm) [%.4f]: ', param.holgura_radial_mm));
    if ~isempty(val), param.holgura_radial_mm = val; end
    val = input(sprintf('  Temperatura fondo (C) [%.1f]: ', param.temperatura_fondo_C));
    if ~isempty(val), param.temperatura_fondo_C = val; param.origen_temperatura_fondo='MANUAL'; end
    val = input(sprintf('  Viscosidad fluido (cP; 0=estimar) [%.3f]: ', param.viscosidad_fluido_cP));
    if ~isempty(val)
        if val > 0
            param.viscosidad_fluido_cP=val; param.origen_viscosidad='MANUAL'; param.metodo_viscosidad='EXPLICITA';
        else
            if isfield(param,'viscosidad_fluido_cP'), param=rmfield(param,'viscosidad_fluido_cP'); end
            param.origen_viscosidad='AUTO';
        end
    end
    param = aos_bm_propiedades_fluido(param);
    fprintf('Parametros actualizados.\n');
else
    fprintf('Se conservan los parametros de configuracion.\n');
end

% --- Seleccion de modelo IPR; el .aosdat define el default ---
fprintf('\n--- CONFIGURACION DE SIMULACION BM ---\n');
fprintf('Modelos IPR: 1-Linear | 2-Vogel | 3-Fetkovich\n');
op_def = aos_opcion_modelo_ipr(param.modelo_IPR);
opcion = input(sprintf('Seleccione IPR (1-3) [%d]: ', op_def));
if isempty(opcion), opcion = op_def; end
if opcion == 2
    param.modelo_IPR = 'Vogel';
    P_b_def = param.P_b / 1e5;
    val = input(sprintf('Presion de burbuja (bar) [%.2f]: ', P_b_def));
    if ~isempty(val), param.P_b = val * 1e5; end
elseif opcion == 3
    param.modelo_IPR = 'Fetkovich';
else
    param.modelo_IPR = 'linear';
end
fprintf('Modelo IPR usado: %s\n', param.modelo_IPR);

% --- Consolidar snapshot runtime y asegurar survey ---
param = aos_sincronizar_config(param, 'BM');
param.survey = obtener_survey(param);

% --- Ejecutar simulacion BM ---
[Ql, Qo, potencia, diagnostico, bm_detalle] = BM_core(param);
param.BM_resultado = bm_detalle;

% --- Diseno / recuperacion de varillas desde BM_core ---
varillas = [];
if isstruct(bm_detalle) && isfield(bm_detalle, 'varillas')
    varillas = bm_detalle.varillas;
    param.varillas = varillas;
elseif Ql > 0
    varillas = diseno_varillas(param, Ql);
    param.varillas = varillas;
end
if isstruct(bm_detalle) && isfield(bm_detalle, 'gibbs')
    param.BM_resultado = bm_detalle;
end

% --- Resultados ---
BM_imprimir_resultados(Ql, Qo, potencia, diagnostico, bm_detalle);
if ~isempty(varillas)
    BM_imprimir_varillas(varillas);
end

% --- Ajuste opcional de velocidad ---
if Ql > 0
    fprintf('\n--- AJUSTE DE VELOCIDAD ---\n');
    fprintf('Velocidad actual: %.0f golpes/min\n', param.N_velocidad);
    if aos_preguntar_sn('Ajustar los golpes/min? (s/n) [n]: ', false)
        nuevo_gpm = input(sprintf('Nuevos golpes/min [%.0f]: ', param.N_velocidad));
        if ~isempty(nuevo_gpm) && nuevo_gpm > 0
            param.N_velocidad = nuevo_gpm;
            param = aos_sincronizar_config(param, 'BM');
            [Ql, Qo, potencia, diagnostico, bm_detalle] = BM_core(param);
            param.BM_resultado = bm_detalle;
            if isstruct(bm_detalle) && isfield(bm_detalle, 'varillas')
                varillas = bm_detalle.varillas;
                param.varillas = varillas;
            elseif Ql > 0
                varillas = diseno_varillas(param, Ql);
                param.varillas = varillas;
            else
                varillas = [];
                if isfield(param, 'varillas'), param = rmfield(param, 'varillas'); end
            end
            if isstruct(bm_detalle) && isfield(bm_detalle, 'gibbs')
                param.BM_resultado = bm_detalle;
            end
            fprintf('\n--- RESULTADOS ACTUALIZADOS ---\n');
            BM_imprimir_resultados(Ql, Qo, potencia, diagnostico, bm_detalle);
            if ~isempty(varillas)
                BM_imprimir_varillas(varillas);
            end
        end
    end
end

% --- Gibbs y diagnosticos BM ---
if Ql > 0 && ~isempty(varillas)
    opciones_gibbs = struct();
    opciones_gibbs.graficar = true;
    opciones_gibbs.imprimir = true;
    opciones_gibbs.n_puntos = 500;
    opciones_gibbs.n_tabla = 30;
    try
        diag_gibbs = diagnostico_bm_gibbs(param, Ql, varillas, opciones_gibbs);
        param.cartas_sup = diag_gibbs.tabla_sup;
        param.cartas_fondo = diag_gibbs.tabla_fondo;
        param.diagnostico_gibbs = diag_gibbs;
    catch err
        fprintf('No se pudo generar diagnostico Gibbs BM: %s\n', err.message);
    end
end

% --- Diagnostico comun de tuberia: erosion, carga y Taitel ---
try
    opciones_tuberia = struct();
    if isfield(param, 'D_bomba'), opciones_tuberia.D_inyeccion = param.D_bomba; end
    opciones_tuberia.detalle = true;
    diagnostico_tuberia = diagnostico_tuberia_produccion(param, 'BM', Ql, 0, opciones_tuberia);
    param.diagnostico_tuberia = diagnostico_tuberia;
catch err
    fprintf('No se pudo generar diagnostico comun de tuberia: %s\n', err.message);
end

% --- Semaforos operativos globales AOS ---
try
    extras_sem = struct();
    if exist('bm_detalle', 'var') && isstruct(bm_detalle), extras_sem = bm_detalle; end
    if exist('varillas', 'var'), param.varillas = varillas; end
    if exist('diagnostico_tuberia', 'var'), param.diagnostico_tuberia = diagnostico_tuberia; end
    semaforos = aos_semaforo_operacion('BM', param, Ql, Qo, 0, bm_detalle);
    param.semaforos = semaforos;
    aos_imprimir_semaforos(semaforos, 'BM');
catch err
    fprintf('No se pudo generar semaforos operativos BM: %s\n', err.message);
end

fprintf('=======================================\n');

% --- Almacenar para exportacion/reporte ---
global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
ULTIMO_QL = Ql;
ULTIMO_QO = Qo;
ULTIMO_QINY = 0;
ULTIMO_TIPO = 'BM';
param = aos_sincronizar_config(param, 'BM');
ULTIMO_PARAM = param;

preguntar_exportar_aosrpt;

end

function s = aos_sn(valor)
  if valor
      s = 's';
  else
      s = 'n';
  end
end

function s = aos_texto_anclada(valor)
  if valor
      s = 'anclada';
  else
      s = 'libre/no anclada';
  end
end

function BM_imprimir_resultados(Ql, Qo, potencia, diagnostico, detalle)
  fprintf('\n===== RESULTADOS BOMBEO MECANICO =====\n');
  fprintf('Liquido total       : %s\n', aos_formato_caudal_liquido(Ql));
  fprintf('Petroleo            : %s\n', aos_formato_caudal_liquido(Qo));
  fprintf('Potencia estimada   : %.2f kW\n', potencia / 1000);
  if nargin >= 5 && isstruct(detalle)
      if isfield(detalle, 'Q_teorico')
          fprintf('Q geom. superficie  : %s\n', aos_formato_caudal_liquido(detalle.Q_teorico));
      end
      if isfield(detalle, 'Q_teorico_fondo')
          fprintf('Q geom. fondo       : %s\n', aos_formato_caudal_liquido(detalle.Q_teorico_fondo));
      end
      if isfield(detalle, 'Q_bomba')
          fprintf('Q bomba efectivo    : %s\n', aos_formato_caudal_liquido(detalle.Q_bomba));
      end
      if isfield(detalle, 'S_superficie_m')
          fprintf('Carrera superficie  : %s\n', aos_formato_longitud(detalle.S_superficie_m, 3));
      end
      if isfield(detalle, 'S_fondo_m')
          fprintf('Carrera fondo       : %s\n', aos_formato_longitud(detalle.S_fondo_m, 3));
      end
      if isfield(detalle, 'llenado_bomba')
          fprintf('Llenado estimado    : %.1f %%\n', detalle.llenado_bomba * 100);
      end
      if isfield(detalle, 'espaciamiento') && isstruct(detalle.espaciamiento)
          fprintf('Espaciamiento recom.: %s\n', aos_formato_longitud(detalle.espaciamiento.recomendacion_m, 2));
      end
      if isfield(detalle, 'P_intake')
          fprintf('P intake estimada   : %s\n', aos_formato_presion(detalle.P_intake, 2));
      end
  end
  if ~isempty(diagnostico)
      fprintf('Diagnostico         : %s\n', diagnostico);
  end
end

function BM_imprimir_varillas(varillas)
  fprintf('\n--- CONFIGURACION DE VARILLAS ---\n');
  for i = 1:length(varillas.secciones)
      sec = varillas.secciones(i);
      fprintf('Seccion %d: %.0f mm (%.3f in) - %.0f m\n', i, sec.diametro_mm, sec.diametro_pulg, sec.longitud_m);
  end
  fprintf('Material                  : %s\n', varillas.material);
  fprintf('Peso flotado varillas     : %.0f kgf\n', varillas.peso_flotado_kg);
  fprintf('Carga fluido sobre bomba  : %.0f kgf\n', varillas.peso_fluido_kg);
  fprintf('Tension maxima superficial: %.0f kgf\n', varillas.tension_max_kg);
  fprintf('Tension minima superficial: %.0f kgf\n', varillas.tension_min_kg);
  fprintf('Estiramiento elastico     : %.2f m\n', varillas.estiramiento_m);
  fprintf('Factor seguridad fatiga   : %.2f\n', varillas.fs_fatiga);
  if varillas.sinker_bars
      fprintf('Aviso: se recomiendan barras de peso, aprox. %.0f kgf adicionales.\n', varillas.peso_sinker_kg);
  else
      fprintf('No se requieren barras de peso adicionales segun criterio preliminar.\n');
  end
  if varillas.fs_fatiga < 1.1
      fprintf('ALERTA: factor de seguridad bajo. Revisar diseno de varillas.\n');
  end
  fprintf('---------------------------------\n');
end

function BM_imprimir_semaforo(varillas, param, Ql, detalle)
  % Funcion conservada por compatibilidad. Desde v13 usa el semaforo global
  % con spots, igual que el resto de AOS.
  if nargin < 2, param = struct(); end
  if nargin < 3, Ql = 0; end
  if nargin < 4, detalle = struct(); end
  try
      if nargin >= 1 && ~isempty(varillas)
          param.varillas = varillas;
      end
      extra = detalle;
      sem = aos_semaforo_operacion('BM', param, Ql, max(Ql*(1-leer_campo_local(param,'WC',0)),0), 0, detalle);
      aos_imprimir_semaforos(sem, 'BM');
  catch err
      fprintf('Aviso: no se pudo imprimir semaforo BM: %s\n', err.message);
  end
end

function v = leer_campo_local(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end
