function A = sens_ajuste_polinomico(x, y, valido, cfg)
% SENS_AJUSTE_POLINOMICO Ajuste explicito, normalizado y auditable.
% SENS-GLJGL-02. Solo usa puntos aceptados. No extrapola y no reemplaza
% resultados del solver. El grado puede ser automatico o 2..5.

  if nargin < 4 || ~isstruct(cfg), cfg = struct(); endif
  if nargin < 3 || isempty(valido), valido = true(size(x)); endif
  x = double(x(:)');
  y = double(y(:)');
  valido = logical(valido(:)');

  A = base_local(cfg, numel(x));
  if numel(x) ~= numel(y) || numel(x) ~= numel(valido)
    A.estado = 'DIMENSIONES_INCOMPATIBLES';
    A.motivos_rechazo{end+1} = 'x, y y valido deben tener igual longitud.';
    return;
  endif

  mask_fin = isfinite(x) & isfinite(y);
  if sum(mask_fin & valido) < 3
    A.estado = 'DATOS_INSUFICIENTES';
    A.motivos_rechazo{end+1} = 'Se requieren al menos tres puntos validos.';
    return;
  endif

  [xs_all, ord] = sort(x);
  ys_all = y(ord);
  vs_all = valido(ord) & isfinite(xs_all) & isfinite(ys_all);

  % Qiny debe ser unico en la curva. Si hay duplicados se conserva el primer
  % punto valido; si ninguno es valido se conserva el primero solo para dejar
  % visible la discontinuidad. La malla ya esta ordenada.
  xs_u = unique(xs_all);
  ys_u = NaN(size(xs_u));
  vs_u = false(size(xs_u));
  for j = 1:numel(xs_u)
    ids = find(xs_all == xs_u(j));
    iv = ids(find(vs_all(ids), 1, 'first'));
    if isempty(iv), iv = ids(1); endif
    ys_u(j) = ys_all(iv);
    vs_u(j) = vs_all(iv);
  endfor
  if numel(xs_u) < numel(xs_all)
    A.advertencias{end+1} = 'Se eliminaron valores repetidos de la variable independiente.';
  endif

  segmentos = segmentos_validos_local(vs_u);
  if isempty(segmentos)
    A.estado = 'SIN_SEGMENTO_VALIDO';
    A.motivos_rechazo{end+1} = 'No existe un segmento continuo de puntos validos.';
    return;
  endif
  [seg, nseg] = elegir_segmento_local(segmentos, xs_u);
  A.n_segmentos_validos = nseg;
  A.discontinuidad = nseg > 1;
  if A.discontinuidad
    A.advertencias{end+1} = sprintf(['La curva contiene %d segmentos validos separados. ' ...
      'El ajuste usa solo el segmento continuo mas extenso.'], nseg);
  endif

  idx_seg = seg(1):seg(2);
  xs = xs_u(idx_seg);
  ys = ys_u(idx_seg);
  A.indices_segmento_ordenado = idx_seg;
  A.n_puntos_usados = numel(xs);
  A.dominio_min = min(xs);
  A.dominio_max = max(xs);
  A.x_usado = xs;
  A.y_usado = ys;

  if numel(xs) < 3 || ~(A.dominio_max > A.dominio_min)
    A.estado = 'SEGMENTO_INSUFICIENTE';
    A.motivos_rechazo{end+1} = 'El segmento continuo no permite un ajuste polinomico.';
    return;
  endif

  grado_req = numero_local(cfg, 'grado_solicitado', 0);
  grado_max = max(2, min(5, round(numero_local(cfg, 'grado_maximo', 5))));
  ngrid = max(51, min(5001, round(numero_local(cfg, 'n_grid', 201))));
  if mod(ngrid,2) == 0, ngrid = ngrid + 1; endif
  A.grado_solicitado = round(grado_req);
  A.grado_maximo = grado_max;
  A.n_grid = ngrid;

  x0 = (A.dominio_min + A.dominio_max) / 2;
  sx = (A.dominio_max - A.dominio_min) / 2;
  if ~isfinite(sx) || sx <= 0, sx = 1; endif
  u = (xs - x0) / sx;
  ug = linspace(-1, 1, ngrid);
  xg = x0 + sx * ug;
  A.x_centro = x0;
  A.x_escala = sx;

  if A.grado_solicitado == 0
    grados = 2:min([grado_max, numel(xs)-1, 5]);
  else
    g = max(2, min(5, A.grado_solicitado));
    if g > numel(xs)-1
      grados = [];
      A.advertencias{end+1} = sprintf(['El grado %d requiere al menos %d puntos ' ...
        'continuos; solo hay %d.'], g, g+1, numel(xs));
    else
      grados = g;
    endif
  endif
  if isempty(grados)
    A.estado = 'GRADO_NO_DISPONIBLE';
    A.motivos_rechazo{end+1} = 'No hay puntos suficientes para el grado solicitado.';
    return;
  endif

  candidatos = cell(1, numel(grados));
  for k = 1:numel(grados)
    candidatos{k} = ajustar_grado_local(u, ys, ug, xg, x0, sx, grados(k), cfg);
  endfor
  [C, motivo] = elegir_candidato_local(candidatos, A.grado_solicitado == 0);
  if isempty(C)
    A.estado = 'AJUSTE_FALLIDO';
    A.motivos_rechazo{end+1} = motivo;
    return;
  endif

  A.grado_efectivo = C.grado;
  A.coeficientes_normalizados = C.coeficientes;
  A.x_grid = xg;
  A.y_grid = C.y_grid;
  A.derivada_grid = C.derivada_grid;
  A.y_ajustada_puntos_usados = C.y_puntos;
  A.residuos_puntos_usados = C.residuos;
  A.rmse = C.rmse;
  A.error_maximo = C.error_maximo;
  A.r2 = C.r2;
  A.condicion = C.condicion;
  A.n_extremos_internos = C.n_extremos_internos;
  A.n_extremos_discretos = C.n_extremos_discretos;
  A.estacionarios = C.estacionarios;
  A.maximo_global = C.maximo_global;
  A.maximo_interior = C.maximo_interior;
  A.minimo_global = C.minimo_global;
  A.apto_informativo = C.apto_informativo;
  A.apto_para_optimizacion = C.apto_para_optimizacion;
  A.violacion_limite_inferior = C.violacion_limite_inferior;
  A.violacion_limite_superior = C.violacion_limite_superior;
  A.sobreoscilacion = C.sobreoscilacion;
  A.score_auto = C.score;

  % Serie derivada evaluada en la malla original, solo dentro del dominio.
  A.y_en_puntos_originales = NaN(size(x));
  dentro = isfinite(x) & x >= A.dominio_min & x <= A.dominio_max;
  A.y_en_puntos_originales(dentro) = polyval(A.coeficientes_normalizados, ...
    (x(dentro)-A.x_centro)/A.x_escala);

  if A.apto_para_optimizacion
    if A.discontinuidad
      A.estado = 'OK_SEGMENTO_CONTINUO';
    else
      A.estado = 'OK';
    endif
  elseif A.apto_informativo
    A.estado = 'POLINOMIO_SOLO_INFORMATIVO';
    A.advertencias{end+1} = 'El ajuste no cumple todos los criterios para optimizacion.';
  else
    A.estado = 'POLINOMIO_RECHAZADO';
    A.motivos_rechazo{end+1} = 'El ajuste no es numericamente apto.';
  endif
endfunction

function C = ajustar_grado_local(u, y, ug, xg, x0, sx, grado, cfg)
  C = struct('grado',grado,'coeficientes',[],'y_grid',NaN(size(ug)), ...
    'derivada_grid',NaN(size(ug)),'y_puntos',NaN(size(y)), ...
    'residuos',NaN(size(y)),'rmse',NaN,'error_maximo',NaN,'r2',NaN, ...
    'condicion',Inf,'n_extremos_internos',0,'n_extremos_discretos',0, ...
    'estacionarios',struct([]),'maximo_global',punto_vacio_local(), ...
    'maximo_interior',punto_vacio_local(),'minimo_global',punto_vacio_local(), ...
    'apto_informativo',false,'apto_para_optimizacion',false, ...
    'violacion_limite_inferior',false,'violacion_limite_superior',false, ...
    'sobreoscilacion',false,'score',Inf,'error','');
  try
    coef = polyfit(u, y, grado);
    yp = polyval(coef, u);
    yg = polyval(coef, ug);
    dc = polyder(coef);
    dg = polyval(dc, ug) / sx;
    res = y - yp;
    rmse = sqrt(mean(res.^2));
    emax = max(abs(res));
    sst = sum((y-mean(y)).^2);
    sse = sum(res.^2);
    if sst <= eps
      if sse <= eps, r2 = 1; else, r2 = NaN; endif
    else
      r2 = 1 - sse/sst;
    endif

    V = zeros(numel(u), grado+1);
    pot = grado:-1:0;
    for j = 1:numel(pot), V(:,j) = u(:).^pot(j); endfor
    cnd = cond(V);

    est = estacionarios_local(coef, x0, sx);
    next = numel(est);
    nd = extremos_discretos_local(y);
    maxglob = extremo_global_local(coef, x0, sx, xg, 'MAX');
    minglob = extremo_global_local(coef, x0, sx, xg, 'MIN');
    maxint = maximo_interior_local(est);

    linf = numero_local(cfg,'limite_inferior',-Inf);
    lsup = numero_local(cfg,'limite_superior',Inf);
    tol_abs = max(1e-9, numero_local(cfg,'tolerancia_fisica_abs',0));
    escala = max([max(abs(y)), max(abs(yg)), 1]);
    tol = tol_abs + numero_local(cfg,'tolerancia_fisica_rel',1e-4)*escala;
    viol_inf = isfinite(linf) && any(yg < linf - tol);
    viol_sup = isfinite(lsup) && any(yg > lsup + tol);

    max_ext = max(2, nd + 1);
    sobre = next > max_ext;
    informativo = all(isfinite(coef)) && all(isfinite(yg)) && isfinite(cnd) && cnd <= 1e12;
    apto = informativo && ~viol_inf && ~viol_sup && ~sobre;

    escala_err = max(max(y)-min(y), max(abs(y))*0.05);
    escala_err = max(escala_err, 1e-9);
    score = rmse/escala_err + 0.015*grado + 0.08*max(0,next-max_ext);
    if ~apto, score = score + 1; endif
    if cnd > 1e8, score = score + log10(cnd/1e8); endif

    C.coeficientes = coef;
    C.y_grid = yg;
    C.derivada_grid = dg;
    C.y_puntos = yp;
    C.residuos = res;
    C.rmse = rmse;
    C.error_maximo = emax;
    C.r2 = r2;
    C.condicion = cnd;
    C.n_extremos_internos = next;
    C.n_extremos_discretos = nd;
    C.estacionarios = est;
    C.maximo_global = maxglob;
    C.maximo_interior = maxint;
    C.minimo_global = minglob;
    C.apto_informativo = informativo;
    C.apto_para_optimizacion = apto;
    C.violacion_limite_inferior = viol_inf;
    C.violacion_limite_superior = viol_sup;
    C.sobreoscilacion = sobre;
    C.score = score;
  catch err
    C.error = err.message;
  end_try_catch
endfunction

function [C, motivo] = elegir_candidato_local(candidatos, automatico)
  C = [];
  motivo = 'Ningun grado produjo un ajuste finito.';
  validos = [];
  for i = 1:numel(candidatos)
    if candidatos{i}.apto_informativo
      validos(end+1) = i;
    endif
  endfor
  if isempty(validos), return; endif
  if ~automatico
    C = candidatos{validos(1)};
    return;
  endif
  aptos = [];
  for i = validos
    if candidatos{i}.apto_para_optimizacion, aptos(end+1) = i; endif
  endfor
  if ~isempty(aptos), validos = aptos; endif
  scores = NaN(size(validos));
  for k = 1:numel(validos), scores(k) = candidatos{validos(k)}.score; endfor
  [~, j] = min(scores);
  C = candidatos{validos(j)};
endfunction

function est = estacionarios_local(coef, x0, sx)
  est = struct('qiny',{},'valor',{},'tipo',{},'derivada_segunda',{});
  if numel(coef) < 3, return; endif
  dc = polyder(coef);
  rr = roots(dc);
  d2 = polyder(dc);
  for i = 1:numel(rr)
    if abs(imag(rr(i))) > 1e-8, continue; endif
    u = real(rr(i));
    if u <= -1+1e-9 || u >= 1-1e-9, continue; endif
    sec = polyval(d2,u)/(sx^2);
    tipo = 'PLANO';
    if sec < 0, tipo = 'MAXIMO'; elseif sec > 0, tipo = 'MINIMO'; endif
    e = struct('qiny',x0+sx*u,'valor',polyval(coef,u), ...
      'tipo',tipo,'derivada_segunda',sec);
    est(end+1) = e;
  endfor
  if numel(est) > 1
    [~,o] = sort([est.qiny]);
    est = est(o);
  endif
endfunction

function p = maximo_interior_local(est)
  p = punto_vacio_local();
  if isempty(est), return; endif
  idx = [];
  for i = 1:numel(est)
    if strcmp(est(i).tipo,'MAXIMO') && isfinite(est(i).valor), idx(end+1)=i; endif
  endfor
  if isempty(idx), return; endif
  [~,j] = max([est(idx).valor]);
  e = est(idx(j));
  p.qiny_sm3d = e.qiny;
  p.valor = e.valor;
  p.tipo = 'MAXIMO_INTERIOR_DERIVADA_CERO';
  p.interior = true;
endfunction

function p = extremo_global_local(coef, x0, sx, xg, tipo)
  p = punto_vacio_local();
  est = estacionarios_local(coef,x0,sx);
  xc = [xg(1), xg(end)];
  for i = 1:numel(est), xc(end+1) = est(i).qiny; endfor
  uc = (xc-x0)/sx;
  yc = polyval(coef,uc);
  if strcmp(tipo,'MIN')
    [v,j] = min(yc);
  else
    [v,j] = max(yc);
  endif
  p.qiny_sm3d = xc(j);
  p.valor = v;
  p.interior = p.qiny_sm3d > xg(1)+1e-9 && p.qiny_sm3d < xg(end)-1e-9;
  if p.interior
    p.tipo = [tipo '_INTERIOR'];
  else
    p.tipo = [tipo '_BORDE'];
  endif
endfunction

function n = extremos_discretos_local(y)
  n = 0;
  if numel(y) < 3, return; endif
  d = diff(y);
  tol = max(1e-12, 1e-9*max(abs(y)));
  d(abs(d)<=tol) = 0;
  for i = 1:numel(d)-1
    if d(i)==0 || d(i+1)==0, continue; endif
    if d(i)*d(i+1) < 0, n = n + 1; endif
  endfor
endfunction

function S = segmentos_validos_local(v)
  S = zeros(0,2);
  i = 1;
  while i <= numel(v)
    if ~v(i), i = i + 1; continue; endif
    a = i;
    while i < numel(v) && v(i+1), i = i + 1; endwhile
    S(end+1,:) = [a i];
    i = i + 1;
  endwhile
endfunction

function [seg,n] = elegir_segmento_local(S,x)
  n = size(S,1);
  punt = S(:,2)-S(:,1)+1;
  span = zeros(n,1);
  for i=1:n, span(i)=x(S(i,2))-x(S(i,1)); endfor
  mejor = 1;
  for i=2:n
    if punt(i)>punt(mejor) || (punt(i)==punt(mejor) && span(i)>span(mejor))
      mejor=i;
    endif
  endfor
  seg = S(mejor,:);
endfunction

function A = base_local(cfg,n)
  nombre = texto_local(cfg,'nombre','CURVA');
  A = struct('schema','AOS_POLYNOMIAL_FIT_1.0','hotfix','SENS-GLJGL-02', ...
    'nombre',nombre,'estado','NO_EVALUADO','grado_solicitado',NaN, ...
    'grado_efectivo',NaN,'grado_maximo',5,'coeficientes_normalizados',[], ...
    'x_centro',NaN,'x_escala',NaN,'dominio_min',NaN,'dominio_max',NaN, ...
    'n_puntos_entrada',n,'n_puntos_usados',0,'n_grid',0, ...
    'n_segmentos_validos',0,'discontinuidad',false, ...
    'indices_segmento_ordenado',[],'x_usado',[],'y_usado',[], ...
    'x_grid',[],'y_grid',[],'derivada_grid',[], ...
    'y_ajustada_puntos_usados',[],'residuos_puntos_usados',[], ...
    'y_en_puntos_originales',NaN(1,n),'rmse',NaN,'error_maximo',NaN, ...
    'r2',NaN,'condicion',NaN,'n_extremos_internos',0, ...
    'n_extremos_discretos',0,'estacionarios',struct([]), ...
    'maximo_global',punto_vacio_local(),'maximo_interior',punto_vacio_local(), ...
    'minimo_global',punto_vacio_local(),'apto_informativo',false, ...
    'apto_para_optimizacion',false,'violacion_limite_inferior',false, ...
    'violacion_limite_superior',false,'sobreoscilacion',false, ...
    'score_auto',NaN,'extrapolacion',false,'advertencias',{{}}, ...
    'motivos_rechazo',{{}});
endfunction

function p = punto_vacio_local()
  p = struct('qiny_sm3d',NaN,'valor',NaN,'tipo','NO_DISPONIBLE','interior',false);
endfunction
function v = numero_local(s,c,d),v=d;if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&~isempty(s.(c))&&isfinite(s.(c)(1)),v=double(s.(c)(1));endif,endfunction
function t = texto_local(s,c,d),t=d;if isstruct(s)&&isfield(s,c)&&ischar(s.(c))&&~isempty(s.(c)),t=s.(c);endif,endfunction
