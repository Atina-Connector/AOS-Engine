function O = sens_optimo_inyeccion(qiny_sm3d, rendimiento_pct, ql_m3d, qo_m3d, valido_optimo, econ, tratamiento, valido_curva)
% SENS_OPTIMO_INYECCION Analisis discreto o polinomico explicito de Qiny.
% SENS-GLJGL-02:
%   - sin tratamiento explicito, NO ejecuta polyfit;
%   - el modo informativo no cambia la recomendacion discreta;
%   - el modo verificado solo propone un maximo interior por derivada cero;
%     la recomendacion cambia despues de recalcularlo con el solver fisico.
%   - valido_curva y valido_optimo se conservan como contratos separados.

  if nargin < 5 || isempty(valido_optimo), valido_optimo = true(size(qiny_sm3d)); endif
  if nargin < 6 || ~isstruct(econ), econ = struct('habilitado',false); endif
  if nargin < 7 || ~isstruct(tratamiento), tratamiento = tratamiento_discreto_local(); endif
  if nargin < 8 || isempty(valido_curva), valido_curva = valido_optimo; endif

  x = double(qiny_sm3d(:)');
  r = double(rendimiento_pct(:)');
  ql = double(ql_m3d(:)');
  qo = double(qo_m3d(:)');
  valido_optimo = logical(valido_optimo(:)');
  valido_curva = logical(valido_curva(:)');

  O = base_local(tratamiento);
  O.economia = econ;
  O.qiny_sm3d = x;
  O.rendimiento_pct = r;
  O.ql_m3d = ql;
  O.qo_m3d = qo;
  O.valido_para_curva = valido_curva;
  O.valido_para_optimo = valido_optimo;

  if numel(x) ~= numel(r) || numel(x) ~= numel(ql) || numel(x) ~= numel(qo) || ...
      numel(x) ~= numel(valido_curva) || numel(x) ~= numel(valido_optimo)
    O.estado = 'DIMENSIONES_INCOMPATIBLES';
    O.advertencias{end+1} = 'Las series y mascaras deben tener igual longitud.';
    return;
  endif

  mask_curva = valido_curva & isfinite(x) & isfinite(ql) & isfinite(qo);
  if sum(mask_curva) < 3
    O.estado = 'DATOS_INSUFICIENTES';
    O.advertencias{end+1} = 'Se requieren al menos tres puntos validos para curva.';
    return;
  endif

  [xs, idx] = sort(x(mask_curva));
  rs = r(mask_curva); rs = rs(idx);
  qls = ql(mask_curva); qls = qls(idx);
  qos = qo(mask_curva); qos = qos(idx);
  [xs, iu] = unique(xs, 'stable');
  rs = rs(iu); qls = qls(iu); qos = qos(iu);
  if numel(xs) < 3
    O.estado = 'DATOS_INSUFICIENTES';
    O.advertencias{end+1} = 'La curva no contiene suficientes Qiny unicos.';
    return;
  endif

  O.puntos_validos = struct('qiny_sm3d',xs,'rendimiento_pct',rs, ...
    'ql_m3d',qls,'qo_m3d',qos);

  % Derivadas descriptivas de la curva publicada. No utilizan polyfit.
  dql_curva = derivada_discreta_local(xs, qls);
  dqo_curva = derivada_discreta_local(xs, qos);
  dr_curva = derivada_discreta_local(xs, rs);
  O.x_derivada_sm3d = xs;
  O.derivada_ql_m3d_por_Sm3d = dql_curva;
  O.derivada_qo_m3d_por_Sm3d = dqo_curva;
  O.derivada_rendimiento_pct_por_Sm3d = dr_curva;

  % La recomendacion discreta usa exclusivamente puntos habilitados para optimo.
  mask_opt = valido_optimo & mask_curva;
  xo=[]; ro=[]; qlo=[]; qoo=[];
  if any(mask_opt)
    [xo, io] = sort(x(mask_opt));
    ro = r(mask_opt); ro = ro(io);
    qlo = ql(mask_opt); qlo = qlo(io);
    qoo = qo(mask_opt); qoo = qoo(io);
    [xo, iuo] = unique(xo, 'stable');
    ro = ro(iuo); qlo = qlo(iuo); qoo = qoo(iuo);
  endif
  O.puntos_validos_optimo = struct('qiny_sm3d',xo,'rendimiento_pct',ro, ...
    'ql_m3d',qlo,'qo_m3d',qoo);

  if ~isempty(xo)
    O.max_produccion_liquida = maximo_discreto_local(xo, qlo);
    O.max_produccion_petroleo = maximo_discreto_local(xo, qoo);
    O.max_rendimiento = maximo_discreto_local(xo, ro);
  endif

  if numel(xo) >= 3
    dql_opt = derivada_discreta_local(xo, qlo);
    dr_opt = derivada_discreta_local(xo, ro);
    O.max_derivada_rendimiento = maximo_discreto_local(xo, dr_opt);
    O.cero_derivada_rendimiento = cero_derivada_local(xo, ro, dr_opt);

    qlmax = O.max_produccion_liquida.valor;
    i95 = find(isfinite(qlo) & qlo >= 0.95*qlmax, 1, 'first');
    if ~isempty(i95)
      O.qiny_95pct_produccion = punto_local(xo(i95), qlo(i95), 'PUNTO_DISCRETO');
    endif

    dmax = max_finito_local(dql_opt);
    imaxd = indice_max_finito_local(dql_opt);
    if isfinite(dmax) && dmax > 0 && isfinite(imaxd)
      ids = find((1:numel(xo)) > imaxd & isfinite(dql_opt) & ...
        dql_opt <= 0.25*dmax & qlo >= 0.85*qlmax,1,'first');
      if isempty(ids), ids = i95; endif
      if ~isempty(ids)
        O.rendimientos_decrecientes = punto_local(xo(ids), qlo(ids), 'DISCRETO');
        O.rendimientos_decrecientes.pendiente_m3d_por_Sm3d = dql_opt(ids);
      endif
    endif

    O.recomendado_discreto = recomendado_discreto_local(xo,ro,qlo,qoo,i95,O.max_rendimiento.valor);
    O.recomendado = O.recomendado_discreto;
    O.estado_recomendacion = 'OPTIMO_DISCRETO';
    O.economico = economia_discreta_local(xo,qoo,econ);
  else
    O.estado_recomendacion = 'OPTIMO_NO_DISPONIBLE_PUNTOS_VALIDOS_INSUFICIENTES';
    O.advertencias{end+1} = ['La curva puede representarse, pero hay menos de tres ' ...
      'puntos habilitados para optimizacion.'];
    O.economico = base_economia_local([]);
  endif

  T = normalizar_tratamiento_local(tratamiento);
  O.tratamiento_curva = T;
  if T.cancelado
    O.estado = 'CANCELADO';
    return;
  endif

  if T.usar_polinomio
    cfg = T;
    cfg.limite_inferior = 0;
    cfg.nombre = 'Ql';
    if isfield(T,'limite_ql_m3d') && isfinite(T.limite_ql_m3d)
      cfg.limite_superior = T.limite_ql_m3d;
    else
      cfg.limite_superior = Inf;
    endif
    Aql = sens_ajuste_polinomico(x, ql, mask_curva, cfg);

    cfg.nombre = 'Qo';
    % Qo no puede superar el mismo limite superior fisico impuesto a Ql.
    Aqo = sens_ajuste_polinomico(x, qo, mask_curva, cfg);

    cfg.nombre = 'Rendimiento';
    cfg.limite_inferior = -Inf;
    cfg.limite_superior = Inf;
    Ar = sens_ajuste_polinomico(x, r, valido_curva & isfinite(x) & isfinite(r), cfg);

    vcfg = struct();
    if isfield(T,'limite_ql_m3d'), vcfg.Ql_max_m3d = T.limite_ql_m3d; endif
    Vp = sens_validar_ajuste_polinomico(Aql,Aqo,Ar,vcfg);
    O.ajuste_polinomico = struct('ql',Aql,'qo',Aqo,'rendimiento',Ar);
    O.validacion_polinomica = Vp;

    if Aql.apto_informativo
      O.x_ajuste_sm3d = Aql.x_grid;
      O.ql_ajustada_m3d = Aql.y_grid;
      O.ql_polinomio_en_puntos_m3d = Aql.y_en_puntos_originales;
      O.max_produccion_liquida_polinomica = Aql.maximo_global;
      O.cero_derivada_produccion_liquida = Aql.maximo_interior;
      O.derivada_ql_polinomica_m3d_por_Sm3d = Aql.derivada_grid;
    endif
    if Aqo.apto_informativo
      O.qo_ajustada_m3d = Aqo.y_grid;
      O.qo_polinomio_en_puntos_m3d = Aqo.y_en_puntos_originales;
      O.max_produccion_petroleo_polinomica = Aqo.maximo_global;
      O.cero_derivada_produccion_petroleo = Aqo.maximo_interior;
      O.derivada_qo_polinomica_m3d_por_Sm3d = Aqo.derivada_grid;
    endif
    if Ar.apto_informativo
      O.rendimiento_ajustado_pct = Ar.y_grid;
      O.derivada_rendimiento_polinomica_pct_por_Sm3d = Ar.derivada_grid;
      O.max_rendimiento_polinomico = Ar.maximo_global;
      O.cero_derivada_rendimiento_polinomico = Ar.maximo_interior;
      % La vista de derivada usa el polinomio solo porque fue elegido de modo
      % visible por el usuario; la derivada discreta se conserva por separado.
      O.x_derivada_sm3d = Ar.x_grid;
      O.derivada_rendimiento_pct_por_Sm3d = Ar.derivada_grid;
    elseif Aql.apto_informativo
      O.x_derivada_sm3d = Aql.x_grid;
    endif

    if isfield(Aqo,'grado_efectivo'), O.grado_ajuste = Aqo.grado_efectivo; endif
    O.economico_polinomico = economia_polinomica_local(Aqo,econ,qos(1));

    if Aqo.apto_informativo && isfinite(Aqo.maximo_interior.qiny_sm3d)
      qstar = Aqo.maximo_interior.qiny_sm3d;
      qlstar = NaN;
      if Aql.apto_informativo && qstar >= Aql.dominio_min && qstar <= Aql.dominio_max
        qlstar = polyval(Aql.coeficientes_normalizados,(qstar-Aql.x_centro)/Aql.x_escala);
      endif
      O.recomendado_polinomico_estimado = struct('qiny_sm3d',qstar, ...
        'ql_m3d',qlstar,'qo_m3d',Aqo.maximo_interior.valor, ...
        'rendimiento_pct',NaN,'criterio','MAXIMO_QO_POLINOMICO_DERIVADA_CERO_ESTIMADO');
    endif

    if T.usar_para_recomendacion && numel(xo) >= 3 && ...
        Vp.apto_para_optimizacion && isfinite(Aqo.maximo_interior.qiny_sm3d)
      O.candidato_verificacion = struct('disponible',true, ...
        'qiny_sm3d',Aqo.maximo_interior.qiny_sm3d, ...
        'qo_estimado_m3d',Aqo.maximo_interior.valor, ...
        'ql_estimado_m3d',O.recomendado_polinomico_estimado.ql_m3d, ...
        'criterio','DERIVADA_CERO_QO_GRADO_EXPLICITO');
      O.estado_recomendacion = 'OPTIMO_POLINOMICO_ESTIMADO_PENDIENTE_VERIFICACION';
    elseif T.usar_para_recomendacion
      O.advertencias{end+1} = 'El ajuste no produjo un maximo interior apto para verificacion.';
      if numel(xo) < 3
        O.estado_recomendacion = 'OPTIMO_NO_DISPONIBLE_PUNTOS_VALIDOS_INSUFICIENTES';
      else
        O.estado_recomendacion = 'OPTIMO_DISCRETO_POLINOMIO_NO_APTO';
      endif
    endif
  endif

  O.estado = 'OK';
endfunction

function T = tratamiento_discreto_local()
  T = struct('schema','AOS_CURVE_TREATMENT_1.0','hotfix','SENS-GLJGL-02', ...
    'modo','DISCRETO','habilitado',false,'usar_polinomio',false, ...
    'usar_para_recomendacion',false,'verificar_optimo',false, ...
    'grado_solicitado',NaN,'grado_maximo',5,'n_grid',201, ...
    'cancelado',false,'oculto',false,'extrapolacion',false);
endfunction

function T = normalizar_tratamiento_local(T)
  D = tratamiento_discreto_local();
  if ~isstruct(T), T=D; return; endif
  f=fieldnames(D);
  for i=1:numel(f), if ~isfield(T,f{i}), T.(f{i})=D.(f{i}); endif; endfor
  if ~ischar(T.modo), T.modo='DISCRETO'; endif
  T.habilitado = logico_local(T,'habilitado',~strcmpi(T.modo,'DISCRETO'));
  T.usar_polinomio = logico_local(T,'usar_polinomio',T.habilitado);
  T.usar_para_recomendacion = logico_local(T,'usar_para_recomendacion',strcmpi(T.modo,'POLINOMICO_VERIFICADO'));
  T.verificar_optimo = logico_local(T,'verificar_optimo',T.usar_para_recomendacion);
  T.cancelado = logico_local(T,'cancelado',false);
  T.oculto = false;
  T.extrapolacion = false;
endfunction

function d = derivada_discreta_local(x,y)
  d = NaN(size(y));
  n=numel(x);if n<2,return;endif
  for i=1:n
    if ~isfinite(y(i)),continue;endif
    if i==1,j1=1;j2=2;elseif i==n,j1=n-1;j2=n;else,j1=i-1;j2=i+1;endif
    dx=x(j2)-x(j1);
    if isfinite(y(j1))&&isfinite(y(j2))&&isfinite(dx)&&abs(dx)>eps
      d(i)=(y(j2)-y(j1))/dx;
    endif
  endfor
endfunction

function p = maximo_discreto_local(x,y)
  p=punto_vacio_local();ids=find(isfinite(x)&isfinite(y));if isempty(ids),return;endif
  [v,j]=max(y(ids));i=ids(j);p=punto_local(x(i),v,'MAXIMO_DISCRETO');
endfunction

function p = cero_derivada_local(x,y,d)
  p=punto_vacio_local();
  for i=1:numel(x)-1
    if isfinite(d(i))&&isfinite(d(i+1))&&d(i)>0&&d(i+1)<=0
      q=interp_cero_local(x(i),x(i+1),d(i),d(i+1));
      v=interp1(x,y,q,'linear');p=punto_local(q,v,'CERO_DERIVADA_DISCRETO_APROX');return;
    endif
  endfor
endfunction

function R = recomendado_discreto_local(x,r,ql,qo,i95,rmax)
  R=struct('qiny_sm3d',NaN,'ql_m3d',NaN,'qo_m3d',NaN, ...
    'rendimiento_pct',NaN,'criterio','NO_DISPONIBLE');
  if isempty(i95),[~,i95]=max(ql);endif
  rec=i95;
  if isfinite(rmax)
    cand=find(ql>=0.95*max(ql)&isfinite(r)&r>=0.85*rmax);
    if ~isempty(cand),rec=cand(1);endif
  endif
  if isempty(rec)||~isfinite(rec),return;endif
  R.qiny_sm3d=x(rec);R.ql_m3d=ql(rec);R.qo_m3d=qo(rec);
  if isfinite(r(rec)),R.rendimiento_pct=r(rec);endif
  R.criterio='OPTIMO_DISCRETO_MENOR_QINY_CON_95PCT_QMAX_Y_85PCT_REND_MAX';
endfunction

function E = economia_discreta_local(x,qo,econ)
  E=base_economia_local(x);
  if ~isstruct(econ)||~isfield(econ,'habilitado')||~econ.habilitado,return;endif
  E.habilitado=true;E.metodo='DISCRETO';
  E=leer_economia_local(E,econ);
  qoref=qo(1);dq=max(qo-qoref,0);ing=dq*E.valor_petroleo_por_m3;
  costo=x/1000*E.costo_gas_por_1000Sm3+E.costo_fijo_diario;neto=ing-costo;
  ret=NaN(size(x));m=costo>0;ret(m)=ing(m)./costo(m);
  E.qo_referencia_m3d=qoref;E.ingreso_incremental_dia=ing;E.costo_gas_dia=costo;
  E.resultado_neto_dia=neto;E.retorno_sobre_gas=ret;
  [E.max_neto.valor,j]=max(neto);E.max_neto.qiny_sm3d=x(j);E.max_neto.moneda_dia=E.moneda;
  dn=derivada_discreta_local(x,neto);z=cero_derivada_local(x,neto,dn);
  E.equilibrio_marginal.qiny_sm3d=z.qiny_sm3d;E.equilibrio_marginal.valor=z.valor;
endfunction

function E = economia_polinomica_local(Aqo,econ,qoref)
  E=base_economia_local([]);E.metodo='POLINOMICO_DERIVADO';
  if ~isstruct(econ)||~isfield(econ,'habilitado')||~econ.habilitado||~Aqo.apto_informativo,return;endif
  E.habilitado=true;E=leer_economia_local(E,econ);x=Aqo.x_grid;qo=Aqo.y_grid;
  dq=max(qo-qoref,0);ing=dq*E.valor_petroleo_por_m3;
  costo=x/1000*E.costo_gas_por_1000Sm3+E.costo_fijo_diario;neto=ing-costo;
  ret=NaN(size(x));m=costo>0;ret(m)=ing(m)./costo(m);
  E.qiny_sm3d=x;E.qo_referencia_m3d=qoref;E.ingreso_incremental_dia=ing;
  E.costo_gas_dia=costo;E.resultado_neto_dia=neto;E.retorno_sobre_gas=ret;
  [E.max_neto.valor,j]=max(neto);E.max_neto.qiny_sm3d=x(j);E.max_neto.moneda_dia=E.moneda;
  dn=derivada_discreta_local(x,neto);z=cero_derivada_local(x,neto,dn);
  E.equilibrio_marginal.qiny_sm3d=z.qiny_sm3d;E.equilibrio_marginal.valor=z.valor;
endfunction

function E=base_economia_local(x)
  E=struct('habilitado',false,'metodo','NO_EVALUADO','moneda','USD', ...
    'valor_petroleo_por_m3',0,'costo_gas_por_1000Sm3',0,'costo_fijo_diario',0, ...
    'qiny_sm3d',x,'ingreso_incremental_dia',NaN(size(x)), ...
    'costo_gas_dia',NaN(size(x)),'resultado_neto_dia',NaN(size(x)), ...
    'retorno_sobre_gas',NaN(size(x)),'qo_referencia_m3d',NaN, ...
    'max_neto',struct('qiny_sm3d',NaN,'valor',NaN), ...
    'equilibrio_marginal',struct('qiny_sm3d',NaN,'valor',NaN));
endfunction
function E=leer_economia_local(E,econ)
  if isfield(econ,'moneda'),E.moneda=econ.moneda;endif
  if isfield(econ,'valor_petroleo_por_m3'),E.valor_petroleo_por_m3=econ.valor_petroleo_por_m3;endif
  if isfield(econ,'costo_gas_por_1000Sm3'),E.costo_gas_por_1000Sm3=econ.costo_gas_por_1000Sm3;endif
  if isfield(econ,'costo_fijo_diario'),E.costo_fijo_diario=econ.costo_fijo_diario;endif
endfunction

function O=base_local(T)
  vacio=punto_vacio_local();
  O=struct('estado','NO_EVALUADO','estado_recomendacion','NO_EVALUADO', ...
    'advertencias',{{}},'tratamiento_curva',T,'grado_ajuste',NaN, ...
    'max_rendimiento',vacio,'max_derivada_rendimiento',vacio, ...
    'cero_derivada_rendimiento',vacio,'max_produccion_liquida',vacio, ...
    'max_produccion_petroleo',vacio,'qiny_95pct_produccion',vacio, ...
    'rendimientos_decrecientes',vacio,'recomendado_discreto',struct(), ...
    'recomendado',struct(),'recomendado_polinomico_estimado',struct(), ...
    'recomendado_polinomico_verificado',struct(), ...
    'candidato_verificacion',struct('disponible',false), ...
    'verificacion_polinomica',struct('estado','NO_SOLICITADA'), ...
    'ajuste_polinomico',struct(),'validacion_polinomica',struct(), ...
    'economico',struct('habilitado',false),'economico_polinomico',struct('habilitado',false), ...
    'x_ajuste_sm3d',[],'ql_ajustada_m3d',[],'qo_ajustada_m3d',[], ...
    'rendimiento_ajustado_pct',[],'x_derivada_sm3d',[], ...
    'derivada_ql_m3d_por_Sm3d',[],'derivada_qo_m3d_por_Sm3d',[], ...
    'derivada_rendimiento_pct_por_Sm3d',[], ...
    'ql_polinomio_en_puntos_m3d',[],'qo_polinomio_en_puntos_m3d',[]);
endfunction
function p=punto_vacio_local(),p=struct('qiny_sm3d',NaN,'valor',NaN,'tipo','NO_DISPONIBLE','interior',false);endfunction
function p=punto_local(q,v,t),p=struct('qiny_sm3d',q,'valor',v,'tipo',t,'interior',true);endfunction
function v=max_finito_local(x),y=x(isfinite(x));if isempty(y),v=NaN;else,v=max(y);endif,endfunction
function i=indice_max_finito_local(x),ids=find(isfinite(x));if isempty(ids),i=NaN;else,[~,j]=max(x(ids));i=ids(j);endif,endfunction
function z=interp_cero_local(x1,x2,y1,y2),if ~isfinite(y1)||~isfinite(y2)||abs(y2-y1)<eps,z=(x1+x2)/2;else,z=x1-y1*(x2-x1)/(y2-y1);endif,endfunction
function tf=logico_local(s,c,d),tf=d;if isstruct(s)&&isfield(s,c),x=s.(c);if islogical(x)&&~isempty(x),tf=x(1);elseif isnumeric(x)&&~isempty(x),tf=x(1)~=0;endif;endif,endfunction
