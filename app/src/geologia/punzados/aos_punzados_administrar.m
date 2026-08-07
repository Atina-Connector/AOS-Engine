function [punzados, info] = aos_punzados_administrar(opciones)
% AOS_PUNZADOS_ADMINISTRAR Gestor transaccional de intervalos perforados.
% Permite crear, generar, agregar, editar, duplicar, eliminar,
% activar/desactivar, importar, exportar y validar punzados aun cuando no
% exista geologia ni Survey. El caso activo solo cambia al elegir Guardar.

  if nargin<1||~isstruct(opciones),opciones=struct();endif
  guardar_global=opcion_log_local(opciones,'guardar_global',true);
  origen=opcion_txt_local(opciones,'origen','PUNZADOS_MANUALES');
  [base,survey,origen_actual]=obtener_base_local(opciones);
  [base,avisos_base]=aos_punzados_normalizar(base,struct('origen',origen_actual));
  candidato=base;
  info=struct('guardado',false,'cancelado',false,'cambio',false, ...
    'origen',origen,'avisos',{avisos_base});
  sucio=false;

  while true
    imprimir_cabecera_local(candidato,survey,origen_actual,sucio);
    fprintf(' 1 - Ver tabla completa de punzados\n');
    fprintf(' 2 - Crear un conjunto nuevo desde cero\n');
    fprintf(' 3 - Agregar un intervalo\n');
    fprintf(' 4 - Editar un intervalo existente\n');
    fprintf(' 5 - Duplicar un intervalo\n');
    fprintf(' 6 - Activar / desactivar un intervalo\n');
    fprintf(' 7 - Eliminar un intervalo\n');
    fprintf(' 8 - Generar varios intervalos regulares\n');
    fprintf(' 9 - Ordenar y normalizar por profundidad\n');
    fprintf('10 - Importar / fusionar punzados desde .aosdat\n');
    fprintf('11 - Exportar el candidato a .aosdat\n');
    fprintf('12 - Validar contra MD / TVD y Survey activo\n');
    fprintf('13 - Guardar cambios en el caso activo\n');
    fprintf(' 0 - Cancelar y volver sin cambios\n');
    op=aos_leer_opcion('Seleccione [0-13]: ',0);

    switch op
      case 1
        imprimir_tabla_local(candidato,survey);
      case 2
        [nuevo,ok]=crear_conjunto_local(candidato);
        if ok,candidato=nuevo;sucio=true;endif
      case 3
        [t,ok]=crear_tramo_interactivo_local(candidato);
        if ok
          [candidato,~]=aos_punzados_operacion(candidato,'AGREGAR',t);
          sucio=true;
        endif
      case 4
        idx=seleccionar_indice_local(candidato,'Intervalo a editar',survey);
        if idx>0
          [t,ok]=editar_tramo_interactivo_local(candidato.tramos(idx));
          if ok
            [candidato,~]=aos_punzados_operacion(candidato,'EDITAR',idx,t);
            sucio=true;
          endif
        endif
      case 5
        idx=seleccionar_indice_local(candidato,'Intervalo a duplicar',survey);
        if idx>0
          [candidato,~]=aos_punzados_operacion(candidato,'DUPLICAR',idx);
          sucio=true;
        endif
      case 6
        idx=seleccionar_indice_local(candidato,'Intervalo a activar/desactivar',survey);
        if idx>0
          estado=~candidato.tramos(idx).activo;
          [candidato,~]=aos_punzados_operacion(candidato,'ACTIVAR',idx,estado);
          sucio=true;
          fprintf('%s queda %s.\n',candidato.tramos(idx).id,estado_local(estado));
        endif
      case 7
        idx=seleccionar_indice_local(candidato,'Intervalo a eliminar',survey);
        if idx>0
          t=candidato.tramos(idx);
          if aos_preguntar_sn(sprintf( ...
              'Eliminar %s (%.2f-%.2f m)? (s/n) [n]: ', ...
              t.id,t.MD_desde,t.MD_hasta),false)
            [candidato,~]=aos_punzados_operacion(candidato,'ELIMINAR',idx);
            sucio=true;
          endif
        endif
      case 8
        [generados,ok]=generar_regular_interactivo_local();
        if ok
          fprintf('Se generaron %d intervalos.\n',numel(generados.tramos));
          fprintf(' 1 - Reemplazar el candidato actual\n');
          fprintf(' 2 - Fusionar con el candidato actual\n');
          fprintf(' 0 - Cancelar\n');
          modo=aos_leer_opcion('Seleccione [0-2]: ',0);
          if modo==1
            candidato=generados;sucio=true;
          elseif modo==2
            [candidato,~]=aos_punzados_operacion(candidato,'FUSIONAR',generados);
            sucio=true;
          endif
        endif
      case 9
        [candidato,opinfo]=aos_punzados_operacion(candidato,'ORDENAR');
        info.avisos=[info.avisos,opinfo.avisos];
        sucio=true;
        fprintf('Intervalos ordenados y normalizados.\n');
      case 10
        [candidato,cambio_import]=importar_local(candidato);
        sucio=sucio||cambio_import;
      case 11
        exportar_local(candidato);
      case 12
        aos_punzados_validar(candidato,survey,true);
      case 13
        r=aos_punzados_validar(candidato,survey,true);
        if ~r.ok
          fprintf(2,'No se puede guardar: existen errores de validacion.\n');
          continue;
        endif
        if hay_avisos_confirmables_local(r.avisos)
          if ~aos_preguntar_sn('Hay avisos tecnicos. Guardar de todos modos? (s/n) [n]: ',false)
            continue;
          endif
        endif
        if guardar_global,aos_punzados_commit(candidato,origen);endif
        punzados=candidato;
        info.guardado=true;
        info.cambio=~isequal(base,candidato);
        info.avisos=[info.avisos,r.avisos];
        return;
      case 0
        if sucio&&~aos_preguntar_sn( ...
            'Descartar los cambios no guardados? (s/n) [n]: ',false)
          continue;
        endif
        punzados=base;info.cancelado=true;return;
      otherwise
        fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function [base,survey,origen]=obtener_base_local(opciones)
  base=struct('tramos',struct([]));survey=[];origen='NO_DISPONIBLE';
  if isfield(opciones,'punzados_base')
    base=opciones.punzados_base;
  else
    try
      [survey0,p0,info0]=aos_obtener_geometria_activa();
      survey=survey0;base=p0;
      if isfield(info0,'origen_punzados'),origen=info0.origen_punzados;endif
    catch
    end_try_catch
  endif
  if isfield(opciones,'survey'),survey=opciones.survey;endif
  if isfield(opciones,'origen_actual')
    origen=opcion_txt_local(opciones,'origen_actual',origen);
  endif
  if isempty(base),base=struct('tramos',struct([]));endif
