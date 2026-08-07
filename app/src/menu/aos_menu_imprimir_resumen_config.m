function aos_menu_imprimir_resumen_config(cfg, nombre_archivo, geol)
% Resumen transversal de la configuracion base activa.
fprintf('\n*** CONFIGURACION BASE IMPORTADA (.aosdat, no es la ultima corrida) ***\n');
if ~isempty(nombre_archivo), fprintf('   Archivo .aosdat : %s\n', nombre_archivo); end
if isfield(cfg, 'nombre_pozo'), fprintf('   Pozo            : %s\n', texto(cfg.nombre_pozo)); end
if isfield(cfg, 'P_res'), fprintf('   P_res           : %s\n', aos_formato_presion(cfg.P_res, 1)); end
if isfield(cfg, 'P_b'), fprintf('   P_b             : %s\n', aos_formato_presion(cfg.P_b, 1)); end
if isfield(cfg, 'IP'), fprintf('   IP              : %.3f m3/d/bar\n', cfg.IP * 86400 * 1e5); end
if isfield(cfg, 'WC'), fprintf('   WC              : %.3f\n', cfg.WC); end
if isfield(cfg, 'GLR'), fprintf('   GLR             : %.2f Sm3/m3 liquido\n', cfg.GLR); end
if isfield(cfg, 'P_wh'), fprintf('   P_wh            : %s\n', aos_formato_presion(cfg.P_wh, 1)); end
if isfield(cfg, 'P_iny_sup'), fprintf('   P_iny_sup       : %s\n', aos_formato_presion(cfg.P_iny_sup, 1)); end
if isfield(cfg, 'D_iny')
    fprintf('   Prof. iny.      : %s\n', aos_formato_longitud(cfg.D_iny, 1));
elseif isfield(cfg, 'D_bomba')
    fprintf('   Prof. SLA       : %s\n', aos_formato_longitud(cfg.D_bomba, 1));
end
if isfield(cfg, 'D_res'), fprintf('   Prof. reserv.   : %s\n', aos_formato_longitud(cfg.D_res, 1)); end
if isfield(cfg, 'Q_iny'), fprintf('   Qiny            : %s\n', aos_formato_caudal_gas(cfg.Q_iny)); end
if isfield(cfg, 'modelo_IPR'), fprintf('   IPR             : %s\n', texto(cfg.modelo_IPR)); end
if isfield(cfg, 'modelo_VLP'), fprintf('   VLP             : %s\n', texto(cfg.modelo_VLP)); end

if isfield(cfg, 'survey') && isstruct(cfg.survey) && isfield(cfg.survey, 'MD')
    fprintf('   Survey          : cargado (%d puntos)\n', length(cfg.survey.MD));
else
    fprintf('   Survey          : no cargado\n');
end

n_punz = 0;
if isfield(cfg, 'punzados') && isstruct(cfg.punzados) && isfield(cfg.punzados, 'tramos')
    n_punz = length(cfg.punzados.tramos);
end
if isstruct(geol) && ~isempty(fieldnames(geol))
    fprintf('   Geologia        : cargada automaticamente\n');
else
    fprintf('   Geologia        : no cargada\n');
end
fprintf('   Punzados        : %d tramos\n', n_punz);
end

function s = texto(x)
[s, ok] = aos_texto_seguro(x, '<estructura>');
if ~ok, s = '<estructura>'; end
end
