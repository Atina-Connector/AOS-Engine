function exportar_grafico_modulo()
  % Detecta automáticamente el tipo de módulo (sensibilidad, mandriles, survey)
  % y exporta un reporte enriquecido con los datos y el gráfico actual.
  % Debe llamarse al final del script que generó el gráfico.

  % Las sensibilidades usan un registro explicito. No se pregunta ni se exporta
  % una figura aislada: el .aosrpt final consume todas las figuras registradas.
  caller_vars = evalin('caller', 'who');
  caller_name = '';
  try
      caller_name = evalin('caller', 'mfilename');
  catch
      caller_name = '';
  end_try_catch
  [es_sensibilidad, contexto] = caller_sensibilidad_local(caller_vars, caller_name);
  if es_sensibilidad
      fig = gcf();
      titulo = titulo_figura_local(fig);
      id = [limpiar_id_local(contexto) '_' limpiar_id_local(titulo)];
      entrada = aos_registro_graficos('add',fig,id,titulo,'SENSIBILIDAD',contexto);
      fprintf('Grafico registrado para el reporte: %s [%s]\n',entrada.titulo,entrada.id);
      return;
  endif

  % Variables del workspace del llamante ya capturadas arriba.

  % --- Determinar tipo de módulo según las variables presentes ---
  if any(strcmp(caller_vars, 'valv_D'))
      % Diseño de mandriles
      tipo = 'MANDRILES';
      datos.P_iny_sup = evalin('caller', 'P_iny_sup');
      datos.D_packer   = evalin('caller', 'D_packer');
      datos.metodo     = evalin('caller', 'metodo');
      datos.valv_D     = evalin('caller', 'valv_D');
      datos.valv_Pgas  = evalin('caller', 'valv_Pgas');
      datos.valv_Ptub  = evalin('caller', 'valv_Ptub');
  elseif any(strcmp(caller_vars, 'MD')) && any(strcmp(caller_vars, 'TVD'))
      % Plot survey
      tipo = 'SURVEY';
      datos.MD  = evalin('caller', 'MD');
      datos.TVD = evalin('caller', 'TVD');
      if any(strcmp(caller_vars, 'inclinacion'))
          datos.inclinacion = evalin('caller', 'inclinacion');
      end
  elseif any(strcmp(caller_vars, 'Qiny_vals')) || any(strcmp(caller_vars, 'freq_vals')) ...
         || any(strcmp(caller_vars, 'etapas_vals')) || any(strcmp(caller_vars, 'A_n_vals')) ...
         || any(strcmp(caller_vars, 'd_t_vals')) || any(strcmp(caller_vars, 'P_iny_vals')) ...
         || any(strcmp(caller_vars, 'P_wh_vals')) || any(strcmp(caller_vars, 'D_bomba_vals'))
      % Sensibilidad (JGL, GL, BES, balance energético)
      tipo = 'SENSIBILIDAD';

      % Parámetro de barrido (buscar cuál está presente)
      if any(strcmp(caller_vars, 'Qiny_vals'))
          datos.parametro = 'Qiny (Sm3/d)';
          param_vals = evalin('caller', 'Qiny_vals');
          % En los motores AOS Qiny_vals se conserva en m3/s estandar.
          % Para reportes se presenta en Sm3/d, con imperial solo como referencia.
          if isempty(param_vals)
              datos.param_vals = param_vals;
          elseif max(abs(param_vals)) < 100
              datos.param_vals = param_vals * 86400;
          else
              % Compatibilidad con barridos que ya estuvieran expresados en Sm3/d.
              datos.param_vals = param_vals;
          end
      elseif any(strcmp(caller_vars, 'freq_vals'))
          datos.parametro = 'Frecuencia (Hz)';
          datos.param_vals = evalin('caller', 'freq_vals');
      elseif any(strcmp(caller_vars, 'etapas_vals'))
          datos.parametro = 'Etapas';
          datos.param_vals = evalin('caller', 'etapas_vals');
      elseif any(strcmp(caller_vars, 'A_n_vals'))
          datos.parametro = 'A_n (mm²)';
          datos.param_vals = evalin('caller', 'A_n_vals') * 1e6;
      elseif any(strcmp(caller_vars, 'd_t_vals'))
          datos.parametro = 'd_t (mm)';
          datos.param_vals = evalin('caller', 'd_t_vals') * 1000;
      elseif any(strcmp(caller_vars, 'P_iny_vals'))
          datos.parametro = 'P_iny (bar)';
          datos.param_vals = evalin('caller', 'P_iny_vals') / 1e5;
      elseif any(strcmp(caller_vars, 'P_wh_vals'))
          datos.parametro = 'P_wh (bar)';
          datos.param_vals = evalin('caller', 'P_wh_vals') / 1e5;
      elseif any(strcmp(caller_vars, 'D_bomba_vals'))
          datos.parametro = 'D_bomba (m)';
          datos.param_vals = evalin('caller', 'D_bomba_vals');
      end

      datos.param_min = datos.param_vals(1);
      datos.param_max = datos.param_vals(end);
      datos.param_pasos = length(datos.param_vals);

      % Caudales (pueden existir varias combinaciones)
      if any(strcmp(caller_vars, 'Ql_JGL'))
          datos.Ql_JGL = evalin('caller', 'Ql_JGL');
      end
      if any(strcmp(caller_vars, 'Qo_JGL'))
          datos.Qo_JGL = evalin('caller', 'Qo_JGL');
      end
      if any(strcmp(caller_vars, 'Ql_GL'))
          datos.Ql_GL = evalin('caller', 'Ql_GL');
      end
      if any(strcmp(caller_vars, 'Qo_GL'))
          datos.Qo_GL = evalin('caller', 'Qo_GL');
      end
      % BES (variables con nombres diferentes)
      if any(strcmp(caller_vars, 'Ql_BES'))
          datos.Ql_BES = evalin('caller', 'Ql_BES');
      end
      if any(strcmp(caller_vars, 'Qo_BES'))
          datos.Qo_BES = evalin('caller', 'Qo_BES');
      end
      % También puede haber Ql_vals, Qo_vals genéricos
      if any(strcmp(caller_vars, 'Ql_vals'))
          datos.Ql = evalin('caller', 'Ql_vals');
      end
      if any(strcmp(caller_vars, 'Qo_vals'))
          datos.Qo = evalin('caller', 'Qo_vals');
      end
      % Eficiencia (balance energético)
      if any(strcmp(caller_vars, 'Efic_JGL'))
          datos.Efic_JGL = evalin('caller', 'Efic_JGL');
      end
      if any(strcmp(caller_vars, 'Efic_GL'))
          datos.Efic_GL = evalin('caller', 'Efic_GL');
      end

      % Óptimos (buscar variables de óptimo)
      if any(strcmp(caller_vars, 'Qiny_opt_JGL'))
          datos.optimo_valor = evalin('caller', 'Qiny_opt_JGL') * 86400;
          datos.optimo_Qo    = evalin('caller', 'Qo_opt_JGL');
      elseif any(strcmp(caller_vars, 'Qiny_opt_GL'))
          datos.optimo_valor = evalin('caller', 'Qiny_opt_GL') * 86400;
          datos.optimo_Qo    = evalin('caller', 'Qo_opt_GL');
      elseif any(strcmp(caller_vars, 'f_opt'))
          datos.optimo_valor = evalin('caller', 'f_opt');
          datos.optimo_Qo    = evalin('caller', 'Qo_opt');
      elseif any(strcmp(caller_vars, 'N_opt'))
          datos.optimo_valor = evalin('caller', 'N_opt');
          datos.optimo_Qo    = evalin('caller', 'Qo_opt');
      elseif any(strcmp(caller_vars, 'A_opt'))
          datos.optimo_valor = evalin('caller', 'A_opt') * 1e6;
          datos.optimo_Qo    = evalin('caller', 'Qo_opt');
      elseif any(strcmp(caller_vars, 'd_opt'))
          datos.optimo_valor = evalin('caller', 'd_opt') * 1000;
          datos.optimo_Qo    = evalin('caller', 'Qo_opt');
      elseif any(strcmp(caller_vars, 'P_opt_JGL'))
          datos.optimo_valor = evalin('caller', 'P_opt_JGL') / 1e5;
          datos.optimo_Qo    = evalin('caller', 'Qo_opt_JGL');
      elseif any(strcmp(caller_vars, 'D_opt_JGL'))
          datos.optimo_valor = evalin('caller', 'D_opt_JGL');
          datos.optimo_Qo    = evalin('caller', 'Qo_opt_JGL');
      end
  else
      warning('No se pudo identificar el tipo de módulo. No se exportará el reporte.');
      return;
  end

  % Nombre del pozo (si hay CONFIG_ACTIVA)
  global CONFIG_ACTIVA;
  if ~isempty(CONFIG_ACTIVA) && isfield(CONFIG_ACTIVA, 'nombre_pozo')
      datos.nombre_pozo = CONFIG_ACTIVA.nombre_pozo;
  end

  % Preguntar y exportar
  preguntar_exportar_grafico(datos, tipo);
