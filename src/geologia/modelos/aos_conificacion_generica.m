function gen = aos_conificacion_generica(geol, Ql)
% Screening generico de conificacion cuando faltan datos de contacto/acuifero.
% Conserva trazabilidad y NO entrega un limite operativo vinculante.
  if nargin < 2 || isempty(Ql), Ql=0; end
  gen=struct();
  gen.tipo='ANALISIS_GENERICO_DE_REFERENCIA';
  gen.vinculante=false;
  kh=getn(geol,'permeabilidad_h',1e-15);
  kv=getn(geol,'permeabilidad_v',0.1*kh);
  drho=max(getn(geol,'rho_agua',1020)-getn(geol,'rho_petroleo',850),1);
  h=max(getn(geol,'espesor_zona_petrolera',20),0.1);
  hp=min(max(getn(geol,'altura_perforados',0.5*h),0),h*0.999);
  mu=max(getn(geol,'mu_petroleo',1.5e-3),1e-6);
  Bo=max(getn(geol,'B_o',1.05),0.1);
  re=max(getn(geol,'radio_drenaje',250),1);
  rw=max(getn(geol,'radio_pozo',0.108),0.01);
  den=2*mu*Bo*max(log(re/rw),0.1);
  qbase=pi*kh*drho*9.81*max(h^2-hp^2,0)/den;
  anis=sqrt(max(kh/max(kv,1e-30),1));
  qprob=qbase*min(max(anis,1),5);
  gen.Q_conservador_m3d=max(0.35*qprob*86400,0);
  gen.Q_probable_m3d=max(qprob*86400,0);
  gen.Q_favorable_m3d=max(3.0*qprob*86400,0);
  gen.Q_actual_m3d=Ql*86400;
  gen.datos_asumidos={'distancia al contacto agua-petroleo','geometria del acuifero','kv/kh efectivo','movilidades relativas','presion capilar'};
  gen.estudios_recomendados={'PLT','perfil de saturacion','build-up o interferencia','estimacion kv/kh','revision del contacto agua-petroleo','analisis de agua'};
  if gen.Q_actual_m3d > 10*max(gen.Q_favorable_m3d,1e-6)
      gen.estado='MODELO_CLASICO_NO_REPRESENTATIVO';
      gen.interpretacion='La operacion observada supera ampliamente el screening de matriz. Posible aporte por fracturas, capas comunicadas, canalizacion o agua ya establecida; no usar este valor como limite.';
  elseif gen.Q_actual_m3d > gen.Q_probable_m3d
      gen.estado='RIESGO_ORIENTATIVO_ALTO';
      gen.interpretacion='El caudal actual supera el escenario probable generico. Requiere datos adicionales antes de una decision operativa.';
  else
      gen.estado='RIESGO_ORIENTATIVO_MODERADO';
      gen.interpretacion='El caudal actual esta dentro del escenario probable generico, con incertidumbre alta.';
  end
end
function v=getn(s,c,d)
  v=d; if isstruct(s)&&isfield(s,c)&&isnumeric(s.(c))&&isscalar(s.(c))&&isfinite(s.(c)), v=s.(c); end
end
