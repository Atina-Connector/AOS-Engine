# AOS 0.1.9 R2 HF3.3

## Correccion critica de GF3

- Corrige la pendiente invertida de la carta de fondo con tuberia libre.
- Separa `elongacion_m` (magnitud positiva) de `u_fondo_m` (posicion firmada).
- Usa `u_piston_relativo = u_varilla_fondo - u_fondo_m`.
- Conserva `x_tuberia_m` como alias historico de elongacion positiva.
- El spacing utiliza exclusivamente la magnitud positiva de elongacion.
- Repara resultados residentes sin volver a integrar la sarta ni cambiar cargas.
- Agrega validacion de rigidez positiva y coincidencia con `E*A/L`.
- Agrega selftest y regresion obligatoria de integracion.

## No modificado

No se modificaron la ecuacion axial de varillas, las cargas de bomba, la logica
de valvulas, la carta superficial, LPP, diseno de sarta ni barras de peso.


## Compatibilidad de reportes

Los contratos tabulares y CSV existentes no cambian. Se agregan solamente
metadatos escalares de convencion de signo, rigidez axial y elongacion maxima.
