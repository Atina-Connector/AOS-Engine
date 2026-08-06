# Notas de liberación — AOS 0.0.11 Benchmark Ready

## Base física heredada de 0.0.11

- eliminación de pisos de producción hardcodeados;
- límites operativos tratados como diagnósticos;
- presión de burbuja ingresada en bar;
- VLP seleccionada y efectiva informadas;
- conservación de curvas crudas en sensibilidades.

## Consolidación Benchmark Ready

- convención métrica de interfaz y archivos;
- caudales de gas en Sm³/d;
- importación integral de `.aosdat`;
- carga automática de survey, geología y punzados;
- preservación de estado mecánico, benchmark y secciones futuras;
- compatibilidad con archivos históricos;
- gráfico de survey con punzados;
- pozo testigo Supati X1 ST incluido;
- suite de verificación `VERIFICAR_AOS_0_0_11`.

## Fuera de alcance

El solver iterativo acoplado JGL se desarrollará en AOS 0.0.12.
