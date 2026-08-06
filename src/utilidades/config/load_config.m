
function param = load_config(filename)
  % Lee archivos de configuración con formato: nombre = valor
  % Ignora comentarios con # y líneas vacías.
  % Si el valor se puede convertir a número, lo guarda como número.
  % Si no, lo guarda como texto.

  fid = fopen(filename, 'r');
  if fid == -1
    error('No se pudo abrir %s', filename);
  end

  param = struct();

  while ~feof(fid)
    linea = fgetl(fid);
    if ~ischar(linea)
      continue;
    end

    linea = strtrim(linea);
    if isempty(linea) || linea(1) == '#'
      continue;
    end

    % Eliminar comentarios al final de la línea.
    pos_hash = strfind(linea, '#');
    if ~isempty(pos_hash)
      linea = strtrim(linea(1:pos_hash(1)-1));
    end
    if isempty(linea)
      continue;
    end

    % Separar nombre y valor por el primer signo igual.
    pos_eq = strfind(linea, '=');
    if isempty(pos_eq)
      continue;
    end

    nombre = strtrim(linea(1:pos_eq(1)-1));
    valor_str = strtrim(linea(pos_eq(1)+1:end));

    if isempty(nombre)
      continue;
    end

    % Si el valor está entre comillas, quitarlas.
    if length(valor_str) >= 2
      if (valor_str(1) == '"' && valor_str(end) == '"') || ...
         (valor_str(1) == '''' && valor_str(end) == '''')
        valor_str = valor_str(2:end-1);
      end
    end

    % Parseo seguro: escalares y vectores numericos sin evaluar codigo.
    param.(nombre) = parsear_valor_local(valor_str);
  end

  fclose(fid);
end

function valor = parsear_valor_local(texto)
  valor = aos_parse_valor(texto);
  [v, ok] = aos_vector_seguro(texto, []);
  if ok && es_lista_explicita_local(texto, v)
    valor = v;
  endif
endfunction

function tf = es_lista_explicita_local(texto, v)
  t = strtrim(texto);
  tf = numel(v) > 1 || ~isempty(strfind(t, ',')) || ...
       ~isempty(strfind(t, ';')) || ...
       (~isempty(t) && any(t(1) == '[({'));
endfunction
