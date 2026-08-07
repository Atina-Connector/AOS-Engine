function salida = aos_registro_graficos(accion, varargin)
% AOS_REGISTRO_GRAFICOS Registro explicito y ordenado de figuras AOS.
% Evita depender de findall(), del titulo de los axes o de una cantidad fija.
%
% Uso:
%   aos_registro_graficos('reset', contexto)
%   entrada = aos_registro_graficos('add', fig, id, titulo, seccion, contexto)
%   lista = aos_registro_graficos('list', contexto)
%   auditoria = aos_registro_graficos('audit', contexto)
%   aos_registro_graficos('clear')

  global AOS_REGISTRO_GRAFICOS;
  if isempty(AOS_REGISTRO_GRAFICOS) || ~isstruct(AOS_REGISTRO_GRAFICOS)
    AOS_REGISTRO_GRAFICOS = base_local();
  endif
  if nargin < 1 || isempty(accion), accion = 'list'; endif
  accion = lower(strtrim(accion));
  salida = [];

  switch accion
    case 'reset'
      contexto = arg_txt_local(varargin,1,'GENERAL');
      AOS_REGISTRO_GRAFICOS = base_local();
      AOS_REGISTRO_GRAFICOS.contexto = contexto;
      AOS_REGISTRO_GRAFICOS.iniciado = now();
      salida = AOS_REGISTRO_GRAFICOS;

    case 'add'
      if numel(varargin) < 1, error('Falta handle de figura.'); endif
      fig = varargin{1};
      id = arg_txt_local(varargin,2,'grafico');
      titulo = arg_txt_local(varargin,3,id);
      seccion = arg_txt_local(varargin,4,'SENSIBILIDAD');
      contexto = arg_txt_local(varargin,5,AOS_REGISTRO_GRAFICOS.contexto);
      if isempty(contexto), contexto='GENERAL'; endif
      if ~strcmp(AOS_REGISTRO_GRAFICOS.contexto,contexto)
        AOS_REGISTRO_GRAFICOS = base_local();
        AOS_REGISTRO_GRAFICOS.contexto = contexto;
        AOS_REGISTRO_GRAFICOS.iniciado = now();
      endif
      id = id_unico_local(id,AOS_REGISTRO_GRAFICOS.entradas);
      n = numel(AOS_REGISTRO_GRAFICOS.entradas)+1;
      e = struct('handle',fig,'id',id,'titulo',titulo,'seccion',seccion, ...
        'orden',n,'contexto',contexto,'estado_registro','REGISTRADO', ...
        'fecha_num',now());
      AOS_REGISTRO_GRAFICOS.entradas(end+1)=e;
      salida=e;

    case 'list'
      contexto = arg_txt_local(varargin,1,'');
      lista=AOS_REGISTRO_GRAFICOS.entradas;
      if ~isempty(contexto)
        keep=false(1,numel(lista));
        for i=1:numel(lista), keep(i)=strcmp(lista(i).contexto,contexto); endfor
        lista=lista(keep);
      endif
      salida=lista;

    case 'audit'
      contexto = arg_txt_local(varargin,1,'');
      lista=aos_registro_graficos('list',contexto);
      ids=cell(1,numel(lista)); vivos=false(1,numel(lista));
      for i=1:numel(lista)
        ids{i}=lista(i).id;
        vivos(i)=handle_valido_local(lista(i).handle);
      endfor
      salida=struct('contexto',AOS_REGISTRO_GRAFICOS.contexto, ...
        'n_registrados',numel(lista),'n_handles_validos',sum(vivos), ...
        'n_handles_invalidos',sum(~vivos),'ids',{ids},'handles_validos',vivos);

    case 'clear'
      AOS_REGISTRO_GRAFICOS=base_local();
      salida=AOS_REGISTRO_GRAFICOS;

    otherwise
      error('Accion de registro de graficos no reconocida: %s',accion);
  endswitch
endfunction

function r=base_local()
  vacio=struct('handle',{},'id',{},'titulo',{},'seccion',{},'orden',{}, ...
    'contexto',{},'estado_registro',{},'fecha_num',{});
  r=struct('schema','AOS_GRAPH_REGISTRY_1_0','contexto','', ...
    'iniciado',NaN,'entradas',vacio);
endfunction

function s=arg_txt_local(args,idx,def)
  s=def;
  if numel(args)>=idx && ischar(args{idx}) && ~isempty(strtrim(args{idx}))
    s=strtrim(args{idx});
  endif
endfunction

function id=id_unico_local(id,entradas)
  id=limpiar_id_local(id);
  base=id;k=2;
  existentes=cell(1,numel(entradas));
  for i=1:numel(entradas), existentes{i}=entradas(i).id; endfor
  while any(strcmp(existentes,id))
    id=sprintf('%s_%02d',base,k);k=k+1;
  endwhile
endfunction

function s=limpiar_id_local(txt)
  if ~ischar(txt),txt='grafico';endif
  s=lower(regexprep(txt,'[^A-Za-z0-9]+','_'));
  s=regexprep(s,'^_+|_+$','');
  if isempty(s),s='grafico';endif
endfunction

function tf=handle_valido_local(h)
  tf=false;
  try, tf=ishandle(h) && strcmpi(get(h,'type'),'figure'); catch, tf=false; end_try_catch
endfunction
