function sens_imprimir_optimo_inyeccion(nombre,O)
% Imprime el analisis de optimizacion de Qiny en forma auditable.
% SENS-GLJGL-02 distingue siempre resultado discreto, polinomio estimado y
% verificacion fisica.
  fprintf('\n--- OPTIMIZACION DE INYECCION %s ---\n',nombre);
  if ~isstruct(O) || ~isfield(O,'estado') || ~strcmp(O.estado,'OK')
    fprintf('Estado: %s\n',campo_local(O,'estado','NO_EVALUADO'));
    return;
  endif

  modo='DISCRETO';
  if isfield(O,'tratamiento_curva')&&isstruct(O.tratamiento_curva)&&isfield(O.tratamiento_curva,'modo')
    modo=O.tratamiento_curva.modo;
  endif
  fprintf('Tratamiento de curva         : %s\n',modo);
  fprintf('Polinomio oculto             : NO\n');

  fprintf('\nResultado oficial discreto:\n');
  imprimir_local('Maximo indice energetico bruto',O.max_rendimiento,'%%');
  imprimir_local('Maxima derivada indice bruto',O.max_derivada_rendimiento,'%%/(Sm3/d)');
  imprimir_local('Cero derivada indice bruto',O.cero_derivada_rendimiento,'%%');
  imprimir_local('Maxima produccion liquida',O.max_produccion_liquida,'m3/d');
  imprimir_local('Maxima produccion petroleo',O.max_produccion_petroleo,'m3/d');
  imprimir_local('95 %% de produccion maxima',O.qiny_95pct_produccion,'m3/d');
  imprimir_local('Inicio rendimientos decrecientes',O.rendimientos_decrecientes,'m3/d');
  if isfield(O,'recomendado_discreto')
    imprimir_recomendado_local('Inyeccion discreta recomendada',O.recomendado_discreto);
  endif

  if isfield(O,'tratamiento_curva')&&isstruct(O.tratamiento_curva)&& ...
      isfield(O.tratamiento_curva,'habilitado')&&O.tratamiento_curva.habilitado
    sens_imprimir_diagnostico_polinomio(nombre,O);
    if isfield(O,'recomendado_polinomico_estimado')&&isstruct(O.recomendado_polinomico_estimado)&& ...
        isfield(O.recomendado_polinomico_estimado,'qiny_sm3d')&&isfinite(O.recomendado_polinomico_estimado.qiny_sm3d)
      imprimir_recomendado_local('Optimo polinomico estimado',O.recomendado_polinomico_estimado);
    endif
  endif

  if isfield(O,'recomendado')&&isstruct(O.recomendado)&&isfield(O.recomendado,'qiny_sm3d')
    fprintf('\nRecomendacion efectiva publicada:\n');
    imprimir_recomendado_local('Inyeccion recomendada',O.recomendado);
    fprintf('Estado recomendacion          : %s\n',campo_local(O,'estado_recomendacion','NO_EVALUADO'));
  endif

  if isfield(O,'economico')&&isstruct(O.economico)&&isfield(O.economico,'habilitado')&&O.economico.habilitado
    fprintf('\nResultado economico discreto (%s):\n',O.economico.moneda);
    fprintf('  Valor petroleo             : %.4g %s/m3\n',O.economico.valor_petroleo_por_m3,O.economico.moneda);
    fprintf('  Costo gas                  : %.4g %s/1000 Sm3\n',O.economico.costo_gas_por_1000Sm3,O.economico.moneda);
    fprintf('  Maximo resultado neto      : Qiny %.0f Sm3/d, %.2f %s/d\n', ...
      O.economico.max_neto.qiny_sm3d,O.economico.max_neto.valor,O.economico.moneda);
    if isfinite(O.economico.equilibrio_marginal.qiny_sm3d)
      fprintf('  Equilibrio marginal aprox. : Qiny %.0f Sm3/d\n',O.economico.equilibrio_marginal.qiny_sm3d);
    endif
  endif
  if isfield(O,'economico_polinomico')&&isstruct(O.economico_polinomico)&& ...
      isfield(O.economico_polinomico,'habilitado')&&O.economico_polinomico.habilitado
    fprintf('  Curva economica polinomica : DERIVADA / INFORMATIVA\n');
    fprintf('  Maximo neto estimado       : Qiny %.0f Sm3/d, %.2f %s/d\n', ...
      O.economico_polinomico.max_neto.qiny_sm3d,O.economico_polinomico.max_neto.valor,O.economico_polinomico.moneda);
  endif
endfunction

function imprimir_recomendado_local(etiqueta,R)
  if ~isstruct(R)||~isfield(R,'qiny_sm3d')||~isfinite(R.qiny_sm3d)
    fprintf('%-31s: N/A\n',etiqueta);return;
  endif
  fprintf('%-31s: %.0f Sm3/d\n',etiqueta,R.qiny_sm3d);
  if isfield(R,'ql_m3d')&&isfield(R,'qo_m3d')&&isfinite(R.ql_m3d)&&isfinite(R.qo_m3d)
    fprintf('  Ql / Qo                    : %.3f / %.3f m3/d\n',R.ql_m3d,R.qo_m3d);
  endif
  if isfield(R,'rendimiento_pct')&&isfinite(R.rendimiento_pct)
    fprintf('  Indice energetico bruto    : %.3f %%\n',R.rendimiento_pct);
  endif
  if isfield(R,'criterio'),fprintf('  Criterio                   : %s\n',R.criterio);endif
endfunction

function imprimir_local(etiqueta,s,unidad)
  if isstruct(s)&&isfield(s,'qiny_sm3d')&&isfinite(s.qiny_sm3d)
    v=NaN;if isfield(s,'valor'),v=s.valor;endif
    fprintf('%-31s: Qiny %.0f Sm3/d',etiqueta,s.qiny_sm3d);
    if isfinite(v),fprintf(', %.4g %s',v,unidad);endif
    fprintf('\n');
  else
    fprintf('%-31s: N/A\n',etiqueta);
  endif
endfunction
function v=campo_local(s,n,d),v=d;if isstruct(s)&&isfield(s,n),v=s.(n);endif,endfunction
