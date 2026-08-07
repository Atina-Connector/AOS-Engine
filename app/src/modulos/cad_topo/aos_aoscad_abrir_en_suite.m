function ok = aos_aoscad_abrir_en_suite(archivo, silencioso)
% AOS_AOSCAD_ABRIR_EN_SUITE Recarga el JSON canonico para editar/recalcular.
% Esqueleto: no implementa UI de comparacion corrida previa vs nueva.
  global CONFIG_ACTIVA;
  if nargin < 2, silencioso = false; endif
  ok = false;

  if nargin < 1 || isempty(archivo)
    root = aos_cad_raiz();
    bandeja = fullfile(root, 'intercambio', 'cad', 'aoscad');
    archivo = '';
    if exist(bandeja, 'dir') == 7
      lista = dir(fullfile(bandeja, '*.aoscad'));
      if ~isempty(lista)
        % mas reciente
        [~, idx] = max([lista.datenum]);
        archivo = fullfile(bandeja, lista(idx).name);
      endif
    endif
    if isempty(archivo)
      if ~silencioso
        fprintf('No hay .aoscad en intercambio/cad/aoscad.\n');
      endif
      return;
    endif
  endif

  modelo = aos_aoscad_leer(archivo, true);
  if isempty(CONFIG_ACTIVA) || ~isstruct(CONFIG_ACTIVA)
    CONFIG_ACTIVA = struct();
  endif
  if ~isfield(CONFIG_ACTIVA, 'cad_topologia') || ~isstruct(CONFIG_ACTIVA.cad_topologia)
    CONFIG_ACTIVA.cad_topologia = struct();
  endif

  % Guardar corrida previa como esqueleto de comparacion
  if isfield(CONFIG_ACTIVA.cad_topologia, 'modelo_aoscad')
    CONFIG_ACTIVA.cad_topologia.corrida_previa = CONFIG_ACTIVA.cad_topologia.modelo_aoscad;
  else
    CONFIG_ACTIVA.cad_topologia.corrida_previa = [];
  endif

  CONFIG_ACTIVA.cad_topologia.modelo_aoscad = modelo;
  CONFIG_ACTIVA.cad_topologia.aoscad_archivo = char(archivo);
  if isfield(modelo, 'info') && isfield(modelo.info, 'fuente_dxf') && ...
      ~isempty(modelo.info.fuente_dxf)
    CONFIG_ACTIVA.cad_topologia.dxf_archivo = char(modelo.info.fuente_dxf);
  endif
  if isfield(modelo, 'topologia')
    CONFIG_ACTIVA.cad_topologia.topologia = modelo.topologia;
  endif
  ok = true;

  if ~silencioso
    fprintf('\n--- AOSCAD ABIERTO EN SUITE (memoria) ---\n');
    fprintf('archivo     : %s\n', archivo);
    fprintf('perfil      : %s\n', modelo.info.aoscad_perfil);
    fprintf('Fuente canonica: .aoscad JSON. Listo para editar y recalcular.\n');
    fprintf('(Comparacion corrida previa vs nueva: esqueleto / pendiente UI)\n');
  endif
endfunction
