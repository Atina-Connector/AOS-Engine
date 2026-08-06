function [datos, info] = importar_catalogo(tipo, archivo)
% IMPORTAR_CATALOGO Importa catalogos .aosdat con contrato simetrico R2.
% Tipos: bombas, valvulas, varillas, unidades_bm.
  if nargin < 1 || isempty(tipo)
    fprintf('Tipos disponibles: bombas, valvulas, varillas, unidades_bm\n');
    tipo = input('Seleccione tipo de catalogo: ', 's');
  endif
  [tipo_txt, tipo_ok] = aos_texto_seguro(tipo, '');
  if ~tipo_ok, error('Tipo de catalogo invalido o no textual.'); endif
  tipo = lower(strtrim(tipo_txt));
  tipos = {'bombas','valvulas','varillas','unidades_bm'};
  if ~any(strcmp(tipo,tipos))
    error('Tipo no valido. Use: bombas, valvulas, varillas, unidades_bm');
  endif

  if nargin < 2 || isempty(archivo), archivo = seleccionar_local(tipo); endif
  datos = struct([]);
  info = struct('ok',false,'tipo',tipo,'archivo','','seccion',upper(tipo), ...
    'cantidad',0,'advertencias',{{}},'metadata',struct(),'contract','');
  if isempty(archivo), fprintf('Importacion cancelada.\n'); return; endif
  if exist(archivo,'file') ~= 2, error('No se pudo abrir %s',archivo); endif

  opciones = struct('activar_caso',false,'imprimir_resumen',false,'normalizar',false);
  cfg = importar_aosdat(archivo, opciones);
  if ~isfield(cfg,'aosdat_sections') || ~isstruct(cfg.aosdat_sections)
    error('Catalogo sin secciones .aosdat preservadas: %s',archivo);
  endif
  [sec, nombre_sec, existe] = seccion_ci_local(cfg.aosdat_sections,tipo);
  if ~existe || ~isstruct(sec)
    error('El archivo no contiene la seccion [%s].',upper(tipo));
  endif

  switch tipo
    case 'bombas', datos = parsear_bombas_local(sec);
    case 'valvulas', datos = parsear_valvulas_local(sec);
    case 'varillas', datos = parsear_varillas_local(sec);
    case 'unidades_bm', datos = parsear_unidades_local(sec);
  endswitch

  info.ok = true;
  [info.archivo, archivo_ok] = aos_texto_seguro(archivo, '');
  if ~archivo_ok, info.archivo = ''; endif
  info.seccion = nombre_sec;
  info.cantidad = numel(datos);
  if isfield(cfg,'catalogo_metadata')
    info.metadata=cfg.catalogo_metadata;
    [cv,existe]=campo_ci_simple_local(cfg.catalogo_metadata,'contract');
    if existe,info.contract=texto_local(cv);endif
  endif
  if isempty(datos), info.advertencias{end+1}='La seccion existe pero no contiene elementos validos.'; endif

  fprintf('Catalogo importado: %s\n',archivo);
  fprintf('   Tipo      : %s\n',tipo);
  fprintf('   Elementos : %d\n',numel(datos));
endfunction

function datos = parsear_bombas_local(sec)
  idx = indices_local(sec,{'modelo','q','head','potencia','etapas'});
  datos = struct([]);
  for k=1:numel(idx)
    i=idx(k);
    modelo=texto_local(campo_indexado_local(sec,'modelo',i,''));
    Q=vector_local(campo_indexado_local(sec,'q',i,[]));
    head=vector_local(campo_indexado_local(sec,'head',i,[]));
    potencia=vector_local(campo_indexado_local(sec,'potencia',i,[]));
    if isempty(modelo) || isempty(Q) || isempty(head), continue; endif
    n=min([numel(Q),numel(head)]);
    Q=Q(1:n); head=head(1:n);
    if isempty(potencia), potencia=NaN(1,n);
    elseif numel(potencia)<n, potencia(end+1:n)=NaN;
    else, potencia=potencia(1:n); endif
    item=struct('modelo',modelo,'Q',Q,'head',head,'potencia',potencia);
    etapas=numero_local(campo_indexado_local(sec,'etapas',i,NaN));
    if isfinite(etapas), item.etapas=round(etapas); endif
    datos=agregar_local(datos,item);
  endfor
endfunction

function datos = parsear_valvulas_local(sec)
  idx=indices_local(sec,{'valvula'}); datos=struct([]);
  for k=1:numel(idx)
    v=partes_local(campo_indexado_local(sec,'valvula',idx(k),''));
    if numel(v)<4, continue; endif
    item=struct('codigo',v{1},'diam_orificio_m',str2double(v{2}), ...
      'R_fuelle',str2double(v{3}),'pres_max_domo_Pa',str2double(v{4})*1e5);
    if ~isfinite(item.diam_orificio_m)||~isfinite(item.R_fuelle)||~isfinite(item.pres_max_domo_Pa), continue; endif
    datos=agregar_local(datos,item);
  endfor
