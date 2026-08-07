function AOS_menu_configuracion()
% AOS_MENU_CONFIGURACION Configuracion transversal AOS Suite 0.1.9 R2.
  while true
    fprintf('\n--- CONFIGURACION GENERAL ---\n');
    fprintf(' 1 - Estado de la configuracion activa\n');
    fprintf(' 2 - Sistema de unidades\n');
    fprintf(' 3 - Solvers, tolerancias e iteraciones\n');
    fprintf(' 4 - Sensibilidades\n');
    fprintf(' 5 - Graficos, reportes y AOS Viewer\n');
    fprintf(' 6 - Seguridad y codificacion\n');
    fprintf(' 7 - Parametros economicos generales\n');
    fprintf(' 8 - Catalogos y prioridades\n');
    fprintf(' 9 - SCADA y recepcion automatica\n');
    fprintf('10 - Registro y estado de modulos\n');
    fprintf('11 - Version, rutas y diagnostico\n');
    fprintf('12 - Restaurar preferencias generales\n');
    fprintf('13 - Descartar caso activo de memoria\n');
    fprintf('14 - Importar configuracion completa desde .aosdat\n');
    fprintf('15 - Exportar configuracion activa a .aosdat\n');
    fprintf('16 - Catalogos y galerias definidos por .aosdat\n');
    fprintf(' 0 - Volver\n');
    op = aos_leer_opcion('Seleccione: ', []);
    switch op
      case 1, mostrar_estado_activo_local();
      case 2, configurar_unidades_local();
      case 3, configurar_solver_local();
      case 4, configurar_sensibilidad_local();
      case 5, configurar_reportes_local();
      case 6, configurar_seguridad_local();
      case 7, configurar_economia_local();
      case 8, configurar_catalogos_local();
      case 9, configurar_scada_local();
      case 10, mostrar_modulos_local();
      case 11, mostrar_version_local();
      case 12, restaurar_local();
      case 13, descartar_caso_local();
      case 14, importar_aosdat();
      case 15, exportar_config_local();
      case 16, AOS_menu_catalogos();
      case 0, break;
      otherwise, fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function mostrar_estado_activo_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    fprintf('\nNo hay un caso activo cargado.\n');
    return;
  endif
  try
    aos_menu_imprimir_resumen_config(CONFIG_ACTIVA, AOSDAT_ACTIVO, geologia);
  catch err
    fprintf('Configuracion activa: %d campos. No se pudo imprimir el resumen: %s\n', ...
      numel(fieldnames(CONFIG_ACTIVA)), err.message);
  end_try_catch
endfunction

function configurar_unidades_local()
  p=aos_preferencias_usuario('cargar');
  fprintf('\nSistema principal vigente: METRICO AOS\n');
  fprintf('Presion bar | profundidad m | liquido m3/d | gas Sm3/d | temperatura C | potencia kW\n');
  fprintf('Las unidades imperiales son referencias de presentacion y no alteran el nucleo SI.\n');
  fprintf('En AOS 0.1.9 el sistema metrico no puede desactivarse.\n');
  p.unidades.sistema='METRICO_AOS';
  aos_preferencias_usuario('guardar',p);
endfunction

function configurar_solver_local()
  p=aos_preferencias_usuario('cargar'); s=p.solver;
  fprintf('\nValores actuales: modo JGL=%s | max iter=%d | tolerancia relativa=%.4g\n', ...
    s.modo_jgl,s.max_iter_jgl,s.tolerancia_relativa);
  txt=upper(strtrim(input(sprintf('Modo JGL [AUTOMATICO/ITERATIVO/DIRECTO/HIBRIDO] [%s]: ',s.modo_jgl),'s')));
  validos={'AUTOMATICO','ITERATIVO','DIRECTO','HIBRIDO'};
  if ~isempty(txt)
    if any(strcmp(txt,validos)), s.modo_jgl=txt; else, fprintf('Modo no reconocido; se conserva.\n'); endif
  endif
  s.max_iter_jgl=leer_numero_local(sprintf('Maximo de iteraciones JGL [%d]: ',s.max_iter_jgl),s.max_iter_jgl,1,10000,true);
  s.tolerancia_relativa=leer_numero_local(sprintf('Tolerancia relativa [%.4g]: ',s.tolerancia_relativa),s.tolerancia_relativa,eps,1,false);
  s.registrar_diagnostico=leer_si_no_local('Registrar diagnostico detallado',s.registrar_diagnostico);
  p.solver=s; aos_preferencias_usuario('guardar',p);
  fprintf('Preferencias de solver guardadas. Los modulos pueden declarar limites mas estrictos.\n');
