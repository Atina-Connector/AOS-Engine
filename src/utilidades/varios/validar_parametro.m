function valor = validar_parametro(param, campo, descripcion, unidad, defecto)
% VALIDAR_PARAMETRO - Verifica si un campo existe en param. Si no, lo pide al usuario.
%
% Entradas:
%   param      : estructura de parámetros (puede ser vacía)
%   campo      : nombre del campo (ej: 'API')
%   descripcion: texto descriptivo para mostrar al usuario (ej: 'Gravedad API')
%   unidad     : unidad del parámetro (ej: '°API')
%   defecto    : valor por defecto (opcional). Si no se da, no hay valor por defecto.
%
% Salida:
%   valor      : el valor del campo (existente, ingresado por usuario, o defecto)

    % Si el campo ya existe en param, devolverlo
    if isfield(param, campo)
        valor = param.(campo);
        return;
    end

    % Si no existe, preguntar al usuario
    if nargin >= 5 && ~isempty(defecto)
        prompt = sprintf('  %s (%s) [%g]: ', descripcion, unidad, defecto);
        entrada = input(prompt, 's');
        if isempty(entrada)
            valor = defecto;
        else
            valor = str2double(entrada);
            if isnan(valor)
                fprintf('⚠️  Valor no válido. Usando valor por defecto: %g\n', defecto);
                valor = defecto;
            end
        end
    else
        prompt = sprintf('  %s (%s): ', descripcion, unidad);
        entrada = input(prompt, 's');
        if isempty(entrada)
            fprintf('⚠️  No se ingresó un valor. El programa no puede continuar sin %s.\n', descripcion);
            error('Falta el campo "%s" y no se proporcionó un valor.', campo);
        else
            valor = str2double(entrada);
            if isnan(valor)
                fprintf('⚠️  Valor no válido. Intente nuevamente.\n');
                valor = validar_parametro(param, campo, descripcion, unidad);
            end
        end
    end
end