end

function [tf,contexto]=caller_sensibilidad_local(caller_vars,caller_name)
  tf=false;contexto='SENSIBILIDAD';
  if nargin<1 || ~iscell(caller_vars),caller_vars={};endif
  if nargin<2 || ~ischar(caller_name),caller_name='';endif
  if ~isempty(caller_name) && strncmpi(caller_name,'sens_',5)
    tf=true;contexto=caller_name;return;
  endif
  marcadores={'Qiny_vals','Qvals','qvals','SENS_QINY_AUDIT', ...
    'SENS_QINY_JGL_AUDIT','SENS_QINY_GL_AUDIT','SENS_BALANCE_ENERGETICO_AUDIT'};
  if any(ismember(marcadores,caller_vars))
    tf=true;
    if ~isempty(caller_name),contexto=caller_name;endif
    return;
  endif
  try
    st=dbstack();
    for kk=2:numel(st)
      if strcmp(st(kk).name,'exportar_grafico_modulo') || strcmp(st(kk).name,'caller_sensibilidad_local')
        continue;
      endif
      contexto=st(kk).name;
      f='';if isfield(st(kk),'file'),f=st(kk).file;endif
      tf=~isempty(strfind(lower(f),[filesep 'sensibilidad' filesep])) || ...
         ~isempty(strfind(lower(contexto),'sens_'));
      if tf,return;endif
    endfor
  catch
    tf=false;
  end_try_catch
endfunction

function titulo=titulo_figura_local(fig)
  titulo='Grafico de sensibilidad';
  try
    axes_list=findall(fig,'type','axes');
    candidatos={};
    for k=1:numel(axes_list)
      h=get(axes_list(k),'title');s=get(h,'string');
      if ischar(s)&&~isempty(strtrim(s)),candidatos{end+1}=strtrim(s);endif
    endfor
    if ~isempty(candidatos)
      % findall suele devolver los subplots en orden inverso; combinar evita
      % perder identidad cuando dos figuras comparten un titulo parcial.
      titulo=strjoin(fliplr(candidatos),' / ');
    endif
  catch
  end_try_catch
endfunction

function s=limpiar_id_local(txt)
  if ~ischar(txt),txt='grafico';endif
  s=lower(regexprep(txt,'[^A-Za-z0-9]+','_'));
  s=regexprep(s,'^_+|_+$','');if isempty(s),s='grafico';endif
endfunction

