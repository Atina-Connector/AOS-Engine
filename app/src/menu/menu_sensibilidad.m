function menu_sensibilidad
  % Submenú de sensibilidades para AOS

  while true
    fprintf('\n--- ANÁLISIS DE SENSIBILIDAD ---\n');
    fprintf(' 1 - Caudal de gas inyectado (JGL)\n');
    fprintf(' 2 - Caudal de gas inyectado (GL)\n');
    fprintf(' 3 - Caudal de gas inyectado (JGL vs GL)\n');
    fprintf(' 4 - Presión de inyección\n');
    fprintf(' 5 - Profundidad del eductor / válvula\n');
    fprintf(' 6 - Área de salida de la tobera\n');
    fprintf(' 7 - Diámetro de garganta\n');
    fprintf(' 8 - Presión en cabeza\n');
    fprintf(' 9 - Balance energético (JGL vs GL)\n');
    fprintf(' 0 - Volver al menú principal\n');

    op = input('Seleccione una opción: ');

    switch op
      case 1
        if exist('sens_Qiny_JGL', 'file')
          sens_Qiny_JGL
        else
          fprintf('Módulo sens_Qiny_JGL no encontrado.\n');
        end
      case 2
        if exist('sens_Qiny_GL', 'file')
          sens_Qiny_GL
        else
          fprintf('Módulo sens_Qiny_GL no encontrado.\n');
        end
      case 3
        if exist('sens_Qiny', 'file')
          sens_Qiny
        else
          fprintf('Módulo sens_Qiny no encontrado.\n');
        end
      case 4
        if exist('sens_P_iny', 'file')
          sens_P_iny
        else
          fprintf('Módulo sens_P_iny no encontrado.\n');
        end
      case 5
        if exist('sens_D_bomba', 'file')
          sens_D_bomba
        else
          fprintf('Módulo sens_D_bomba no encontrado.\n');
        end
      case 6
        if exist('sens_A_n', 'file')
          sens_A_n
        else
          fprintf('Módulo sens_A_n no encontrado.\n');
        end
      case 7
        if exist('sens_d_t', 'file')
          sens_d_t
        else
          fprintf('Módulo sens_d_t no encontrado.\n');
        end
      case 8
        if exist('sens_P_wh', 'file')
          sens_P_wh
        else
          fprintf('Módulo sens_P_wh no encontrado.\n');
        end
      case 9
        if exist('sens_balance_energetico', 'file')
          sens_balance_energetico
        else
          fprintf('Módulo sens_balance_energetico no encontrado.\n');
        end
      case 0
        return;
      otherwise
        fprintf('Opción no válida.\n');
    end
  end
end
