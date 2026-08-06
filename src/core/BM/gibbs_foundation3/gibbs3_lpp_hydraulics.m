function lpp = gibbs3_lpp_hydraulics(param, bomba, velocidad_piston_m_s)
% GIBBS3_LPP_HYDRAULICS Perdida de carga instantanea en piston LPP AESIR.
% Modelo inicial auditable: Darcy-Weisbach + perdidas localizadas K.
% La fuerza firmada se opone al movimiento del piston.

  vrod = velocidad_piston_m_s;
  n = numel(vrod);
  lpp = struct();
  lpp.activa = logical(param.bomba_lpp);
  lpp.Q_m3_s = zeros(size(vrod));
  lpp.velocidad_interna_m_s = zeros(size(vrod));
  lpp.Re = zeros(size(vrod));
  lpp.factor_friccion_Darcy = zeros(size(vrod));
  lpp.deltaP_distribuida_Pa = zeros(size(vrod));
  lpp.deltaP_local_Pa = zeros(size(vrod));
  lpp.deltaP_total_Pa = zeros(size(vrod));
  lpp.F_magnitud_N = zeros(size(vrod));
  lpp.F_firmada_N = zeros(size(vrod));

  if ~lpp.activa
    return;
  end

  D = param.lpp_id_piston_mm / 1000.0;
  L = param.lpp_longitud_piston_m;
  Aflujo = pi * D^2 / 4.0;
  if isfinite(param.lpp_area_efectiva_m2)
    Aef = param.lpp_area_efectiva_m2;
  else
    Aef = bomba.area_piston_m2;
  end
  rho = bomba.rho_liquido_kg_m3;
  mu = param.viscosidad_fluido_cP * 1e-3;
  epsr = param.lpp_rugosidad_m / D;
  K = param.lpp_coef_perdidas_K;

  % Aproximacion volumetrica: caudal desplazado por el area del piston.
  % El signo se conserva para aplicar una fuerza resistente.
  Q = bomba.area_piston_m2 .* vrod;
  vint = Q ./ Aflujo;
  Re = rho .* abs(vint) .* D ./ max(mu, eps);
  f = zeros(size(Re));

  lam = Re > 0 & Re < 2300;
  f(lam) = 64 ./ Re(lam);
  turb = Re >= 2300;
  if any(turb(:))
    % Swamee-Jain, explicita y estable para rugosidad conocida.
    f(turb) = 0.25 ./ (log10(epsr/3.7 + 5.74 ./ (Re(turb).^0.9))).^2;
  end

  qdyn = 0.5 * rho .* vint.^2;
  dPd = f .* (L/D) .* qdyn;
  dPl = K .* qdyn;
  dPt = dPd + dPl;
  Fmag = dPt .* Aef;
  Fsig = sign(vrod) .* Fmag;

  lpp.Q_m3_s = Q;
  lpp.velocidad_interna_m_s = vint;
  lpp.Re = Re;
  lpp.factor_friccion_Darcy = f;
  lpp.deltaP_distribuida_Pa = dPd;
  lpp.deltaP_local_Pa = dPl;
  lpp.deltaP_total_Pa = dPt;
  lpp.F_magnitud_N = Fmag;
  lpp.F_firmada_N = Fsig;
  lpp.area_flujo_m2 = Aflujo;
  lpp.area_efectiva_m2 = Aef;
  lpp.longitud_piston_m = L;
  lpp.id_piston_m = D;
end
