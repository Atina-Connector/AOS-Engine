# AOS 0.1.1-alpha1 — BES V2, CGF V1 y EGF V1

## Propósito

Esta rama inaugura AOS 0.1.1 con tres módulos paralelos y experimentales:

- **BES V2**, reimplementado alrededor de un único resultado estructurado;
- **CGF V1**, compresión de gas en fondo con compresor axial y motor PM;
- **EGF V1**, eyector gas-gas de fondo basado en un núcleo jet cuasi-1D.

Los módulos existentes GL/JGL, Diseño de Mandriles, BM y BES V1 se conservan como referencia y no se reemplazan.

## Núcleos comunes nuevos

### Gas

- propiedades de gas real de screening;
- perfil de presión y temperatura por MD/TVD;
- IPR de gas lineal o backpressure;
- flujo compresible por tobera con detección de choking.

### Eléctrico de fondo

- motor de imanes permanentes;
- cable trifásico y caída de tensión;
- VSD;
- potencia, corriente y torque;
- modelo térmico lumped de screening.

### Jet gas-gas

- tobera primaria y secundaria;
- choking;
- balance de masa y momento;
- mezcla;
- recuperación de presión en difusor;
- acoplamiento iterativo con la contrapresión del tubing.

## BES V2

- intake exclusivamente asociado a `D_bomba`;
- PVT en condiciones de intake;
- gas libre y eficiencia de separación;
- degradación configurable de head y eficiencia por gas;
- curva con BEP y rango recomendado;
- afinidad por frecuencia y número de etapas;
- búsqueda de todas las raíces y selección del cruce físico;
- potencia hidráulica, de eje y eléctrica;
- motor PM, cable, VSD y térmica;
- sensibilidades y reportes propios;
- comparación contra BES V1.

## CGF V1

- reservorio de gas, tramo inferior, compresor y tramo superior acoplados;
- mapa axial genérico corregido por velocidad y condiciones de succión;
- surge, choke y rango estable;
- compresión politrópica;
- presión y temperatura de descarga;
- potencia de gas, eje y superficie;
- motor PM y diagnóstico térmico/elétrico;
- límite preliminar de líquido;
- sensibilidades y reportes.

## EGF V1

- gas motriz desde superficie por anular;
- aspiración del gas de formación;
- toberas compresibles primaria y secundaria;
- choking primario, secundario y doble;
- relación de arrastre;
- mezcla de cantidad de movimiento;
- recuperación en difusor;
- potencia equivalente de compresión superficial;
- sensibilidades de presión, profundidad y geometría;
- reportes propios.

## Limitaciones declaradas

- curvas y mapas incluidos son **genéricos AOS para screening**;
- no sustituyen datos OEM, mapas de ensayo ni validación de campo;
- CGF es estacionario y no modela dinámica de surge;
- EGF es cuasi-1D y no resuelve explícitamente ondas de choque internas;
- BES V2 usa una degradación preliminar por gas y un modelo térmico lumped;
- los tres módulos deben someterse a evaluación física antes de promoción a beta.
