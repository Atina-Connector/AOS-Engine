function [Ql_JGL, Qo_JGL, Ql_GL, Qo_GL, avisos] = sens_aplicar_consistencia_jgl_gl(base, Qiny_vals, Ql_JGL, Qo_JGL, Ql_GL, Qo_GL)
% sens_aplicar_consistencia_jgl_gl.m
% AOS 0.0.11 - Diagnostico de invariante JGL/GL sin modificar resultados.
%
% Invariante fisico:
%   Para mismo pozo, fluido, survey y Qiny:
%      JGL = GL + trabajo del eductor
%   Por lo tanto JGL no deberia quedar por debajo de GL. Si ocurre, es una
%   violacion del modelo o de datos; no se corrige por software.
%
% Esta funcion conserva Ql/Qo crudos o postprocesados previos y solo agrega avisos.

  avisos = {};
  if nargin < 2 || isempty(Qiny_vals), return; end

  tol_qiny = max(1e-12, 1e-9 * max(abs(Qiny_vals)));
  tol_q = 1e-4;

  idx0 = find(abs(Qiny_vals) <= tol_qiny & isfinite(Ql_JGL) & isfinite(Ql_GL));
  for k = 1:length(idx0)
      i = idx0(k);
      if abs(Ql_JGL(i) - Ql_GL(i)) > max(tol_q, 1e-3 * max(abs(Ql_GL(i)), 1))
          avisos{end+1} = sprintf('[AMARILLO] Qiny=0: JGL %.2f m3/d y GL %.2f m3/d no coinciden. Revisar degeneracion JGL->GL.', Ql_JGL(i), Ql_GL(i));
      end
      if isfinite(Ql_GL(i)) && Ql_GL(i) > 0.5
          avisos{end+1} = sprintf('Advertencia: el modelo predice flujo natural/base con Qiny = 0 (Ql = %.2f m3/d). Verificar P_res, IP, P_wh, WC, GLR, profundidad y VLP.', Ql_GL(i));
      end
  end

  idxpos = find(Qiny_vals > tol_qiny & isfinite(Ql_JGL) & isfinite(Ql_GL));
  viol = [];
  for k = 1:length(idxpos)
      i = idxpos(k);
      if Ql_JGL(i) + max(tol_q, 1e-3 * max(abs(Ql_GL(i)), 1)) < Ql_GL(i)
          viol(end+1) = i;
      end
  end

  if ~isempty(viol)
      avisos{end+1} = sprintf('[ROJO] INVARIANTE JGL/GL VIOLADO en %d punto(s). JGL no fue elevado por software. Revisar DeltaP_eductor, VLP efectiva, presion motriz y unidades de gas.', length(viol));
  elseif ~isempty(idxpos)
      dif = Ql_JGL(idxpos) - Ql_GL(idxpos);
      if max(abs(dif)) < 1e-3
          avisos{end+1} = 'Nota: JGL y GL quedaron practicamente iguales en el barrido positivo; puede indicar DeltaP_eductor bajo o limite por IPR.';
      end
  end
end
