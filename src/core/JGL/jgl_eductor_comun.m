function e = jgl_eductor_comun(p,Ql,Qiny,Ps)
% Fisica comun JGL independiente del CFD.
% El CFD gas-gas queda fuera del runtime AOS y solo podra usarse en el futuro
% como referencia externa de calibracion.
%
% SENS-GLJGL-03: la condicion motriz se resuelve antes del eductor mediante
% jgl_condicion_motriz. Un Qiny forzado puede derivar explicitamente la
% presion minima requerida sin reemplazar el P_iny_sup importado.

  p = jgl_defaults(p);
  C = jgl_condicion_motriz(p,Qiny,Ps);
  e = struct('estado','OK','deltaP',0,'Ps',Ps,'Pd',Ps,'Pm',NaN, ...
             'Pm_requerida',C.P_motriz_fondo_requerida_Pa, ...
             'Piny_sup_requerida',C.P_iny_sup_requerida_Pa, ...
             'Piny_sup_disponible',C.P_iny_sup_disponible_Pa, ...
             'pot_disp',0,'pot_trans',0,'eta',0,'entrainment',NaN, ...
             'factibilidad_presion',C.factible_por_presion, ...
             'referencia_cfd','NO_USADA','condicion_motriz',C);
  e.Pm = C.P_motriz_fondo_efectiva_Pa;

  if Qiny <= 1e-12
    e.estado = 'SIN_GAS_MOTRIZ';
    e.detalle = struct('condicion_motriz',C,'origen_deltaP','sin_gas_motriz');
    return;
  end
  if C.bloquea_operacion
    e.estado = C.estado;
    e.detalle = struct('condicion_motriz',C,'origen_deltaP','condicion_motriz_bloqueada');
    return;
  end
  if ~isfinite(e.Pm) || e.Pm <= Ps
    e.estado = 'SIN_PRESION_MOTRIZ';
    e.detalle = struct('condicion_motriz',C,'origen_deltaP','presion_efectiva_no_valida');
    return;
  end

  rho_g_std = p.rho_g_std;
  mdot = max(Qiny,0) * max(rho_g_std,1e-12);
  [Pd,dp,det] = eductor_jgl(Ps,e.Pm,max(Ql,0),mdot,p,Ps,Qiny*86400/0.0283168/1e6);
  det.condicion_motriz = C;

  T = p.T_fondo;
  if T < 150, T = T + 273.15; end
  Qm_local = Qiny * (101325/max(e.Pm,1e5)) * (T/288.15);
  e.pot_disp = max((e.Pm-Ps) * Qm_local,0);
  dp_energia = e.pot_disp / max(Ql,1e-12);
  dp = max(min(dp,dp_energia),0);
  e.deltaP = dp;
  e.Pd = Ps + dp;
  e.pot_trans = dp * max(Ql,0);
  e.eta = e.pot_trans / max(e.pot_disp,1e-12);
  e.detalle = det;
  if Ql <= 1e-12
    e.estado = 'LIMITADO_POR_RESERVORIO';
  elseif dp <= 0
    e.estado = 'SIN_TRABAJO_TRANSFERIDO';
  elseif e.pot_trans > e.pot_disp*(1+1e-8)
    e.estado = 'RESULTADO_NO_FISICO';
  end
end
