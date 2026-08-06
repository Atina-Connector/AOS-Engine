function sens_imprimir_diagnostico_polinomio(nombre, O)
% SENS_IMPRIMIR_DIAGNOSTICO_POLINOMIO Resumen visible y auditable.
  fprintf('\n--- ARMONIZACION POLINOMICA %s ---\n', upper(nombre));
  if ~isstruct(O) || ~isfield(O,'tratamiento_curva')
    fprintf('Estado: NO_CONFIGURADO\n');
    return;
  endif
  T = O.tratamiento_curva;
  fprintf('Modo                       : %s\n', texto_local(T,'modo','NO_INFORMADO'));
  fprintf('Ejecucion oculta           : NO\n');
  if ~isfield(T,'habilitado') || ~T.habilitado
    fprintf('Polyfit ejecutado          : NO\n');
    return;
  endif
  fprintf('Grado solicitado           : %s\n', grado_texto_local(T));
  if isfield(O,'ajuste_polinomico') && isstruct(O.ajuste_polinomico)
    nombres = {'Ql','Qo','Rendimiento'};
    campos = {'ql','qo','rendimiento'};
    for i=1:numel(campos)
      if ~isfield(O.ajuste_polinomico,campos{i}), continue; endif
      A=O.ajuste_polinomico.(campos{i});
      if ~isstruct(A), continue; endif
      fprintf('%-27s: estado=%s | grado=%s | R2=%s | RMSE=%s\n', ...
        nombres{i},texto_local(A,'estado','NO_EVALUADO'),num_texto_local(A,'grado_efectivo','N/A'), ...
        num_texto_local(A,'r2','N/A'),num_texto_local(A,'rmse','N/A'));
    endfor
  endif
  if isfield(O,'validacion_polinomica') && isstruct(O.validacion_polinomica)
    fprintf('Validacion conjunta         : %s\n',texto_local(O.validacion_polinomica,'estado','NO_EVALUADA'));
  endif
  if isfield(O,'candidato_verificacion') && isstruct(O.candidato_verificacion) && ...
      isfield(O.candidato_verificacion,'disponible') && O.candidato_verificacion.disponible
    fprintf('Candidato derivada cero     : %.0f Sm3/d\n',O.candidato_verificacion.qiny_sm3d);
  endif
  if isfield(O,'verificacion_polinomica') && isstruct(O.verificacion_polinomica)
    V=O.verificacion_polinomica;
    fprintf('Verificacion con solver     : %s\n',texto_local(V,'estado','NO_EVALUADA'));
    if isfield(V,'qiny_efectivo_sm3d') && isfinite(V.qiny_efectivo_sm3d)
      fprintf('Qiny fisico verificado      : %.0f Sm3/d\n',V.qiny_efectivo_sm3d);
      fprintf('Qo estimado / solver        : %.3f / %.3f m3/d\n',V.qo_estimado_m3d,V.qo_solver_m3d);
    endif
  endif
endfunction

function s=grado_texto_local(T)
  s='N/A';if ~isstruct(T)||~isfield(T,'grado_solicitado'),return;endif
  g=T.grado_solicitado;if isnumeric(g)&&isscalar(g)&&isfinite(g),if g==0,s='AUTOMATICO';else,s=sprintf('%d',round(g));endif;endif
endfunction
function s=num_texto_local(A,c,d),s=d;if isstruct(A)&&isfield(A,c)&&isnumeric(A.(c))&&~isempty(A.(c))&&isfinite(A.(c)(1)),s=sprintf('%.6g',A.(c)(1));endif,endfunction
function t=texto_local(s,c,d),t=d;if isstruct(s)&&isfield(s,c)&&ischar(s.(c))&&~isempty(s.(c)),t=s.(c);endif,endfunction
