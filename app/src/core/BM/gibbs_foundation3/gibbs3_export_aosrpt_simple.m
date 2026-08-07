function archivo = gibbs3_export_aosrpt_simple(contexto, archivo)
% GIBBS3_EXPORT_AOSRPT_SIMPLE Informe simple GF3 reconstruible.

  if nargin < 2 || ~ischar(archivo) || isempty(archivo)
    error('Debe indicarse el archivo de salida del informe GF3.');
  end
  if ~isfield(contexto, 'resultado') || ~isstruct(contexto.resultado)
    error('El contexto no contiene resultado GF3.');
  end

  [ruta, nombre, ext] = fileparts(archivo);
  if isempty(ext), ext = '.aosrpt'; end
  if isempty(ruta), ruta = pwd(); end
  if exist(ruta, 'dir') ~= 7, mkdir(ruta); end
  archivo = fullfile(ruta, [nombre ext]);

  p = contexto.param;
  if ~isfield(p,'aosrpt_es_enriquecido'),p.aosrpt_es_enriquecido=false;endif
  p.aosrpt_omitir_crypto = true;
  p.aosrpt_omitir_mensaje = true;
  exportar_aosrpt(p, contexto.Ql, contexto.Qo, contexto.Qiny, 'BM', archivo);
  gibbs3_report_append_sections(archivo, contexto.resultado, 'SIMPLE');

  if exist(archivo, 'file') ~= 2
    error('No se creo el informe GF3 simple: %s', archivo);
  end
end
