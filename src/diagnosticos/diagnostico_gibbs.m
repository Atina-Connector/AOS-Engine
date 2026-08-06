% diagnostico_gibbs.m
% Diagnostico rapido de Bombeo Mecanico con Gibbs/onda AOS v11.

iniciar_aos;
[param, origen_config] = aos_config_base('BM');
fprintf('Usando %s.\n', origen_config);

[Ql, Qo, potencia, diagnostico, detalle_bm] = BM_core(param);
if Ql <= 0
    error('BM_core devolvio caudal nulo. No se puede generar diagnostico Gibbs. %s', diagnostico);
end

if isfield(detalle_bm, 'varillas')
    varillas = detalle_bm.varillas;
else
    varillas = diseno_varillas(param, Ql);
end
param.varillas = varillas;
param.BM_resultado = detalle_bm;

opciones = struct();
opciones.graficar = true;
opciones.imprimir = true;
opciones.n_tabla = 50;
diag_gibbs = diagnostico_bm_gibbs(param, Ql, varillas, opciones);

fprintf('\nResumen BM / Gibbs v11:\n');
fprintf('  Ql              : %.2f m3/d\n', Ql*86400);
fprintf('  Qo              : %.2f m3/d\n', Qo*86400);
fprintf('  Potencia        : %.2f kW\n', potencia/1000);
fprintf('  Diagnostico     : %s\n', diagnostico);
fprintf('  Stroke sup.     : %.3f m\n', diag_gibbs.S_superficie_m);
fprintf('  Stroke fondo    : %.3f m\n', diag_gibbs.S_fondo_m);
fprintf('  Llenado         : %.1f %%\n', diag_gibbs.llenado_bomba*100);
fprintf('  Espaciamiento   : %.2f m\n', diag_gibbs.espaciamiento.recomendacion_m);
