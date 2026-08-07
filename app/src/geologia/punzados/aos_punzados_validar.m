function resultado = aos_punzados_validar(punzados, survey, imprimir, opciones)
% AOS_PUNZADOS_VALIDAR Valida intervalos y calcula magnitudes derivadas.
% La ausencia de Survey no impide crear o guardar punzados manuales.
% Por defecto, un intervalo fuera del rango del Survey genera un aviso y no
% un bloqueo, porque el Survey disponible puede ser parcial.

  if nargin < 2, survey = []; endif
  if nargin < 3 || isempty(imprimir), imprimir = false; endif
  if nargin < 4 || ~isstruct(opciones), opciones = struct(); endif
  fuera_es_error = opcion_log_local(opciones,'survey_fuera_es_error',false);

  [p, avisos_norm] = aos_punzados_normalizar(punzados);
  resultado = struct('ok',true,'errores',{{}},'avisos',{avisos_norm}, ...
    'n_tramos',0,'n_activos',0,'longitud_total_m',0, ...
    'n_tiros_estimado',0,'survey_disponible',false, ...
    'rango_survey_md',[NaN NaN],'tabla',struct([]),'punzados',p);

  if ~isstruct(p) || ~isfield(p,'tramos') || isempty(p.tramos)
    resultado.avisos{end+1} = 'No hay intervalos de punzado cargados.';
    if imprimir, imprimir_local(resultado); endif
    return;
  endif

  rango_survey = [NaN NaN];
  if isstruct(survey) && isfield(survey,'MD') && isnumeric(survey.MD) && ~isempty(survey.MD)
    md = survey.MD(isfinite(survey.MD));
    if ~isempty(md)
      rango_survey = [min(md) max(md)];
      resultado.survey_disponible = true;
      resultado.rango_survey_md = rango_survey;
    endif
  endif
  if ~resultado.survey_disponible
    resultado.avisos{end+1} = ...
      'Survey no disponible: los punzados se conservan en MD y no puede calcularse TVD.';
  endif

  resultado.n_tramos = numel(p.tramos);
  activos_previos = zeros(0,2);
  tabla = struct([]);

  for i = 1:numel(p.tramos)
    t = p.tramos(i);
    L = t.MD_hasta - t.MD_desde;
    tiros = max(L,0) * max(t.densidad_tpm,0);
    if t.activo
      resultado.n_activos = resultado.n_activos + 1;
      resultado.longitud_total_m = resultado.longitud_total_m + max(L,0);
      resultado.n_tiros_estimado = resultado.n_tiros_estimado + tiros;
    endif

    if t.MD_desde < 0 || t.MD_hasta <= t.MD_desde
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): profundidades MD invalidas.',i,t.id);
    endif
    if t.activo && t.densidad_tpm <= 0
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): densidad debe ser mayor que cero si esta activo.',i,t.id);
    elseif t.densidad_tpm < 0
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): densidad negativa.',i,t.id);
    endif
    if ~isfinite(t.diametro_punzado_m) || t.diametro_punzado_m <= 0
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): diametro de punzado invalido.',i,t.id);
    endif
    if isfinite(t.fase_deg) && (t.fase_deg < 0 || t.fase_deg > 360)
      resultado.avisos{end+1} = sprintf( ...
        'Tramo %d (%s): fase fuera de 0 a 360 grados.',i,t.id);
    endif
    if isfinite(t.penetracion_m) && t.penetracion_m < 0
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): penetracion negativa.',i,t.id);
    endif
    if isfinite(t.permeabilidad_mD) && t.permeabilidad_mD < 0
      resultado.ok = false;
      resultado.errores{end+1} = sprintf( ...
        'Tramo %d (%s): permeabilidad negativa.',i,t.id);
    endif

    fuera = false;
    if all(isfinite(rango_survey))
      fuera = t.MD_desde < rango_survey(1)-0.1 || ...
              t.MD_hasta > rango_survey(2)+0.1;
      if fuera
        msg = sprintf('Tramo %d (%s): fuera del rango MD del Survey.',i,t.id);
        if fuera_es_error
          resultado.ok = false;
          resultado.errores{end+1} = msg;
        else
          resultado.avisos{end+1} = msg;
        endif
      endif
    endif

    if t.activo && ~isempty(activos_previos)
      solape = any(t.MD_desde < activos_previos(:,2) & ...
                   t.MD_hasta > activos_previos(:,1));
      if solape
        resultado.avisos{end+1} = sprintf( ...
          'Tramo activo %d (%s) se superpone con otro tramo activo.',i,t.id);
      endif
    endif
    if t.activo
      activos_previos(end+1,:) = [t.MD_desde,t.MD_hasta]; %#ok<AGROW>
    endif

    fila = struct('indice',i,'id',t.id,'MD_desde_m',t.MD_desde, ...
      'MD_hasta_m',t.MD_hasta,'MD_medio_m',(t.MD_desde+t.MD_hasta)/2, ...
      'TVD_desde_m',NaN,'TVD_hasta_m',NaN,'TVD_medio_m',NaN, ...
      'longitud_m',L,'densidad_tpm',t.densidad_tpm, ...
      'n_tiros_estimado',tiros,'activo',t.activo, ...
      'fuera_survey',fuera,'estado_validacion',t.estado_validacion);
    if resultado.survey_disponible && isfield(survey,'TVD') && ...
       isnumeric(survey.TVD) && numel(survey.TVD)==numel(survey.MD)
      try
        fila.TVD_desde_m = interp1(survey.MD(:),survey.TVD(:), ...
          t.MD_desde,'linear','extrap');
        fila.TVD_hasta_m = interp1(survey.MD(:),survey.TVD(:), ...
          t.MD_hasta,'linear','extrap');
        fila.TVD_medio_m = interp1(survey.MD(:),survey.TVD(:), ...
          fila.MD_medio_m,'linear','extrap');
      catch
      end_try_catch
    endif
    if isempty(tabla),tabla=fila;else,tabla(end+1)=fila;endif
  endfor

  resultado.tabla = tabla;
  if resultado.n_activos == 0
    resultado.avisos{end+1} = ...
      'No hay intervalos activos; los solvers no recibiran aporte por punzados.';
  endif
  if imprimir, imprimir_local(resultado); endif
endfunction

function imprimir_local(r)
  fprintf('\n--- VALIDACION DE PUNZADOS ---\n');
  fprintf('Tramos totales           : %d\n',r.n_tramos);
  fprintf('Tramos activos           : %d\n',r.n_activos);
  fprintf('Longitud activa total    : %.3f m\n',r.longitud_total_m);
  fprintf('Tiros estimados          : %.0f\n',r.n_tiros_estimado);
  if r.survey_disponible
    fprintf('Rango MD del Survey      : %.3f a %.3f m\n', ...
      r.rango_survey_md(1),r.rango_survey_md(2));
  else
    fprintf('Survey                   : NO DISPONIBLE\n');
  endif
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

function v=opcion_log_local(s,c,d)
  v=d;if isfield(s,c),[x,ok]=aos_logico_seguro(s.(c),d);if ok,v=x;endif,endif
endfunction
