function VERIFICAR_CRYPTO_TRANSVERSAL_AOS_0_0_12B()
% Verifica el ciclo de cifrado/descifrado sin solicitar datos interactivos.
% GNU Octave es el entorno objetivo.

  raiz = fileparts(mfilename('fullpath'));
  if exist(fullfile(raiz,'src'),'dir') ~= 7
      raiz = pwd;
  end
  addpath(genpath(fullfile(raiz,'src')));

  fprintf('\n=== VERIFICACION CRYPTO TRANSVERSAL AOS 0.0.12B ===\n');
  requeridas = {'aos_encrypt','aos_decrypt','aos_archivo_codificado', ...
                'aos_finalizar_archivo_crypto','exportar_aosdat', ...
                'exportar_aosrpt','exportar_aosrpt_enriquecido', ...
                'exportar_aosrpt_grafico','exportar_catalogo', ...
                'importar_aosdat','importar_aosrpt'};
  for i=1:length(requeridas)
      ruta = which(requeridas{i});
      assert(~isempty(ruta), ['Falta ', requeridas{i}]);
      fprintf('[OK] %s -> %s\n', requeridas{i}, ruta);
  end

  [st,~] = system('openssl version >/dev/null 2>&1');
  assert(st == 0, 'OpenSSL no esta disponible.');
  fprintf('[OK] OpenSSL disponible.\n');

  plano = [tempname(), '.aosdat'];
  cipher = [tempname(), '.bin'];
  contenedor = [tempname(), '.aosdat'];
  recuperado = [tempname(), '.txt'];
  texto = sprintf('[AOS_DATA]\nversion=prueba\nvalor=12345\n');
  fid=fopen(plano,'wb'); assert(fid>=0); fwrite(fid,uint8(texto),'uint8'); fclose(fid);

  id1='1234567890'; id2='0987654321';
  aos_encrypt(plano,id1,id2,cipher);
  fin=fopen(contenedor,'wb'); assert(fin>=0); fprintf(fin,'AOS_ENCRYPTED\n');
  fc=fopen(cipher,'rb'); assert(fc>=0); bytes=fread(fc,Inf,'uint8=>uint8'); fclose(fc);
  fwrite(fin,bytes,'uint8'); fclose(fin);
  assert(aos_archivo_codificado(contenedor), 'No se detecto AOS_ENCRYPTED.');
  fprintf('[OK] Contenedor codificado detectado.\n');

  aos_decrypt(contenedor,id1,id2,recuperado);
  fr=fopen(recuperado,'rb'); assert(fr>=0); out=char(fread(fr,Inf,'uint8=>uint8')'); fclose(fr);
  assert(strcmp(out,texto), 'El contenido recuperado no coincide con el original.');
  fprintf('[OK] Ciclo cifrado-descifrado sin perdida.\n');

  archivos = {plano,cipher,contenedor,recuperado};
  for i=1:length(archivos), if exist(archivos{i},'file')==2, delete(archivos{i}); end, end
  fprintf('VERIFICACION CRYPTO TRANSVERSAL APROBADA.\n');
end
