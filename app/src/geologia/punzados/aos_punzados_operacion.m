function [salida, info] = aos_punzados_operacion(entrada, accion, varargin)
% AOS_PUNZADOS_OPERACION API programatica CRUD para intervalos.
% Acciones:
%   AGREGAR, EDITAR, ELIMINAR, DUPLICAR, ACTIVAR,
%   REEMPLAZAR, FUSIONAR, LIMPIAR y ORDENAR.

  [salida, avisos] = aos_punzados_normalizar(entrada);
  info = struct('ok',true,'accion','','indice',NaN,'avisos',{avisos});
  [accion, okacc] = aos_texto_seguro(accion,'');
  if ~okacc, error('AOS Punzados: accion invalida.'); endif
  accion = upper(strtrim(accion));
  info.accion = accion;

  switch accion
    case 'AGREGAR'
      if isempty(varargin) || ~isstruct(varargin{1})
        error('AGREGAR requiere un tramo struct.');
      endif
      [p, av] = aos_punzados_normalizar(struct('tramos',varargin{1}), ...
        struct('densidad_default_tpm',10));
      info.avisos = [info.avisos,av];
      if isempty(p.tramos), error('El tramo a agregar no es valido.'); endif
      if isempty(salida.tramos), salida.tramos = p.tramos(1);
      else, salida.tramos(end+1) = p.tramos(1); endif
      [salida, av2] = aos_punzados_normalizar(salida);
      info.avisos = [info.avisos,av2];
      info.indice = localizar_id_local(salida,p.tramos(1).id);

    case 'EDITAR'
      [idx, cambios] = argumentos_editar_local(varargin);
      validar_indice_local(salida,idx);
      combinado = salida.tramos(idx);
      combinado = aplicar_cambios_local(combinado, cambios);
      [uno, av0] = aos_punzados_normalizar(struct('tramos',combinado));
      info.avisos = [info.avisos,av0];
      if isempty(uno.tramos), error('Los cambios dejan un intervalo invalido.'); endif
      combinado = uno.tramos(1);
      tmp = salida.tramos;
      tmp(idx) = combinado;
      id_objetivo = combinado.id;
      salida.tramos = tmp;
      [salida, av] = aos_punzados_normalizar(salida);
      info.avisos = [info.avisos,av];
      info.indice = localizar_id_local(salida,id_objetivo);

    case 'ELIMINAR'
      idx = argumento_indice_local(varargin);
      validar_indice_local(salida,idx);
      salida.tramos(idx) = [];
      [salida, av] = aos_punzados_normalizar(salida);
      info.avisos = [info.avisos,av];
      info.indice = idx;

    case 'DUPLICAR'
      idx = argumento_indice_local(varargin);
      validar_indice_local(salida,idx);
      t = salida.tramos(idx);
      t.id = [t.id '_COPIA'];
      t.nombre = [t.nombre ' (copia)'];
      t.estado_validacion = 'NO_VALIDADO';
      if isempty(salida.tramos), salida.tramos=t;
      else, salida.tramos(end+1)=t; endif
      [salida,av]=aos_punzados_normalizar(salida);
      info.avisos=[info.avisos,av];
      info.indice=localizar_id_local(salida,t.id);

    case 'ACTIVAR'
      if numel(varargin)<2, error('ACTIVAR requiere indice y estado.'); endif
      idx=varargin{1}; estado=varargin{2};
      validar_indice_local(salida,idx);
      [estado,ok]=aos_logico_seguro(estado,true);
      if ~ok, error('Estado activo invalido.'); endif
      salida.tramos(idx).activo=logical(estado);
      info.indice=idx;
      [salida, av] = aos_punzados_normalizar(salida);
      info.avisos=[info.avisos,av];

    case 'REEMPLAZAR'
      if isempty(varargin), error('REEMPLAZAR requiere nuevos punzados.'); endif
      [salida,av]=aos_punzados_normalizar(varargin{1});
      info.avisos=[info.avisos,av];

    case 'FUSIONAR'
      if isempty(varargin), error('FUSIONAR requiere nuevos punzados.'); endif
      [nuevo,av]=aos_punzados_normalizar(varargin{1});
      info.avisos=[info.avisos,av];
      todos=salida.tramos;
      for i=1:numel(nuevo.tramos)
        if isempty(todos), todos=nuevo.tramos(i);
        else, todos(end+1)=nuevo.tramos(i); endif
      endfor
      todos=eliminar_duplicados_exactos_local(todos);
      salida.tramos=todos;
      [salida,av2]=aos_punzados_normalizar(salida);
      info.avisos=[info.avisos,av2];

    case 'LIMPIAR'
      salida.tramos=struct([]);
      salida = aos_punzados_normalizar(salida);

    case 'ORDENAR'
      [salida,av]=aos_punzados_normalizar(salida);
      info.avisos=[info.avisos,av];

    otherwise
      error('AOS Punzados: accion no reconocida: %s',accion);
  endswitch
endfunction

function t=aplicar_cambios_local(t,cambios)
% Aplica cambios sin romper la forma homogenea del struct array. Los campos
% no canonicos se preservan en extras en lugar de agregarse a un solo tramo.
  canonicos={'id','nombre','MD_desde','MD_hasta','densidad_tpm', ...
    'diametro_punzado_m','activo','fase_deg','penetracion_m', ...
    'tipo_disparo','formacion','permeabilidad_mD','skin', ...
    'estado_validacion','observaciones','origen'};
  if ~isfield(t,'extras')||~isstruct(t.extras),t.extras=struct();endif
  fn=fieldnames(cambios);
  for i=1:numel(fn)
    c=fn{i};
    if strcmp(c,'extras')&&isstruct(cambios.extras)
      fe=fieldnames(cambios.extras);
      for j=1:numel(fe)
        t.extras.(aos_sanitizar_campo(fe{j}))=cambios.extras.(fe{j});
      endfor
    elseif any(strcmp(c,canonicos))
      t.(c)=cambios.(c);
    else
      t.extras.(aos_sanitizar_campo(c))=cambios.(c);
    endif
  endfor
endfunction

function [idx,cambios]=argumentos_editar_local(args)
  if numel(args)<2, error('EDITAR requiere indice y cambios struct.'); endif
  idx=args{1}; cambios=args{2};
  if ~isstruct(cambios), error('Los cambios deben ser struct.'); endif
endfunction

function idx=argumento_indice_local(args)
  if isempty(args), error('La operacion requiere un indice.'); endif
  idx=args{1};
endfunction

function validar_indice_local(p,idx)
  if ~isnumeric(idx)||~isscalar(idx)||~isfinite(idx)||idx<1|| ...
     idx>numel(p.tramos)||idx~=round(idx)
    error('Indice de punzado fuera de rango.');
  endif
endfunction

function idx=localizar_id_local(p,id)
  idx=NaN;
  if ~isstruct(p)||~isfield(p,'tramos')||isempty(p.tramos),return;endif
  ids={p.tramos.id};
  j=find(strcmpi(ids,id),1,'last');
  if ~isempty(j),idx=j;else,idx=numel(p.tramos);endif
endfunction

function out=eliminar_duplicados_exactos_local(in)
  out=struct([]);
  for i=1:numel(in)
    duplicado=false;
    for j=1:numel(out)
      if isequaln(in(i),out(j)),duplicado=true;break;endif
    endfor
    if ~duplicado
      if isempty(out),out=in(i);else,out(end+1)=in(i);endif
    endif
  endfor
endfunction
