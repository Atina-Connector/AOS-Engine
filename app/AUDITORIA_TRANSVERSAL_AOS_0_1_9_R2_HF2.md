# Auditoria transversal AOS 0.1.9 R2 HF2

## Alcance

Se reviso el arbol activo `src/` de AOS 0.1.9 R2 HF1, con foco en:

- preguntas ambiguas o binarias sin validacion;
- conversiones de estructuras/celdas a texto o numeros;
- parseo de `.aosdat`, `.aosrpt` y catalogos;
- operaciones destructivas y transaccionalidad;
- preservacion de catalogos y galerias;
- efectos laterales sobre el path durante selftests;
- componentes AOSBCK y reportes GF3;
- ausencia de `str2num`, `.mat` y funciones duplicadas.

## Hallazgos corregidos

1. Gestion geologica ambigua y no transaccional.
2. Perdida posible de punzados durante reemplazo.
3. Preguntas s/n directas distribuidas en menus y sensibilidades.
4. Conversores locales que podian aplicar `num2str` a estructuras.
5. Listas de catalogos interpretadas como escalares ambiguos.
6. Elementos deshabilitados eliminados al cargar galerias.
7. Selftests que retiraban `src/tests` del path de la campana.
8. Uso de `str2num` en la reconstruccion de reportes.
9. Metadatos AOSBCK y campos GF3 sin validacion uniforme.
10. Ausencia de un linter de interacciones como barrera de regresion.

## Resultado estatico

- No existen preguntas `(s/n)` implementadas mediante `input(...,'s')` en el
  codigo activo: todas usan `aos_preguntar_sn`.
- No existe uso activo de `str2num`.
- No existen patrones `if ~ischar(...) num2str(...)`.
- No existen archivos `.mat`.
- No se eliminaron funciones unicas respecto de HF1.
- Las funciones fisicas y los solvers no fueron modificados.

## Limite de la auditoria

La auditoria realizada en el entorno de construccion es estatica porque GNU
Octave no esta instalado en dicho entorno. La aprobacion final corresponde a la
campana dinamica incluida en `VERIFICAR_AOS_0_1_9_R2_HF2(true)`.
