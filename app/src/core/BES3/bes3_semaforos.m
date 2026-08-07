function S = bes3_semaforos(sol)
  S=struct('id',{},'estado',{},'mensaje',{});S(end+1)=item_local('VALIDACION','AMARILLO','BES3 en desarrollo; resultado no certificado.');
  apagada=isfield(sol,'modo_operacion')&&strcmp(sol.modo_operacion,'BOMBA_APAGADA');
  if apagada
    if sol.convergido,c='VERDE';msg='Punto de flujo natural productivo convergido.';
    elseif strcmp(sol.estado,'POZO_SIN_FLUJO_NATURAL'),c='AMARILLO';msg='El punto Q=0 no se clasifica como flujo natural productivo.';
    elseif strcmp(sol.estado,'FLUJO_NATURAL_LIMITADO_POR_IPR'),c='AMARILLO';msg='Flujo natural limitado por el dominio de la IPR.';
    else,c='ROJO';msg=['Flujo natural sin cruce: ' sol.estado];endif
    S(end+1)=item_local('BALANCE_NODAL',c,msg);S(end+1)=item_local('FRECUENCIA','VERDE','Bomba apagada intencionalmente: 0 Hz.');
    S(end+1)=item_local('CURVA','VERDE','Curva de bomba no aplicada a 0 Hz.');S(end+1)=item_local('RECIRCULACION_DISENO','VERDE','No aplica con bomba apagada.');
    S(end+1)=item_local('GAS','VERDE','No aplica diagnostico de gas en bomba detenida.');S(end+1)=item_local('REFRIGERACION','VERDE','Motor sin carga; capilar inactivo.');
    S(end+1)=item_local('ELECTRICO_TERMICO','VERDE','Potencia y corriente iguales a cero.');return;
  endif
  if sol.convergido,c='VERDE';msg='Cruce nodal convergido.';elseif ~isempty(strfind(sol.estado,'EXCESO_CAPACIDAD')),c='AMARILLO';msg=sprintf('Sin cruce nodal: exceso de capacidad o limite del dominio. Margen %.2f bar.',sol.margen_nodal_bar);else,c='ROJO';msg=sprintf('Sin cruce nodal: %s. Margen %.2f bar.',sol.estado,sol.margen_nodal_bar);endif
  S(end+1)=item_local('BALANCE_NODAL',c,msg);
  if strcmp(sol.frecuencia_estado,'DENTRO_RANGO_OPERATIVO'),c='VERDE';elseif strcmp(sol.frecuencia_estado,'DEBAJO_MIN_OPERATIVA')||strcmp(sol.frecuencia_estado,'SOBRE_MAX_OPERATIVA'),c='AMARILLO';else,c='ROJO';endif
  S(end+1)=item_local('FRECUENCIA',c,sol.frecuencia_estado);
  d=sol.diagnostico_recirculacion;
  if strcmp(d.estado_secciones,'AMBAS_SECCIONES_DENTRO_RANGO'),c='VERDE';elseif strcmp(d.estado_secciones,'UNA_SECCION_FUERA_RANGO'),c='AMARILLO';else,c='ROJO';endif
  S(end+1)=item_local('SECCIONES_BOMBA',c,sprintf('%s | BEP inferior %.1f %% | BEP superior %.1f %%',d.estado_secciones,d.BEP_inferior_pct,d.BEP_superior_pct));
  if strcmp(d.estado_diseno,'RECIRCULACION_DENTRO_LIMITE')||strcmp(d.estado_diseno,'SIN_RECIRCULACION'),c='VERDE';
  elseif strcmp(d.estado_diseno,'Q_NOMINAL_NO_DISPONIBLE'),c='AMARILLO';else,c='ROJO';endif
  S(end+1)=item_local('RECIRCULACION_DISENO',c,sprintf('%s | Qrec %.2f %% de Qnom | limite %.2f %%',d.estado_diseno,d.Q_recirc_pct_nominal,d.limite_recirc_pct_nominal));
  if strcmp(d.estado_operativo,'RECIRCULACION_INTERNA_SIN_PRODUCCION')||strcmp(d.estado_operativo,'SIN_PRODUCCION_NETA'),c='ROJO';
  elseif strcmp(d.estado_operativo,'RECIRCULACION_MAYOR_QUE_PRODUCCION'),c='AMARILLO';else,c='VERDE';endif
  S(end+1)=item_local('PRODUCTIVIDAD_NETA',c,d.estado_operativo);
  S(end+1)=item_local('GAS',color_local(strcmp(sol.gas_estado,'GAS_ADMISIBLE'),~strcmp(sol.gas_estado,'RIESGO_GAS_LOCK')),sol.gas_estado);
  req=sol.recirculacion.Q_requerido_m3_s>0;if ~req,c='VERDE';elseif sol.recirculacion.cumple,c='VERDE';else,c='ROJO';endif
  S(end+1)=item_local('REFRIGERACION',c,sol.recirculacion.estado);
  if strcmp(sol.geometria.posicion_estado,'CONJUNTO_TOTALMENTE_DEBAJO_PUNZADOS'),if sol.recirculacion.cumple,c='AMARILLO';else,c='ROJO';endif
  elseif strcmp(sol.geometria.posicion_estado,'PUNZADOS_NO_DISPONIBLES'),c='AMARILLO';else,c='VERDE';endif
  S(end+1)=item_local('POSICION_PUNZADOS',c,sol.geometria.posicion_estado);
  if strcmp(sol.electrico.estado,'OK'),c='VERDE';elseif strcmp(sol.electrico.estado,'MARGEN_TERMICO_BAJO'),c='AMARILLO';else,c='ROJO';endif
  S(end+1)=item_local('ELECTRICO_TERMICO',c,sol.electrico.estado);
endfunction
function x=item_local(id,estado,mensaje),x=struct('id',id,'estado',estado,'mensaje',mensaje);endfunction
function c=color_local(ok,yellow),if ok,c='VERDE';elseif yellow,c='AMARILLO';else,c='ROJO';endif,endfunction
