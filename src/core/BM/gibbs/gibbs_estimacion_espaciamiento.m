function esp = gibbs_estimacion_espaciamiento(param, metricas, cartas, malla)
  % Estimacion preliminar de espaciamiento de bomba.
  % Resultado positivo = levantar/espaciar hacia arriba esa distancia aproximada.
  margen_min = leer_campo(param, 'margen_espaciamiento_min_m', 0.15);
  margen_max = leer_campo(param, 'margen_espaciamiento_max_m', 0.60);
  golpe_fluido = detectar_golpe_fluido(cartas.carta_fondo);
  carrera_fondo = metricas.stroke_fondo_m;

  rec = margen_min;
  criterio = 'normal';
  if golpe_fluido.indice > 0.35
      rec = min(max(0.10 + 0.25*golpe_fluido.indice*carrera_fondo, margen_min), margen_max);
      criterio = 'posible_golpe_fluido';
  end
  if metricas.relacion_stroke_fondo < 0.65
      rec = max(rec, 0.25);
      criterio = 'baja_carrera_fondo_revisar_elasticidad_o_espaciamiento';
  end

  esp = struct();
  esp.recomendacion_m = rec;
  esp.criterio = criterio;
  esp.golpe_fluido_indice = golpe_fluido.indice;
  esp.golpe_fluido_md = golpe_fluido.descripcion;
  esp.margen_min_m = margen_min;
  esp.margen_max_m = margen_max;
  esp.nota = 'Estimacion preliminar. Validar con carta real, nivel y condiciones de bomba.';
end

function g = detectar_golpe_fluido(carta)
  pos = carta(:,1)'; carga = carta(:,2)';
  n = length(pos);
  if n < 20
      g.indice = 0; g.descripcion = 'sin_datos'; return;
  end
  % Golpe de fluido aproximado: caida brusca de carga en ultimo tramo de carrera descendente.
  [~, imax] = max(pos);
  [~, imin] = min(pos);
  if imax < imin
      idx = imax:imin;
  else
      idx = [imax:n, 1:imin];
  end
  if length(idx) < 5
      g.indice = 0; g.descripcion = 'no_detectado'; return;
  end
  c = carga(idx);
  dc = diff(c);
  caida = abs(min(dc));
  rango = max(carga) - min(carga);
  indice = caida / max(rango, 1);
  g.indice = min(max(indice,0),1);
  if g.indice > 0.35
      g.descripcion = 'posible_golpe_fluido';
  else
      g.descripcion = 'no_detectado';
  end
end

function v = leer_campo(s, campo, defecto)
  v = defecto;
  if isstruct(s) && isfield(s, campo)
      tmp = s.(campo);
      if isnumeric(tmp) && ~isempty(tmp) && isfinite(tmp(1))
          v = tmp(1);
      end
  end
end
