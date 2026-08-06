function menu_sensibilidad_BES
  % Submenú de sensibilidades para BES

  while true
    fprintf('\n--- ANÁLISIS DE SENSIBILIDAD BES ---\n');
    fprintf(' 1 - Presión en cabeza (P_wh)\n');
    fprintf(' 2 - Frecuencia de operación\n');
    fprintf(' 3 - Sumergencia de la bomba\n');
    fprintf(' 4 - Run Life vs Potencia (frecuencia)\n');
    fprintf(' 5 - Número de etapas\n');
    fprintf(' 0 - Volver al menú principal\n');

    op = input('Seleccione una opción: ');

    switch op
      case 1
        if exist('sens_P_wh_BES', 'file')
          sens_P_wh_BES
        else
          fprintf('Módulo sens_P_wh_BES no encontrado.\n');
        end
      case 2
        if exist('sens_frecuencia_BES', 'file')
          sens_frecuencia_BES
        else
          fprintf('Módulo sens_frecuencia_BES no encontrado.\n');
        end
      case 3
        if exist('sens_sumergencia_BES', 'file')
          sens_sumergencia_BES
        else
          fprintf('Módulo sens_sumergencia_BES no encontrado.\n');
        end
      case 4
        if exist('sens_RunLife_BES', 'file')
          sens_RunLife_BES
        else
          fprintf('Módulo sens_RunLife_BES no encontrado.\n');
        end
         case 5
        if exist('sens_etapas_BES', 'file')
          sens_etapas_BES
        else
          fprintf('Módulo sens_etapas_BES no encontrado.\n');
        end
      case 0
        return;
      otherwise
        fprintf('Opción no válida.\n');
    end
  end
end
