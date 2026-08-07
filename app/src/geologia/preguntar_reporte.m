function preguntar_reporte(Ql, param)
  % Pregunta si se desea un reporte geologico tras una simulacion.
  % AOS 0.0.11: si el .aosdat trae punzados/geologia en param pero la
  % variable global aun no esta poblada, se hidrata antes de decidir.

  if nargin < 2 || isempty(param), param = struct(); end
  global geologia;

  if (isempty(geologia) || ~isstruct(geologia)) && isstruct(param)
      if isfield(param, 'geologia') && isstruct(param.geologia) && ~isempty(fieldnames(param.geologia))
          geologia = param.geologia;
      end
  end

  if isempty(geologia) || ~isstruct(geologia)
      return;
  end

  if aos_preguntar_sn('Generar reporte de geologia? (s/n) [n]: ', false)
      reporte_alerta(Ql, geologia, param);
  end
end
