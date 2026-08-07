function [politica, q_fijo] = sens_menu_qiny_comun(base, defecto)
% Politica comun de gas para comparar JGL y GL.
% 1/Enter mantiene el Qiny configurado; 2 fuerza cualquier valor >=0;
% 3 calcula por presion/orificio para ambos motores.
  if nargin<1 || ~isstruct(base), base=struct(); end
  if nargin<2, defecto='configurado'; end %#ok<NASGU>
  [qref,fuente]=aos_qiny_referencia(base);
  fprintf('\n--- POLITICA COMUN DE GAS JGL/GL ---\n');
  if isempty(qref), fprintf('Valor configurado: no disponible.\n');
  else, fprintf('Valor configurado: %s [%s].\n',aos_formato_caudal_gas(qref),fuente); end
  fprintf('1 - Mantener valor configurado para ambos motores (Enter)\n');
  fprintf('2 - Forzar un valor manual comun (se admite 0 o cualquier valor >= 0)\n');
  fprintf('3 - Calcular Qiny por presion/orificio, comun para ambos\n');
  op=input('Seleccione opcion [1]: '); if isempty(op),op=1;end
  if op==3
    politica='presion'; q_fijo=NaN;
  elseif op==2
    if isempty(qref),qdef=0;else,qdef=qref*86400;end
    qin=leer_q(sprintf('Qiny manual comun (Sm3/d) [%.0f]: ',qdef),qdef);
    politica='fijo'; q_fijo=qin/86400;
  else
    if isempty(qref),error('No existe Qiny configurado. Use opcion 2 o 3.');end
    politica='fijo'; q_fijo=qref;
  end
end
function q=leer_q(txt,def)
  while true
    q=input(txt);if isempty(q),q=def;end
    if isnumeric(q)&&isscalar(q)&&isfinite(q)&&q>=0,return;end
    fprintf('Valor invalido. Ingrese un numero mayor o igual que cero.\n');
  end
end
