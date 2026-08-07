function preguntar_exportar_grafico(datos, tipo_modulo)
  % Pregunta si se desea exportar un reporte enriquecido del gráfico actual.
  % Entradas:
  %   datos      : estructura con los datos del módulo.
  %   tipo_modulo: string ('SENSIBILIDAD_JGL_QINY', 'MANDRILES', 'SURVEY', etc.)

  if aos_preguntar_sn('Exportar reporte enriquecido de este modulo? (s/n) [n]: ', false)
      exportar_aosrpt_grafico(datos, tipo_modulo);
  end
end
