function d = aos_sensibilidad_diagnosticar(R, modulo, param)
% AOS_SENSIBILIDAD_DIAGNOSTICAR Diagnostico transversal de sensibilidades.
% No modifica resultados fisicos. Clasifica usando estados, aceptacion y
% tolerancias ya informadas por cada solver.

  if nargin < 1 || ~isstruct(R), R = struct(); endif
  if nargin < 2 || ~ischar(modulo) || isempty(strtrim(modulo)), modulo = 'GENERAL'; endif
  if nargin < 3 || ~isstruct(param), param = struct(); endif

  modulo = upper(strtrim(modulo));
  n = numero_puntos_local(R);
  estados = serie_texto_local(R, {'estado','estados','Estado','Estado_solver'}, n);
  estados_op = serie_texto_local(R, {'estado_operativo','Estado_operativo'}, n);
  rangos_inf = serie_texto_local(R, {'rango_inferior_estado','Rango_inferior'}, n);
  rangos_sup = serie_texto_local(R, {'rango_superior_estado','rango_estado','Rango_superior'}, n);
  secciones = serie_texto_local(R, {'estado_secciones','Estado_secciones'}, n);
  aceptado = serie_logica_local(R, {'aceptado','Aceptado'}, n);
  convergido = serie_logica_local(R, {'convergido','Convergido'}, n);

  if isempty(aceptado)
    aceptado = false(n,1);
    encontrado = false(n,1);
    if isfield(R, 'soluciones') && iscell(R.soluciones)
      for i = 1:min(n, numel(R.soluciones))
        s = R.soluciones{i};
        if isstruct(s) && isfield(s, 'aceptado') && isscalar(s.aceptado)
          aceptado(i) = logical(s.aceptado); encontrado(i) = true;
        endif
        if isempty(rangos_inf{i}) && isstruct(s)
          rangos_inf{i} = texto_struct_local(s, {'rango_inferior_estado','rango_estado'});
        endif
        if isempty(rangos_sup{i}) && isstruct(s)
          rangos_sup{i} = texto_struct_local(s, {'rango_superior_estado','rango_estado'});
        endif
        if isempty(secciones{i}) && isstruct(s) && isfield(s, 'diagnostico_recirculacion') && ...
            isstruct(s.diagnostico_recirculacion)
          secciones{i} = texto_struct_local(s.diagnostico_recirculacion, {'estado_secciones'});
        endif
      endfor
    endif
    if ~any(encontrado)
      aceptado = inferir_aceptacion_local(estados, n);
    endif
  endif

  if isempty(convergido)
    convergido = true(n,1);
    if isfield(R, 'soluciones') && iscell(R.soluciones)
      encontrado = false(n,1);
      for i = 1:min(n, numel(R.soluciones))
        s = R.soluciones{i};
        if isstruct(s) && isfield(s, 'convergido') && isscalar(s.convergido)
          convergido(i) = logical(s.convergido); encontrado(i) = true;
        endif
      endfor
      if ~any(encontrado), convergido = inferir_convergencia_local(estados, n); endif
    else
      convergido = inferir_convergencia_local(estados, n);
    endif
  endif

  [q, q_nombre, q_unidad] = serie_produccion_local(R, n);
  tol = tolerancia_produccion_local(q, modulo, param, R);
  sin_prod = false(n,1);
  if ~isempty(q), sin_prod = isfinite(q) & q <= tol; endif
  for i = 1:n
    txt = upper([celda_local(estados_op,i) ' ' celda_local(estados,i)]);
    if contiene_local(txt, 'SIN_PRODUCCION') || contiene_local(txt, 'SIN_FLUJO') || ...
       contiene_local(txt, 'POZO_SIN_FLUJO') || contiene_local(txt, 'RECIRCULACION_INTERNA_SIN_PRODUCCION')
      sin_prod(i) = true;
    endif
  endfor

  advertencia = false(n,1);
  for i = 1:n
    txt = upper([celda_local(estados,i) ' ' celda_local(estados_op,i) ' ' ...
      celda_local(rangos_inf,i) ' ' celda_local(rangos_sup,i) ' ' celda_local(secciones,i)]);
    advertencia(i) = contiene_local(txt,'RIESGO') || contiene_local(txt,'FUERA_') || ...
      contiene_local(txt,'ALTA') || contiene_local(txt,'LIMITADO') || ...
      contiene_local(txt,'EXCEDE_LIMITE') || contiene_local(txt,'FUERA_LIMITE') || ...
      contiene_local(txt,'BAJO_RANGO') || contiene_local(txt,'MAYOR_QUE_PRODUCCION') || ...
      contiene_local(txt,'INTERFERENCIA') || contiene_local(txt,'SIN_CRUCE');
  endfor

  no_conv = ~convergido;
  n_aceptados = sum(aceptado);
  n_sin_prod = sum(sin_prod);
  n_no_conv = sum(no_conv);
  n_advert = sum(advertencia);
  estado_global = 'RESULTADOS_DISPONIBLES';
  semaforo = 'VERDE';
  mensajes = {};

  if n == 0
    estado_global = 'SIN_PUNTOS'; semaforo = 'ROJO';
    mensajes{end+1} = 'La sensibilidad no contiene puntos evaluados.';
  elseif n_no_conv == n
    estado_global = 'NINGUN_PUNTO_CONVERGIDO'; semaforo = 'ROJO';
    mensajes{end+1} = 'Ningun punto de la sensibilidad alcanzo convergencia.';
  elseif n_aceptados == 0
    estado_global = 'SIN_PUNTO_OPERATIVO_ACEPTABLE_EN_RANGO'; semaforo = 'ROJO';
    mensajes{end+1} = 'No se encontro un punto operativo aceptable en el rango evaluado.';
  elseif n_aceptados < n
    estado_global = 'RANGO_CON_PUNTOS_ACEPTABLES_Y_RECHAZADOS'; semaforo = 'AMARILLO';
    mensajes{end+1} = 'El rango contiene puntos aceptables y puntos rechazados o no validados.';
  endif

  if n_sin_prod > 0
    mensajes{end+1} = sprintf('%d de %d puntos se clasifican sin produccion o flujo neto.', n_sin_prod, n);
  endif
  if n_no_conv > 0
    mensajes{end+1} = sprintf('%d de %d puntos no convergieron.', n_no_conv, n);
  endif
  if n_advert > 0
    mensajes{end+1} = sprintf('%d de %d puntos contienen advertencias operativas o numericas.', n_advert, n);
  endif

  if contiene_local(modulo, 'BES3')
    activos = true(n,1);
    modos = serie_texto_local(R, {'modo','Modo'}, n);
    for i = 1:n
      if contiene_local(upper(celda_local(modos,i)), 'BOMBA_APAGADA'), activos(i) = false; endif
    endfor
    bajos = false(n,1);
    for i = 1:n
      txt = upper([celda_local(rangos_inf,i) ' ' celda_local(rangos_sup,i) ' ' celda_local(secciones,i)]);
      bajos(i) = contiene_local(txt,'BAJO_RANGO');
    endfor
    ids = find(activos);
    if ~isempty(ids) && all(bajos(ids))
      estado_global = 'BOMBA_SOBREDIMENSIONADA_EN_TODO_EL_RANGO'; semaforo = 'ROJO';
      mensajes{end+1} = 'Las secciones de la bomba permanecen por debajo del rango recomendado en todo el rango evaluado.';
    endif
    rec_alta = contar_patron_local(serie_texto_local(R, {'estado_diseno','Estado_diseno'}, n), 'RECIRCULACION_ALTA');
    if rec_alta > 0
      mensajes{end+1} = sprintf('%d puntos exceden el limite configurado de recirculacion.', rec_alta);
    endif
    bi = max_finito_local(serie_num_local(R, {'BEP_inferior_pct','BEPinf'}, n));
    bs = max_finito_local(serie_num_local(R, {'BEP_superior_pct','BEPsup'}, n));
    if isfinite(bi), mensajes{end+1} = sprintf('BEP maximo de etapas inferiores: %.2f %%.', bi); endif
    if isfinite(bs), mensajes{end+1} = sprintf('BEP maximo de etapas superiores: %.2f %%.', bs); endif
  elseif contiene_local(modulo, 'BES')
    rangos = rangos_sup;
    bajos = false(n,1);
    for i = 1:n, bajos(i) = contiene_local(upper(celda_local(rangos,i)),'BAJO_RANGO'); endfor
    if n > 0 && all(bajos)
      estado_global = 'BOMBA_SOBREDIMENSIONADA_EN_TODO_EL_RANGO'; semaforo = 'ROJO';
      mensajes{end+1} = 'La bomba opera por debajo de su rango recomendado en todos los puntos.';
    endif
  endif

  if isempty(mensajes)
    mensajes{1} = 'La sensibilidad no presenta advertencias globales con los criterios disponibles.';
  endif

  d = struct();
  d.schema = 'AOS_EXECUTIVE_DIAGNOSIS_1.0';
  d.modulo = modulo;
  d.estado_global = estado_global;
  d.semaforo = semaforo;
  d.n_puntos = n;
  d.n_aceptados = n_aceptados;
  d.n_rechazados = max(n - n_aceptados, 0);
  d.n_sin_produccion = n_sin_prod;
  d.n_no_convergidos = n_no_conv;
  d.n_advertencias = n_advert;
  d.q_tolerancia = tol;
  d.q_nombre = q_nombre;
  d.q_unidad = q_unidad;
  d.punto_aceptado = aceptado;
  d.punto_convergido = convergido;
  d.punto_sin_produccion = sin_prod;
  d.mensajes = mensajes;
  d.resumen = sprintf('%s: %d/%d puntos aceptables; %d sin produccion; %d no convergidos.', ...
    estado_global, n_aceptados, n, n_sin_prod, n_no_conv);
