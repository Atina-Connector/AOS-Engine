function paquete = aosbck_crear_desde_step(step_archivo, meta, salida, silencioso)
% AOSBCK_CREAR_DESDE_STEP Convierte un STEP en componente reutilizable AOSBCK.
  if nargin<4, silencioso=false; endif
  if nargin<2 || ~isstruct(meta), meta=struct(); endif
  if nargin<1 || isempty(step_archivo), step_archivo=seleccionar_step_local(); endif
  paquete=''; if isempty(step_archivo), return; endif
  if exist(step_archivo,'file')~=2, error('AOSBCK: STEP inexistente: %s',step_archivo); endif
  if nargin<3 || isempty(salida)
    outdir=fullfile(aosbck_raiz(),'intercambio','cad','aosbck');
    if exist(outdir,'dir')~=7, mkdir(outdir); endif
    [~,base]=fileparts(step_archivo); salida=fullfile(outdir,[base '.aosbck']);
  endif
  m=aosbck_manifest_nuevo(step_archivo,meta);
  tmp=[tempname() '_aosbck_build']; mkdir(tmp); mkdir(fullfile(tmp,'geometry')); mkdir(fullfile(tmp,'metadata')); mkdir(fullfile(tmp,'preview'));
  [~,gn,ge]=fileparts(step_archivo); copyfile(step_archivo,fullfile(tmp,'geometry',[gn ge]));
  m.geometry.package_path=['geometry/' gn ge];
  aosbck_escribir_json(fullfile(tmp,'manifest.json'),m);
  aosbck_escribir_json(fullfile(tmp,'metadata','properties.json'),m.component);
  fid=fopen(fullfile(tmp,'preview','README.txt'),'wt');
  fprintf(fid,'AOSBCK R1: previsualizacion grafica pendiente. Use FreeCAD para visualizar geometry/%s%s.\n',gn,ge); fclose(fid);
  unwind_protect
    paquete=aosbck_empaquetar(tmp,salida);
  unwind_protect_cleanup
    if exist(tmp,'dir')==7, aos_rmdir_seguro(tmp,tempdir()); endif
  end_unwind_protect
  aosbck_abrir(paquete,true);
  if ~silencioso
    fprintf('\n--- AOSBCK CREADO ---\n');
    fprintf('Paquete     : %s\n',paquete); fprintf('Componente  : %s\n',m.component.component_id);
    fprintf('Parte       : %s\n',m.component.part_number); fprintf('Geometria   : una copia STEP reutilizable\n');
    fprintf('Instancias  : 0 (se agregan sin duplicar geometria)\n');
  endif
endfunction

function archivo=seleccionar_step_local()
  archivo='';
  try
    [f,p]=uigetfile({'*.step;*.stp','Archivos STEP'},'Crear AOSBCK desde STEP');
    if isnumeric(f)&&f==0, return; endif; archivo=fullfile(p,f);
  catch
    archivo=strtrim(input('Ruta del STEP: ','s'));
  end_try_catch
endfunction