endfunction

function imprimir_cabecera_local(p,survey,origen,sucio)
  r=aos_punzados_validar(p,survey,false);
  fprintf('\n--- ADMINISTRAR / GENERAR PUNZADOS ---\n');
  fprintf('Origen                  : %s\n',origen);
  fprintf('Survey                  : %s\n',survey_local(survey));
  fprintf('Tramos totales          : %d\n',r.n_tramos);
  fprintf('Tramos activos          : %d\n',r.n_activos);
  fprintf('Longitud activa         : %.2f m\n',r.longitud_total_m);
  fprintf('Tiros estimados         : %.0f\n',r.n_tiros_estimado);
  fprintf('Cambios sin guardar     : %s\n\n',si_no_local(sucio));
endfunction

function imprimir_tabla_local(p,survey)
  fprintf('\n--- TABLA EDITABLE DE PUNZADOS ---\n');
  if ~isstruct(p)||~isfield(p,'tramos')||isempty(p.tramos)
    fprintf('No hay intervalos cargados. Use las opciones 2, 3 u 8.\n');return;
  endif
  r=aos_punzados_validar(p,survey,false);
  fprintf(' N  ID             MD desde  MD hasta   TVD med. Long. tiros/m diam(mm) Act  Tiros  Formacion\n');
  for i=1:numel(p.tramos)
    t=p.tramos(i);fila=r.tabla(i);
    tvd=texto_num_local(fila.TVD_medio_m,'-');
    fprintf('%2d  %-13s %9.2f %9.2f %10s %5.2f %7.2f %8.2f %3s %6.0f  %s\n', ...
      i,cortar_local(t.id,13),t.MD_desde,t.MD_hasta,tvd, ...
      fila.longitud_m,t.densidad_tpm,1000*t.diametro_punzado_m, ...
      si_no_local(t.activo),fila.n_tiros_estimado,texto_corto_local(t.formacion,18));
  endfor
