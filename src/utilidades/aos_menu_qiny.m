function [p, info] = aos_menu_qiny(p, titulo)
% AOS_MENU_QINY Menu comun y no ambiguo para GL y JGL.
% 1 conserva un valor existente; 2 fuerza cualquier valor >=0; 3 automatico.
% Cuando no existe Qiny, la opcion 1 queda deshabilitada y no provoca error.
  if nargin<1 || ~isstruct(p), p=struct(); endif
  if nargin<2 || isempty(titulo), titulo='CAUDAL DE GAS A INYECTAR'; endif
  [qref, modo_ref, fuente]=aos_resolver_qiny_configurado(p);
  fprintf('\n--- %s ---\n',titulo);
  if isempty(qref)
    fprintf('Valor configurado: no disponible.\n');
    defecto=3;
  else
    fprintf('Valor configurado: %s\n',aos_formato_caudal_gas(qref));
    fprintf('Origen            : %s\n',fuente);
    fprintf('Modo              : %s\n',modo_ref);
    defecto=1;
  endif
  fprintf('1 - Mantener el valor configurado%s\n',marca_local(isempty(qref)));
  fprintf('2 - Forzar un valor manual (se admite 0 o cualquier valor >= 0)\n');
  fprintf('3 - Calcular Qiny automaticamente\n');
  while true
    if exist('aos_leer_opcion','file')==2
      op=aos_leer_opcion(sprintf('Seleccione opcion [%d]: ',defecto),defecto);
    else
      txt=strtrim(input(sprintf('Seleccione opcion [%d]: ',defecto),'s'));
      if isempty(txt),op=defecto;else,op=str2double(txt);endif
    endif
    if any(op==[1,2,3])
      if op==1 && isempty(qref)
        fprintf('La opcion 1 no esta disponible porque el caso no contiene Qiny. Use 2 o 3.\n');
        continue;
      endif
      break;
    endif
    fprintf('Opcion invalida. Use 1, 2 o 3.\n');
  endwhile

  if op==2
    if isempty(qref), qdef=0; else, qdef=qref*86400; endif
    while true
      txt=strtrim(input(sprintf('Qiny manual (Sm3/d) [%.0f]: ',qdef),'s'));
      if isempty(txt), qin=qdef; else, qin=str2double(txt); endif
      if isfinite(qin) && qin>=0, break; endif
      fprintf('Valor invalido. Ingrese un numero mayor o igual que cero.\n');
    endwhile
    [p,info]=aos_aplicar_opcion_qiny(p,2,qin);
    fprintf('Qiny manual aplicado: %s\n',aos_formato_caudal_gas(p.Q_iny));
    if qin==0
      fprintf('Prueba sin inyeccion: AOS resolvera el balance nodal con Qiny = 0.\n');
    endif
  elseif op==3
    [p,info]=aos_aplicar_opcion_qiny(p,3,[]);
    fprintf('Qiny automatico seleccionado. El valor se calculara antes del solver.\n');
  else
    [p,info]=aos_aplicar_opcion_qiny(p,1,[]);
    fprintf('Se mantiene Qiny configurado: %s\n',aos_formato_caudal_gas(p.Q_iny));
  endif
endfunction

function s=marca_local(sin_valor)
  if sin_valor,s=' [NO DISPONIBLE]';else,s=' (Enter)';endif
endfunction