endfunction

function n = numero_puntos_local(R)
  n = 0;
  if isfield(R,'valores') && isnumeric(R.valores), n = numel(R.valores); return; endif
  if isfield(R,'n') && isnumeric(R.n) && isscalar(R.n), n = max(round(R.n),0); return; endif
  if isfield(R,'rows') && iscell(R.rows), n = size(R.rows,1); return; endif
  if isfield(R,'columnas') && iscell(R.columnas) && ~isempty(R.columnas), n = numel(R.columnas{1}); endif
endfunction

function [q,nombre,unidad] = serie_produccion_local(R,n)
  q = []; nombre = 'produccion'; unidad = '-';
  candidatos = {'Qprod_m3_d','Ql_m3_d','Ql_m3d','Qg_Sm3_d','Qs_Sm3_d', ...
    'Q_aspirado_Sm3_d','Ql_JGL_m3d','Ql_GL_m3d','Qo_m3_d','Qo_m3d'};
  for i = 1:numel(candidatos)
    v = serie_num_local(R,{candidatos{i}},n);
    if ~isempty(v), q=v; nombre=candidatos{i}; break; endif
  endfor
  if contiene_local(lower(nombre),'sm3'), unidad='Sm3/d';
  elseif contiene_local(lower(nombre),'m3'), unidad='m3/d'; endif
