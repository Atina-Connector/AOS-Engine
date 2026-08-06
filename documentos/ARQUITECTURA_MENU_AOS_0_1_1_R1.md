# Arquitectura de menús — AOS 0.1.1-R1

```text
AOS
├─ 1. Simulación y operación del yacimiento
│  ├─ 1. Sistemas de Levantamiento Artificial
│  │  ├─ GL / JGL [OPERATIVO, JGL PROPIETARIO]
│  │  ├─ BES [BETA + LEGADO]
│  │  ├─ Bombeo Mecánico [BETA]
│  │  ├─ PCP [DESARROLLO]
│  │  │  └─ LDL [DESARROLLO, PROPIETARIO AESIR]
│  │  ├─ CGF [BETA, PROPIETARIO AESIR]
│  │  ├─ EGF [BETA, PROPIETARIO AESIR]
│  │  ├─ Comparación de sistemas
│  │  └─ Herramientas comunes
│  ├─ 2. Pozos inyectores
│  ├─ 3. Mallas y niveles
│  ├─ 4. Baterías e instalaciones
│  ├─ 5. Fluidos y aseguramiento de flujo
│  ├─ 6. Redes eléctricas
│  ├─ 7. Secuencia de arranque del yacimiento
│  ├─ 8. SCADA y operación en tiempo real
│  ├─ 9. Análisis integral del yacimiento
│  └─ 10. Herramientas generales
├─ 2. Importar / Exportar
│  ├─ Importar AOSDAT [AUTOMÁTICO E INDIFERENCIADO]
│  ├─ Exportar AOSDAT
│  ├─ Datos y geometrías
│  ├─ Formatos externos
│  ├─ Catálogos
│  ├─ Reportes / Viewer
│  ├─ Diagnóstico
│  └─ Bandejas SCADA
├─ 3. Configuración general
└─ 4. Salir
```

## LDL

LDL pertenece exclusivamente a PCP. Su contrato está destinado a estimar presión y temperatura de fondo sin sensores, utilizando variables de superficie, calibración, históricos y datos SCADA. El modelo físico propietario no se publica en esta versión.

## Importación nativa

`importar_aosdat` es el único punto de entrada. El archivo se lee completo, se preservan todas sus secciones, se normalizan aliases y se despachan bloques a los dominios correspondientes. El usuario no selecciona componentes individuales.

## Separación de responsabilidades

- Los menús son adaptadores interactivos.
- Los solvers no deben pedir datos por consola.
- Los resultados estructurados alimentan consola, gráficos y reportes.
- Los módulos no disponibles muestran estado y datos, pero no inventan física.
