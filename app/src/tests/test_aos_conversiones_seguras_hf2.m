function ok = test_aos_conversiones_seguras_hf2()
% TEST_AOS_CONVERSIONES_SEGURAS_HF2 Regresion transversal de tipos.
  ok = false;
  iniciar_aos(true);

  [n, valido] = aos_numero_seguro(' -1.25D+03 ', NaN);
  assert(valido && abs(n + 1250) < 1e-12);
  [~, valido] = aos_numero_seguro([1 2], NaN);
  assert(~valido);
  [~, valido] = aos_numero_seguro(struct('x',1), NaN);
  assert(~valido);

  [v, valido] = aos_vector_seguro('10,20,30', []);
  assert(valido && isequal(v, [10 20 30]));
  [v, valido] = aos_vector_seguro('[1; 2; 3]', []);
  assert(valido && isequal(v, [1 2 3]));
  [~, valido] = aos_vector_seguro('1,ERROR,3', []);
  assert(~valido);

  escalar = aos_parse_valor('12.5');
  lista = aos_parse_valor('10,20,30');
  assert(isnumeric(escalar) && isscalar(escalar) && abs(escalar-12.5)<1e-12);
  assert(ischar(lista) && strcmp(lista,'10,20,30'));

  [txt, valido] = aos_texto_seguro(struct('nombre','OBJETO-01'), '');
  assert(valido && strcmp(txt,'OBJETO-01'));
  [txt, valido] = aos_texto_seguro(struct(), 'DEFECTO');
  assert(~valido && strcmp(txt,'DEFECTO'));

  tmp = [tempname() '.step'];
  fid = fopen(tmp,'wt');
  assert(fid >= 0);
  fprintf(fid,'ISO-10303-21;\nEND-ISO-10303-21;\n');
  fclose(fid);
  unwind_protect
    meta = struct('part_number','PART-HF2', ...
      'description',struct('nombre','Descripcion segura'), ...
      'material_id',{'MAT-HF2'});
    m = aosbck_manifest_nuevo(tmp, meta);
    assert(strcmp(m.component.part_number,'PART-HF2'));
    assert(strcmp(m.component.description,'Descripcion segura'));
  unwind_protect_cleanup
    if exist(tmp,'file')==2, delete(tmp); endif
  end_unwind_protect

  ok = true;
  fprintf('RESULTADO: test_aos_conversiones_seguras_hf2 APROBADO\n');
endfunction
