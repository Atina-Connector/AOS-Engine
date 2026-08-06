# AOS - Rol de `config/`

`config/` queda reservado para defaults generales y catálogos compartidos del programa.

No debe ser la fuente principal de un caso real cuando existe un `.aosdat` activo.

Flujo recomendado:

```text
config/ defaults
      ↓
.aosdat importado, si existe
      ↓
ajustes temporales del usuario durante cualquier módulo
      ↓
simulación
      ↓
.aosrpt con lo efectivamente usado
```

Regla principal:

```text
config/ nunca pisa un .aosdat cargado
```

Casos operativos y archivos importados deben entrar preferentemente por:

```text
intercambio/pozos/recibidos/
datos/ejemplos/
```

La ruta `config/importados/` se conserva solo como compatibilidad legacy si el usuario la crea manualmente.
