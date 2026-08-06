function [galeria, fuente, avisos] = mandriles_cargar_galeria(param)
% Carga galeria desde [MANDRILES_GALERIA] del .aosdat.
% Si no existe, usa una galeria generica configurable.

  galeria = struct([]);
  fuente = 'NO_DISPONIBLE';
  avisos = {};
  sec = [];
  if isstruct(param) && isfield(param,'mandriles_galeria') && isstruct(param.mandriles_galeria)
    sec = param.mandriles_galeria;
  elseif isstruct(param) && isfield(param,'aosdat_sections') && ...
         isstruct(param.aosdat_sections) && isfield(param.aosdat_sections,'mandriles_galeria')
    sec = param.aosdat_sections.mandriles_galeria;
  endif

  if isstruct(sec) && ~isempty(fieldnames(sec))
    galeria = parsear_seccion_local(sec);
    if ~isempty(galeria)
      fuente = 'AOSDAT_MANDRILES_GALERIA';
    else
      avisos{end+1} = 'La seccion MANDRILES_GALERIA existe pero no contiene elementos validos.';
    endif
  endif

  if isempty(galeria) && (~isfield(param,'mand_usar_galeria_generica') || logical(param.mand_usar_galeria_generica))
    galeria = galeria_generica_local(param);
    fuente = 'GALERIA_GENERICA_AOS';
    avisos{end+1} = 'Se usa galeria generica; confirmar modelos y ratings con inventario real.';
  endif

  for i=1:numel(galeria)
    galeria(i).indice = i;
    if ~isfield(galeria(i),'habilitado'), galeria(i).habilitado = true; endif
  endfor
endfunction

function g = parsear_seccion_local(sec)
  g = struct([]);
  n = entero_local(leer_local(sec,{'n','cantidad','n_elementos'},0));
  if n <= 0
    n = inferir_n_local(fieldnames(sec));
  endif
  for i=1:n
    suf = sprintf('%02d',i);
    item = struct();
    item.id = texto_local(leer_local(sec,{['id_' suf],['modelo_' suf],['nombre_' suf]},sprintf('ITEM_%02d',i)));
    item.fabricante = texto_local(leer_local(sec,{['fabricante_' suf]},'NO_DEFINIDO'));
    item.mandril = texto_local(leer_local(sec,{['mandril_' suf],['tipo_mandril_' suf]},'MANDRIL_GL'));
    item.valvula = texto_local(leer_local(sec,{['valvula_' suf],['tipo_valvula_' suf]},'IPO'));
    item.rating_bar = numero_local(leer_local(sec,{['rating_bar_' suf],['presion_max_bar_' suf]},NaN));
    item.Tmax_C = numero_local(leer_local(sec,{['tmax_c_' suf],['temperatura_max_c_' suf]},NaN));
    item.Qmax_Sm3_d = numero_local(leer_local(sec,{['qmax_sm3_d_' suf],['caudal_max_sm3_d_' suf]},Inf));
    item.dP_apertura_min_bar = numero_local(leer_local(sec,{['dp_apertura_min_bar_' suf]},0));
    item.dP_apertura_max_bar = numero_local(leer_local(sec,{['dp_apertura_max_bar_' suf]},Inf));
    item.dP_cierre_bar = numero_local(leer_local(sec,{['dp_cierre_bar_' suf]},NaN));
    item.puertos_mm = vector_local(leer_local(sec,{['puertos_mm_' suf],['puerto_mm_' suf]},[]));
    item.habilitado = logico_local(leer_local(sec,{['habilitado_' suf],['disponible_' suf]},true));
    item.stock = numero_local(leer_local(sec,{['stock_' suf]},Inf));
    if isempty(item.puertos_mm), item.puertos_mm = [2 2.5 3 3.5 4 4.5 5 6 7 8 10 12]; endif
    % La carga preserva tambien elementos deshabilitados o sin stock.
    % El filtrado fisico corresponde a mandriles_seleccionar_galeria.
    if isfinite(item.rating_bar) && item.rating_bar > 0
      if isempty(g), g=item; else, g(end+1)=item; endif
    endif
  endfor
endfunction

function g = galeria_generica_local(p)
  ports = p.mand_puertos_mm;
  ratings = unique([min(175,p.mand_rating_bar), min(250,p.mand_rating_bar), p.mand_rating_bar]);
  ratings = ratings(ratings>0);
  g = struct([]);
  for i=1:numel(ratings)
    item=struct('id',sprintf('AOS_GENERIC_%03dBAR',round(ratings(i))), ...
      'fabricante','GENERICO_AOS','mandril','SIDE_POCKET_GL','valvula','IPO', ...
      'rating_bar',ratings(i),'Tmax_C',150,'Qmax_Sm3_d',Inf, ...
      'dP_apertura_min_bar',0,'dP_apertura_max_bar',Inf,'dP_cierre_bar',p.mand_dP_cierre_bar, ...
      'puertos_mm',ports,'habilitado',true,'stock',Inf);
    if isempty(g),g=item;else,g(end+1)=item;endif
  endfor
endfunction

function n = inferir_n_local(campos)
  n=0;
  for i=1:numel(campos)
    tok=regexp(campos{i},'_(\d+)$','tokens');
    if ~isempty(tok), n=max(n,str2double(tok{1}{1})); endif
  endfor
endfunction
function v=leer_local(s,campos,def)
  v=def; for i=1:numel(campos), if isfield(s,campos{i}),v=s.(campos{i});return;endif,endfor
endfunction
function v=numero_local(x)
  [v,ok]=aos_numero_seguro(x,NaN); if ~ok,v=NaN;endif
endfunction
function n=entero_local(x), n=max(0,round(numero_local(x))); if ~isfinite(n),n=0;endif, endfunction
function s=texto_local(x)
  [s,ok]=aos_texto_seguro(x,''); if ~ok,s='';endif
endfunction
function b=logico_local(x)
  [b,ok]=aos_logico_seguro(x,false); if ~ok,b=false;endif
endfunction
function v=vector_local(x)
  [v,ok]=aos_vector_seguro(x,[]); if ~ok,v=[];endif
  v=v(isfinite(v)&v>0); v=unique(v);
endfunction
