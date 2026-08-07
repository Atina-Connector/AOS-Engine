function L = sens_jgl_limite_presion(Qiny_Sm3_d, P_req_bar, P_disp_bar)
% SENS_JGL_LIMITE_PRESION Estima el Qiny maximo permitido por presion.
% Usa interpolacion lineal del margen entre puntos calculados. No extrapola.

  x = fila_local(Qiny_Sm3_d);
  r = fila_local(P_req_bar);
  d = fila_local(P_disp_bar);
  n = min([numel(x),numel(r),numel(d)]);
  x = x(1:n); r = r(1:n); d = d(1:n);

  L = struct('schema','AOS_JGL_PRESSURE_LIMIT_1.0','hotfix','SENS-GLJGL-03', ...
    'estado','NO_EVALUADO','evaluado',false,'Qiny_max_presion_Sm3_d',NaN, ...
    'P_disponible_bar',NaN,'n_factibles',0,'n_evaluados',0, ...
    'margen_bar',NaN(1,n),'advertencias',{{}});

  ok = isfinite(x) & isfinite(r) & isfinite(d);
  if ~any(ok)
    L.estado = 'PRESION_DISPONIBLE_NO_INFORMADA';
    return;
  endif
  L.evaluado = true;
  L.margen_bar(ok) = d(ok) - r(ok);
  L.n_evaluados = sum(ok);
  dv = d(ok);
  if ~isempty(dv), L.P_disponible_bar = dv(1); endif

  ids = find(ok);
  [xs,ord] = sort(x(ids));
  ms = L.margen_bar(ids(ord));
  fact = ms >= 0;
  L.n_factibles = sum(fact);

  if all(fact)
    L.Qiny_max_presion_Sm3_d = max(xs);
    L.estado = 'TODO_EL_BARRIDO_FACTIBLE';
    return;
  endif
  if ~any(fact)
    L.estado = 'NINGUN_PUNTO_FACTIBLE';
    return;
  endif

  qlim = max(xs(fact));
  % Buscar un cruce factible -> no factible en orden creciente.
  for i = 1:numel(xs)-1
    if ms(i) >= 0 && ms(i+1) < 0
      den = ms(i) - ms(i+1);
      if abs(den) > 1e-12
        qlim = xs(i) + (xs(i+1)-xs(i)) * ms(i) / den;
      else
        qlim = xs(i);
      endif
      break;
    endif
  endfor
  L.Qiny_max_presion_Sm3_d = qlim;
  L.estado = 'LIMITE_INTERPOLADO_EN_EL_BARRIDO';

  % Advertir si la factibilidad no es monotona con Qiny.
  cambios = sum(abs(diff(double(fact))) > 0);
  if cambios > 1
    L.advertencias{end+1} = ...
      'La factibilidad por presion no es monotona; el limite informado es el primer cruce factible-no factible.';
  endif
endfunction

function x = fila_local(v)
  if isnumeric(v), x = double(v(:)'); else, x = []; endif
endfunction
