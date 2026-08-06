function ok = VERIFICAR_AOS_0_1_9_R2_HF3_4_AOSCAD_R16(profundo)
% Compatibilidad: la baseline HF3.4-CAD-R16 fue integrada en AOS 0.2.0 DEV1.
  if nargin < 1, profundo = false; endif
  fprintf('AVISO: HF3.4-CAD-R16 esta integrado en AOS 0.2.0 DEV1.\n');
  ok = VERIFICAR_AOS_0_2_0_DEV1(profundo);
endfunction
