function conf = aos_evaluar_confianza_geologica(geol)
% Evalua procedencia y suficiencia de la geologia para uso operativo.
% No bloquea el analisis: clasifica confianza y habilita modelo generico.
  if nargin < 1 || ~isstruct(geol), geol = struct(); end
  conf = struct('puntaje',0,'nivel','BAJA / GENERICA','tipo','MODELO_GENERICO', ...
                'uso_operativo',false,'campos_estimados',{{}},'campos_presentes',{{}}, ...
                'advertencias',{{}});
  if isfield(geol,'aos_campos_estimados') && iscell(geol.aos_campos_estimados)
      conf.campos_estimados = geol.aos_campos_estimados;
  end
  esenciales = {'permeabilidad_h','permeabilidad_v','porosidad','espesor_zona_petrolera', ...
                'altura_perforados','radio_drenaje','radio_pozo','skin_factor', ...
                'rho_petroleo','rho_agua','mu_petroleo','B_o'};
  n=0;
  for i=1:length(esenciales)
      c=esenciales{i};
      if isfield(geol,c) && isnumeric(geol.(c)) && isscalar(geol.(c)) && isfinite(geol.(c))
          n=n+1; conf.campos_presentes{end+1}=c;
      end
  end
  conf.puntaje = round(100*n/length(esenciales));
  sintetica = false;
  campos_txt={'tipo_dato','confianza_geologia','comentario'};
  for i=1:length(campos_txt)
      if isfield(geol,campos_txt{i}) && ischar(geol.(campos_txt{i}))
          t=upper(geol.(campos_txt{i}));
          if ~isempty(strfind(t,'SINTET')) || ~isempty(strfind(t,'ANALOG')) || ~isempty(strfind(t,'GENERIC')) || ~isempty(strfind(t,'BAJA'))
              sintetica=true;
          end
      end
  end
  if sintetica || length(conf.campos_estimados) >= 5
      conf.nivel='BAJA / GENERICA'; conf.tipo='MODELO_GENERICO'; conf.uso_operativo=false;
      conf.puntaje=min(conf.puntaje,45);
  elseif length(conf.campos_estimados) >= 2
      conf.nivel='MEDIA'; conf.tipo='MODELO_MIXTO'; conf.uso_operativo=false;
      conf.puntaje=min(max(conf.puntaje,46),74);
  else
      conf.nivel='ALTA'; conf.tipo='MODELO_ESPECIFICO'; conf.uso_operativo=true;
      conf.puntaje=max(conf.puntaje,75);
  end
  if ~conf.uso_operativo
      conf.advertencias{end+1}='Resultado orientativo para screening; no usar como limite operativo definitivo.';
  end
end
