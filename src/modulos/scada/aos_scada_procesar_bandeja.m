function resumen = aos_scada_procesar_bandeja(max_archivos)
% Procesa .aosdat de la bandeja SCADA usando el importador nativo unico.
% No interpreta fisica ni comandos. Los archivos codificados quedan pendientes.
  if nargin<1 || isempty(max_archivos),max_archivos=Inf;endif
  rutas=aos_scada_rutas();
  d=dir(fullfile(rutas.entrada,'*.aosdat'));
  [~,ix]=sort([d.datenum]); d=d(ix);
  resumen=struct('encontrados',numel(d),'procesados',0,'pendientes',0,'fallidos',0,'mensajes',{{}});
  if isempty(d)
    fprintf('Bandeja SCADA vacia: %s\n',rutas.entrada);
    return;
  endif
  limite=min(numel(d),max_archivos);
  for i=1:limite
    origen=fullfile(rutas.entrada,d(i).name);
    try
      if exist('aos_archivo_codificado','file')==2 && aos_archivo_codificado(origen)
        msg=sprintf('PENDIENTE CODIFICADO: %s',d(i).name);
        resumen.pendientes=resumen.pendientes+1;
        resumen.mensajes{end+1}=msg;
        fprintf('%s\n',msg);
        continue;
      endif
      importar_aosdat(origen);
      destino=destino_unico_local(rutas.procesados,d(i).name);
      [ok,m]=movefile(origen,destino);
      if ~ok,error('Importado, pero no se pudo archivar: %s',m);endif
      resumen.procesados=resumen.procesados+1;
      resumen.mensajes{end+1}=sprintf('OK: %s',d(i).name);
    catch err
      resumen.fallidos=resumen.fallidos+1;
      resumen.mensajes{end+1}=sprintf('ERROR %s: %s',d(i).name,err.message);
      destino=destino_unico_local(rutas.rechazados,d(i).name);
      try,movefile(origen,destino);catch,end_try_catch
      fprintf('ERROR SCADA %s: %s\n',d(i).name,err.message);
    end_try_catch
  endfor
  escribir_log_local(rutas.logs,resumen);
  fprintf('SCADA: encontrados=%d, procesados=%d, pendientes=%d, fallidos=%d\n', ...
          resumen.encontrados,resumen.procesados,resumen.pendientes,resumen.fallidos);
endfunction

function d=destino_unico_local(carpeta,nombre)
  [~,b,e]=fileparts(nombre);
  d=fullfile(carpeta,[datestr(now,'yyyymmdd_HHMMSS'),'_',b,e]);
  k=1;
  while exist(d,'file')==2
    d=fullfile(carpeta,sprintf('%s_%s_%d%s',datestr(now,'yyyymmdd_HHMMSS'),b,k,e));k=k+1;
  endwhile
endfunction

function escribir_log_local(carpeta,r)
  f=fullfile(carpeta,['scada_',datestr(now,'yyyymmdd'),'.log']);
  fid=fopen(f,'a');if fid<0,return;endif
  fprintf(fid,'\n[%s] encontrados=%d procesados=%d pendientes=%d fallidos=%d\n', ...
          datestr(now,'yyyy-mm-dd HH:MM:SS'),r.encontrados,r.procesados,r.pendientes,r.fallidos);
  for i=1:numel(r.mensajes),fprintf(fid,'%s\n',r.mensajes{i});endfor
  fclose(fid);
endfunction
