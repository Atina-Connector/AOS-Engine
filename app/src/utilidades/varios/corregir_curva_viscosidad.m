function [C_Q, C_H, C_eta] = corregir_curva_viscosidad(Q_bep, H_bep, nu_cSt)
  % Calcula los factores de corrección por viscosidad según ANSI/HI 9.6.7-2015.
  % Entradas:
  %   Q_bep   : caudal en el BEP (m³/s)
  %   H_bep   : cabeza en el BEP (m)
  %   nu_cSt  : viscosidad cinemática del líquido (cSt = mm²/s)
  % Salidas:
  %   C_Q, C_H, C_eta : factores de corrección (adimensionales, ≤ 1)
  
  % Convertir caudal a m³/h
  Q_bep_m3h = Q_bep * 3600;
  
  % Parámetro B del HI
  B = 2.6 * sqrt(nu_cSt / Q_bep_m3h) * H_bep^(-0.25);
  
  if B <= 1
      % Efecto despreciable
      C_Q   = 1.0;
      C_H   = 1.0;
      C_eta = 1.0;
  else
      % Factores de corrección (fórmulas empíricas del HI)
      logB = log10(B);
      C_Q   = 1 - 0.06 * logB;
      C_H   = 1 - 0.08 * logB;
      C_eta = 1 - 0.12 * logB;
      
      % Limitar a valores mínimos razonables
      C_Q   = max(0.6, C_Q);
      C_H   = max(0.5, C_H);
      C_eta = max(0.4, C_eta);
  end
end
