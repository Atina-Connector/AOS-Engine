function R = bes3_comparar_v1_v2_v3(param)
  p=bes3_defaults(param);v1=struct('Ql_m3_d',NaN,'Pintake_bar',NaN,'estado','ERROR');
  try,[q1,~,~,pi1]=BES_sim(p);v1.Ql_m3_d=q1*86400;v1.Pintake_bar=pi1/1e5;v1.estado='OK';catch err,v1.estado=['ERROR_' regexprep(err.message,'[^A-Za-z0-9]+','_')];end_try_catch
  try,v2=bes2_solver(p);catch err,v2=struct('Ql_m3_d',NaN,'estado',['ERROR_' regexprep(err.message,'[^A-Za-z0-9]+','_')]);end_try_catch
  try,v3=bes3_solver(p);catch err,v3=struct('Ql_m3_d',NaN,'estado',['ERROR_' regexprep(err.message,'[^A-Za-z0-9]+','_')]);end_try_catch
  fprintf('\n=== COMPARACION BES1 / BES2 / BES3 ===\nMotor | Ql(m3/d) | Pintake(bar) | Qrec(m3/d) | Estado\n');
  fprintf('BES1  | %9.2f | %12.2f | %10s | %s\n',v1.Ql_m3_d,v1.Pintake_bar,'-',v1.estado);
  pi2=NaN;if isfield(v2,'punto'),pi2=v2.punto.Pintake_Pa/1e5;endif
  fprintf('BES2  | %9.2f | %12.2f | %10s | %s\n',v2.Ql_m3_d,pi2,'-',v2.estado);
  pi3=NaN;qr3=NaN;if isfield(v3,'punto'),pi3=v3.punto.Pintake_Pa/1e5;qr3=v3.Q_recirc_m3_d;endif
  fprintf('BES3  | %9.2f | %12.2f | %10.2f | %s\n',v3.Ql_m3_d,pi3,qr3,v3.estado);
  R=struct('BES1',v1,'BES2',v2,'BES3',v3);
endfunction
