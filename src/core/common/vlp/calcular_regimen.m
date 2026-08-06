function regimen = calcular_regimen(vsg, vsl, d, rho_g, rho_l, sigma, mu_l, inclinacion_rad)
  % calcular_regimen.m
  % Clasificador diagnostico de regimen de flujo bifasico para el modulo
  % comun de tuberia.
  %
  % Convencion AOS para el survey:
  %   0 grados  = vertical
  %   90 grados = horizontal
  %
  % Importante:
  %   Es un criterio Taitel-Dukler simplificado/orientativo para graficos y
  %   alertas operativas. No reemplaza las correlaciones VLP HB/DR.

  if nargin < 8 || isempty(inclinacion_rad), inclinacion_rad = 0; end
  if nargin < 7 || isempty(mu_l), mu_l = 0.001; end
  if nargin < 6 || isempty(sigma), sigma = 0.030; end

  g = 9.81;
  vsg = max(vsg, 0);
  vsl = max(vsl, 0);
  d = max(d, 1e-4);
  rho_g = max(rho_g, 0.01);
  rho_l = max(rho_l, rho_g + 0.01);
  sigma = max(sigma, 1e-6);
  mu_l = max(mu_l, 1e-6);

  inc_deg = rad2deg(inclinacion_rad);   % desde vertical
  inc_deg = max(min(inc_deg, 90), 0);

  vm = vsg + vsl;
  if vm <= 1e-9
      regimen = 'desconocido';
      return;
  end

  lambda_g = vsg / vm;
  v_ref = sqrt(g * d);
  Fr_g = vsg / max(v_ref, eps);
  Fr_m = vm / max(v_ref, eps);

  % Correccion suave por inclinacion: en tramos mas desviados aparece slug
  % con velocidades de gas algo mayores.
  factor_desvio = 1 + 0.35 * sin(deg2rad(inc_deg));

  % Zona de burbuja: gas bajo y liquido dominante.
  if vsg < max(0.25, 0.45 * vsl) && lambda_g < 0.35
      regimen = 'burbuja';
      return;
  end

  if inc_deg < 60
      % Vertical/inclinado: separa slug de churn/transicion con Froude y Vsg.
      limite_slug = factor_desvio * max(3.2 + 1.8 * vsl, 4.0 * v_ref);
      limite_niebla = max(12.0 + 3.0 * vsl, 14.0 * v_ref);

      if vsg < limite_slug || Fr_g < 4.0
          if vsg < 1.0 && vsl > 0.25 && inc_deg > 25
              regimen = 'slug_severo';
          else
              regimen = 'slug';
          end
      elseif vsg < limite_niebla || Fr_m < 14.0
          regimen = 'transicion';
      else
          regimen = 'niebla';
      end
  else
      % Muy desviado/cercano a horizontal. Sin categoria estratificado en AOS,
      % se agrupa como slug/transicion segun gas y Froude.
      limite_slug = factor_desvio * max(2.5 + 2.5 * vsl, 5.5 * v_ref);
      limite_niebla = max(10.0 + 4.0 * vsl, 16.0 * v_ref);

      if vsg < limite_slug
          if vsl > 0.35 && vsg < 1.2
              regimen = 'slug_severo';
          else
              regimen = 'slug';
          end
      elseif vsg < limite_niebla
          regimen = 'transicion';
      else
          regimen = 'niebla';
      end
  end
end
