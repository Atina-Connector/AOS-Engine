# Cambios AOS 0.0.12

- Se elimina el JGL preliminar como motor activo.
- Se agrega fisica comun de eductor CFD/energia.
- Solver iterativo de referencia con convergencia Q, Ps y DeltaP.
- Solver directo de una pasada sobre la misma fisica.
- Modo automatico con verificacion iterativa segun confianza.
- Sensibilidad hibrida: directo en malla e iterativo en puntos relevantes.
- Confianza ALTA/MEDIA/BAJA con puntaje y motivos.
- Dominio CFD explicito y sin extrapolacion silenciosa.
- Tabla CFD original archivada en data/CFD.
