function aos_menu_imprimir_ultima_corrida(p, Ql, Qo, Qiny, tipo)
% Resumen transversal de la ultima corrida efectiva.
fprintf('\n*** ULTIMA CORRIDA EFECTIVA ***\n');
fprintf('   Sistema          : %s\n', texto(tipo));
fprintf('   Ql efectivo      : %s\n', aos_formato_caudal_liquido(Ql));
fprintf('   Qo efectivo      : %s\n', aos_formato_caudal_liquido(Qo));
if any(strcmpi(tipo, {'GL','JGL'}))
    fprintf('   Qiny efectivo    : %s\n', aos_formato_caudal_gas(Qiny));
elseif strcmpi(tipo,'CGF') && isfield(p,'cgf_ultima_Qg_Sm3_d')
    fprintf('   Qg efectivo      : %.0f Sm3/d\n', p.cgf_ultima_Qg_Sm3_d);
elseif strcmpi(tipo,'EGF') && isfield(p,'egf_ultima_Qs_Sm3_d')
    fprintf('   Gas aspirado     : %.0f Sm3/d\n', p.egf_ultima_Qs_Sm3_d);
    if isfield(p,'egf_ultima_Qm_Sm3_d'), fprintf('   Gas motriz       : %.0f Sm3/d\n', p.egf_ultima_Qm_Sm3_d); end
end
if isfield(p, 'qiny_modo'), fprintf('   Modo Qiny        : %s\n', texto(p.qiny_modo)); end
if isfield(p, 'IP'), fprintf('   IP efectivo      : %.3f m3/d/bar\n', p.IP * 86400 * 1e5); end
if isfield(p, 'P_wh'), fprintf('   P_wh efectiva    : %s\n', aos_formato_presion(p.P_wh, 1)); end
if isfield(p, 'P_iny_sup') && any(strcmpi(tipo, {'GL','JGL'}))
    fprintf('   P_iny efectiva   : %s\n', aos_formato_presion(p.P_iny_sup, 1));
end
if any(strcmpi(tipo, {'GL','JGL'})) && isfield(p, 'D_iny')
    fprintf('   Prof. efectiva   : %s [inyeccion]\n', aos_formato_longitud(p.D_iny, 1));
elseif strcmpi(tipo,'CGF') && isfield(p,'D_cgf')
    fprintf('   Prof. efectiva   : %s [compresor CGF]\n', aos_formato_longitud(p.D_cgf, 1));
elseif strcmpi(tipo,'EGF') && isfield(p,'D_egf')
    fprintf('   Prof. efectiva   : %s [eyector EGF]\n', aos_formato_longitud(p.D_egf, 1));
elseif isfield(p, 'D_bomba')
    fprintf('   Prof. efectiva   : %s [bomba]\n', aos_formato_longitud(p.D_bomba, 1));
end
end

function s = texto(x)
[s, ok] = aos_texto_seguro(x, '<estructura>');
if ~ok, s = '<estructura>'; end
end
