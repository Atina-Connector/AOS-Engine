function R=aos_comparar_gas_fondo()
  [p,~]=aos_config_base('GENERAL');pc=cgf_defaults(p);pe=egf_defaults(p);
  [Qmax,pwf,~]=aos_gas_ipr(p);Qnat=0;
  % Flujo natural: raíz Pwf disponible vs presión requerida en superficie.
  q=linspace(max(Qmax*1e-4,1/86400),Qmax,121);r=NaN(size(q));
  for i=1:numel(q)
    Pwf_i=pwf(q(i));[Preq,~]=aos_gas_profile(p.P_wh,q(i),0,p.D_res,p.diam_tbg,p,'OPPOSE');r(i)=Pwf_i-Preq;
  endfor
  for i=1:numel(q)-1
    if r(i)*r(i+1)<=0,Qnat=interp1([r(i) r(i+1)],[q(i) q(i+1)],0);break;endif
  endfor
  sc=cgf_solver(pc);se=egf_solver(pe);
  fprintf('\n=== COMPARACION PRODUCCION DE GAS ===\n');
  fprintf('Alternativa | Gas producido/aspirado (Sm3/d) | Energia/consumo | Estado\n');
  fprintf('Natural     | %14.0f                | n/a             | REFERENCIA\n',Qnat*86400);
  fprintf('CGF         | %14.0f                | %8.2f kW     | %s\n',sc.Qg_Sm3_d,getpk_local(sc),sc.estado);
  fprintf('EGF         | %14.0f                | Qm=%8.0f    | %s\n',se.Qg_aspirado_Sm3_d,se.Qg_motriz_Sm3_d,se.estado);
  R=struct('Qnatural_Sm3_d',Qnat*86400,'CGF',sc,'EGF',se);
endfunction
function v=getpk_local(s),v=NaN;if isfield(s,'electrico'),v=s.electrico.P_superficie_kW;endif,endfunction
