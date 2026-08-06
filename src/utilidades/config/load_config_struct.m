function param = load_config_struct(filename)
  % Lee archivos de configuración con campos anidados.
  % Ejemplo:
  %   pozo.D_res = 3000
  % se guarda como:
  %   param.pozo.D_res

  fid = fopen(filename, 'r');
  if fid == -1
    error('No se pudo abrir el archivo %s', filename);
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

    pos_hash = strfind(linea, '#');
    if ~isempty(pos_hash)
      linea = strtrim(linea(1:pos_hash(1)-1));
    end
    if isempty(linea)
      continue;
    end

    pos_eq = strfind(linea, '=');
    if isempty(pos_eq)
      continue;
    end

    nombre = strtrim(linea(1:pos_eq(1)-1));
    valor_str = strtrim(linea(pos_eq(1)+1:end));

    valor = parsear_valor_local(valor_str);

    partes = strsplit(nombre, '.');
    param = setfield_nested(param, partes, valor);
  end

  fclose(fid);
end

function s = setfield_nested(s, partes, valor)
  % Crea estructuras internas según sea necesario.
  if numel(partes) == 1
    s.(partes{1}) = valor;
  else
    campo = partes{1};
    if ~isfield(s, campo) || ~isstruct(s.(campo))
      s.(campo) = struct();
    end
    s.(campo) = setfield_nested(s.(campo), partes(2:end), valor);
  end
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
