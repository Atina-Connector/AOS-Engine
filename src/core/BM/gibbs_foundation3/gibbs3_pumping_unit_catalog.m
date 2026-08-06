function catalogo = gibbs3_pumping_unit_catalog(ruta)
% GIBBS3_PUMPING_UNIT_CATALOG Lee el catalogo AOS de aparatos de bombeo.
% El catalogo base contiene carrera, velocidad y torque. Las capacidades
% que no existen en el archivo quedan en NaN y se informan como no evaluadas.

  script_dir = fileparts(mfilename('fullpath'));
  raiz = fileparts(fileparts(fileparts(fileparts(script_dir))));
  if nargin < 1 || isempty(ruta)
    ruta = fullfile(raiz, 'config', 'BM', 'unidades.txt');
  elseif exist(ruta, 'file') ~= 2
    candidata = fullfile(raiz, ruta);
    if exist(candidata, 'file') == 2
      ruta = candidata;
    end
  end

  catalogo = struct('fabricante', {}, 'modelo', {}, 'tipo', {}, ...
    'carrera_max_m', {}, 'spm_min', {}, 'spm_max', {}, ...
    'torque_max_kNm', {}, 'carga_pr_max_kN', {}, 'potencia_motor_kW', {}, ...
    'peso_kg', {}, 'modelo_cinematico', {}, 'geometria_disponible', {}, ...
    'origen', {});

  if exist(ruta, 'file') == 2
    fid = fopen(ruta, 'r');
    if fid >= 0
      cleaner = onCleanup(@() fclose(fid));
      while true
        linea = fgetl(fid);
        if ~ischar(linea), break; end
        linea = strtrim(linea);
        if isempty(linea) || linea(1) == '#', continue; end
        partes = strsplit(linea, ',');
        if numel(partes) < 6, continue; end
        modelo = strtrim(partes{1});
        tipo = strtrim(partes{2});
        carrera = str2double(strtrim(partes{3}));
        spmmax = str2double(strtrim(partes{4}));
        torque_klb_in = str2double(strtrim(partes{5}));
        peso = str2double(strtrim(partes{6}));
        if any(~isfinite([carrera, spmmax, torque_klb_in, peso]))
          continue;
        end
        item = crear_item(modelo, tipo, carrera, spmmax, ...
          torque_klb_in, peso, ruta);
        catalogo(end+1) = item;
      end
    end
  end

  if isempty(catalogo)
    catalogo = catalogo_respaldo();
  end
end

function item = crear_item(modelo, tipo, carrera, spmmax, torque_klb_in, peso, origen)
  item = struct();
  item.fabricante = 'CATALOGO_AOS';
  item.modelo = modelo;
  item.tipo = tipo;
  item.carrera_max_m = carrera;
  item.spm_min = 1.0;
  item.spm_max = spmmax;
  item.torque_max_kNm = torque_klb_in * 0.112984829;
  item.carga_pr_max_kN = NaN;
  item.potencia_motor_kW = NaN;
  item.peso_kg = peso;
  [item.modelo_cinematico, item.geometria_disponible] = modelo_por_tipo(tipo);
  item.origen = origen;
end

function [modelo, geo] = modelo_por_tipo(tipo)
  t = lower(strtrim(tipo));
  geo = 0;
  if ~isempty(strfind(t, 'reverse')) || ~isempty(strfind(t, 'revers'))
    modelo = 'perfil_reverse_mark_representativo';
  elseif ~isempty(strfind(t, 'mark'))
    modelo = 'perfil_markii_representativo';
  elseif ~isempty(strfind(t, 'rota')) || ~isempty(strfind(t, 'carrera'))
    modelo = 'perfil_carrera_larga';
  elseif ~isempty(strfind(t, 'hidrau'))
    modelo = 'perfil_hidraulico_suave';
  else
    modelo = 'perfil_convencional_representativo';
  end
end

function c = catalogo_respaldo()
  c = struct('fabricante', {}, 'modelo', {}, 'tipo', {}, ...
    'carrera_max_m', {}, 'spm_min', {}, 'spm_max', {}, ...
    'torque_max_kNm', {}, 'carga_pr_max_kN', {}, 'potencia_motor_kW', {}, ...
    'peso_kg', {}, 'modelo_cinematico', {}, 'geometria_disponible', {}, ...
    'origen', {});
  c(end+1) = crear_item('AOS-CONV-REF', 'Convencional', 4.0, 20, 500, 30000, 'FALLBACK');
  c(end+1) = crear_item('AOS-MARKII-REF', 'MarkII', 5.5, 15, 900, 50000, 'FALLBACK');
  c(end+1) = crear_item('AOS-LONG-REF', 'Rotaflex', 6.0, 12, 800, 42000, 'FALLBACK');
  c(end+1) = crear_item('AOS-HYD-REF', 'Hidraulico', 5.0, 10, 400, 35000, 'FALLBACK');
end
