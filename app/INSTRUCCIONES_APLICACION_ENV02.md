# Instrucciones de aplicacion - ENV-02

## Opcion recomendada: distribucion completa

1. Conservar intacta la carpeta ENV-01 como baseline historica.
2. Extraer `AOS_0_2_0_DEV1_ENV02_COMPLETO.zip` en una carpeta nueva.
3. Abrir GNU Octave y ejecutar:

```octave
cd('/ruta/AOS_0_2_0_DEV1_ENV02')
clear functions
rehash
VERIFICAR_AOS_0_2_0_DEV1(false)
test_aos_environmental_runtime_shell_env02()
AOS
```

La campana completa se ejecuta con:

```octave
VERIFICAR_AOS_0_2_0_DEV1(true)
```

## Aplicacion del parche sobre ENV-01

El parche ENV-02 contiene una carpeta `payload`. Copiar su contenido sobre la raiz de una copia de `AOS_0_2_0_DEV1_ENV01`, preservando rutas relativas y permitiendo reemplazar los archivos listados en `PATCH_FILE_LIST_ENV02.txt`.

Antes de iniciar AOS:

```octave
clear functions
rehash
```

## Resultado esperado

El menu principal debe mostrar:

```text
10 - AOS SCADA
11 - AOS ENVIRONMENTAL [ROADMAP_RUNTIME_SHELL | 0.0.1 ENV-02]
12 - AOS MAINTENANCE
```

`AOS_menu_environmental` debe abrir un menu propio de 18 opciones. Las funciones cientificas permanecen en roadmap y no deben anunciarse como implementadas.