endfunction

function datos = parsear_varillas_local(sec)
  idx=indices_local(sec,{'varilla'}); datos=struct([]);
  for k=1:numel(idx)
    v=partes_local(campo_indexado_local(sec,'varilla',idx(k),''));
    if numel(v)<5, continue; endif
    item=struct('nombre',v{1},'densidad_kg_m3',str2double(v{2}), ...
      'modulo_young_GPa',str2double(v{3}),'limite_fatiga_MPa',str2double(v{4}), ...
      'resistencia_ultima_MPa',str2double(v{5}));
    if any(~isfinite([item.densidad_kg_m3,item.modulo_young_GPa,item.limite_fatiga_MPa,item.resistencia_ultima_MPa])), continue; endif
    datos=agregar_local(datos,item);
  endfor
endfunction

function datos = parsear_unidades_local(sec)
  idx=indices_local(sec,{'unidad'}); datos=struct([]);
  for k=1:numel(idx)
    v=partes_local(campo_indexado_local(sec,'unidad',idx(k),''));
    if numel(v)<6, continue; endif
    item=struct('modelo',v{1},'tipo',v{2},'carrera_max_m',str2double(v{3}), ...
      'vel_max_gpm',str2double(v{4}),'torque_max_klb_in',str2double(v{5}), ...
      'peso_kg',str2double(v{6}));
    if any(~isfinite([item.carrera_max_m,item.vel_max_gpm,item.torque_max_klb_in,item.peso_kg])), continue; endif
    datos=agregar_local(datos,item);
  endfor
endfunction

function idx = indices_local(sec,prefijos)
  fn=fieldnames(sec); idx=[];
  for i=1:numel(fn)
    n=lower(fn{i});
    for j=1:numel(prefijos)
      tok=regexp(n,['^' lower(prefijos{j}) '_(\d+)$'],'tokens');
      if ~isempty(tok), idx(end+1)=str2double(tok{1}{1}); endif %#ok<AGROW>
    endfor
  endfor
  idx=unique(idx(isfinite(idx)&idx>=1));
endfunction

function v = campo_indexado_local(sec,prefijo,idx,def)
  v=def; objetivo=lower(sprintf('%s_%d',prefijo,idx)); fn=fieldnames(sec);
  for i=1:numel(fn)
    if strcmp(lower(fn{i}),objetivo), v=sec.(fn{i}); return; endif
  endfor
endfunction

function [sec,nombre,ok] = seccion_ci_local(secciones,nombre_buscado)
  sec=struct();nombre='';ok=false;fn=fieldnames(secciones);
  for i=1:numel(fn)
    if strcmpi(fn{i},nombre_buscado),sec=secciones.(fn{i});nombre=fn{i};ok=true;return;endif
  endfor
endfunction

function datos=agregar_local(datos,item)
  if isempty(datos), datos=item; else, datos(end+1)=item; endif
endfunction

function v=vector_local(x)
  [v, ok] = aos_vector_seguro(x, []);
  if ~ok, v = []; endif
endfunction

function p=partes_local(x)
  [txt, ok] = aos_texto_seguro(x, '');
  if ~ok, p = {}; return; endif
  p = strsplit(txt, ',');
  for i=1:numel(p), p{i}=strtrim(p{i}); endfor
endfunction

function s=texto_local(x)
  [s, ok] = aos_texto_seguro(x, '');
  if ~ok, s = ''; endif
endfunction

function n=numero_local(x)
  [n, ok] = aos_numero_seguro(x, NaN);
  if ~ok, n = NaN; endif
endfunction

function [v,ok]=campo_ci_simple_local(s,nombre)
  v=[];ok=false;fn=fieldnames(s);
  for i=1:numel(fn),if strcmpi(fn{i},nombre),v=s.(fn{i});ok=true;return;endif,endfor
endfunction

function archivo=seleccionar_local(tipo)
  archivo=''; root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  carpetas={fullfile(root,'intercambio','catalogos','recibidos',tipo), ...
    fullfile(root,'datos_usuario','catalogos','aosdat'), ...
    fullfile(root,'datos','ejemplos','catalogos'),pwd};
  lista={};
  for c=1:numel(carpetas)
    if exist(carpetas{c},'dir')~=7,continue;endif
    d=dir(fullfile(carpetas{c},'*.aosdat'));
    for i=1:numel(d),lista{end+1}=fullfile(carpetas{c},d(i).name);endfor %#ok<AGROW>
  endfor
  if isempty(lista)
    archivo=strtrim(input('Ruta completa del catalogo .aosdat (Enter cancela): ','s'));return;
  endif
  fprintf('\n--- CATALOGOS %s ---\n',upper(tipo));
  for i=1:numel(lista),fprintf('%2d - %s\n',i,lista{i});endfor
  fprintf(' 0 - Cancelar\n'); op=aos_leer_opcion('Seleccione: ',0);
  if op>=1&&op<=numel(lista),archivo=lista{op};endif
endfunction
