# Reporte de empaquetado SENS-GLJGL-03

## Identidad

- Producto: `AOS Suite 0.2.0 DEV1 ENV-02 SENS03`.
- Revision cientifica: `SENS-GLJGL-03`.
- Fecha: 6 de agosto de 2026.
- Base funcional acumulada: `SENS-GLJGL-01` + `SENS-GLJGL-02` + `SENS-GLJGL-03`.
- Estado: candidato a validacion dinamica en GNU Octave.

## Entregables

1. `AOS_0_2_0_DEV1_ENV02_SENS03_COMPLETO.zip`: distribucion autonoma recomendada. No requiere instalar SENS02 por separado.
2. `PARCHE_AOS_SENS_GLJGL_03_DESDE_SENS01.zip`: parche acumulativo para una copia limpia de SENS01.
3. `PARCHE_AOS_SENS_GLJGL_03_DESDE_SENS02.zip`: parche incremental para una copia limpia de SENS02.

## Diferencias

| Base | Agregados | Modificados | Eliminados |
|---|---:|---:|---:|
| SENS01 | 52 | 32 | 0 |
| SENS02 | 27 | 26 | 0 |

## Alcance funcional

- Modo motriz JGL visible: `DERIVADA_DESDE_QINY`, `PRESION_DISPONIBLE` o `SIN_PRESION_MOTRIZ`.
- `P_iny_sup = 0` se conserva como dato importado; no se reemplaza silenciosamente.
- En modo derivado se calcula la presion motriz minima de fondo y la presion superficial requerida para cada `Qiny`.
- La presion requerida se obtiene invirtiendo exactamente el mismo modelo de columna de gas y perdidas utilizado por JGL.
- Se calculan presion de succion, diferencial motriz, presion motriz de fondo, contribucion de columna, friccion, presion superficial requerida, margen y limite de `Qiny` por presion disponible.
- Se agrega una grafica de presiones y componentes frente a `Qiny`.
- La simulacion puntual JGL y la sensibilidad comparten el mismo contrato de condicion motriz.
- SENS02 permanece incluido: tratamiento discreto, polinomico informativo y polinomico verificado, con grado 5 historico seleccionable.

## Controles de construccion

- Auditoria estatica: `PASS_STATIC`.
- JSON validados.
- Sin archivos `.mat`.
- Sin nombres `.m` duplicados dentro de `src`.
- Nucleos fisicos protegidos sin cambios: GL puntual, balance nodal GL, buscador de cruce y solvers JGL directo/iterativo.
- ZIP completo y parches construidos de forma determinista con fecha interna fija.
- La extraccion del ZIP completo se compara por SHA-256 contra el arbol candidato.
- La aplicacion de cada parche se compara por SHA-256 contra el arbol candidato.

## Validacion pendiente

GNU Octave no esta disponible en el entorno de construccion. Deben ejecutarse en la maquina del proyecto:

```octave
VERIFICAR_SENS_GLJGL_03(false)
VERIFICAR_SENS_GLJGL_03(true)
VERIFICAR_AOS_0_2_0_DEV1(true)
```

El caso `MDM-2064` debe conservarse como benchmark de regresion para verificar la curva JGL, la presion requerida y la paridad entre punto individual y sensibilidad.
