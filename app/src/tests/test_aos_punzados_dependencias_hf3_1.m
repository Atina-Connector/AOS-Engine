function ok = test_aos_punzados_dependencias_hf3_1()
% Verifica cierre autocontenido de dependencias del gestor de punzados HF3.1.
  ok = false;
  raiz = fileparts(fileparts(fileparts(mfilename('fullpath'))));
  dependencias = { ...
    'aos_texto_seguro',  'src/utilidades/config/aos_texto_seguro.m'; ...
    'aos_numero_seguro', 'src/utilidades/config/aos_numero_seguro.m'; ...
    'aos_vector_seguro', 'src/utilidades/config/aos_vector_seguro.m'; ...
    'aos_logico_seguro', 'src/utilidades/config/aos_logico_seguro.m'; ...
    'aos_preguntar_sn',  'src/utilidades/varios/aos_preguntar_sn.m'};

  for i = 1:rows(dependencias)
    nombre = dependencias{i,1};
    esperado = fullfile(raiz, dependencias{i,2});
    assert(exist(esperado, 'file') == 2);
    activo = which(nombre);
    assert(ischar(activo) && ~isempty(activo));
    assert(ruta_igual_local(activo, esperado));
  endfor

  [v, valido] = aos_logico_seguro('si', false);
  assert(valido && v);
  [v, valido] = aos_logico_seguro('no', true);
  assert(valido && ~v);

  tramo = struct('id','PZ-DEP-001','MD_desde',1000, ...
    'MD_hasta',1010,'densidad_tpm',12,'diametro_punzado_m',0.010, ...
    'activo','no');
  [punzados, avisos] = aos_punzados_normalizar(tramo); %#ok<NASGU>
  assert(punzados.n_tramos == 1);
  assert(~punzados.tramos(1).activo);

  ok = true;
  fprintf('RESULTADO: test_aos_punzados_dependencias_hf3_1 APROBADO\n');
endfunction

function tf = ruta_igual_local(a, b)
  a = canon_local(a); b = canon_local(b);
  if ispc(), a = lower(a); b = lower(b); endif
  tf = strcmp(a, b);
endfunction

function p = canon_local(p)
  p = strrep(char(p), '\\', '/');
  try
    c = canonicalize_file_name(p);
    if ischar(c) && ~isempty(c), p = strrep(c, '\\', '/'); endif
  catch
  end_try_catch
  while numel(p) > 1 && p(end) == '/', p(end) = []; endwhile
endfunction
