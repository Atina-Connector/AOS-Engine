function [P_d, deltaP_eductor, detalle] = eductor_jgl(P_s, P_m, Q_l, m_dot_m, param, P_base, Qiny_MMscfd)
% eductor_jgl.m - Presion de descarga del eductor JGL.
%
% AOS 0.0.11 - Formulacion GL + trabajo del eductor:
%   P_d = P_s + DeltaP_eductor
%   DeltaP_eductor >= 0 para gas motriz disponible.
%
% SENS-GLJGL-03 separa explicitamente la condicion motriz:
%   DERIVADA_DESDE_QINY  -> usa el diferencial minimo de tobera para Qiny.
%   PRESION_DISPONIBLE   -> usa el diferencial realmente disponible.
%   SIN_PRESION_MOTRIZ   -> no transfiere trabajo.
%   AUTO_LEGACY          -> conserva max(disponible,cinetico) solo por legado.
%
% Si Q_iny = 0, m_dot_m = 0 y DeltaP_eductor = 0. En ese limite JGL
% degenera a GL/flujo base. No se usa ningun piso hardcodeado contra GL.

    if nargin < 3 || isempty(Q_l), Q_l = 0; end
    if nargin < 4 || isempty(m_dot_m), m_dot_m = 0; end
    if nargin < 5 || isempty(param), param = struct(); end

    Q_l = max(Q_l, 0);
    if isempty(P_s) || ~isfinite(P_s), P_s = 1e5; end
    P_s = max(P_s, 1e5);
    if isempty(P_m) || ~isfinite(P_m), P_m = P_s; end

    deltaP_eductor = 0;
    detalle = struct();
    detalle.P_s = P_s;
    detalle.P_m_original = P_m;
    detalle.m_dot_m = m_dot_m;
    detalle.deltaP_eductor = 0;
    detalle.deltaP_motriz = 0;
    detalle.deltaP_cinetico = 0;
    detalle.deltaP_base = 0;
    detalle.delta_p_adim = 0;
    detalle.M = Inf;
    detalle.estado = 'SIN_GAS_MOTRIZ';
    detalle.origen_deltaP = 'ninguno';
    detalle.modo_condicion_motriz = jgl_modo_condicion_motriz(param);

    if m_dot_m <= 1e-12
        P_d = P_s;
        deltaP_eductor = 0;
        return;
    end

    [a, b] = coeficientes_eductor(param);

    rho_o = leer_num(param, {'rho_o'}, 850);
    rho_w = leer_num(param, {'rho_w'}, 1000);
    WC = leer_num(param, {'WC'}, 0);
    WC = min(max(WC, 0), 1);
    rho_l = rho_o * (1 - WC) + rho_w * WC;
    rho_l = max(rho_l, 1);

    m_dot_s = Q_l * rho_l;
    M = m_dot_s / max(m_dot_m, 1e-12);

    % Transferencia continua: no existe un corte artificial a-b*M=0.
    % a define la capacidad asintotica y b la degradacion con carga aspirada.
    delta_p_adim = a / max(1 + b * max(M,0), 1);
    delta_p_adim = min(max(delta_p_adim, 0), 0.95);

    % 1) Presion motriz disponible en el punto del eductor.
    deltaP_motriz = max(P_m - P_s, 0);

    % 2) Diferencial minimo asociado al Qiny impuesto y la tobera.
    rho_g_std = leer_num(param, {'rho_g_std'}, 0.8);
    Qiny_std = m_dot_m / max(rho_g_std,1e-12);
    [deltaP_cinetico, det_tobera] = jgl_deltaP_cinetica_qiny(P_s,Qiny_std,param);
    if ~isfinite(deltaP_cinetico), deltaP_cinetico = 0; end

    modo_motriz = jgl_modo_condicion_motriz(param);
    if strcmp(modo_motriz,'DERIVADA_DESDE_QINY')
        deltaP_base = deltaP_cinetico;
        origen = 'qiny_impuesto_cinetico_explicito';
    elseif strcmp(modo_motriz,'PRESION_DISPONIBLE')
        deltaP_base = deltaP_motriz;
        origen = 'presion_motriz_disponible';
    elseif strcmp(modo_motriz,'AUTO_LEGACY')
        if deltaP_motriz >= deltaP_cinetico
            deltaP_base = deltaP_motriz;
            origen = 'auto_legacy_presion_motriz';
        else
            deltaP_base = deltaP_cinetico;
            origen = 'auto_legacy_qiny_cinetico';
        end
    else
        deltaP_base = 0;
        origen = 'sin_presion_motriz';
    end

    deltaP_eductor = max(delta_p_adim * max(deltaP_base, 0), 0);
    P_d = P_s + deltaP_eductor;

    detalle.P_m_efectiva = P_s + deltaP_base;
    detalle.deltaP_motriz = deltaP_motriz;
    detalle.deltaP_cinetico = deltaP_cinetico;
    detalle.deltaP_base = deltaP_base;
    detalle.deltaP_eductor = deltaP_eductor;
    detalle.delta_p_adim = delta_p_adim;
    detalle.M = M;
    detalle.origen_deltaP = origen;
    detalle.modo_condicion_motriz = modo_motriz;
    detalle.tobera = det_tobera;
    if deltaP_base <= 0 || delta_p_adim <= 0
        detalle.estado = 'SIN_TRABAJO_TRANSFERIDO';
    else
        detalle.estado = 'OK';
    end
end

function [a, b] = coeficientes_eductor(param)
    modo = 'derivada';
    if isstruct(param) && isfield(param,'jgl_geometria_modo') && ischar(param.jgl_geometria_modo)
        modo = lower(strtrim(param.jgl_geometria_modo));
    end
    if strcmp(modo,'calibrada')
        a = leer_num(param, {'a_eductor'}, 0.01);
        b = leer_num(param, {'b_eductor'}, 0.005);
    else
        A_n = leer_num(param, {'A_n'}, 12e-6);
        d_t = leer_num(param, {'d_t'}, 0.038);
        A_t = pi * (max(d_t,1e-9) / 2)^2;
        R_area = A_t / max(A_n, 1e-12);
        a = 0.0020 * R_area;
        b = 0.00010 * R_area;
    end
    a = max(a, 0);
    b = max(b, 0);
end

function v = leer_num(s, nombres, defecto)
  v = defecto;
  if ~isstruct(s), return; end
  for k = 1:length(nombres)
      nombre = nombres{k};
      if isfield(s, nombre)
          tmp = s.(nombre);
          if isnumeric(tmp) && ~isempty(tmp)
              v = tmp(1);
              return;
          end
      end
  end
end
