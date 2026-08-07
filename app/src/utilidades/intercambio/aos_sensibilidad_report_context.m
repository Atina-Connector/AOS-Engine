function contexto = aos_sensibilidad_report_context(modulo, param, R)
% AOS_SENSIBILIDAD_REPORT_CONTEXT Adaptador transversal al dispatcher AOSRPT.
  if nargin<1||~ischar(modulo)||isempty(strtrim(modulo)),modulo='GENERAL';endif
  if nargin<2||~isstruct(param),param=struct();endif
  if nargin<3||~isstruct(R),error('Falta resultado de sensibilidad.');endif
  modulo=upper(strtrim(modulo));
  contexto=struct();
  contexto.tipo=modulo;
  contexto.tipo_calculo=['sensibilidad_' texto_local(R,'campo','parametro')];
  contexto.solver=solver_local(R,modulo);
  contexto.param=param;
  contexto.Ql=0;contexto.Qo=0;contexto.Qiny=0;
  contexto.sensibilidad=R;
  contexto.exportador_simple='aos_exportar_sensibilidad_simple';
  contexto.exportador_enriquecido='aos_exportar_sensibilidad_enriquecido';
  contexto.carpeta_defecto=fullfile('intercambio','reportes','enviados');
  contexto.nombre_pozo=nombre_pozo_local(param);
  contexto.nombre_caso=nombre_caso_local(contexto.nombre_pozo,modulo,R);
  contexto.diagnostico=aos_sensibilidad_diagnosticar(R,modulo,param);
endfunction
function s=solver_local(R,m)
  s=[m '_SOLVER'];
  if isfield(R,'soluciones')&&iscell(R.soluciones)
    for i=1:numel(R.soluciones)
      q=R.soluciones{i};if isstruct(q)&&isfield(q,'version')&&ischar(q.version)&&~isempty(q.version),s=q.version;return;endif
    endfor
  endif
endfunction
function n=nombre_pozo_local(p)
  n='Pozo sin identificar';campos={'nombre_pozo','pozo','nombre'};
  for i=1:numel(campos),if isfield(p,campos{i})&&ischar(p.(campos{i}))&&~isempty(strtrim(p.(campos{i}))),n=strtrim(p.(campos{i}));return;endif,endfor
  global AOSDAT_ACTIVO;
  if ischar(AOSDAT_ACTIVO)&&~isempty(strtrim(AOSDAT_ACTIVO)),[~,x,~]=fileparts(AOSDAT_ACTIVO);if ~isempty(x),n=x;endif,endif
endfunction
function n=nombre_caso_local(pozo,modulo,R)
  base=pozo;if strcmpi(base,'Pozo sin identificar'),base='reporte';endif
  campo=texto_local(R,'campo','parametro');
  n=[base '_' modulo '_sensibilidad_' campo];
  n=regexprep(n,'[^A-Za-z0-9_-]+','_');n=regexprep(n,'_+','_');n=regexprep(n,'^_+|_+$','');
endfunction
function t=texto_local(s,c,d)
  t=d;if isfield(s,c)&&ischar(s.(c))&&~isempty(strtrim(s.(c))),t=s.(c);endif
endfunction
