function ok = VERIFICAR_AOS_0_1_9_R2_HF3_5(profundo)
% Compatibilidad: HF3.5 fue integrado en AOS 0.2.0 DEV1.
  if nargin < 1, profundo = false; endif
  fprintf('AVISO: HF3.5 esta integrado en AOS 0.2.0 DEV1. Ejecutando verificador vigente.\n');
  ok = VERIFICAR_AOS_0_2_0_DEV1(profundo);
endfunction
