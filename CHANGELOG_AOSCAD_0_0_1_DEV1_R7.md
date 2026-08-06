# AOSCAD 0.0.1 DEV1 R7

## Correccion de lanzador CAD sombreado

- Se elimina la copia heredada `src/modulos/cad_topo/aos_cad_abrir_externo.m`.
- La funcion publica queda unicamente en `src/menu/aos_cad_abrir_externo.m`.
- La implementacion real pasa a `aos_cad_abrir_externo_impl.m`.
- El lanzador publico usa el mismo localizador que el diagnostico de plataforma.
- Se conserva soporte para Flatpak host, AppImage, Snap, PATH y rutas manuales.
- Se agrega control de funciones duplicadas/sombreadas al verificador DEV1.
- No se modifica fisica, topologia, DXF, STEP, `.aoscad` ni hidraulica.
