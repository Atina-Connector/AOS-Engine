function ok = test_aos_path_selftests_hf2()
% TEST_AOS_PATH_SELFTESTS_HF2 Verifica que el modo tests sea recuperable.
  iniciar_aos(true);
  assert(exist('test_aosdat_roundtrip_001','file')==2);
  iniciar_aos(false);
  iniciar_aos(true);
  rehash();
  assert(exist('test_aosdat_roundtrip_001','file')==2);
  assert(exist('test_aosdat_legacy_compat_001','file')==2);
  ok = true;
  fprintf('RESULTADO: test_aos_path_selftests_hf2 APROBADO\n');
endfunction
