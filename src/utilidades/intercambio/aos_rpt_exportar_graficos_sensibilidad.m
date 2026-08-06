function auditoria = aos_rpt_exportar_graficos_sensibilidad(fid, paquete, param, sistema, archivo)
% Exporta todas las figuras registradas por la sensibilidad, en orden.
% No supone una cantidad fija ni deduplica por titulos ambiguos.

  carpeta=fileparts(archivo);if isempty(carpeta),carpeta='.';endif
  graficos=struct('id',{},'titulo',{},'seccion',{},'estado',{},'base64',{});
  fallas={}; ids_reg={}; ids_ok={};

  registros=struct([]);
  if exist('aos_registro_graficos','file')==2
    try, registros=aos_registro_graficos('list'); catch, registros=struct([]); end_try_catch
  endif

  % Compatibilidad: si el script legado no registro figuras, se inspeccionan
  % las figuras abiertas que coincidan con la variable independiente.
  if isempty(registros)
    x=[];if isstruct(paquete)&&isfield(paquete,'columnas')&&~isempty(paquete.columnas),x=paquete.columnas{1};endif
    registros=registro_fallback_local(x);
  endif

  for i=1:numel(registros)
    id=limpiar_id_local(registros(i).id);ids_reg{end+1}=id;
    titulo=registros(i).titulo;seccion=registros(i).seccion;
    tmp=[tempname(carpeta) '.png'];estado='NO_DISPONIBLE';
    if handle_valido_local(registros(i).handle)
      try
        print(registros(i).handle,'-dpng','-r150',tmp);
        estado='OK';ids_ok{end+1}=id;
      catch err
        estado=['ERROR_' limpiar_estado_local(err.message)];
        fallas{end+1}=sprintf('%s:%s',id,estado);
      end_try_catch
    else
      estado='ERROR_HANDLE_CERRADO';fallas{end+1}=sprintf('%s:%s',id,estado);
    endif
    graficos(end+1)=entrada_local(id,titulo,seccion,estado,tmp);
    borrar_local(tmp);
  endfor
  n_sens_ok=numel(ids_ok);

  % Contexto geometrico adicional, sin alterar el conteo de figuras propias.
  [tmp,estado]=aos_generar_imagen_survey(param,sistema,carpeta);
  graficos(end+1)=entrada_local('survey','Survey del pozo','SURVEY',estado,tmp);borrar_local(tmp);
  [tmp,estado]=aos_generar_imagen_punzados(param,sistema,carpeta);
  graficos(end+1)=entrada_local('punzados','Geometria de punzados','PUNZADOS',estado,tmp);borrar_local(tmp);
  if isstruct(param)&&isfield(param,'diagnostico_tuberia')
    [tmp,estado]=aos_generar_imagen_tuberia(param,sistema,[],[],carpeta);
    graficos(end+1)=entrada_local('taitel_tuberia','Diagnostico Taitel, Turner y erosion','DIAGNOSTICO_TUBERIA',estado,tmp);borrar_local(tmp);
  endif

  n_total_ok=aos_rpt_escribir_graficos(fid,graficos);
  auditoria=struct('schema','AOS_GRAPH_EXPORT_AUDIT_1_0', ...
    'n_generados',numel(registros),'n_registrados',numel(registros), ...
    'n_sensibilidad_exportados',n_sens_ok, ...
    'n_sensibilidad_fallidos',numel(registros)-n_sens_ok, ...
    'n_total_enriquecido',n_total_ok,'ids_registrados',{ids_reg}, ...
    'ids_exportados',{ids_ok},'fallas',{fallas});
  escribir_auditoria_local(fid,auditoria);
endfunction

function registros=registro_fallback_local(x)
  registros=struct('handle',{},'id',{},'titulo',{},'seccion',{},'orden',{},'contexto',{},'estado_registro',{},'fecha_num',{});
  figs=findall(0,'type','figure');orden=0;
  for i=numel(figs):-1:1
    if ~isempty(x)&&~figura_coincide_local(figs(i),x),continue;endif
    orden=orden+1;titulo=titulo_fig_local(figs(i));
    id=sprintf('fallback_%02d_%s',orden,limpiar_id_local(titulo));
    registros(end+1)=struct('handle',figs(i),'id',id,'titulo',titulo, ...
      'seccion','SENSIBILIDAD','orden',orden,'contexto','FALLBACK', ...
      'estado_registro','FALLBACK_FINDALL','fecha_num',now());
  endfor
