function pkg = aos_aoscad_nuevo_paquete(aoscad_perfil, dxf_clase, dominio_sim)
% AOS_AOSCAD_NUEVO_PAQUETE Crea un contenedor AOSCAD-0.0.1-DEV1.
% Plataforma objetivo unica: GNU Octave. Formato canonico: JSON UTF-8.
  if nargin < 1 || isempty(aoscad_perfil), aoscad_perfil = 'SIMPLE'; endif
  if nargin < 2 || isempty(dxf_clase), dxf_clase = 'INSTALACION'; endif
  if nargin < 3 || isempty(dominio_sim), dominio_sim = 'HIDRAULICO'; endif

  aoscad_perfil = upper(char(aoscad_perfil));
  dxf_clase = upper(char(dxf_clase));
  dominio_sim = upper(char(dominio_sim));

  perfiles = {'SIMPLE', 'ENRIQUECIDO'};
  clases = {'INSTALACION', 'GALERIAS'};
  dominios = {'HIDRAULICO', 'ELECTRICO', 'COMBINADO'};
  if ~any(strcmp(aoscad_perfil, perfiles))
    error('AOS CAD_TOPO: perfil no valido: %s', aoscad_perfil);
  endif
  if ~any(strcmp(dxf_clase, clases))
    error('AOS CAD_TOPO: clase DXF no valida: %s', dxf_clase);
  endif
  if ~any(strcmp(dominio_sim, dominios))
    error('AOS CAD_TOPO: dominio no valido: %s', dominio_sim);
  endif

  pkg = struct();
  pkg.info = struct();
  pkg.info.schema = 'AOSCAD-0.0.1-DEV1';
  pkg.info.formato_canonico = 'JSON_UTF8';
  pkg.info.motor_objetivo = 'GNU_OCTAVE';
  pkg.info.estado_desarrollo = 'PROTOTIPO_NO_VALIDADO';
  pkg.info.dxf_clase = dxf_clase;
  pkg.info.aoscad_perfil = aoscad_perfil;
  pkg.info.dominio_sim = dominio_sim;
  pkg.info.fuente_dxf = '';
  pkg.info.creado_en = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  pkg.info.modificado_en = pkg.info.creado_en;
  pkg.info.version_modulo = '0.0.1-DEV1';
  pkg.info.asset_identity_schema = 'AOS_ASSET_IDENTITY_0_2_0';
  pkg.info.schema_revision = 'R11_ASSET_IDENTITY';
  pkg.info.notas = ['Contenedor abierto, editable y recalculable. ' ...
                    'Se escribe solo despues de una simulacion.'];

  pkg.tablas_entrada = struct();
  pkg.tablas_entrada.nodos = {};
  pkg.tablas_entrada.tramos = {};
  pkg.tablas_entrada.accesorios = {};
  pkg.tablas_entrada.valvulas = {};
  pkg.tablas_entrada.equipos = {};
  pkg.tablas_entrada.condiciones_borde = {};
  pkg.tablas_entrada.fluidos = {};
  pkg.tablas_entrada.dominios_hidraulicos = {};
  pkg.tablas_entrada.camaras = {};
  pkg.tablas_entrada.ramales = {};
  pkg.tablas_entrada.accesos = {};
  pkg.tablas_entrada.puertos = {};

  % Registro de activos (Sprint 2): vacio hasta aos_cad_asignar_asset_ids
  pkg.activos = {};

  pkg.geometria = struct();
  pkg.geometria.sistema_coordenadas = 'LOCAL_METRICO';
  pkg.geometria.unidades = 'm';
  pkg.geometria.entidades_dxf = {};

  pkg.topologia = struct();
  pkg.topologia.origen = 'DERIVADA_DE_TABLAS';
  pkg.topologia.tolerancia_m = 0.05;
  pkg.topologia.aristas = {};
  pkg.topologia.nodos_grafo = {};

  pkg.simulacion = struct();
  pkg.simulacion.motor = '';
  pkg.simulacion.dominio = dominio_sim;
  pkg.simulacion.estado = 'NO_EJECUTADA';
  pkg.simulacion.parametros_efectivos = struct();
  pkg.simulacion.advertencias = {};
  pkg.simulacion.corrida_id = '';
  pkg.simulacion.fecha = '';
  pkg.simulacion.entradas_hash = '';
  pkg.simulacion.dominio_hidraulico_activo_id = '';

  pkg.tablas_resultados = struct();
  pkg.tablas_resultados.nodos = {};
  pkg.tablas_resultados.tramos = {};

  pkg.validaciones = struct();
  pkg.validaciones.estado = 'PENDIENTE';
  pkg.validaciones.items = {};

  pkg.historial_edicion = {};

  % SIMPLE y ENRIQUECIDO comparten el mismo modelo. Solo cambia esta seccion.
  % Recursos son secundarios/regenerables; never sustituyen tablas.
  pkg.recursos_visuales = {};
  if strcmp(aoscad_perfil, 'ENRIQUECIDO')
    pkg.recursos_visuales = struct( ...
      'tipo', 'RECURSOS_VIEWER', ...
      'planos', {{}}, ...
      'graficos', {{}}, ...
      'vigente', false, ...
      'obsoletos', false, ...
      'nota', ['DEV1: contenedor ENRIQUECIDO preparado; ' ...
              'recursos visuales regenerables pendientes de generacion.']);
  endif
endfunction
