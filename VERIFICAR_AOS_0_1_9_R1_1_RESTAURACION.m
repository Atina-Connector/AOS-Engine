function ok = VERIFICAR_AOS_0_1_9_R1_1_RESTAURACION(profundo)
% Verifica la restauracion transversal de importacion, catalogos y galerias.
  if nargin<1,profundo=false;endif
  ok=true;
  fprintf('\n=== VERIFICAR AOS 0.1.9 R1.1 RESTAURACION ===\n');
  requeridas={'AOS_menu_gestion_caso','aos_menu_abrir_contextual','AOS_menu_galerias', ...
    'aos_catalogos_fusionar_desde_aosdat','importar_aosdat','exportar_aosdat', ...
    'importar_aosrpt','mandriles_cargar_galeria','aos_cad_importar_dxf'};
  for i=1:numel(requeridas)
    if exist(requeridas{i},'file')==2
      fprintf('OK    %s\n',requeridas{i});
    else
      fprintf(2,'FALTA %s\n',requeridas{i});ok=false;
    endif
  endfor

  root=fileparts(mfilename('fullpath'));
  menu=fullfile(root,'src','menu','AOS_app.m');
  if revisar_texto_local(menu,{'NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO','AOS_menu_gestion_caso','AOS_menu_suite_compat_r1'})
    fprintf('OK    menu principal restaurado\n');
  else
    fprintf(2,'FALLO menu principal incompleto\n');ok=false;
  endif

  archivos_contexto={'AOS_menu_SLA.m','AOS_menu_BM.m','AOS_menu_GL_JGL.m','AOS_menu_BES.m', ...
    'AOS_menu_PCP.m','AOS_menu_CGF.m','AOS_menu_EGF.m','AOS_menu_networks.m', ...
    'AOS_menu_electrical.m','AOS_menu_facilities.m','AOS_menu_geology.m', ...
    'AOS_menu_fluidos.m','AOS_menu_wells.m','AOS_menu_scada.m','AOS_menu_maintenance.m'};
  for i=1:numel(archivos_contexto)
    ruta=fullfile(root,'src','menu',archivos_contexto{i});
    if revisar_texto_local(ruta,{'aos_menu_abrir_contextual'})
      fprintf('OK    acceso contextual %s\n',archivos_contexto{i});
    else
      fprintf(2,'FALLO acceso contextual %s\n',archivos_contexto{i});ok=false;
    endif
  endfor

  ejemplos={fullfile(root,'datos','ejemplos','catalogos','AOS_GALERIA_MANDRILES_COMPLETA.aosdat'), ...
    fullfile(root,'datos','ejemplos','cad','demo_aos_galerias.dxf')};
  for i=1:numel(ejemplos)
    if exist(ejemplos{i},'file')==2,fprintf('OK    ejemplo %s\n',ejemplos{i});else,fprintf(2,'FALTA ejemplo %s\n',ejemplos{i});ok=false;endif
  endfor

  nmat=contar_mat_local(root);
  if nmat==0,fprintf('OK    sin archivos .mat\n');else,fprintf(2,'FALLO se encontraron %d .mat\n',nmat);ok=false;endif

  if profundo
    pruebas={'test_aosdat_legacy_compat_001','test_aosdat_roundtrip_001','test_aos_cad_galerias'};
    for i=1:numel(pruebas)
      if exist(pruebas{i},'file')==2
        try
          r=feval(pruebas{i});
          if isempty(r)||logical(r),fprintf('OK    %s\n',pruebas{i});else,fprintf(2,'FALLO %s\n',pruebas{i});ok=false;endif
        catch err
          fprintf(2,'ERROR %s: %s\n',pruebas{i},err.message);ok=false;
        end_try_catch
      endif
    endfor
  endif

  if ok,fprintf('RESULTADO: RESTAURACION R1.1 APROBADA\n');else,fprintf(2,'RESULTADO: RESTAURACION R1.1 NO APROBADA\n');endif
endfunction

function ok=revisar_texto_local(ruta,patrones)
  ok=false;if exist(ruta,'file')~=2,return;endif
  txt=fileread(ruta);ok=true;
  for i=1:numel(patrones),if isempty(strfind(txt,patrones{i})),ok=false;return;endif,endfor
endfunction

function n=contar_mat_local(carpeta)
  n=0;d=dir(carpeta);
  for i=1:numel(d)
    if strcmp(d(i).name,'.')||strcmp(d(i).name,'..'),continue;endif
    p=fullfile(carpeta,d(i).name);
    if d(i).isdir,n=n+contar_mat_local(p);
    else,[~,~,ext]=fileparts(d(i).name);if strcmpi(ext,'.mat'),n=n+1;endif
    endif
  endfor
endfunction