endfunction

function [nuevo,ok]=crear_conjunto_local(actual)
  nuevo=actual;ok=false;
  if ~isempty(actual.tramos)
    if ~aos_preguntar_sn( ...
        'Crear un conjunto nuevo descarta el candidato actual. Continuar? (s/n) [n]: ',false)
      return;
    endif
  endif
  nuevo=aos_punzados_normalizar(struct('tramos',struct([])));
  while true
    [t,agregar]=crear_tramo_interactivo_local(nuevo);
    if ~agregar
      if isempty(nuevo.tramos),return;else,break;endif
    endif
    [nuevo,~]=aos_punzados_operacion(nuevo,'AGREGAR',t);
    if ~aos_preguntar_sn('Agregar otro intervalo? (s/n) [n]: ',false),break;endif
  endwhile
  ok=~isempty(nuevo.tramos);
endfunction

function [t,ok]=crear_tramo_interactivo_local(p)
  idx=numel(p.tramos)+1;
  desde=0;
  if ~isempty(p.tramos),desde=max([p.tramos.MD_hasta]);endif
  t=tramo_default_local(idx,desde);
  fprintf('\n--- NUEVO INTERVALO DE PUNZADOS ---\n');
  [t,ok]=editar_tramo_interactivo_local(t);
  if ok
    mostrar_tramo_local(t);
    ok=aos_preguntar_sn('Agregar este intervalo? (s/n) [n]: ',false);
  endif
endfunction

function t=tramo_default_local(idx,desde)
  t=struct('id',sprintf('PUNZ-%03d',idx), ...
    'nombre',sprintf('Tramo %d',idx),'MD_desde',desde, ...
    'MD_hasta',desde+1,'densidad_tpm',10, ...
    'diametro_punzado_m',0.010,'activo',true,'fase_deg',NaN, ...
    'penetracion_m',NaN,'tipo_disparo','','formacion','', ...
    'permeabilidad_mD',NaN,'skin',NaN, ...
    'estado_validacion','NO_VALIDADO','observaciones','', ...
    'origen','MANUAL','extras',struct());
endfunction

function [t,ok]=editar_tramo_interactivo_local(t)
  [p0,~]=aos_punzados_normalizar(struct('tramos',t), ...
    struct('densidad_default_tpm',10));
  if ~isempty(p0.tramos),t=p0.tramos(1);endif
  ok=false;
  while true
    fprintf('\n--- EDITAR INTERVALO %s ---\n',t.id);
    mostrar_tramo_local(t);
    fprintf(' 1 - ID tecnico\n');
    fprintf(' 2 - Nombre / etiqueta\n');
    fprintf(' 3 - MD desde [m]\n');
    fprintf(' 4 - MD hasta [m]\n');
    fprintf(' 5 - Densidad [tiros/m]\n');
    fprintf(' 6 - Diametro de punzado [mm]\n');
    fprintf(' 7 - Estado activo / inactivo\n');
    fprintf(' 8 - Fase [grados] (opcional)\n');
    fprintf(' 9 - Penetracion [mm] (opcional)\n');
    fprintf('10 - Tipo de disparo / carga (opcional)\n');
    fprintf('11 - Formacion / zona (opcional)\n');
    fprintf('12 - Permeabilidad del tramo [mD] (opcional)\n');
    fprintf('13 - Skin del tramo (opcional)\n');
    fprintf('14 - Estado de validacion\n');
    fprintf('15 - Observaciones (opcional)\n');
    fprintf('16 - Campos adicionales\n');
    fprintf('17 - Terminar edicion\n');
    fprintf(' 0 - Cancelar edicion\n');
    op=aos_leer_opcion('Seleccione [0-17]: ',17);
    switch op
      case 1,t.id=leer_texto_local('ID tecnico',t.id,false);
      case 2,t.nombre=leer_texto_local('Nombre',t.nombre,false);
      case 3,t.MD_desde=leer_numero_local('MD desde [m]',t.MD_desde,false);
      case 4,t.MD_hasta=leer_numero_local('MD hasta [m]',t.MD_hasta,false);
      case 5,t.densidad_tpm=leer_numero_local( ...
          'Densidad [tiros/m]',t.densidad_tpm,false);
      case 6
        t.diametro_punzado_m=leer_numero_local( ...
          'Diametro [mm]',1000*t.diametro_punzado_m,false)/1000;
      case 7,t.activo=~t.activo;
      case 8,t.fase_deg=leer_numero_local('Fase [grados]',t.fase_deg,true);
      case 9
        mm=leer_numero_local('Penetracion [mm]', ...
          valor_mm_local(t.penetracion_m),true);
        if isfinite(mm),t.penetracion_m=mm/1000;else,t.penetracion_m=NaN;endif
      case 10,t.tipo_disparo=leer_texto_local( ...
          'Tipo de disparo',t.tipo_disparo,true);
      case 11,t.formacion=leer_texto_local( ...
          'Formacion / zona',t.formacion,true);
      case 12,t.permeabilidad_mD=leer_numero_local( ...
          'Permeabilidad [mD]',t.permeabilidad_mD,true);
      case 13,t.skin=leer_numero_local('Skin',t.skin,true);
      case 14,t.estado_validacion=leer_texto_local( ...
          'Estado de validacion',t.estado_validacion,false);
      case 15,t.observaciones=leer_texto_local( ...
          'Observaciones',t.observaciones,true);
      case 16,t.extras=editar_extras_local(t.extras);
      case 17
        [pn,avisos]=aos_punzados_normalizar(struct('tramos',t), ...
          struct('densidad_default_tpm',10));
        if isempty(pn.tramos)
          fprintf(2,'El intervalo no es valido: MD hasta debe ser mayor que MD desde.\n');
        else
          t=pn.tramos(1);
          if ~isempty(avisos)
            for ia=1:numel(avisos),fprintf('AVISO - %s\n',avisos{ia});endfor
          endif
          ok=true;return;
        endif
      case 0,return;
      otherwise,fprintf('Opcion no valida.\n');
    endswitch
  endwhile
