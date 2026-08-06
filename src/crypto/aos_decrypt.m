function aos_decrypt(archivo_cifrado, id_sender, id_receiver, archivo_plano)
% AOS_DECRYPT Descifra archivos AOS codificados.
% Acepta el contenedor AOS_ENCRYPTED y el ciphertext OpenSSL directo.
% GNU Octave es el entorno objetivo.

  validar_id(id_sender, 'ID del remitente');
  validar_id(id_receiver, 'ID propio');
  if exist(archivo_cifrado, 'file') ~= 2
      error('No se encontro el archivo cifrado: %s', archivo_cifrado);
  end
  if system('openssl version >/dev/null 2>&1') ~= 0
      error('OpenSSL no esta disponible. No se puede descifrar el archivo.');
  end

  origen_openssl = archivo_cifrado;
  temporal = '';
  fid = fopen(archivo_cifrado, 'rb');
  if fid < 0, error('No se pudo abrir el archivo cifrado.'); end
  primera = fgetl(fid);
  if ischar(primera) && strcmp(strtrim(primera), 'AOS_ENCRYPTED')
      temporal = [tempname(), '.aosenc'];
      fout = fopen(temporal, 'wb');
      if fout < 0
          fclose(fid);
          error('No se pudo crear el archivo temporal de descifrado.');
      end
      bytes = fread(fid, Inf, 'uint8=>uint8');
      fwrite(fout, bytes, 'uint8');
      fclose(fout);
      origen_openssl = temporal;
  end
  fclose(fid);

  if strcmp(id_sender, id_receiver) < 0
      clave_base = [id_sender id_receiver];
  else
      clave_base = [id_receiver id_sender];
  end
  pass = hash('SHA256', clave_base);
  setenv('AOS_ENC_PASS', pass);
  comando = sprintf('openssl enc -d -aes-256-cbc -pbkdf2 -in "%s" -out "%s" -pass env:AOS_ENC_PASS', ...
                    origen_openssl, archivo_plano);
  [status, output] = system(comando);
  unsetenv('AOS_ENC_PASS');
  if ~isempty(temporal) && exist(temporal, 'file') == 2, delete(temporal); end

  if status ~= 0
      if exist(archivo_plano, 'file') == 2, delete(archivo_plano); end
      error(['No se pudo descifrar el archivo. Verifique los IDs del remitente y receptor. ', ...
             'Detalle OpenSSL: %s'], strtrim(output));
  end
end

function validar_id(id, etiqueta)
  if ~ischar(id) || length(id) ~= 10 || any(id < '0') || any(id > '9')
      error('%s debe contener exactamente 10 digitos.', etiqueta);
  end
end
