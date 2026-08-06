function [codificado, archivo_final] = aos_finalizar_archivo_crypto(archivo, preguntar)
% AOS_FINALIZAR_ARCHIVO_CRYPTO Pregunta y protege un .aosdat/.aosrpt.
% El archivo queda en la misma ruta y conserva su extension.
% GNU Octave es el entorno objetivo.

  if nargin < 2, preguntar = true; end
  codificado = false;
  archivo_final = archivo;
  if exist(archivo, 'file') ~= 2
      error('No existe el archivo a finalizar: %s', archivo);
  end
  if ~preguntar, return; end

  fprintf('\n--- PROTECCION DEL ARCHIVO ---\n');
  if ~aos_preguntar_sn( ...
      'Cifrar el archivo para un destinatario AOS? (s/n) [n]: ', false)
      fprintf('Archivo guardado en texto plano.\n');
      return;
  end

  if system('openssl version >/dev/null 2>&1') ~= 0
      fprintf('ADVERTENCIA: OpenSSL no esta disponible. El archivo queda en texto plano.\n');
      return;
  end

  id_destino = pedir_id('ID del destinatario (10 digitos): ');
  id_propio = pedir_id('Su ID AOS/remitente (10 digitos): ');

  temporal_cifrado = [tempname(), '.aosenc'];
  temporal_final = [tempname(), '.aosfinal'];
  try
      aos_encrypt(archivo, id_propio, id_destino, temporal_cifrado);
      fin = fopen(temporal_final, 'wb');
      if fin < 0, error('No se pudo crear el contenedor cifrado temporal.'); end
      fprintf(fin, 'AOS_ENCRYPTED\n');
      fc = fopen(temporal_cifrado, 'rb');
      if fc < 0
          fclose(fin);
          error('No se pudo leer el ciphertext temporal.');
      end
      bytes = fread(fc, Inf, 'uint8=>uint8');
      fclose(fc);
      fwrite(fin, bytes, 'uint8');
      fclose(fin);

      respaldo_plano = [archivo, '.plain.tmp'];
      movefile(archivo, respaldo_plano, 'f');
      try
          movefile(temporal_final, archivo, 'f');
          if ~aos_archivo_codificado(archivo)
              error('La verificacion del contenedor cifrado fallo.');
          end
          delete(respaldo_plano);
      catch err_move
          if exist(archivo, 'file') == 2, delete(archivo); end
          movefile(respaldo_plano, archivo, 'f');
          rethrow(err_move);
      end
      codificado = true;
      fprintf('Archivo codificado correctamente para el destinatario %s.\n', id_destino);
  catch err
      fprintf('ERROR DE CODIFICACION: %s\n', err.message);
      fprintf('El archivo se conserva en texto plano.\n');
      if exist(temporal_final, 'file') == 2, delete(temporal_final); end
  end
  if exist(temporal_cifrado, 'file') == 2, delete(temporal_cifrado); end
  if exist(temporal_final, 'file') == 2, delete(temporal_final); end
end

function id = pedir_id(mensaje)
  while true
      id = strtrim(input(mensaje, 's'));
      if length(id) == 10 && all(id >= '0') && all(id <= '9')
          return;
      end
      fprintf('El ID debe contener exactamente 10 digitos.\n');
  end
end
