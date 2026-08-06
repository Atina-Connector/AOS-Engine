# Regresiones AOS 0.1.3R1.1

## Cerrada en esta revision

**BES3 incompleto por consolidacion:** la carpeta activa contenia llamadas a funciones ausentes. La causa fue integrar parches incrementales sin conservar archivos base que no habian sido modificados por los parches posteriores.

Impacto potencial:

- fallo inmediato de `bes3_selftest`;
- imposibilidad de resolver geometria de completacion e intake;
- imposibilidad de calcular ajuste, perdida y caudal capilar;
- fallo en rendimiento por etapa y comparacion BES1/BES2/BES3;
- ausencia de servicios transversales.

Correccion:

- restitucion de nueve archivos BES3 y un caso sintetico;
- verificador ampliado a la lista completa de 44 archivos activos;
- prueba integral opcional sobre el caso sintetico.

## Estado pendiente

La ejecutabilidad no equivale a validacion fisica. Quedan pendientes:

1. pruebas unitarias de cada bloque BES3;
2. matriz de casos limite y sensibilidades;
3. comparacion con curvas OEM y simulador de referencia;
4. validacion con datos de campo;
5. tolerancias formales para caudal, intake, head, potencia, temperatura y recirculacion.
