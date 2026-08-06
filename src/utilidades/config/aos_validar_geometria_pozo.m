function resultado = aos_validar_geometria_pozo(survey, punzados, imprimir)
% Valida Survey y punzados sin bloquear la configuracion manual en MD.
  if nargin < 3 || isempty(imprimir), imprimir=false; endif
  resultado=struct('ok',true,'errores',{{}},'avisos',{{}}, ...
    'n_survey',0,'n_punzados',0,'n_punzados_activos',0, ...
    'punzados',struct());

  if isempty(survey)
    resultado.avisos{end+1}= ...
      'No hay Survey cargado: los punzados pueden editarse en MD, pero no se calcula TVD.';
  elseif ~isstruct(survey) || ~isfield(survey,'MD') || ~isfield(survey,'TVD')
    resultado.ok=false;
    resultado.errores{end+1}='Survey sin campos MD/TVD validos.';
  else
    resultado.n_survey=numel(survey.MD);
    if numel(survey.MD)~=numel(survey.TVD)
      resultado.ok=false;
      resultado.errores{end+1}='MD y TVD tienen distinta cantidad de puntos.';
    endif
    if any(~isfinite(survey.MD)) || any(~isfinite(survey.TVD))
      resultado.ok=false;
      resultado.errores{end+1}='El Survey contiene valores MD/TVD no finitos.';
    endif
    if numel(survey.MD)>1 && any(diff(survey.MD)<=0)
      resultado.ok=false;
      resultado.errores{end+1}='MD no es estrictamente creciente.';
    endif
    if any(survey.MD<0) || any(survey.TVD<0)
      resultado.ok=false;
      resultado.errores{end+1}='El Survey contiene profundidades negativas.';
    endif
    if ~isempty(survey.MD) && any(survey.TVD-survey.MD>max(0.5,1e-4*max(survey.MD)))
      resultado.avisos{end+1}= ...
        'Hay puntos con TVD mayor que MD; revisar unidades o convencion.';
    endif
    if numel(survey.TVD)>1 && any(diff(survey.TVD)<-0.5)
      resultado.avisos{end+1}= ...
        'TVD no es monotona; puede ser valido en un pozo complejo, pero debe revisarse.';
    endif
    if isfield(survey,'inclinacion') && any(survey.inclinacion<0 | survey.inclinacion>180)
      resultado.avisos{end+1}='Hay inclinaciones fuera del rango 0 a 180 grados.';
    endif
    if isfield(survey,'azimut') && any(survey.azimut<-360 | survey.azimut>720)
      resultado.avisos{end+1}='Hay azimuts fuera del rango esperado.';
    endif
  endif

  rp=aos_punzados_validar(punzados,survey,false, ...
    struct('survey_fuera_es_error',false));
  resultado.punzados=rp;
  resultado.n_punzados=rp.n_tramos;
  resultado.n_punzados_activos=rp.n_activos;
  resultado.ok=resultado.ok && rp.ok;
  resultado.errores=[resultado.errores,rp.errores];
  resultado.avisos=[resultado.avisos,rp.avisos];

  if imprimir, imprimir_local(resultado); endif
endfunction

function imprimir_local(r)
  fprintf('\n--- VALIDACION DE GEOMETRIA Y PUNZADOS ---\n');
  fprintf('Puntos de Survey         : %d\n',r.n_survey);
  fprintf('Intervalos de punzado    : %d (%d activos)\n', ...
    r.n_punzados,r.n_punzados_activos);
  if isempty(r.errores)
    fprintf('Errores                  : ninguno\n');
  else
    fprintf('Errores                  : %d\n',numel(r.errores));
    for i=1:numel(r.errores),fprintf('  ERROR - %s\n',r.errores{i});endfor
  endif
  if isempty(r.avisos)
    fprintf('Avisos                   : ninguno\n');
  else
    fprintf('Avisos                   : %d\n',numel(r.avisos));
    for i=1:numel(r.avisos),fprintf('  AVISO - %s\n',r.avisos{i});endfor
  endif
  if r.ok,fprintf('Estado                   : APROBADO\n');
  else,fprintf('Estado                   : REQUIERE CORRECCION\n');endif
endfunction
