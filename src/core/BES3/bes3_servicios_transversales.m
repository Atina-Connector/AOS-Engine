function sol = bes3_servicios_transversales(sol,mostrar)
% Integra servicios comunes heredados de BES1 sin alterar el solver BES3.
% Incluye diagnostico de tuberia y semaforos globales AOS.
  if nargin<2||isempty(mostrar),mostrar=true;endif
  if ~isstruct(sol)||~isfield(sol,'punto')||~isfield(sol,'param'),return;endif
  p=sol.param;Ql=sol.Ql_m3_d/86400;Qo=sol.Qo_m3_d/86400;
  sol.diagnostico_tuberia=struct();sol.semaforos_globales=struct([]);
  try
    opt=struct();opt.Qgas_total_std=sol.Qg_total_Sm3_d/86400;
    if isfield(p,'D_bomba'),opt.D_inyeccion=p.D_bomba;endif
    opt.detalle=mostrar;opt.mostrar_tabla=false;opt.graficar=mostrar;
    diag=diagnostico_tuberia_produccion(p,'BES3',Ql,0,opt);
    sol.diagnostico_tuberia=diag;p.diagnostico_tuberia=diag;
  catch err
    sol.diagnostico_tuberia=struct('estado','NO_DISPONIBLE','mensaje',err.message);
    if mostrar,fprintf('No se pudo generar diagnostico comun de tuberia BES3: %s\n',err.message);endif
  end_try_catch
  try
    ext=struct();ext.P_intake=sol.punto.Pintake_Pa;
    ext.T_motor=sol.punto.electrico.termica.T_motor_C;
    ext.temperatura_motor=ext.T_motor;
    ext.diagnostico_tuberia=sol.diagnostico_tuberia;
    sem=aos_semaforo_operacion('BES',p,Ql,Qo,0,ext);
    sol.semaforos_globales=sem;
    if mostrar,aos_imprimir_semaforos(sem,'BES3 / SEMAFOROS GLOBALES AOS');endif
  catch err
    if mostrar,fprintf('No se pudo generar semaforo global BES3: %s\n',err.message);endif
  end_try_catch
  sol.param=p;
endfunction
