# AOS 0.0.11e - Geologia operativa generica

## Principio

Cuando la informacion geologica esta incompleta, AOS construye el modelo mas representativo posible con los datos disponibles y analogos trazables. El analisis no se bloquea, pero tampoco presenta una estimacion como verdad operativa.

## Cambios

- Confianza geologica: alta, media o baja/generica.
- Procedencia y campos estimados conservados.
- Conificacion especifica solo cuando existen datos suficientes de contacto, anisotropia y acuifero.
- Si faltan datos, se generan escenarios conservador, probable y favorable de screening.
- El screening generico no participa del minimo de caudal seguro.
- `No evaluable` nunca se interpreta como cero.
- La geologia sintetica no habilita recomendaciones automaticas de choke.
- El reporte indica los estudios que mas reducirian la incertidumbre.
- La distribucion entre punzados y el zoom de survey de 0.0.11d se mantienen.
- Los graficos geologicos permanecen exclusivos del `.aosrpt` enriquecido.

## Regla de campo

> AOS debe dar una idea rapida y trazable aun con datos incompletos, indicando claramente que se asumio y que informacion permitiria mejorar el modelo.
