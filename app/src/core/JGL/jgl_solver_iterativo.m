function sol = jgl_solver_iterativo(p, Qiny)
% JGL_SOLVER_ITERATIVO Solver preciso de referencia AOS 0.0.12.
% Convergencia: Q relativo, Ps y DeltaP; minimo y maximo configurables.
% GNU Octave es el entorno objetivo.

  p = jgl_defaults(p);
  Qiny = max(Qiny, 0);

  [Q, ~, ~, ~, diagnostico_gl] = GL_sim(p, Qiny);
  Ps_prev = calcular_columna_succion(max(Q,1e-12), p);

  if Qiny <= 1e-12
    e = jgl_eductor_estado_aplicado(p, Q, 0, Ps_prev, 0, 'QINY_CERO');
    if Q > 1e-10
      estado0 = 'FLUJO_NATURAL_CALCULADO';
    else
      estado0 = 'SIN_FLUJO_NATURAL';
    end
    sol = jgl_armar_solucion(p, Q, 0, e, 'ITERATIVO', estado0);
    sol.diagnostico = diagnostico_gl;
    sol.iteraciones = 0;
    sol.historial = [];
    sol.error_directo_iterativo = NaN;
    sol.confianza = jgl_confianza(p, sol);
    return;
  end

  dp_prev = 0;
  H = repmat(struct('iter',0,'Q',0,'Ps',0,'deltaP',0, ...
      'rQ',Inf,'rPs',Inf,'rdP',Inf,'estado_nodal','', ...
      'estado_eductor','','pot_disp',0,'pot_trans',0), 1, p.jgl_max_iter);
  estado = 'NO_CONVERGE';
  det_nodal_final = struct();

  for it = 1:p.jgl_max_iter
    ecalc = jgl_eductor_comun(p, max(Q,1e-12), Qiny, Ps_prev);

    % Sin energia o presion motriz no hay una iteracion fisica que continuar.
    if ~strcmp(ecalc.estado,'OK')
      estado = ecalc.estado;
      e = jgl_eductor_estado_aplicado(p, Q, Qiny, Ps_prev, 0, 'EDUCTOR_NO_FACTIBLE');
      H(it).iter = it;
      H(it).Q = Q;
      H(it).Ps = Ps_prev;
      H(it).deltaP = 0;
      H(it).estado_nodal = 'NO_EJECUTADO';
      H(it).estado_eductor = ecalc.estado;
      H(it).pot_disp = e.pot_disp;
      H(it).pot_trans = e.pot_trans;
      H = H(1:it);
      break;
    end

    dp_calc = ecalc.deltaP;
    [Qcalc, det_nodal] = jgl_resolver_nodal_deltaP(p, Qiny, dp_calc);
    det_nodal_final = det_nodal;

    Qnew = p.jgl_alpha * Qcalc + (1-p.jgl_alpha) * Q;
    Ps_calc = calcular_columna_succion(max(Qnew,1e-12), p);
    Psnew = p.jgl_alpha * Ps_calc + (1-p.jgl_alpha) * Ps_prev;
    dpnew = p.jgl_alpha * dp_calc + (1-p.jgl_alpha) * dp_prev;

    eacept = jgl_eductor_estado_aplicado(p, Qnew, Qiny, Psnew, dpnew, 'ITERACION_RELAJADA');
    dpnew = eacept.deltaP;

    rQ = abs(Qnew-Q) / max(abs(Qnew),1e-12);
    rPs = abs(Psnew-Ps_prev) / 1e5;
    rdP = abs(dpnew-dp_prev) / 1e5;

    H(it).iter = it;
    H(it).Q = Qnew;
    H(it).Ps = Psnew;
    H(it).deltaP = dpnew;
    H(it).rQ = rQ;
    H(it).rPs = rPs;
    H(it).rdP = rdP;
    H(it).estado_nodal = det_nodal.estado;
    H(it).estado_eductor = eacept.estado;
    H(it).pot_disp = eacept.pot_disp;
    H(it).pot_trans = eacept.pot_trans;

    Q = Qnew;
    Ps_prev = Psnew;
    dp_prev = dpnew;
    e = eacept;

    if it >= p.jgl_min_iter && rQ < p.jgl_tol_Q_rel && ...
       rPs < p.jgl_tol_P_bar && rdP < p.jgl_tol_dP_bar
      estado = 'CONVERGIDO';
      H = H(1:it);
      break;
    end

    if it == p.jgl_max_iter
      H = H(1:it);
    end
  end

  if ~exist('e','var')
    e = jgl_eductor_estado_aplicado(p, Q, Qiny, Ps_prev, dp_prev, 'SALIDA_ITERATIVA');
  else
    e = jgl_eductor_estado_aplicado(p, Q, Qiny, Ps_prev, dp_prev, 'SALIDA_ITERATIVA');
  end

  sol = jgl_armar_solucion(p, Q, Qiny, e, 'ITERATIVO', estado);
  sol.historial = H;
  sol.iteraciones = length(H);
  sol.diagnostico = diagnostico_gl;
  sol.nodal = det_nodal_final;
  sol.error_directo_iterativo = NaN;
  sol.confianza = jgl_confianza(p, sol);
end
