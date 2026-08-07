function aos_punzados_escribir_aosdat(fid, punzados)
% Escribe contrato historico [PUNZADOS] y metadatos extendidos HF3.
% Los lectores antiguos siguen viendo cuatro columnas. Un tramo inactivo se
% escribe con densidad cero en la seccion legacy para evitar aporte fisico.
  if nargin<2, error('Se requiere fid y punzados.'); endif
  [p,~]=aos_punzados_normalizar(punzados);

  fprintf(fid,'\n# Formato legacy: MD_tope_m,MD_base_m,tiros_por_m,diametro_punzado_m\n');
  fprintf(fid,'[PUNZADOS]\n');
  for i=1:numel(p.tramos)
    t=p.tramos(i);
    dens=t.densidad_tpm;
    if ~t.activo, dens=0; endif
    fprintf(fid,'%.10g,%.10g,%.10g,%.10g\n', ...
      t.MD_desde,t.MD_hasta,dens,t.diametro_punzado_m);
  endfor

  fprintf(fid,'\n# Metadatos completos y editables. Compatibilidad AOS 0.1.9 R2 HF3.\n');
  fprintf(fid,'[PUNZADOS_META]\n');
  kv_local(fid,'schema','AOS_PUNZADOS_META_1.0');
  kv_local(fid,'n',numel(p.tramos));
  for i=1:numel(p.tramos)
    t=p.tramos(i);
    suf=sprintf('_%d',i);
    kv_local(fid,['id' suf],t.id);
    kv_local(fid,['nombre' suf],t.nombre);
    kv_local(fid,['MD_desde' suf],t.MD_desde);
    kv_local(fid,['MD_hasta' suf],t.MD_hasta);
    kv_local(fid,['densidad_tpm' suf],t.densidad_tpm);
    kv_local(fid,['diametro_punzado_m' suf],t.diametro_punzado_m);
    kv_local(fid,['activo' suf],t.activo);
    kv_opcional_local(fid,['fase_deg' suf],t.fase_deg);
    kv_opcional_local(fid,['penetracion_m' suf],t.penetracion_m);
    kv_local(fid,['tipo_disparo' suf],t.tipo_disparo);
    kv_local(fid,['formacion' suf],t.formacion);
    kv_opcional_local(fid,['permeabilidad_mD' suf],t.permeabilidad_mD);
    kv_opcional_local(fid,['skin' suf],t.skin);
    kv_local(fid,['estado_validacion' suf],t.estado_validacion);
    kv_local(fid,['observaciones' suf],t.observaciones);
    kv_local(fid,['origen' suf],t.origen);
    if isstruct(t.extras) && ~isempty(fieldnames(t.extras))
      try
        txt=jsonencode(t.extras);
        kv_local(fid,['extras_json_pct' suf],pct_encode_local(txt));
      catch
        fn=fieldnames(t.extras);
        for k=1:numel(fn)
          v=t.extras.(fn{k});
          if es_escalar_local(v)
            kv_local(fid,sprintf('extra_%s_%d',aos_sanitizar_campo(fn{k}),i),v);
          endif
        endfor
      end_try_catch
    endif
  endfor
endfunction

function kv_opcional_local(fid,campo,valor)
  if isnumeric(valor)&&isscalar(valor)&&isfinite(valor)
    kv_local(fid,campo,valor);
  endif
endfunction

function kv_local(fid,campo,valor)
  campo=aos_sanitizar_campo(campo);
  if islogical(valor)&&isscalar(valor)
    if valor,txt='true';else,txt='false';endif
  elseif isnumeric(valor)&&isscalar(valor)
    if isnan(valor),txt='NaN';
    elseif isinf(valor)&&valor>0,txt='Inf';
    elseif isinf(valor),txt='-Inf';
    else,txt=sprintf('%.15g',valor);endif
  else
    [txt,ok]=aos_texto_seguro(valor,'');
    if ~ok,return;endif
    txt=regexprep(txt,'[\r\n]+',' ');
    txt=strrep(txt,'#','-');
    txt=strtrim(txt);
  endif
  fprintf(fid,'%s=%s\n',campo,txt);
endfunction

function out=pct_encode_local(txt)
% Protege caracteres que el formato .aosdat interpreta como comentarios.
  [txt,ok]=aos_texto_seguro(txt,'');
  if ~ok,out='';return;endif
  out=strrep(txt,'%','%25');
  out=strrep(out,'#','%23');
endfunction

function tf=es_escalar_local(v)
  tf=(isnumeric(v)&&isscalar(v))||(islogical(v)&&isscalar(v))||ischar(v);
endfunction
