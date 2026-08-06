function ok = test_aos_punzados_crud_hf3()
% CRUD, generacion regular, metadatos y validacion sin Survey.
  ok=false; iniciar_aos(true);
  t1=struct('id','PZ-A','nombre','Arena A','MD_desde',1000, ...
    'MD_hasta',1005,'densidad_tpm',12,'diametro_punzado_m',0.010, ...
    'activo',true,'formacion','A','permeabilidad_mD',25,'skin',1.5, ...
    'origen','MANUAL','lote_cargas','L-77');
  [p,~]=aos_punzados_operacion(struct('tramos',struct([])),'AGREGAR',t1);
  assert(numel(p.tramos)==1);
  assert(strcmp(p.tramos(1).id,'PZ-A'));
  assert(isfield(p.tramos(1).extras,'lote_cargas'));

  cambios=struct('MD_hasta',1006,'densidad_tpm',15, ...
    'diametro_punzado_m',0.012,'observaciones','editado', ...
    'proveedor_cargas','AESIR');
  [p,~]=aos_punzados_operacion(p,'EDITAR',1,cambios);
  assert(abs(p.tramos(1).MD_hasta-1006)<1e-12);
  assert(abs(p.tramos(1).densidad_tpm-15)<1e-12);
  assert(strcmp(p.tramos(1).observaciones,'editado'));
  assert(isfield(p.tramos(1).extras,'proveedor_cargas'));
  assert(strcmp(p.tramos(1).extras.proveedor_cargas,'AESIR'));

  [p,~]=aos_punzados_operacion(p,'DUPLICAR',1);
  assert(numel(p.tramos)==2);
  [p,~]=aos_punzados_operacion(p,'ACTIVAR',2,false);
  assert(~p.tramos(2).activo);
  [p,~]=aos_punzados_operacion(p,'ELIMINAR',2);
  assert(numel(p.tramos)==1);

  reg=aos_punzados_generar_regular(1100,1120,3, ...
    struct('separacion_m',2,'longitud_m',4,'densidad_tpm',10, ...
    'diametro_punzado_m',0.009,'prefijo_id','REG'));
  assert(numel(reg.tramos)==3);
  assert(abs(reg.tramos(2).MD_desde-1106)<1e-12);
  [p,~]=aos_punzados_operacion(p,'FUSIONAR',reg);
  assert(numel(p.tramos)==4);

  r=aos_punzados_validar(p,[],false);
  assert(r.ok);
  assert(r.n_tramos==4 && r.n_activos==4);
  assert(any(~cellfun('isempty',strfind(r.avisos,'Survey no disponible'))));
  ok=true;
  fprintf('RESULTADO: test_aos_punzados_crud_hf3 APROBADO\n');
endfunction
