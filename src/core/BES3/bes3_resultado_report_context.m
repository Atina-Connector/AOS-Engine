function contexto = bes3_resultado_report_context(sol)
% Contexto transversal para una simulacion puntual BES3.
  if nargin < 1 || ~isstruct(sol), error('Falta resultado BES3.'); endif
  contexto = struct();
  contexto.tipo = 'BES3';
  contexto.tipo_calculo = 'simulacion';
  if isfield(sol,'modo_operacion')&&ischar(sol.modo_operacion),contexto.tipo_calculo=lower(sol.modo_operacion);endif
  contexto.solver = 'BES3';if isfield(sol,'version')&&ischar(sol.version),contexto.solver=sol.version;endif
  contexto.param = struct();if isfield(sol,'param')&&isstruct(sol.param),contexto.param=sol.param;endif
  contexto.Ql = 0;if isfield(sol,'Ql_m3_d'),contexto.Ql=sol.Ql_m3_d/86400;endif
  contexto.Qo = 0;if isfield(sol,'Qo_m3_d'),contexto.Qo=sol.Qo_m3_d/86400;endif
  contexto.Qiny = 0;
  contexto.resultado = sol;
  contexto.exportador_simple = 'bes3_exportar_resultado_simple';
  contexto.exportador_enriquecido = 'bes3_exportar_resultado_enriquecido';
  contexto.carpeta_defecto = fullfile('intercambio','reportes','enviados');
  contexto.nombre_caso = nombre_local(contexto.param);
endfunction
function n=nombre_local(p)
  n='BES3';campos={'nombre_pozo','pozo','nombre','archivo_aosdat'};
  for i=1:numel(campos),if isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i}))),n=[p.(campos{i}) '_BES3'];return;endif,endfor
  global AOSDAT_ACTIVO;if ischar(AOSDAT_ACTIVO)&&~isempty(AOSDAT_ACTIVO),[~,b,~]=fileparts(AOSDAT_ACTIVO);n=[b '_BES3'];endif
endfunction
