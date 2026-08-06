function [p, ok] = gibbs3_lpp_menu(p)
% GIBBS3_LPP_MENU Seleccion explicita de bomba convencional o LPP AESIR.

  p = gibbs3_defaults(p);
  ok = true;
  fprintf('\n====================================================\n');
  fprintf(' GF3 - TIPO DE BOMBA\n');
  fprintf('====================================================\n');

  defecto = logical(p.bomba_lpp);
  if defecto
    prompt = 'Usa bomba LPP AESIR? (s/n) [s]: ';
  else
    prompt = 'Usa bomba LPP AESIR? (s/n) [n]: ';
  end
  r = input(prompt, 's');
  if isempty(r)
    usar = defecto;
  else
    usar = lower(r(1)) == 's';
  end

  p.bomba_lpp = double(usar);
  p.gibbs3_config_lpp_confirmada = 1;
  if usar
    p.lpp_longitud_piston_m = leer_numero('Longitud del piston LPP (m)', ...
      p.lpp_longitud_piston_m);
    p.lpp_id_piston_mm = leer_numero('ID interno del piston LPP (mm)', ...
      p.lpp_id_piston_mm);
    p.lpp_coef_perdidas_K = leer_numero('Coeficiente de perdidas localizadas K', ...
      p.lpp_coef_perdidas_K);
    fprintf('La perdida de carga LPP se incorporara a las cargas GF3 y barras de peso.\n');
  else
    fprintf('Se utilizara el modelo de bomba convencional.\n');
  end
end

function v = leer_numero(etiqueta, actual)
  x = input(sprintf('%s [%.6g]: ', etiqueta, actual));
  if isempty(x), v = actual; else, v = x; end
end