endfunction

function configurar_sensibilidad_local()
  p=aos_preferencias_usuario('cargar'); s=p.sensibilidades;
  s.n_puntos=leer_numero_local(sprintf('Puntos predeterminados [%d]: ',s.n_puntos),s.n_puntos,2,10001,true);
  s.modo_abreviado=leer_si_no_local('Activar modo abreviado predeterminado',s.modo_abreviado);

  if ~isfield(s,'tratamiento_curva_default'),s.tratamiento_curva_default='DISCRETO';endif
  fprintf('\nTratamiento predeterminado de curvas (siempre se confirma en cada corrida):\n');
  fprintf('  1 - DISCRETO\n  2 - POLINOMICO_INFORMATIVO\n  3 - POLINOMICO_VERIFICADO\n');
  opdef=1;
  if strcmpi(s.tratamiento_curva_default,'POLINOMICO_INFORMATIVO')
    opdef=2;
  elseif strcmpi(s.tratamiento_curva_default,'POLINOMICO_VERIFICADO')
    opdef=3;
  endif
  op=aos_leer_opcion(sprintf('Seleccione predeterminado [%d]: ',opdef),opdef);
  if op==2
    s.tratamiento_curva_default='POLINOMICO_INFORMATIVO';
  elseif op==3
    s.tratamiento_curva_default='POLINOMICO_VERIFICADO';
  else
    s.tratamiento_curva_default='DISCRETO';
  endif

  if ~isfield(s,'grado_polinomio_default'),s.grado_polinomio_default=0;endif
  if ~isfield(s,'grado_polinomio_max'),s.grado_polinomio_max=5;endif
  if ~isfield(s,'n_puntos_polinomio'),s.n_puntos_polinomio=201;endif
  g=leer_numero_local(sprintf('Grado polinomico default [0 auto, 2-5] [%d]: ', ...
    s.grado_polinomio_default),s.grado_polinomio_default,0,5,true);
  if g==1,g=0;endif
  s.grado_polinomio_default=g;
  s.grado_polinomio_max=leer_numero_local(sprintf('Grado maximo de ajuste [2-5] [%d]: ', ...
    s.grado_polinomio_max),s.grado_polinomio_max,2,5,true);
  if s.grado_polinomio_default>s.grado_polinomio_max,s.grado_polinomio_default=0;endif
  s.n_puntos_polinomio=leer_numero_local(sprintf('Puntos de la curva polinomica [%d]: ', ...
    s.n_puntos_polinomio),s.n_puntos_polinomio,51,5001,true);
  if mod(s.n_puntos_polinomio,2)==0,s.n_puntos_polinomio=s.n_puntos_polinomio+1;endif
  s.verificacion_selectiva=leer_si_no_local('Verificacion iterativa selectiva',s.verificacion_selectiva);
  p.sensibilidades=s; aos_preferencias_usuario('guardar',p);
  fprintf('Preferencias guardadas. El menu de tratamiento permanece visible en cada corrida.\n');
endfunction

function configurar_reportes_local()
  p=aos_preferencias_usuario('cargar'); r=p.reportes;
  txt=upper(strtrim(input(sprintf('Formato predeterminado [LIGERO/ENRIQUECIDO] [%s]: ',r.formato_predeterminado),'s')));
  if any(strcmp(txt,{'LIGERO','ENRIQUECIDO'})), r.formato_predeterminado=txt; endif
  r.incluir_contexto_pozo=leer_si_no_local('Incluir contexto geometrico del pozo',r.incluir_contexto_pozo);
  r.incluir_survey=leer_si_no_local('Incluir survey cuando este disponible',r.incluir_survey);
  r.codificar_preguntar=leer_si_no_local('Preguntar por codificacion al exportar',r.codificar_preguntar);
  p.reportes=r; aos_preferencias_usuario('guardar',p);
  fprintf('Preferencias de reportes guardadas. El reporte conserva siempre la configuracion efectiva.\n');
