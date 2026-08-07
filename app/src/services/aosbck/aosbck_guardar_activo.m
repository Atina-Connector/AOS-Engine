function paquete = aosbck_guardar_activo(silencioso)
% AOSBCK_GUARDAR_ACTIVO Reempaqueta el manifest y la geometria activa.
  if nargin<1, silencioso=false; endif
  e=aosbck_estado('GET');
  if isempty(e.paquete)||isempty(e.carpeta_temporal), error('AOSBCK: no hay paquete activo.'); endif
  e.manifest.info.modified_at=datestr(now,'yyyy-mm-dd HH:MM:SS');
  if ~isfield(e.manifest,'validation')||~isstruct(e.manifest.validation),e.manifest.validation=struct();endif
  e.manifest.validation.instance_count=numel(e.manifest.instances);
  aosbck_escribir_json(fullfile(e.carpeta_temporal,'manifest.json'),e.manifest);
  aosbck_escribir_json(fullfile(e.carpeta_temporal,'metadata','properties.json'),e.manifest.component);
  paquete=aosbck_empaquetar(e.carpeta_temporal,e.paquete);
  aosbck_estado('SET',e);
  if ~silencioso, fprintf('AOSBCK actualizado: %s\n',paquete); endif
endfunction
