# installer/

Definición del instalador Windows. Pendiente de Fase 4.

Va a incluir `AOS.iss` (Inno Setup) que:

- Instala en `Program Files\AOS\` (`AOS.exe`, `runtime\octave\`, `app\`).
- Siembra `%USERPROFILE%\Documents\AOS\{datos_usuario,intercambio,salida,logs}`
  copiando una vez el contenido semilla de `app\datos_usuario` y
  `app\intercambio`, y reemplaza esas carpetas dentro de la instalación por
  junctions NTFS (`mklink /J`) hacia la ubicación real del usuario — así el
  código Octave (que ya asume rutas relativas tipo
  `fullfile('intercambio','reportes',...)`) sigue funcionando sin cambios.
- Crea acceso directo, registra versión/publisher, permite upgrade y
  desinstalación sin borrar `Documents\AOS`.
- Soporta instalación silenciosa y Windows 10/11 de 64 bits.

Nada de esto está implementado todavía.
