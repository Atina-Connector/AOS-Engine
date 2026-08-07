function BM_operativo_GF3_menu()
% BM_OPERATIVO_GF3_MENU Entrada integral con nucleo Gibbs Foundation 3.
% Conserva BM Operativo legacy como opcion independiente.

  fprintf('\n====================================================\n');
  fprintf(' AOS - BM OPERATIVO II [GF3 INTEGRAL]\n');
  fprintf(' Aparato + sarta + bomba/LPP + barras + spacing\n');
  fprintf('====================================================\n');

  if exist('gibbs3_menu', 'file') ~= 2
    error(['No se encontro gibbs3_menu. Verifique la instalacion en ' ...
      'src/core/BM/gibbs_foundation3.']);
  end
  gibbs3_menu();
end
