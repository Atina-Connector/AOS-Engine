function met = gibbs3_metrics(res)
% GIBBS3_METRICS Metricas mecanicas, volumetricas y de periodicidad.

  p=res.promedio;
  stroke_s=rango(p.u_superficie_m);
  stroke_rod=rango(p.u_varilla_fondo_m);
  stroke_rel=rango(p.u_piston_relativo_m);
  stroke_tub=rango(p.u_tuberia_fondo_m);
  Ap=res.bomba.area_piston_m2;
  qteo=Ap*stroke_rel*res.param.N_velocidad*1440;

  ppc=res.param.gibbs3_puntos_por_ciclo;
  ncy=res.param.gibbs3_n_ciclos;
  if ncy>=2
    i1=(ncy-2)*ppc+(1:ppc);
    i2=(ncy-1)*ppc+(1:ppc);
    a=res.F_superficie_N(i1);
    b=res.F_superficie_N(i2);
    escala=max(max(abs([a;b])),eps);
    periodicidad=max(abs(a-b))/escala;
  else
    periodicidad=NaN;
  end

  met=struct();
  met.carrera_superficie_m=stroke_s;
  met.carrera_varilla_fondo_m=stroke_rod;
  met.movimiento_tuberia_fondo_m=stroke_tub;
  met.carrera_piston_relativa_m=stroke_rel;
  met.carrera_bomba_m=stroke_rel; % compatibilidad
  met.transmision_varilla_fondo=stroke_rod/stroke_s;
  met.transmision_carrera=stroke_rel/stroke_s;
  met.perdida_carrera_tuberia_m=max(stroke_rod-stroke_rel,0);
  met.perdida_carrera_tuberia_pct=100*met.perdida_carrera_tuberia_m/max(stroke_rod,eps);
  met.elongacion_tuberia_max_m=res.tuberia.delta_max_m;
  met.area_metal_tuberia_m2=res.tuberia.area_metal_m2;
  if isfield(res.tuberia, 'rigidez_axial_N_m')
    met.rigidez_axial_tuberia_N_m=res.tuberia.rigidez_axial_N_m;
  else
    met.rigidez_axial_tuberia_N_m=NaN;
  endif
  met.desplazamiento_tuberia_fondo_min_m=min(p.u_tuberia_fondo_m);
  met.desplazamiento_tuberia_fondo_max_m=max(p.u_tuberia_fondo_m);
  if isfield(res.tuberia, 'convencion_signo')
    met.convencion_signo_tuberia=res.tuberia.convencion_signo;
  else
    met.convencion_signo_tuberia='NO_DECLARADA';
  endif
  met.carga_superficie_max_N=max(p.F_superficie_N);
  met.carga_superficie_min_N=min(p.F_superficie_N);
  met.carga_bomba_max_N=max(p.F_bomba_N);
  met.carga_bomba_min_N=min(p.F_bomba_N);
  met.caudal_teorico_bomba_m3_d=qteo;
  met.caudal_estimado_m3_d=qteo*res.bomba.llenado;
  met.lpp_activa=logical(res.param.bomba_lpp);
  met.lpp_deltaP_max_Pa=max(res.promedio.deltaP_LPP_Pa);
  met.lpp_carga_adicional_max_N=max(abs(res.promedio.F_LPP_N));
  met.lpp_velocidad_interna_max_m_s=max(abs(res.promedio.Q_LPP_m3_s)) / ...
    max(pi*(res.param.lpp_id_piston_mm/1000)^2/4,eps);
  if isfield(res.promedio,'aparato')
    met.velocidad_PR_max_m_s=max(abs(res.promedio.aparato.velocidad_m_s));
    met.aceleracion_PR_max_m_s2=max(abs(res.promedio.aparato.aceleracion_m_s2));
  else
    met.velocidad_PR_max_m_s=NaN;
    met.aceleracion_PR_max_m_s2=NaN;
  end
  met.error_periodicidad_rel=periodicidad;
  met.periodicidad_aprobada=isnan(periodicidad) || ...
    periodicidad<=res.param.gibbs3_tolerancia_periodicidad_rel;
end

function r=rango(x)
  r=max(x)-min(x);
end
