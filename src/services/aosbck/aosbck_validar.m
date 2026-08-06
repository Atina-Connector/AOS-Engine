function r = aosbck_validar(manifest, carpeta, imprimir)
% AOSBCK_VALIDAR Verifica contrato, geometria e identidades.
  if nargin<2, carpeta=''; endif
  if nargin<3, imprimir=true; endif
  errores={}; avisos={};
  if ~isstruct(manifest), errores{end+1}='manifest no es struct';
  else
    if ~isfield(manifest,'info') || ~isfield(manifest.info,'schema'), errores{end+1}='falta info.schema';
    elseif ~strcmp(char(manifest.info.schema),'AOSBCK-0.1.9-R1'), errores{end+1}='schema no soportado'; endif
    if ~isfield(manifest,'component') || ~isfield(manifest.component,'component_id'), errores{end+1}='falta component_id'; endif
    if ~isfield(manifest,'geometry') || ~isfield(manifest.geometry,'package_path'), errores{end+1}='falta geometria';
    elseif ~isempty(carpeta) && exist(fullfile(carpeta,char(manifest.geometry.package_path)),'file')~=2
      errores{end+1}='STEP no encontrado dentro del paquete';
    endif
    if ~isfield(manifest,'instances'), avisos{end+1}='sin coleccion instances'; endif
    if ~isfield(manifest,'ports'), avisos{end+1}='sin coleccion ports'; endif
  endif
  r=struct('ok',isempty(errores),'status','VALID','errors',{errores},'warnings',{avisos});
  if ~r.ok, r.status='INVALID'; elseif ~isempty(avisos), r.status='VALID_WITH_WARNINGS'; endif
  if imprimir
    fprintf('\n--- VALIDACION AOSBCK ---\n'); fprintf('Estado: %s\n',r.status);
    for i=1:numel(errores), fprintf(2,'ERROR: %s\n',errores{i}); endfor
    for i=1:numel(avisos), fprintf('AVISO: %s\n',avisos{i}); endfor
  endif
endfunction