endfunction

function escribir_auditoria_local(fid,a)
  fprintf(fid,'\n[GRAPHICS_AUDIT]\n');
  fprintf(fid,'schema=%s\n',a.schema);
  fprintf(fid,'figuras_generadas=%d\n',a.n_generados);
  fprintf(fid,'figuras_registradas=%d\n',a.n_registrados);
  fprintf(fid,'figuras_sensibilidad_exportadas=%d\n',a.n_sensibilidad_exportados);
  fprintf(fid,'figuras_sensibilidad_fallidas=%d\n',a.n_sensibilidad_fallidos);
  fprintf(fid,'figuras_totales_enriquecido=%d\n',a.n_total_enriquecido);
  fprintf(fid,'ids_registrados=%s\n',strjoin(a.ids_registrados,'|'));
  fprintf(fid,'ids_exportados=%s\n',strjoin(a.ids_exportados,'|'));
  if isempty(a.fallas),fprintf(fid,'fallas=NINGUNA\n');else,fprintf(fid,'fallas=%s\n',strjoin(a.fallas,'|'));endif
endfunction

function tf=figura_coincide_local(fig,x)
  tf=false;if isempty(x),tf=true;return;endif
  try
    lineas=findall(fig,'type','line');
    for k=1:numel(lineas)
      xd=get(lineas(k),'XData');
      if isnumeric(xd)&&numel(xd)==numel(x)
        a=double(xd(:));b=double(x(:));ok=isfinite(a)&isfinite(b);
        if any(ok)
          den=max(1,max(abs(b(ok))));
          if max(abs(a(ok)-b(ok)))/den<1e-6,tf=true;return;endif
        endif
      endif
    endfor
  catch,tf=false;end_try_catch
endfunction

function titulo=titulo_fig_local(fig)
  titulo='Grafico de sensibilidad';
  try
    axes_list=findall(fig,'type','axes');c={};
    for k=1:numel(axes_list)
      h=get(axes_list(k),'title');s=get(h,'string');
      if ischar(s)&&~isempty(strtrim(s)),c{end+1}=strtrim(s);endif
    endfor
    if ~isempty(c),titulo=strjoin(fliplr(c),' / ');endif
  catch
  end_try_catch
endfunction

function g=entrada_local(id,titulo,seccion,estado,ruta)
  g=struct('id',id,'titulo',titulo,'seccion',seccion,'estado',estado,'base64','');
  if ischar(ruta)&&~isempty(ruta)&&exist(ruta,'file')==2&&strcmpi(estado,'OK')
    g.base64=base64_local(ruta);if isempty(g.base64),g.estado='ERROR_BASE64';endif
  endif
endfunction
function s=base64_local(ruta)
  s='';fid=fopen(ruta,'rb');if fid<0,return;endif
  bytes=fread(fid,Inf,'uint8=>uint8');fclose(fid);
  try,s=base64_encode(bytes);catch,s='';end_try_catch
endfunction
function borrar_local(ruta)
  if ischar(ruta)&&~isempty(ruta)&&exist(ruta,'file')==2
    delete(ruta);
  endif
endfunction
function tf=handle_valido_local(h)
  tf=false;
  try
    tf=ishandle(h)&&strcmpi(get(h,'type'),'figure');
  catch
    tf=false;
  end_try_catch
endfunction
function s=limpiar_id_local(txt)
  if ~ischar(txt),txt='grafico';endif
  s=lower(regexprep(txt,'[^A-Za-z0-9]+','_'));
  s=regexprep(s,'^_+|_+$','');
  if isempty(s),s='grafico';endif
endfunction
function s=limpiar_estado_local(txt)
  if ~ischar(txt),txt='DESCONOCIDO';endif
  s=regexprep(txt,'[^A-Za-z0-9]+','_');
endfunction
