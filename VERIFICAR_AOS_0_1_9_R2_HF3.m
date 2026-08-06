function ok = VERIFICAR_AOS_0_1_9_R2_HF3(profundo)
% Compatibilidad: HF3 queda contenido en HF3.4.
  if nargin < 1, profundo = false; endif
  fprintf('AVISO: HF3 fue reemplazado por HF3.4. Ejecutando verificador vigente.\n');
  ok = VERIFICAR_AOS_0_1_9_R2_HF3_4(profundo);
endfunction
