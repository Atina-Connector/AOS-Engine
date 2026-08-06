function valvula = cargar_valvula(codigo)
  % Carga los datos de una válvula desde el catálogo config/GL/valvulas.txt
  % Entrada: codigo (string, ej. 'V-IPO-12')
  % Salida: estructura con campos: diam_orificio_m, R_fuelle, pres_max_domo_Pa

  archivo = 'config/GL/valvulas.txt';
  fid = fopen(archivo, 'r');
  if fid == -1
      error('No se pudo abrir el catálogo de válvulas: %s', archivo);
  end

  % Ignorar líneas de comentario y encabezado
  while ~feof(fid)
      linea = fgetl(fid);
      if isempty(linea) || linea(1) == '#'
          continue;
      end
      % Buscar el código en la línea
      if aos_starts_with(strtrim(linea), codigo)
          partes = strsplit(strtrim(linea));
          if numel(partes) >= 4
              valvula.diam_orificio_m = str2double(partes{2}) / 1000;   % mm -> m
              valvula.R_fuelle = str2double(partes{3});
              valvula.pres_max_domo_Pa = str2double(partes{4}) * 1e5;   % bar -> Pa
              fclose(fid);
              return;
          end
      end
  end
  fclose(fid);
  error('Válvula no encontrada en el catálogo: %s', codigo);
end
