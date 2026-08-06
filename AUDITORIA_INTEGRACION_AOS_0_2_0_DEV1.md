# Auditoría de integración AOS 0.2.0 DEV1

## Método

Se realizó una fusión de tres vías:

- base común: AOS 0.1.9 R2 HF3.4;
- rama integrada: HF3.4-CAD-R16 subida por el usuario;
- evolución de reportes: HF3.5.

El delta HF3.5 y el delta CAD-R16 solo coincidían funcionalmente en
`src/modulos/cad_topo/aos_aoscad_escribir.m`, además de los archivos de versión.

## Resolución del conflicto

El escritor resultante:

1. normaliza el modelo y metadatos;
2. registra la composición de tablas HF3.5;
3. genera/regenera recursos visuales R16 para el perfil enriquecido;
4. serializa el JSON canónico de forma atómica.

## Integridad conceptual

- Los datos de tablas no se eliminan.
- Los recursos visuales siguen siendo regenerables.
- AOSCAD conserva estado candidato, sin promoción beta.
- Los verificadores heredados se conservan para regresión.

## Validación pendiente

La auditoría estática se realiza en el entorno de construcción. La aprobación
dinámica debe ejecutarse en GNU Octave con `VERIFICAR_AOS_0_2_0_DEV1(true)`.

## Enmienda posterior de arquitectura ENV-01

La enmienda ENV-01 se limita a documentación y manifests de arquitectura:

- incorpora AOS Environmental como workbench independiente;
- define AOSCAD como autoridad espacial;
- separa actividad energética de cálculo ambiental;
- redefine la frontera con Maintenance;
- conserva aliases y rutas heredadas;
- no modifica archivos `.m`, solvers ni resultados científicos.

La validación de ENV-01 es estática y documental. Los contratos y el runtime se validarán en entregas posteriores.
