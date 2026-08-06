function factor_IP = calc_factor_declinacion(archivo_csv, modelo)
  % Ajusta un modelo de declinación de Arps a datos históricos.
  % Entradas:
  %   archivo_csv : ruta al archivo con columnas: fecha, Ql (m³/d)
  %   modelo     : 'exponencial', 'hiperbolico', 'armonico'
  % Salida:
  %   factor_IP  : IP_actual / IP_inicial estimado

  % Leer datos
  data = csvread(archivo_csv, 1, 0);   % salta la primera línea (encabezado)
  t = data(:,1);   % tiempo (días desde inicio o fecha convertida)
  q = data(:,2);   % caudal de líquido (m³/d)

  % Ajustar según modelo
  switch modelo
      case 'exponencial'
          % q(t) = qi * exp(-D*t)
          p = polyfit(t, log(q), 1);
          D = -p(1);
          qi = exp(p(2));
      case 'hiperbolico'
          % (1+q/q_i)^b ...
          warning('Modelo hiperbólico requiere optimización no lineal. Se usará exponencial.');
          p = polyfit(t, log(q), 1);
          D = -p(1);
          qi = exp(p(2));
      case 'armonico'
          % q(t) = qi / (1 + D*t)
          p = polyfit(t, 1./q, 1);
          D = p(1) / p(2);
          qi = 1/p(2);
      otherwise
          error('Modelo no reconocido.');
  end

  % Calcular factor de IP residual (suponiendo IP proporcional a q)
  q_actual = qi * exp(-D * t(end));   % caudal estimado al final del histórico
  factor_IP = q_actual / qi;

  fprintf('Factor de IP residual estimado: %.3f (qi=%.2f, D=%.4f)\n', factor_IP, qi, D);
end
