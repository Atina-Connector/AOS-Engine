# AOS 0.0.12B - Restauracion transversal de proteccion de archivos

## Objetivo

Restaurar la pregunta de codificacion/proteccion antes de finalizar las exportaciones AOS y unificar el comportamiento en GNU Octave.

## Rutas cubiertas

- `.aosdat` de pozo;
- `.aosdat` de catalogos;
- `.aosrpt` ligero;
- `.aosrpt` enriquecido;
- `.aosrpt` generado por sensibilidades, survey, mandriles y otros modulos graficos;
- importacion de `.aosdat` y `.aosrpt` protegidos.

## Flujo

```text
construir archivo temporal/plano
-> preguntar si se desea proteger
-> solicitar ID destinatario y remitente
-> cifrar con AES-256-CBC/PBKDF2 mediante OpenSSL
-> crear contenedor AOS_ENCRYPTED
-> verificar la marca
-> conservar la misma extension y nombre
```

La respuesta predeterminada es `n`, por lo que Enter guarda texto plano.

## Correcciones adicionales

- La deteccion de archivos protegidos ya no depende de `AOS_CIFRADO_ACTIVO`.
- Se elimina la ruta de copia sin cifrado de los modulos crypto.
- `aos_decrypt` reconoce y retira correctamente la cabecera `AOS_ENCRYPTED` antes de invocar OpenSSL.
- Los `.aosdat` protegidos aparecen en el selector estandar.
- Los reportes enriquecidos se cifran solo despues de anexar graficos y survey; no se cifra prematuramente el cuerpo ligero.
- Las llamadas programaticas con una ruta explicita no muestran prompts, para no bloquear verificadores/API.

## Criterio para el hito AOS 0.1.0

Este parche no cambia aun el numero de version. Luego de aprobar:

1. exportacion/importacion plana de `.aosdat`;
2. exportacion/importacion protegida de `.aosdat`;
3. exportacion/importacion plana de `.aosrpt` ligero;
4. exportacion/importacion protegida de `.aosrpt` ligero;
5. exportacion/importacion protegida del enriquecido con graficos y survey;
6. sensibilidades GL/JGL y modos preciso, simple, hibrido y abreviado;

se puede congelar una copia limpia como **AOS 0.1.0**, hito de cierre funcional inicial del modulo GL-JGL.
