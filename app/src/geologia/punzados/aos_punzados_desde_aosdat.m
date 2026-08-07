function [punzados, avisos] = aos_punzados_desde_aosdat(legacy, meta)
% Reconstruye punzados HF3 desde [PUNZADOS] y [PUNZADOS_META].
  if nargin<1,legacy=struct('tramos',struct([]));endif
  if nargin<2||~isstruct(meta),meta=struct();endif
  [base,avisos]=aos_punzados_normalizar(legacy,struct('origen','AOSDAT'));
  nmeta=round(meta_num_local(meta,'n',0));
  n=max(numel(base.tramos),max(nmeta,0));
  tramos=base.tramos;
  for i=numel(tramos)+1:n
    t=tramo_base_local(i);
    t.MD_desde=meta_num_local(meta,sprintf('MD_desde_%d',i),NaN);
    t.MD_hasta=meta_num_local(meta,sprintf('MD_hasta_%d',i),NaN);
    t.densidad_tpm=meta_num_local(meta,sprintf('densidad_tpm_%d',i),0);
    t.diametro_punzado_m=meta_num_local(meta, ...
      sprintf('diametro_punzado_m_%d',i),0.010);
    if isempty(tramos),tramos=t;else,tramos(end+1)=t;endif
  endfor

  for i=1:numel(tramos)
    t=tramos(i);
    t.id=meta_txt_local(meta,sprintf('id_%d',i),sprintf('PUNZ-%03d',i));
    t.nombre=meta_txt_local(meta,sprintf('nombre_%d',i),t.id);
    t.MD_desde=meta_num_local(meta,sprintf('MD_desde_%d',i),valor_local(t,'MD_desde',NaN));
    t.MD_hasta=meta_num_local(meta,sprintf('MD_hasta_%d',i),valor_local(t,'MD_hasta',NaN));
    t.densidad_tpm=meta_num_local(meta,sprintf('densidad_tpm_%d',i),valor_local(t,'densidad_tpm',0));
    t.diametro_punzado_m=meta_num_local(meta,sprintf('diametro_punzado_m_%d',i),valor_local(t,'diametro_punzado_m',0.010));
    % Sin metadatos, un legacy con densidad cero queda inactivo por seguridad.
    activo_def=valor_local(t,'densidad_tpm',0)>0;
    t.activo=meta_log_local(meta,sprintf('activo_%d',i),activo_def);
    t.fase_deg=meta_num_local(meta,sprintf('fase_deg_%d',i),NaN);
    t.penetracion_m=meta_num_local(meta,sprintf('penetracion_m_%d',i),NaN);
    t.tipo_disparo=meta_txt_local(meta,sprintf('tipo_disparo_%d',i),'');
    t.formacion=meta_txt_local(meta,sprintf('formacion_%d',i),'');
    t.permeabilidad_mD=meta_num_local(meta,sprintf('permeabilidad_mD_%d',i),NaN);
    t.skin=meta_num_local(meta,sprintf('skin_%d',i),NaN);
    t.estado_validacion=meta_txt_local(meta,sprintf('estado_validacion_%d',i),'NO_VALIDADO');
    t.observaciones=meta_txt_local(meta,sprintf('observaciones_%d',i),'');
    t.origen=meta_txt_local(meta,sprintf('origen_%d',i),'AOSDAT');
    t.extras=extras_local(meta,i);
    tramos(i)=t;
  endfor
  [punzados,av2]=aos_punzados_normalizar(struct('tramos',tramos), ...
    struct('origen','AOSDAT'));
  avisos=[avisos,av2];
endfunction

function t=tramo_base_local(i)
  id=sprintf('PUNZ-%03d',i);
  t=struct('id',id,'nombre',id,'MD_desde',NaN,'MD_hasta',NaN, ...
    'densidad_tpm',0,'diametro_punzado_m',0.010,'activo',true, ...
    'fase_deg',NaN,'penetracion_m',NaN,'tipo_disparo','', ...
    'formacion','','permeabilidad_mD',NaN,'skin',NaN, ...
    'estado_validacion','NO_VALIDADO','observaciones','', ...
    'origen','AOSDAT','extras',struct());
endfunction

function e=extras_local(meta,idx)
  e=struct();
  raw=meta_val_local(meta,sprintf('extras_json_pct_%d',idx),[]);
  if ischar(raw)&&~isempty(strtrim(raw)),raw=pct_decode_local(raw);endif
  if isempty(raw),raw=meta_val_local(meta,sprintf('extras_json_%d',idx),[]);endif
  if ischar(raw)&&~isempty(strtrim(raw))
    try
      x=jsondecode(raw);
      if isstruct(x),e=x;endif
    catch
    end_try_catch
  endif
  fn=fieldnames(meta);
  suf=sprintf('_%d',idx);
  for k=1:numel(fn)
    low=lower(fn{k});
    if length(low)>length('extra_')+length(suf) && ...
       strncmp(low,'extra_',6) && strcmp(low(end-length(suf)+1:end),lower(suf))
      nombre=fn{k}(7:end-length(suf));
      if ~isempty(nombre),e.(aos_sanitizar_campo(nombre))=meta.(fn{k});endif
    endif
  endfor
endfunction

function out=pct_decode_local(txt)
  [txt,ok]=aos_texto_seguro(txt,'');
  if ~ok,out='';return;endif
  out=strrep(txt,'%23','#');
  out=strrep(out,'%25','%');
endfunction

function v=meta_num_local(s,c,d)
  raw=meta_val_local(s,c,[]);[v,ok]=aos_numero_seguro(raw,d);if ~ok,v=d;endif
endfunction
function v=meta_txt_local(s,c,d)
  raw=meta_val_local(s,c,[]);[v,ok]=aos_texto_seguro(raw,d);if ~ok,v=d;endif
endfunction
function v=meta_log_local(s,c,d)
  raw=meta_val_local(s,c,[]);[v,ok]=aos_logico_seguro(raw,d);if ~ok,v=d;endif
endfunction
function v=meta_val_local(s,c,d)
  v=d;if ~isstruct(s),return;endif
  fn=fieldnames(s);j=find(strcmpi(fn,c),1);if ~isempty(j),v=s.(fn{j});endif
endfunction
function v=valor_local(s,c,d)
  v=d;if isstruct(s)&&isfield(s,c)&&~isempty(s.(c)),v=s.(c);endif
endfunction