endfunction

function configurar_seguridad_local()
  p=aos_preferencias_usuario('cargar'); s=p.seguridad;
  s.preguntar_codificacion=leer_si_no_local('Preguntar por codificacion de archivos AOS',s.preguntar_codificacion);
  s.importacion_transaccional=leer_si_no_local('Exigir importacion AOSDAT transaccional',true);
  s.aceptar_comandos_scada=leer_si_no_local('Permitir comandos operativos recibidos por SCADA',false);
  if s.aceptar_comandos_scada
    fprintf('ADVERTENCIA: AOS 0.1.9 no ejecuta comandos automaticos; la preferencia queda registrada para futura aprobacion.\n');
    s.aceptar_comandos_scada=false;
  endif
  p.seguridad=s; aos_preferencias_usuario('guardar',p);
endfunction

function configurar_economia_local()
  global CONFIG_ACTIVA;
  p=aos_preferencias_usuario('cargar'); e=p.economia;
  if ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA) && isfield(CONFIG_ACTIVA,'economia') && isstruct(CONFIG_ACTIVA.economia)
    e=fusion_economia_local(e,CONFIG_ACTIVA.economia);
  endif
  fprintf('\nLos valores se usan como defaults; cada sensibilidad puede confirmarlos o modificarlos.\n');
  txt=strtrim(input(sprintf('Moneda [%s]: ',e.moneda),'s')); if ~isempty(txt),e.moneda=txt;endif
  e.valor_petroleo_por_m3=leer_numero_local(sprintf('Valor neto del petroleo por m3 [%.6g]: ',e.valor_petroleo_por_m3),e.valor_petroleo_por_m3,0,Inf,false);
  e.costo_gas_por_1000Sm3=leer_numero_local(sprintf('Costo del gas por 1000 Sm3 [%.6g]: ',e.costo_gas_por_1000Sm3),e.costo_gas_por_1000Sm3,0,Inf,false);
  e.costo_fijo_diario=leer_numero_local(sprintf('Costo fijo incremental diario [%.6g]: ',e.costo_fijo_diario),e.costo_fijo_diario,0,Inf,false);
  e.costo_electricidad_por_kWh=leer_numero_local(sprintf('Costo electricidad por kWh [%.6g]: ',e.costo_electricidad_por_kWh),e.costo_electricidad_por_kWh,0,Inf,false);
  p.economia=e; aos_preferencias_usuario('guardar',p);
  aplicar=leer_si_no_local('Aplicar tambien al caso activo',~isempty(CONFIG_ACTIVA)&&isstruct(CONFIG_ACTIVA));
  if aplicar && ~isempty(CONFIG_ACTIVA) && isstruct(CONFIG_ACTIVA), CONFIG_ACTIVA.economia=e; endif
  fprintf('Parametros economicos guardados. No constituyen precios oficiales ni se aplican sin confirmacion de la corrida.\n');
endfunction

function configurar_catalogos_local()
  p=aos_preferencias_usuario('cargar'); c=p.catalogos;
  c.usar_base_aos=leer_si_no_local('Usar catalogos base AOS',c.usar_base_aos);
  c.usar_usuario=leer_si_no_local('Usar catalogos permanentes del usuario',c.usar_usuario);
  c.priorizar_embebidos_aosdat=leer_si_no_local('Priorizar snapshots embebidos en AOSDAT',c.priorizar_embebidos_aosdat);
  p.catalogos=c; aos_preferencias_usuario('guardar',p);
  fprintf('Prioridad efectiva recomendada: pozo/AOSDAT > usuario > base AOS.\n');
endfunction

function configurar_scada_local()
  p=aos_preferencias_usuario('cargar'); s=p.scada;
  s.intervalo_recepcion_s=leer_numero_local(sprintf('Intervalo de recepcion (s) [%d]: ',s.intervalo_recepcion_s),s.intervalo_recepcion_s,1,86400,true);
  s.aplicar_datos_medidos=leer_si_no_local('Aplicar automaticamente datos medidos',s.aplicar_datos_medidos);
  s.aplicar_calibracion=leer_si_no_local('Aplicar automaticamente bloques de calibracion autorizados',s.aplicar_calibracion);
  s.aplicar_comandos=false;
  p.scada=s; aos_preferencias_usuario('guardar',p);
  r=aos_scada_rutas();
  fprintf('Bandeja entrada : %s\n',r.entrada);
  fprintf('Procesados      : %s\n',r.procesados);
  fprintf('Rechazados      : %s\n',r.rechazados);
  fprintf('Los comandos operativos no se ejecutan automaticamente en esta version.\n');