endfunction

function tol = tolerancia_produccion_local(q, modulo, p, R)
  tol = 0.01;
  campos = {'bes3_tol_produccion_m3_d','sens_q_min_productivo','q_min_productivo_m3_d'};
  for i=1:numel(campos)
    if isfield(p,campos{i}) && isnumeric(p.(campos{i})) && isscalar(p.(campos{i})) && isfinite(p.(campos{i}))
      tol=max(double(p.(campos{i})),0); return;
    endif
    if isfield(R,campos{i}) && isnumeric(R.(campos{i})) && isscalar(R.(campos{i})) && isfinite(R.(campos{i}))
      tol=max(double(R.(campos{i})),0); return;
    endif
  endfor
  if ~isempty(q)
    m=max_finito_local(abs(q));
    if isfinite(m), tol=max(tol,1e-8*max(m,1)); endif
  endif
endfunction

function v = serie_num_local(R, nombres, n)
  v = [];
  for k=1:numel(nombres)
    f=nombres{k};
    if isfield(R,f) && isnumeric(R.(f)) && numel(R.(f))==n
      v=double(R.(f)(:)); return;
    endif
  endfor
  [cab, cols] = columnas_local(R);
  for k=1:numel(nombres)
    j=find(strcmpi(cab,nombres{k}),1);
    if ~isempty(j) && j<=numel(cols) && isnumeric(cols{j}) && numel(cols{j})==n
      v=double(cols{j}(:)); return;
    endif
  endfor