endfunction

function extras=editar_extras_local(extras)
  if ~isstruct(extras),extras=struct();endif
  while true
    fn=fieldnames(extras);
    fprintf('\n--- CAMPOS ADICIONALES ---\n');
    if isempty(fn),fprintf('Sin campos adicionales.\n');
    else
      for i=1:numel(fn)
        [txt,~]=aos_texto_seguro(extras.(fn{i}),'[dato complejo]');
        fprintf('%2d - %s = %s\n',i,fn{i},txt);
      endfor
    endif
    fprintf(' 1 - Agregar o editar campo\n');
    fprintf(' 2 - Eliminar campo\n');
    fprintf(' 0 - Volver\n');
    op=aos_leer_opcion('Seleccione [0-2]: ',0);
    if op==0,return;
    elseif op==1
      nombre=strtrim(input('Nombre del campo: ','s'));
      if isempty(nombre),continue;endif
      nombre=aos_sanitizar_campo(nombre);
      valor=input('Valor (texto o numero): ','s');
      extras.(nombre)=aos_parse_valor(valor);
    elseif op==2
      if isempty(fn),continue;endif
      idx=aos_leer_opcion('Numero de campo a eliminar [0 cancela]: ',0);
      if idx>=1&&idx<=numel(fn),extras=rmfield(extras,fn{idx});endif
    endif
  endwhile
endfunction

function [p,ok]=generar_regular_interactivo_local()
  p=struct('tramos',struct([]));ok=false;
  fprintf('\n--- GENERAR INTERVALOS REGULARES ---\n');
  md1=leer_numero_local('MD inicial [m]',0,false);
  md2=leer_numero_local('MD final [m]',md1+10,false);
  n=leer_numero_local('Cantidad de intervalos',1,false);
  if n<1||abs(n-round(n))>1e-9
    fprintf(2,'La cantidad debe ser un entero positivo.\n');return;
  endif
  n=round(n);
  sep=leer_numero_local('Separacion entre intervalos [m]',0,false);
  disponible=md2-md1-(n-1)*sep;
  if disponible<=0
    fprintf(2,'El rango no permite esa cantidad y separacion.\n');return;
  endif
  longitud_def=disponible/n;
  longitud=leer_numero_local('Longitud de cada intervalo [m]',longitud_def,false);
  dens=leer_numero_local('Densidad [tiros/m]',10,false);
  diam_mm=leer_numero_local('Diametro de punzado [mm]',10,false);
  opts=struct('separacion_m',sep,'longitud_m',longitud, ...
    'densidad_tpm',dens,'diametro_punzado_m',diam_mm/1000, ...
    'origen','GENERACION_REGULAR');
  try
    p=aos_punzados_generar_regular(md1,md2,n,opts);
  catch err
    fprintf(2,'No se pudieron generar intervalos: %s\n',err.message);return;
  end_try_catch
  imprimir_tabla_local(p,[]);
  ok=aos_preguntar_sn('Aceptar estos intervalos? (s/n) [n]: ',false);
