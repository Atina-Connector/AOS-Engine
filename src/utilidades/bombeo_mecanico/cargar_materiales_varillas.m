function materiales = cargar_materiales_varillas(archivo)
% cargar_materiales_varillas.m - Lee catalogo config/BM/materiales_varillas.txt
% con resolucion robusta de ruta desde cualquier carpeta de trabajo.

  if nargin < 1 || isempty(archivo)
      archivo = resolver_archivo_aos('config/BM/materiales_varillas.txt');
  elseif ~exist(archivo, 'file')
      archivo = resolver_archivo_aos(archivo);
  end

  if ~exist(archivo, 'file')
      error('No se encontro el archivo de materiales: %s', archivo);
  end

  fid = fopen(archivo, 'r');
  if fid == -1
      error('No se pudo abrir el archivo %s', archivo);
  end

  materiales = [];
  while ~feof(fid)
      linea = strtrim(fgetl(fid));
      if isempty(linea) || linea(1) == '#'
          continue;
      end
      partes = strsplit(linea, ',');
      if length(partes) >= 5
          mat = struct();
          mat.nombre = strtrim(partes{1});
          mat.densidad_kg_m3 = str2double(partes{2});
          mat.modulo_young_GPa = str2double(partes{3});
          mat.limite_fatiga_MPa = str2double(partes{4});
          mat.resistencia_ultima_MPa = str2double(partes{5});
          materiales = [materiales, mat];
      end
  end
  fclose(fid);

  if isempty(materiales)
      error('El catalogo de materiales BM esta vacio o mal formateado: %s', archivo);
  end
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
