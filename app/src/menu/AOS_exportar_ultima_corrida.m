function AOS_exportar_ultima_corrida(tipos_permitidos)
% Exporta la ultima corrida, opcionalmente restringida por sistema.
global ULTIMO_QL ULTIMO_TIPO;
if isempty(ULTIMO_QL)
    fprintf('No hay resultados recientes. Ejecute una simulacion primero.\n');
    return;
end
if nargin >= 1 && ~isempty(tipos_permitidos)
    if isempty(ULTIMO_TIPO) || ~any(strcmpi(ULTIMO_TIPO, tipos_permitidos))
        fprintf('La ultima corrida no pertenece a este grupo de sistemas.\n');
        return;
    end
end
preguntar_exportar_aosrpt;
end
