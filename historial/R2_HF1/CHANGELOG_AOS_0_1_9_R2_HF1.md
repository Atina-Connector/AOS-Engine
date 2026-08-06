# AOS 0.1.9 R2 HF1

## Motivo

Correccion de una excepcion al ingresar en la opcion transversal
`NUEVO / ABRIR / IMPORTAR / CONFIGURAR CASO` cuando la configuracion activa
no tenia nombre de pozo y `aos_normalizar_config` habia creado `pozo` como
estructura obligatoria.

## Causa

`AOS_menu_gestion_caso.m` intentaba convertir cualquier valor no caracter
mediante `num2str`. Cuando el campo legado `pozo` era una estructura, GNU
Octave emitia:

```text
num2str: X must be a numeric, logical, or character array
```

## Correcciones

- Se agrega `aos_texto_seguro.m` para convertir solamente valores escalares
  compatibles y omitir estructuras sin identificacion textual.
- El menu transversal distingue `pozo` como grupo estructurado de datos y usa
  `valor_original_pozo` para casos legacy.
- El origen del caso tambien se formatea de manera segura.
- La fusion de catalogos adopta la misma conversion defensiva.
- Se agrega una regresion para configuracion base sin nombre y para el campo
  legacy `pozo=...`.
- Se agrega `VERIFICAR_AOS_0_1_9_R2_HF1.m`.

## Alcance

No se modificaron ecuaciones, correlaciones, solvers, formatos AOS ni
resultados numericos.
