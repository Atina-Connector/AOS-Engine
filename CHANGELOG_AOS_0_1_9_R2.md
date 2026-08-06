# AOS 0.1.9 R2 - Consolidacion completa previa a AOS 0.2.0

R2 conserva todas las funciones y bloques de AOS 0.1.9 R1 e integra la restauracion transversal R1.1 como una distribucion completa.

## Correcciones de arquitectura

- Gestion universal del caso desde el menu principal.
- Apertura e importacion contextual dentro de los bancos y modulos.
- Prioridad efectiva del `.aosdat` activo sobre defaults de `config/`.
- Catalogos base, permanentes y embebidos nuevamente accesibles.
- Contrato simetrico `AOS_CATALOGO_R2` para importar y exportar bombas, valvulas, varillas y unidades BM.
- Reconocimiento de `.aosdat` puros de catalogo sin reemplazar el caso activo.
- Galeria de mandriles por `[MANDRILES_GALERIA]` y galerias CAD/DXF visibles y verificadas.
- BES3 reconectado al menu BES con su estado `DESARROLLO_NO_VALIDADO`.
- Verificador de Suite basado en registros, entrypoints y despachos; deja de depender de numeros rigidos del menu.
- Limpieza AOSBCK no interactiva y limitada a carpetas temporales.
- Unica funcion publica de verificacion de plataforma CAD, sin copia sombreada.
- `iniciar_aos` usa rutas controladas y excluye tests/legacy del path operativo por defecto.
- Exportacion STEP con candidatos FreeCAD silenciosos y temporales unicos.

## Pruebas nuevas

- Round-trip y fusion no destructiva de catalogos.
- Galeria de mandriles desde `.aosdat`.
- Accesos universal y contextual de menus.
- Integridad del registro de bancos y Viewer ultimo.
- Deteccion de funciones publicas duplicadas y archivos `.mat`.

## Fisica

No se modificaron ecuaciones ni correlaciones de los solvers. Los estados de validacion de cada modulo se conservan.

## Ajustes finales de consolidacion

- Las bibliotecas `.aosdat` que incluyen una seccion `[CONFIG]` de plantilla ya
  no se clasifican como caso de pozo si no contienen secciones fisicas; por lo
  tanto, no reemplazan la configuracion activa.
- Los selftests de catalogos usan un registro temporal aislado y no contaminan
  `datos_usuario/`.
- Se incorpora un test explicito de prioridad del `.aosdat` sobre los defaults.
- El archivo completo R1 se conserva con hash verificado como historial de
  desarrollo independiente.
