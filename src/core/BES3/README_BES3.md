# BES3 - AOS 0.1.3

BES3 es una rama nueva e independiente. BES1 y BES2 permanecen intactos.

## Base fisica

- Solver de multiples raices y PVT de BES2.
- Geometria de succion anular, sin asumir tubing debajo del intake.
- Caudal real local en la bomba.
- Bomba dividida en seccion inferior y superior cuando existe sangrado.
- Capilar externo con descarga por debajo del motor.
- Seleccion automatica de segunda o tercera etapa.
- Perdidas Darcy-Weisbach con regimen laminar, transicional o turbulento.
- Verificacion de capilar, cable, shroud, casing y dogleg.
- Balance electrico y termico comun de AOS.
- Editor, sensibilidades, survey/punzados, reportes y comparacion BES1/BES2/BES3.

## Convencion de etapas

Las etapas desde el intake hasta la toma del capilar procesan el caudal neto mas la recirculacion. Las etapas superiores procesan el caudal neto hacia superficie.

## Estado

DESARROLLO_NO_VALIDADO. Los resultados son fisicos preliminares y no deben usarse como diseno certificado hasta completar benchmarks bottom-up y top-down.

## Servicios transversales recuperados

Despues de cada simulacion BES3 puede ejecutar el diagnostico comun de tuberia y los semaforos globales AOS. El menu permite solicitar el reporte geologico asociado al ultimo resultado. Estos servicios rodean al solver y no alteran su balance hidraulico, electrico o termico.
