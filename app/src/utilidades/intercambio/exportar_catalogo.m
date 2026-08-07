function [nombre_archivo, info] = exportar_catalogo(tipo, datos, nombre_archivo)
% EXPORTAR_CATALOGO Exporta catalogos .aosdat con contrato simetrico R2.
  interactivo=(nargin<3||isempty(nombre_archivo));
  if nargin<1||isempty(tipo)
    fprintf('Tipos disponibles: bombas, valvulas, varillas, unidades_bm\n');
    tipo=input('Seleccione tipo de catalogo: ','s');
  endif
  [tipo_txt,tipo_ok]=aos_texto_seguro(tipo,'');
  if ~tipo_ok,error('Tipo de catalogo invalido o no textual.');endif
  tipo=lower(strtrim(tipo_txt));
  tipos={'bombas','valvulas','varillas','unidades_bm'};
  if ~any(strcmp(tipo,tipos)),error('Tipo no valido. Use: bombas, valvulas, varillas, unidades_bm');endif
  if nargin<2||~isstruct(datos),error('Los datos del catalogo deben ser un struct o struct array.');endif

  root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
  carpeta=fullfile(root,'intercambio','catalogos','enviados',tipo);
  if exist(carpeta,'dir')~=7,mkdir(carpeta);endif
  if interactivo
    nombre_archivo=fullfile(carpeta,['catalogo_' tipo '.aosdat']);
    fprintf('Nombre propuesto: %s\n',nombre_archivo);
    if aos_preguntar_sn('Cambiar el nombre propuesto? (s/n) [n]: ', false)
      nuevo=strtrim(input('Nuevo nombre sin extension: ','s'));
      if ~isempty(nuevo),nombre_archivo=fullfile(carpeta,[nuevo '.aosdat']);endif
    endif
  else
    [p,n,e]=fileparts(nombre_archivo);if isempty(e),e='.aosdat';endif
    if isempty(p),p=carpeta;endif
    if exist(p,'dir')~=7,mkdir(p);endif
    nombre_archivo=fullfile(p,[n e]);
  endif

  fid=fopen(nombre_archivo,'w');if fid==-1,error('No se pudo crear %s',nombre_archivo);endif
  unwind_protect
    fprintf(fid,'[AOS_DATA]\n');
    fprintf(fid,'version=0.1.9-R2-catalogo\n');
    fprintf(fid,'fecha=%s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid,'nombre=CATALOGO_%s\n',upper(tipo));
    fprintf(fid,'secciones=AOS_CATALOGO,%s\n\n',upper(tipo));
    fprintf(fid,'[AOS_CATALOGO]\n');
    fprintf(fid,'contract=AOS_CATALOGO_R2\n');
    fprintf(fid,'tipo=%s\n',tipo);
    fprintf(fid,'cantidad=%d\n',numel(datos));
    fprintf(fid,'fuente=AOS_SUITE\n\n');
    fprintf(fid,'[%s]\n',upper(tipo));
    escribir_datos_local(fid,tipo,datos);
  unwind_protect_cleanup
    fclose(fid);
  end_unwind_protect

  codificado=false;
  if exist('aos_finalizar_archivo_crypto','file')==2
    [codificado,~]=aos_finalizar_archivo_crypto(nombre_archivo,interactivo);
  endif
  d=dir(nombre_archivo);
  info=struct('ok',true,'tipo',tipo,'archivo',nombre_archivo,'cantidad',numel(datos), ...
    'bytes',d.bytes,'codificado',logical(codificado),'contract','AOS_CATALOGO_R2');
  fprintf('Catalogo exportado: %s\n',nombre_archivo);
  fprintf('   Tipo      : %s\n',tipo);
  fprintf('   Elementos : %d\n',numel(datos));
  fprintf('   Proteccion: %s\n',si_no_local(codificado));
endfunction

function escribir_datos_local(fid,tipo,datos)
  switch tipo
    case 'bombas'
      for i=1:numel(datos)
        exigir_local(datos(i),{'modelo','Q','head'},tipo,i);
        fprintf(fid,'modelo_%d=%s\n',i,texto_seguro_local(datos(i).modelo));
        fprintf(fid,'Q_%d=%s\n',i,vector_texto_local(datos(i).Q));
        fprintf(fid,'head_%d=%s\n',i,vector_texto_local(datos(i).head));
        if isfield(datos(i),'potencia'),pot=datos(i).potencia;else,pot=NaN(size(datos(i).Q));endif
        fprintf(fid,'potencia_%d=%s\n',i,vector_texto_local(pot));
        if isfield(datos(i),'etapas')&&isfinite(datos(i).etapas),fprintf(fid,'etapas_%d=%d\n',i,round(datos(i).etapas));endif
      endfor
    case 'valvulas'
      for i=1:numel(datos)
        exigir_local(datos(i),{'codigo','diam_orificio_m','R_fuelle','pres_max_domo_Pa'},tipo,i);
        fprintf(fid,'valvula_%d=%s,%.12g,%.12g,%.12g\n',i,texto_seguro_local(datos(i).codigo), ...
          datos(i).diam_orificio_m,datos(i).R_fuelle,datos(i).pres_max_domo_Pa/1e5);
      endfor
    case 'varillas'
      for i=1:numel(datos)
        exigir_local(datos(i),{'nombre','densidad_kg_m3','modulo_young_GPa','limite_fatiga_MPa','resistencia_ultima_MPa'},tipo,i);
        fprintf(fid,'varilla_%d=%s,%.12g,%.12g,%.12g,%.12g\n',i,texto_seguro_local(datos(i).nombre), ...
          datos(i).densidad_kg_m3,datos(i).modulo_young_GPa,datos(i).limite_fatiga_MPa,datos(i).resistencia_ultima_MPa);
      endfor
    case 'unidades_bm'
      for i=1:numel(datos)
        exigir_local(datos(i),{'modelo','tipo','carrera_max_m','vel_max_gpm','torque_max_klb_in','peso_kg'},tipo,i);
        fprintf(fid,'unidad_%d=%s,%s,%.12g,%.12g,%.12g,%.12g\n',i,texto_seguro_local(datos(i).modelo), ...
          texto_seguro_local(datos(i).tipo),datos(i).carrera_max_m,datos(i).vel_max_gpm, ...
          datos(i).torque_max_klb_in,datos(i).peso_kg);
      endfor
  endswitch
endfunction

function exigir_local(s,campos,tipo,idx)
  for i=1:numel(campos)
    if ~isfield(s,campos{i}),error('Catalogo %s elemento %d: falta %s',tipo,idx,campos{i});endif
  endfor
endfunction

function txt=vector_texto_local(v)
  if isempty(v),txt='';return;endif
  v=double(v(:)');partes=cell(1,numel(v));
  for i=1:numel(v)
    if isnan(v(i)),partes{i}='NaN';elseif isinf(v(i)),partes{i}=ternario_local(v(i)>0,'Inf','-Inf');else,partes{i}=sprintf('%.12g',v(i));endif
  endfor
  txt=strjoin(partes,',');
endfunction

function txt=texto_seguro_local(v)
  [txt,ok]=aos_texto_seguro(v,'');
  if ~ok,error('Valor de catalogo no convertible a texto escalar.');endif
  txt=strrep(txt,sprintf('\n'),' ');txt=strrep(txt,sprintf('\r'),' ');
endfunction

function s=si_no_local(v),if v,s='CODIFICADO';else,s='TEXTO_PLANO';endif,endfunction
function out=ternario_local(c,a,b),if c,out=a;else,out=b;endif,endfunction