endfunction

function c = serie_texto_local(R, nombres, n)
  c = repmat({''},n,1);
  for k=1:numel(nombres)
    f=nombres{k};
    if isfield(R,f) && iscell(R.(f)) && numel(R.(f))==n
      c=R.(f)(:); return;
    endif
  endfor
  [cab, cols] = columnas_local(R);
  for k=1:numel(nombres)
    j=find(strcmpi(cab,nombres{k}),1);
    if ~isempty(j) && j<=numel(cols) && iscell(cols{j}) && numel(cols{j})==n
      c=cols{j}(:); return;
    endif
  endfor
  if isfield(R,'headers') && iscell(R.headers) && isfield(R,'rows') && iscell(R.rows)
    for k=1:numel(nombres)
      j=find(strcmpi(R.headers,nombres{k}),1);
      if ~isempty(j) && size(R.rows,1)==n && size(R.rows,2)>=j
        for i=1:n
          x=R.rows{i,j}; if ischar(x), c{i}=x; endif
        endfor
        return;
      endif
    endfor
  endif
endfunction

function v = serie_logica_local(R,nombres,n)
  v=[];
  for k=1:numel(nombres)
    f=nombres{k};
    if isfield(R,f) && (isnumeric(R.(f)) || islogical(R.(f))) && numel(R.(f))==n
      v=logical(R.(f)(:)); return;
    endif
  endfor
  c=serie_texto_local(R,nombres,n);
  if any(~cellfun(@isempty,c))
    v=false(n,1);
    for i=1:n
      x=upper(strtrim(c{i})); v(i)=strcmp(x,'SI')||strcmp(x,'OK')||strcmp(x,'ACEPTADO')||strcmp(x,'TRUE')||strcmp(x,'1');
    endfor
  endif
endfunction

function [h,c] = columnas_local(R)
  h={}; c={};
  if isfield(R,'nombres') && iscell(R.nombres) && isfield(R,'columnas') && iscell(R.columnas)
    h=R.nombres; c=R.columnas;
  endif
endfunction

function v = inferir_aceptacion_local(estados,n)
  v=true(n,1);
  for i=1:n
    x=upper(celda_local(estados,i));
    if contiene_local(x,'ERROR')||contiene_local(x,'NO_CONVER')||contiene_local(x,'SIN_PUNTO')|| ...
       contiene_local(x,'INVALID')||contiene_local(x,'SIN_CRUCE')||contiene_local(x,'LIMITADO')
      v(i)=false;
    endif
  endfor
endfunction

function v = inferir_convergencia_local(estados,n)
  v=true(n,1);
  for i=1:n
    x=upper(celda_local(estados,i));
    if contiene_local(x,'ERROR')||contiene_local(x,'NO_CONVER')||contiene_local(x,'SIN_PUNTO')|| ...
       contiene_local(x,'SIN_CRUCE')||contiene_local(x,'DOMINIO_VACIO')||contiene_local(x,'SIN_CAPACIDAD')
      v(i)=false;
    endif
  endfor
endfunction

function t = texto_struct_local(s,campos)
  t='';
  for k=1:numel(campos)
    if isfield(s,campos{k}) && ischar(s.(campos{k})), t=s.(campos{k}); return; endif
  endfor
endfunction

function n=contar_patron_local(c,p)
  n=0; for i=1:numel(c), if contiene_local(upper(celda_local(c,i)),upper(p)), n=n+1; endif, endfor
endfunction

function t=celda_local(c,i)
  t=''; if i>=1 && i<=numel(c) && ischar(c{i}), t=c{i}; endif
endfunction

function tf=contiene_local(txt,pat)
  tf=false; if ischar(txt)&&ischar(pat)&&~isempty(strfind(txt,pat)), tf=true; endif
endfunction

function v=max_finito_local(x)
  y=x(isfinite(x)); if isempty(y), v=NaN; else, v=max(y); endif
endfunction
