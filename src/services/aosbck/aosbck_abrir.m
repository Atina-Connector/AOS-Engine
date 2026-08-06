function estado = aosbck_abrir(paquete, silencioso)
% AOSBCK_ABRIR Abre paquete, valida y lo deja activo.
  if nargin<2, silencioso=false; endif
  if nargin<1 || isempty(paquete), paquete=seleccionar_local(); endif
  if isempty(paquete), estado=aosbck_estado('GET'); return; endif
  aosbck_estado('CLEAR');
  carpeta=aosbck_extraer(paquete); m=aosbck_leer_json(fullfile(carpeta,'manifest.json'));
  r=aosbck_validar(m,carpeta,false); if ~r.ok, aos_rmdir_seguro(carpeta,tempdir()); error('AOSBCK: paquete invalido.'); endif
  step=fullfile(carpeta,char(m.geometry.package_path));
  estado=struct('paquete',char(paquete),'manifest',m,'step_extraido',step,'carpeta_temporal',carpeta);
  aosbck_estado('SET',estado);
  if ~silencioso
    fprintf('\n--- AOSBCK ACTIVO ---\n'); fprintf('Paquete    : %s\n',paquete);
    fprintf('Componente : %s\n',m.component.component_id); fprintf('Parte      : %s\n',m.component.part_number);
    fprintf('Instancias : %d\n',numel_coleccion_local(m.instances)); fprintf('STEP       : %s\n',step);
  endif
endfunction

function archivo=seleccionar_local()
  archivo=''; bases={fullfile(aosbck_raiz(),'intercambio','cad','aosbck'), ...
    fullfile(aosbck_raiz(),'datos','ejemplos','aosbck')};
  candidatos={};
  for b=1:numel(bases)
    if exist(bases{b},'dir')~=7,continue;endif
    lista=dir(fullfile(bases{b},'*.aosbck'));
    for i=1:numel(lista),candidatos{end+1}=fullfile(bases{b},lista(i).name);endfor
  endfor
  if ~isempty(candidatos)
    fprintf('AOSBCK disponibles:\n'); for i=1:numel(candidatos), fprintf(' %d - %s\n',i,candidatos{i}); endfor
    fprintf(' 0 - Elegir otro archivo\n'); op=aos_leer_opcion(sprintf('Seleccione [0-%d]: ',numel(candidatos)),[]);
    if ~isempty(op)&&op>=1&&op<=numel(candidatos), archivo=candidatos{op}; return; endif
  endif
  try
    [f,p]=uigetfile({'*.aosbck','Componentes AOSBCK'},'Abrir AOSBCK');
    if isnumeric(f)&&f==0, return; endif; archivo=fullfile(p,f);
  catch, archivo=strtrim(input('Ruta del .aosbck: ','s')); end_try_catch
endfunction

function n=numel_coleccion_local(v)
  if isempty(v), n=0; else, n=numel(v); endif
endfunction
