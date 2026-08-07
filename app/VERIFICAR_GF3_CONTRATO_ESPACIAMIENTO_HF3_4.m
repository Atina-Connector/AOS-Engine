function ok = VERIFICAR_GF3_CONTRATO_ESPACIAMIENTO_HF3_4(profundo)
% Verifica contrato publico de espaciamiento y selftest integral GF3.
  if nargin < 1, profundo = true; endif
  raiz = fileparts(mfilename('fullpath'));
  cd(raiz); addpath(raiz,'-begin'); addpath(fullfile(raiz,'src'),'-begin');
  iniciar_aos(true);
  fprintf('\n============================================================\n');
  fprintf(' GF3 HF3.4 - CONTRATO PUBLICO DE ESPACIAMIENTO\n');
  fprintf('============================================================\n');
  ok = true;
  try
    r = test_gf3_contrato_espaciamiento_hf3_4();
    ok = ~isempty(r) && logical(r);
  catch err
    fprintf(2,'FALLO: %s\n',err.message); ok=false;
  end_try_catch
  if profundo && ok
    try
      r = test_gf3_signo_tuberia_libre_hf3_3();
      ok = ok && ~isempty(r) && logical(r);
    catch err
      fprintf(2,'FALLO signo tubing: %s\n',err.message); ok=false;
    end_try_catch
  endif
  if ok
    fprintf('RESULTADO: GF3 CONTRATO ESPACIAMIENTO HF3.4 APROBADO\n');
  else
    fprintf(2,'RESULTADO: GF3 CONTRATO ESPACIAMIENTO HF3.4 NO APROBADO\n');
  endif
endfunction
