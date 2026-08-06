function contexto = bes3_comparacion_report_context(param, C)
% Contexto transversal para comparacion BES3 ON/OFF.
  if nargin<1||~isstruct(param),param=struct();endif
  if nargin<2||~isstruct(C),error('Falta comparacion BES3 ON/OFF.');endif
  contexto=struct('tipo','BES3','tipo_calculo','comparacion_on_off','solver','BES3', ...
    'param',param,'Ql',0,'Qo',0,'Qiny',0,'comparacion',C, ...
    'exportador_simple','bes3_exportar_comparacion_simple', ...
    'exportador_enriquecido','bes3_exportar_comparacion_enriquecido', ...
    'carpeta_defecto',fullfile('intercambio','reportes','enviados'), ...
    'nombre_caso',[nombre_local(param) '_BES3_ON_OFF']);
  if isfield(C,'version')&&ischar(C.version),contexto.solver=C.version;endif
endfunction
function n=nombre_local(p)
  n='caso';campos={'nombre_pozo','pozo','nombre','archivo_aosdat'};
  for i=1:numel(campos),if isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i}))),n=p.(campos{i});return;endif,endfor
  global AOSDAT_ACTIVO;if ischar(AOSDAT_ACTIVO)&&~isempty(AOSDAT_ACTIVO),[~,n,~]=fileparts(AOSDAT_ACTIVO);endif
endfunction