endfunction

function mostrar_modulos_local()
  mods=aos_registro_modulos();
  fprintf('\n%-16s %-44s %-14s %-12s %s\n','ID','MODULO','GRUPO','ESTADO','AESIR');
  fprintf('%s\n',repmat('-',1,104));
  for i=1:numel(mods)
    fprintf('%-16s %-44s %-14s %-12s %s\n',mods(i).id,mods(i).nombre,mods(i).grupo,mods(i).estado,si_no_local(mods(i).propietario));
  endfor
endfunction

function mostrar_version_local()
  fprintf('\nAOS Suite 0.1.9 R2\n');
  fprintf('Entorno objetivo: GNU Octave.\n');
  fprintf('Arquitectura: menus adaptadores, solvers por modulo, resultado unico y contratos versionados.\n');
  fprintf('Preferencias: %s\n',aos_preferencias_usuario('ruta'));
  if exist('diagnosticar_rutas_archivos','file')==2
    if aos_preguntar_sn('Ejecutar diagnostico de rutas? (s/n) [n]: ',false), diagnosticar_rutas_archivos; endif
  endif
endfunction

function restaurar_local()
  if ~leer_si_no_local('Restaurar preferencias generales a defaults',false), return; endif
  aos_preferencias_usuario('restaurar');
  fprintf('Preferencias restauradas. No se modifico el caso activo ni archivos AOSDAT.\n');
endfunction

function descartar_caso_local()
  global CONFIG_ACTIVA AOSDAT_ACTIVO geologia;
  global ULTIMO_QL ULTIMO_QO ULTIMO_QINY ULTIMO_TIPO ULTIMO_PARAM;
  if ~leer_si_no_local('Descartar caso activo y ultimos resultados de memoria',false), return; endif
  CONFIG_ACTIVA=[]; AOSDAT_ACTIVO=''; geologia=[];
  ULTIMO_QL=[]; ULTIMO_QO=[]; ULTIMO_QINY=[]; ULTIMO_TIPO=[]; ULTIMO_PARAM=[];
  fprintf('Memoria activa limpiada. No se eliminaron archivos externos.\n');
endfunction

function exportar_config_local()
  global CONFIG_ACTIVA;
  if isempty(CONFIG_ACTIVA)||~isstruct(CONFIG_ACTIVA)
    fprintf('No hay configuracion activa.\n'); return;
  endif
  exportar_aosdat(CONFIG_ACTIVA);
endfunction

function v=leer_numero_local(mensaje,defecto,minimo,maximo,entero)
  txt=strtrim(input(mensaje,'s'));
  if isempty(txt),v=defecto;return;endif
  v=str2double(txt);
  if ~isfinite(v) || v<minimo || v>maximo
    fprintf('Valor no valido; se conserva %.6g.\n',defecto);v=defecto;return;
  endif
  if entero,v=round(v);endif
endfunction

function v=leer_si_no_local(etiqueta,defecto)
  if defecto, d='s'; else, d='n'; endif
  v=aos_preguntar_sn(sprintf('%s? (s/n) [%s]: ',etiqueta,d),logical(defecto));
endfunction

function e=fusion_economia_local(e,x)
  campos={'moneda','valor_petroleo_por_m3','costo_gas_por_1000Sm3','costo_fijo_diario','costo_electricidad_por_kWh'};
  for i=1:numel(campos)
    c=campos{i};
    if ~isfield(x,c)||isempty(x.(c)),continue;endif
    if strcmp(c,'moneda')
      if ischar(x.(c)),e.(c)=x.(c);endif
    else
      if isnumeric(x.(c))&&isscalar(x.(c)),v=x.(c);elseif ischar(x.(c)),v=str2double(x.(c));else,v=NaN;endif
      if isfinite(v)&&v>=0,e.(c)=v;endif
    endif
  endfor
endfunction

function s=si_no_local(v)
  if v,s='SI';else,s='NO';endif
endfunction
