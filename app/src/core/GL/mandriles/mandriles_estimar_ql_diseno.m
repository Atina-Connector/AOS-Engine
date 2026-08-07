function [Ql_m3d, fuente, detalle] = mandriles_estimar_ql_diseno(param, Qiny_Sm3d, nivel)
% Obtiene un caudal liquido para el perfil de unloading sin usar la ultima
% corrida global. Trabaja solo con una copia de la configuracion recibida.
  p = mandriles_defaults(param);
  detalle = struct('estado','NO_CALCULADO','mensaje','');

  [ok,Ql_m3d,fuente] = campo_local(p, ...
      {'mand_Ql_diseno_m3d','GL_diseno_Ql_m3_d','Ql_m3_d','Ql_reportado_m3d'});
  if ok && Ql_m3d >= 0
    detalle.estado='CONFIGURADO';
    return;
  endif

  try
    tmp = p;
    qiny_m3s = max(Qiny_Sm3d,0)/86400;
    [Ql,det] = aos_resolver_gl(tmp,qiny_m3s);
    if isfinite(Ql) && Ql > 0
      Ql_m3d = Ql*86400;
      fuente = 'SOLVER_GL_CONFIGURACION_ACTIVA';
      detalle.estado='OK';
      detalle.solver=det;
      return;
    endif
  catch err
    detalle.mensaje=err.message;
  end_try_catch

  if isstruct(nivel) && isfield(nivel,'Ql_natural_m3d') && ...
      isfinite(nivel.Ql_natural_m3d) && nivel.Ql_natural_m3d > 0
    Ql_m3d=nivel.Ql_natural_m3d;
    fuente='FLUJO_NATURAL_QINY_0';
    detalle.estado='RESPALDO_NATURAL';
    return;
  endif

  Ql_m3d=0;
  fuente='NO_DISPONIBLE';
  detalle.estado='SIN_CAUDAL_LIQUIDO';
endfunction

function [ok,v,fuente]=campo_local(s,nombres)
  ok=false;
  v=NaN;
  fuente='';
  for i=1:numel(nombres)
    n=nombres{i};
    if isfield(s,n)
      x=s.(n);
      if isnumeric(x) && ~isempty(x) && isfinite(x(1))
        v=x(1);
        fuente=['AOSDAT_' upper(n)];
        ok=true;
        return;
      endif
    endif
  endfor
endfunction
