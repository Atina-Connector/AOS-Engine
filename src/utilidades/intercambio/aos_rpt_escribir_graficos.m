function n_ok = aos_rpt_escribir_graficos(fid, graficos)
% AOS 0.1.0: contrato de graficos; las tablas no son figuras.
% Escribe un contrato sin PNG Base64 duplicados.
% Cada figura se serializa una sola vez y los aliases quedan como refs.

  if nargin < 2 || isempty(graficos)
    graficos = struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  endif

  graficos = deduplicar_local(graficos);
  fprintf(fid, '\n[GRAFICOS]\n');

  indices_ok = [];
  for i = 1:numel(graficos)
    if isfield(graficos(i), 'base64') && ischar(graficos(i).base64) && ...
       ~isempty(graficos(i).base64) && isfield(graficos(i), 'estado') && ...
       strcmpi(graficos(i).estado, 'OK')
      indices_ok(end+1) = i;
    endif
  endfor

  n_ok = numel(indices_ok);
  fprintf(fid, 'schema=AOS_VIEWER_GRAPHICS_1.2\n');
  fprintf(fid, 'n_figuras=%d\n', n_ok);
  fprintf(fid, 'n_graficos=%d\n', n_ok);
  fprintf(fid, 'n_solicitadas=%d\n', numel(graficos));
  fprintf(fid, 'n_fallidas=%d\n', numel(graficos)-n_ok);
  fprintf(fid, 'base64_unica_por_figura=1\n');

  nums = zeros(1, numel(graficos));
  for ii = 1:numel(indices_ok)
    i = indices_ok(ii);
    nums(i) = ii;
    id = limpiar_id_local(graficos(i).id);
    titulo = limpiar_txt_local(graficos(i).titulo);
    seccion = limpiar_txt_local(graficos(i).seccion);
    fprintf(fid, 'figura_%02d_id=%s\n', ii, id);
    fprintf(fid, 'figura_%02d_titulo=%s\n', ii, titulo);
    fprintf(fid, 'figura_%02d_tipo=PNG_BASE64\n', ii);
    fprintf(fid, 'figura_%02d_seccion=%s\n', ii, seccion);
    fprintf(fid, 'figura_%02d_estado=OK\n', ii);
    fprintf(fid, 'figura_%02d_png_base64=%s\n', ii, graficos(i).base64);
  endfor

  for i = 1:numel(graficos)
    id = limpiar_id_local(graficos(i).id);
    estado = limpiar_txt_local(graficos(i).estado);
    fprintf(fid, '%s_estado=%s\n', id, estado);
    if nums(i) > 0
      fprintf(fid, '%s_ref=figura_%02d\n', id, nums(i));
    endif
  endfor

  escribir_ref_alias_local(fid, graficos, nums, {'nodal','nodal_bes','principal','cartas_gibbs','resumen','grafico_principal'}, 'principal');
  escribir_ref_alias_local(fid, graficos, nums, {'survey_2d','survey'}, 'survey');
  escribir_ref_alias_local(fid, graficos, nums, {'survey_3d_punzados'}, 'survey_3d_punzados');
  escribir_ref_alias_local(fid, graficos, nums, {'punzados_2d','punzados'}, 'punzados');
  escribir_ref_alias_local(fid, graficos, nums, {'taitel_tuberia'}, 'taitel');
  escribir_ref_alias_local(fid, graficos, nums, {'taitel_tuberia'}, 'diagnostico_tuberia');
  escribir_ref_alias_local(fid, graficos, nums, {'punzados_aporte'}, 'punzados_aporte');
endfunction

function salida = deduplicar_local(graficos)
  salida = struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  firmas = {};
  for i = 1:numel(graficos)
    id = limpiar_id_local(graficos(i).id);
    b64 = '';
    if isfield(graficos(i), 'base64') && ischar(graficos(i).base64)
      b64 = graficos(i).base64;
    endif
    if isempty(b64)
      firma = ['estado:' id ':' limpiar_txt_local(graficos(i).estado)];
    else
      n = numel(b64);
      k = min(96, n);
      firma = sprintf('png:%s:%d:%s:%s', id, n, b64(1:k), b64(max(1,n-k+1):n));
    endif
    repetido = false;
    for j = 1:numel(firmas)
      if strcmp(firma, firmas{j})
        repetido = true;
        break;
      endif
    endfor
    if ~repetido
      salida(end+1) = graficos(i);
      firmas{end+1} = firma;
    endif
  endfor
endfunction

function escribir_ref_alias_local(fid, graficos, nums, ids, alias)
  idx = buscar_id_local(graficos, ids);
  if idx <= 0
    return;
  endif
  fprintf(fid, '%s_estado=%s\n', alias, limpiar_txt_local(graficos(idx).estado));
  if nums(idx) > 0
    fprintf(fid, '%s_ref=figura_%02d\n', alias, nums(idx));
  endif
endfunction

function idx = buscar_id_local(graficos, ids)
  idx = 0;
  for i = 1:numel(graficos)
    id = limpiar_id_local(graficos(i).id);
    for k = 1:numel(ids)
      if strcmpi(id, limpiar_id_local(ids{k}))
        idx = i;
        return;
      endif
    endfor
  endfor
endfunction

function s = limpiar_id_local(txt)
  if ~ischar(txt), txt = 'grafico'; endif
  s = lower(regexprep(txt, '[^A-Za-z0-9]+', '_'));
  s = regexprep(s, '^_+|_+$', '');
  if isempty(s), s = 'grafico'; endif
endfunction

function s = limpiar_txt_local(txt)
  if ~ischar(txt), txt = ''; endif
  s = regexprep(txt, '[\r\n=]', ' ');
endfunction