endfunction

function [candidato,cambio]=importar_local(candidato)
  cambio=false;
  ruta=strtrim(input('Ruta .aosdat (Enter abre selector): ','s'));
  try
    opts=struct('activar_caso',false,'imprimir_resumen',false,'normalizar',false);
    if isempty(ruta),cfg=importar_aosdat([],opts);else,cfg=importar_aosdat(ruta,opts);endif
  catch err
    fprintf(2,'No se pudo importar: %s\n',err.message);return;
  end_try_catch
  if isempty(cfg)||~isstruct(cfg),fprintf('Importacion cancelada.\n');return;endif
  nuevos=[];
  if isfield(cfg,'punzados'),nuevos=cfg.punzados;
  elseif isfield(cfg,'geologia')&&isstruct(cfg.geologia)&& ...
         isfield(cfg.geologia,'intervalos'),nuevos=cfg.geologia.intervalos;endif
  [nuevos,~]=aos_punzados_normalizar(nuevos, ...
    struct('origen','AOSDAT_IMPORTADO'));
  if isempty(nuevos.tramos)
    fprintf('El archivo no contiene punzados validos.\n');return;
  endif
  fprintf('Punzados importados: %d intervalo(s).\n',numel(nuevos.tramos));
  fprintf(' 1 - Reemplazar el candidato actual\n');
  fprintf(' 2 - Fusionar con el candidato actual\n');
  fprintf(' 0 - Cancelar\n');
  op=aos_leer_opcion('Seleccione [0-2]: ',0);
  if op==1
    [candidato,~]=aos_punzados_operacion(candidato,'REEMPLAZAR',nuevos);cambio=true;
  elseif op==2
    [candidato,~]=aos_punzados_operacion(candidato,'FUSIONAR',nuevos);cambio=true;
  endif
endfunction

function exportar_local(candidato)
  global CONFIG_ACTIVA;
  cfg=struct('nombre_pozo','PUNZADOS_MANUALES');
  if isstruct(CONFIG_ACTIVA)
    campos={'nombre_pozo','nombre','pozo','descripcion'};
    for i=1:numel(campos)
      if isfield(CONFIG_ACTIVA,campos{i}),cfg.(campos{i})=CONFIG_ACTIVA.(campos{i});endif
    endfor
  endif
  cfg.punzados=candidato;
  try
    exportar_aosdat(cfg,[],{'PUNZADOS'});
  catch err
    fprintf(2,'No se pudo exportar: %s\n',err.message);
  end_try_catch
endfunction

function idx=seleccionar_indice_local(p,titulo,survey)
  idx=0;
  if ~isstruct(p)||~isfield(p,'tramos')||isempty(p.tramos)
    fprintf('No hay intervalos disponibles.\n');return;
  endif
  imprimir_tabla_local(p,survey);
  idx=aos_leer_opcion(sprintf('%s [0 cancela]: ',titulo),0);
  if idx<1||idx>numel(p.tramos),idx=0;endif
endfunction

