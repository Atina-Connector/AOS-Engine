function resultado = aos_buscar_cruce_nodal(balance_fun, qmax, opciones)
% aos_buscar_cruce_nodal.m
% Buscador nodal robusto y auditable para AOS.
% - No oculta el cruce si existe cambio de signo.
% - Guarda tabla Q/residuo y todos los cruces detectados.
% - Usa bisección pura para evitar dependencias o fallos de fzero.

  if nargin < 3 || ~isstruct(opciones), opciones = struct(); end
  n = getnum_bn(opciones, 'n_puntos', 1201);
  tol_P = getnum_bn(opciones, 'tol_P', 0.05e5);      % 0.05 bar
  tol_Q_rel = getnum_bn(opciones, 'tol_Q_rel', 1e-6);
  tol_Q_abs = getnum_bn(opciones, 'tol_Q_abs', 1e-10);

  qmax = max(qmax, 0);
  if ~isfinite(qmax) || qmax <= 0
      resultado = resultado_vacio('IPR sin caudal maximo positivo.');
      return;
  end
  qsup = qmax * 0.999;
  if qsup <= 0, qsup = qmax; end
  qgrid = linspace(0, qsup, max(n, 21));
  resid = NaN(size(qgrid));
  errores = cell(size(qgrid));

  for i = 1:length(qgrid)
      try
          resid(i) = balance_fun(qgrid(i));
      catch err
          resid(i) = NaN;
          errores{i} = err.message;
      end
  end

  validos = find(isfinite(resid));
  roots = [];
  idx_bracket = [];
  if ~isempty(validos)
      % Buscar cambios entre puntos finitos consecutivos en la malla, aunque
      % haya NaN antes/despues. Esto evita declarar cero por un catch local.
      for k = 1:(length(validos)-1)
          i = validos(k); j = validos(k+1);
          fi = resid(i); fj = resid(j);
          if abs(fi) <= tol_P
              roots(end+1) = qgrid(i); %#ok<AGROW>
              idx_bracket(end+1,:) = [i i]; %#ok<AGROW>
          elseif fi * fj < 0
              qa = qgrid(i); qb = qgrid(j); fa = fi;
              qroot = NaN;
              for it = 1:80
                  qm = 0.5 * (qa + qb);
                  try
                      fm = balance_fun(qm);
                  catch
                      fm = NaN;
                  end
                  if ~isfinite(fm)
                      break;
                  end
                  if abs(fm) <= tol_P || abs(qb-qa) <= max(tol_Q_abs, tol_Q_rel * max(abs(qm), tol_Q_abs))
                      qroot = qm; break;
                  end
                  if fa * fm <= 0
                      qb = qm;
                  else
                      qa = qm; fa = fm;
                  end
              end
              if isnan(qroot), qroot = 0.5*(qa+qb); end
              roots(end+1) = qroot; %#ok<AGROW>
              idx_bracket(end+1,:) = [i j]; %#ok<AGROW>
          end
      end
  end

  % Quitar raíces duplicadas muy cercanas.
  if ~isempty(roots)
      roots = sort(roots(:)');
      keep = true(size(roots));
      for i = 2:length(roots)
          if abs(roots(i)-roots(i-1)) <= max(tol_Q_abs, tol_Q_rel*max(abs(roots(i)),1e-9))
              keep(i) = false;
          end
      end
      roots = roots(keep);
  end

  resultado = struct();
  resultado.qgrid = qgrid;
  resultado.residuo = resid;
  resultado.errores = errores;
  resultado.validos = validos;
  resultado.raices = roots;
  resultado.idx_bracket = idx_bracket;
  resultado.tol_P = tol_P;
  resultado.qmax = qmax;

  if ~isempty(roots)
      resultado.Ql = roots(1);
      resultado.estado = 'CRUCE_RESUELTO';
      resultado.mensaje = sprintf('Cruce nodal resuelto con buscador robusto (%d raiz/raices).', length(roots));
      return;
  end

  if isempty(validos)
      resultado.Ql = 0;
      resultado.estado = 'SIN_EVALUACION';
      resultado.mensaje = 'No se pudo evaluar ningun punto del balance nodal.';
      return;
  end

  [res_min, jj] = min(abs(resid(validos)));
  idx_min = validos(jj);
  resultado.idx_min = idx_min;
  resultado.residuo_min = resid(idx_min);
  resultado.Ql_min_residuo = qgrid(idx_min);

  if res_min <= tol_P
      resultado.Ql = qgrid(idx_min);
      resultado.estado = 'CRUCE_APROXIMADO';
      resultado.mensaje = 'Cruce nodal aproximado por minimo residuo.';
  elseif all(resid(validos) > 0)
      resultado.Ql = qsup;
      resultado.estado = 'LIMITADO_POR_IPR';
      resultado.mensaje = 'Presion disponible mayor que VLP en todo el rango; caudal limitado por IPR.';
  elseif all(resid(validos) < 0)
      resultado.Ql = 0;
      resultado.estado = 'SIN_CRUCE_PRESION_INSUFICIENTE';
      resultado.mensaje = 'No se detecto cruce: la presion disponible es menor que la VLP en todo el rango.';
  else
      resultado.Ql = qgrid(idx_min);
      resultado.estado = 'SIN_CAMBIO_SIGNO_MIN_RESIDUO';
      resultado.mensaje = 'No se detecto cambio de signo; se informa el minimo residuo para auditoria.';
  end
end

function r = resultado_vacio(msg)
  r = struct();
  r.Ql = 0; r.qgrid = []; r.residuo = []; r.errores = {}; r.validos = [];
  r.raices = []; r.estado = 'SIN_QMAX'; r.mensaje = msg; r.qmax = 0;
end

function v = getnum_bn(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      x = s.(campo);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1)), v = x(1); end
  end
end
