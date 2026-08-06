function aos_encrypt(archivo_plano, id_sender, id_receiver, archivo_cifrado)
% AOS_ENCRYPT Cifra un archivo AOS con AES-256-CBC mediante OpenSSL.
% GNU Octave es el entorno objetivo.

  validar_id(id_sender, 'ID del remitente');
  validar_id(id_receiver, 'ID del destinatario');
  if exist(archivo_plano, 'file') ~= 2
      error('No se encontro el archivo plano: %s', archivo_plano);
  end
  if system('openssl version >/dev/null 2>&1') ~= 0
      error('OpenSSL no esta disponible. No se puede codificar el archivo.');
  end

  if strcmp(id_sender, id_receiver) < 0
      clave_base = [id_sender id_receiver];
  else
      clave_base = [id_receiver id_sender];
  end
  pass = hash('SHA256', clave_base);

  setenv('AOS_ENC_PASS', pass);
  comando = sprintf('openssl enc -aes-256-cbc -salt -pbkdf2 -in "%s" -out "%s" -pass env:AOS_ENC_PASS', ...
                    archivo_plano, archivo_cifrado);
  [status, output] = system(comando);
  unsetenv('AOS_ENC_PASS');

  if status ~= 0
      if exist(archivo_cifrado, 'file') == 2, delete(archivo_cifrado); end
      error('Error al cifrar con OpenSSL: %s', strtrim(output));
  end
end

function validar_id(id, etiqueta)
  if ~ischar(id) || length(id) ~= 10 || any(id < '0') || any(id > '9')
      error('%s debe contener exactamente 10 digitos.', etiqueta);
  end
end
