function catalogo = cargar_catalogo_bm(archivo)
% cargar_catalogo_bm.m - Lee catalogo de unidades BM desde config/BM/unidades.txt.

  if nargin < 1 || isempty(archivo)
      archivo = resolver_archivo_aos('config/BM/unidades.txt');
  elseif ~exist(archivo, 'file')
      archivo = resolver_archivo_aos(archivo);
  end

  if ~exist(archivo, 'file')
      error('No se encontro el archivo de catalogo: %s', archivo);
  end

  fid = fopen(archivo, 'r');
  if fid == -1
      error('No se pudo abrir el archivo %s', archivo);
  end

  catalogo = [];
  while ~feof(fid)
      linea = strtrim(fgetl(fid));
      if isempty(linea) || linea(1) == '#'
          continue;
      end
      partes = strsplit(linea, ',');
      if length(partes) >= 5
          unidad = struct();
          unidad.modelo = strtrim(partes{1});
          unidad.tipo = strtrim(partes{2});
          unidad.carrera_max_m = str2double(partes{3});
          unidad.vel_max_gpm = str2double(partes{4});
          unidad.torque_max_klb_in = str2double(partes{5});
          if length(partes) >= 6
              unidad.peso_kg = str2double(partes{6});
          else
              unidad.peso_kg = NaN;
          end
          catalogo = [catalogo, unidad];
      end
  end
  fclose(fid);
end

function ruta = resolver_archivo_aos(rel)
  if exist(rel, 'file')
      ruta = rel;
      return;
  end
  try
      este = fileparts(mfilename('fullpath'));
      raiz = fileparts(fileparts(fileparts(este)));
      cand = fullfile(raiz, rel);
      if exist(cand, 'file')
          ruta = cand;
          return;
      end
  catch
  end
  ruta = rel;
end