function mostrar_tramo_local(t)
  fprintf('ID                       : %s\n',t.id);
  fprintf('Nombre                   : %s\n',t.nombre);
  fprintf('MD desde / hasta         : %.3f / %.3f m\n',t.MD_desde,t.MD_hasta);
  fprintf('Longitud                 : %.3f m\n',t.MD_hasta-t.MD_desde);
  fprintf('Densidad                 : %.3f tiros/m\n',t.densidad_tpm);
  fprintf('Tiros estimados          : %.0f\n', ...
    (t.MD_hasta-t.MD_desde)*t.densidad_tpm);
  fprintf('Diametro                 : %.3f mm\n',1000*t.diametro_punzado_m);
  fprintf('Activo                   : %s\n',si_no_local(t.activo));
  fprintf('Fase                     : %s\n', ...
    num_texto_local(t.fase_deg,'NO INFORMADA',' deg'));
  fprintf('Penetracion              : %s\n', ...
    num_texto_local(valor_mm_local(t.penetracion_m),'NO INFORMADA',' mm'));
  fprintf('Tipo de disparo          : %s\n',texto_o_na_local(t.tipo_disparo));
  fprintf('Formacion / zona         : %s\n',texto_o_na_local(t.formacion));
  fprintf('Permeabilidad            : %s\n', ...
    num_texto_local(t.permeabilidad_mD,'NO INFORMADA',' mD'));
  fprintf('Skin                     : %s\n',num_texto_local(t.skin,'NO INFORMADO',''));
  fprintf('Estado de validacion     : %s\n',texto_o_na_local(t.estado_validacion));
  fprintf('Origen                   : %s\n',texto_o_na_local(t.origen));
  fprintf('Observaciones            : %s\n',texto_o_na_local(t.observaciones));
  if isstruct(t.extras)
    fprintf('Campos adicionales       : %d\n',numel(fieldnames(t.extras)));
  endif
endfunction

function v=leer_numero_local(etiqueta,actual,permitir_vacio)
  v=actual;
  if nargin<3,permitir_vacio=false;endif
  if isfinite(actual),def=sprintf('%.12g',actual);else,def='sin dato';endif
  while true
    txt=input(sprintf('%s [%s]: ',etiqueta,def),'s');
    if isempty(strtrim(txt)),return;endif
    if permitir_vacio&&any(strcmpi(strtrim(txt),{'na','ninguno','borrar','-'}))
      v=NaN;return;
    endif
    [x,ok]=aos_numero_seguro(txt,NaN);
    if ok&&isfinite(x),v=x;return;endif
    fprintf('Valor no valido. Ingrese un numero escalar.\n');
  endwhile
endfunction

function v=leer_texto_local(etiqueta,actual,permitir_vacio)
  if nargin<3,permitir_vacio=false;endif
  txt=input(sprintf('%s [%s]: ',etiqueta,texto_o_na_local(actual)),'s');
  if isempty(txt),v=actual;return;endif
  txt=strtrim(txt);
  if permitir_vacio&&any(strcmpi(txt,{'borrar','ninguno','-'})),v='';
  else,v=txt;endif
endfunction

function tf=hay_avisos_confirmables_local(avisos)
  tf=false;
  for i=1:numel(avisos)
    a=lower(avisos{i});
    if ~isempty(strfind(a,'survey no disponible')),continue;endif
    if ~isempty(strfind(a,'no hay intervalos')),continue;endif
    tf=true;return;
  endfor
endfunction

function s=survey_local(survey)
  if isempty(survey)||~isstruct(survey)||~isfield(survey,'MD')||isempty(survey.MD)
    s='NO CARGADO (edicion manual permitida)';
  else
    s=sprintf('%d puntos | MD %.2f a %.2f m', ...
      numel(survey.MD),min(survey.MD),max(survey.MD));
  endif
endfunction

function s=si_no_local(v),if v,s='SI';else,s='NO';endif,endfunction
function s=estado_local(v),if v,s='ACTIVO';else,s='INACTIVO';endif,endfunction
function s=texto_o_na_local(v)
  [s,ok]=aos_texto_seguro(v,'NO INFORMADO');
  if ~ok||isempty(s),s='NO INFORMADO';endif
endfunction
function s=num_texto_local(v,def,suf)
  if isfinite(v),s=[sprintf('%.6g',v) suf];else,s=def;endif
endfunction
function v=valor_mm_local(m),if isfinite(m),v=1000*m;else,v=NaN;endif,endfunction
function s=cortar_local(s,n)
  [s,~]=aos_texto_seguro(s,'');if numel(s)>n,s=s(1:n);endif
endfunction
function s=texto_corto_local(v,n)
  [s,ok]=aos_texto_seguro(v,'-');if ~ok||isempty(s),s='-';endif
  if numel(s)>n,s=s(1:n);endif
endfunction
function s=texto_num_local(v,def)
  if isfinite(v),s=sprintf('%.2f',v);else,s=def;endif
endfunction
function v=opcion_log_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_logico_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
function v=opcion_txt_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_texto_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
