# AOS 0.1.1 — Contexto de pruebas BES V2 / CGF / EGF

## BES V2

El solver barre todo el dominio común IPR–curva de bomba, detecta raíces, refina por bisección y selecciona el punto más cercano al BEP dentro del rango recomendado. No extrapola silenciosamente la curva.

La física inicial incluye PVT local, gas libre, separador, degradación de head/eficiencia, potencia hidráulica y de eje, motor PM, cable, VSD y térmica de screening.

## CGF

El módulo resuelve reservorio → tramo inferior → compresor → tramo superior. El mapa axial genérico se corrige por velocidad y condiciones de succión. Informa surge, choke, presión, temperatura y potencia.

## EGF

El módulo resuelve reservorio → succión → eyector gas-gas → descarga → superficie. El dispositivo usa flujo compresible por toberas, choking, mezcla de momento y recuperación de presión en difusor. El gas motriz se calcula desde la presión superficial y el perfil por anular.

## Limitaciones declaradas

- Mapas y curvas genéricos: uso de screening.
- Modelos térmicos lumped.
- EGF cuasi-1D sin ondas de choque internas explícitas.
- CGF estacionario, sin dinámica de surge.
- BES gas degradation preliminar y configurable.

## Objetivo de las pruebas

1. Verificar consistencia de unidades y monotonía.
2. Comparar solver, gráficos y reportes.
3. Identificar regiones no físicas.
4. Calibrar coeficientes con curvas OEM y datos de campo.
5. Definir benchmarks para 0.1.1-beta.
