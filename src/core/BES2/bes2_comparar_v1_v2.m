function R=bes2_comparar_v1_v2(param)
  p=bes2_defaults(param);v1=struct('Ql_m3_d',NaN,'Qo_m3_d',NaN,'Pintake_bar',NaN,'estado','ERROR');
  try
    [q1,o1,~,pi1]=BES_sim(p);v1.Ql_m3_d=q1*86400;v1.Qo_m3_d=o1*86400;v1.Pintake_bar=pi1/1e5;v1.estado='OK';
  catch err
    v1.estado=['ERROR_' regexprep(err.message,'[^A-Za-z0-9]+','_')];
  end_try_catch
  v2=bes2_solver(p);
  fprintf('\n=== COMPARACION BES V1 vs BES V2 ===\n');
  fprintf('Motor | Ql(m3/d) | Qo(m3/d) | Pintake(bar) | Estado\n');
  fprintf('V1    | %9.2f | %9.2f | %12.2f | %s\n',v1.Ql_m3_d,v1.Qo_m3_d,v1.Pintake_bar,v1.estado);
  pi2=NaN;if isfield(v2,'punto'),pi2=v2.punto.Pintake_Pa/1e5;endif
  fprintf('V2    | %9.2f | %9.2f | %12.2f | %s\n',v2.Ql_m3_d,v2.Qo_m3_d,pi2,v2.estado);
  R=struct('V1',v1,'V2',v2);
endfunction
