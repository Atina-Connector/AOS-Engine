function p = aos_vlp_parametros(param)
% aos_vlp_parametros.m
% Normaliza parametros para motores VLP.
% AOS 0.0.11: no usa variables globales ni pregunta al usuario desde el
% motor. API/gamma_g provienen del caso activo o de defaults explicitos.

    if nargin < 1 || isempty(param), param = struct(); end

    if isfield(param, 'API') && isnumeric(param.API) && ~isempty(param.API)
        p.API = param.API(1);
    elseif isfield(param, 'rho_o') && isnumeric(param.rho_o) && ~isempty(param.rho_o)
        p.API = (141.5 / max(param.rho_o(1)/1000, 1e-9)) - 131.5;
    else
        p.API = 35;
    end

    if isfield(param, 'gamma_g') && isnumeric(param.gamma_g) && ~isempty(param.gamma_g)
        p.gamma_g = param.gamma_g(1);
    elseif isfield(param, 'rho_g_std') && isnumeric(param.rho_g_std) && ~isempty(param.rho_g_std)
        p.gamma_g = max(param.rho_g_std(1) / 1.225, 0.55);
    else
        p.gamma_g = 0.7;
    end

    p.P_wh      = getfield_opt(param, 'P_wh', 6e5);
    p.WC        = getfield_opt(param, 'WC', getfield_opt(param, 'fluidos.WC', 0.5));
    p.GLR       = getfield_opt(param, 'GLR', getfield_opt(param, 'fluidos.GLR', 0));
    p.rho_o     = getfield_opt(param, 'rho_o', getfield_opt(param, 'fluidos.rho_o', 850));
    p.rho_w     = getfield_opt(param, 'rho_w', getfield_opt(param, 'fluidos.rho_w', 1000));
    p.rho_g_std = getfield_opt(param, 'rho_g_std', getfield_opt(param, 'fluidos.rho_g_std', 0.8));
    p.diam_tbg  = getfield_opt(param, 'diam_tbg', getfield_opt(param, 'tubing.ID', 0.062));
    p.T_sup     = getfield_opt(param, 'T_sup', 298.15);
    p.T_fondo   = getfield_opt(param, 'T_fondo', 358.15);
    p.modelo_VLP = getfield_opt(param, 'modelo_VLP', 'simplified');
    p.factor_VLP = getfield_opt(param, 'factor_VLP', 1.0);
    p.Q_iny     = getfield_opt(param, 'Q_iny', getfield_opt(param, 'Qiny_vlp', 0));
    p.Qiny_vlp  = p.Q_iny;

    if isfield(param, 'P_b') && ~isempty(param.P_b)
        p.P_b = aos_presion_burbuja_pa(param.P_b, 100);
    end

    p.Z_gas     = getfield_opt(param, 'Z_gas', NaN);
    p.mu_w      = getfield_opt(param, 'mu_w', 0.001);
    p.mu_g      = getfield_opt(param, 'mu_g', 1.5e-5);
    p.P_std     = getfield_opt(param, 'P_std', 101325);
    p.T_std     = getfield_opt(param, 'T_std', 288.15);
    p.eps_abs   = getfield_opt(param, 'eps_abs', 1.5e-5);

    if isfield(param, 'survey')
        p.survey = param.survey;
    end

    p.WC = max(0, min(1, p.WC));
    p.gamma_g = max(p.gamma_g, 0.1);
    p.diam_tbg = max(p.diam_tbg, 1e-4);
    p.P_wh = max(p.P_wh, 1e4);
    p.T_sup = max(p.T_sup, 250);
    p.T_fondo = max(p.T_fondo, 250);
end

function val = getfield_opt(s, campo, defecto)
    val = defecto;
    if nargin < 3 || ~isstruct(s)
        return;
    end
    partes = strsplit(campo, '.');
    tmp = s;
    for i = 1:length(partes)
        if isstruct(tmp) && isfield(tmp, partes{i})
            tmp = tmp.(partes{i});
        else
            return;
        end
    end
    if ~isempty(tmp)
        val = tmp;
    end
end
