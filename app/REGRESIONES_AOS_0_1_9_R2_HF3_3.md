# Regresiones AOS 0.1.9 R2 HF3.3

## GF3-TUB-SIGN-001

Para tuberia libre:

- `elongacion_m >= 0`;
- `u_fondo_m = -elongacion_m`;
- `u_piston_relativo = u_varilla_fondo - u_fondo_m`;
- la pendiente elastica aislada es positiva;
- la rigidez observada coincide con `E*A/L`;
- las cargas de superficie y bomba no se alteran al reparar el signo;
- el spacing usa elongacion positiva, no posicion firmada.

## GF3-TUB-ANCH-001

Para tuberia anclada, elongacion y posicion de fondo son cero.

## GF3-TUB-RESIDENT-001

Un resultado residente con la convencion anterior se actualiza sin volver a
integrar la sarta y conserva los vectores de carga originales.
