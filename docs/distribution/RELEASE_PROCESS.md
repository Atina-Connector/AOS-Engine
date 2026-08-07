# Proceso de release (pendiente)

Este documento va a cubrir, una vez implementada la Fase 5:

- versión canónica única: `app/VERSION` (ver
  `docs/distribution/REPOSITORY_LAYOUT.md`);
- cómo se nombran los artifacts (`AOS-Setup-<version>.exe`,
  `AOS-Portable-<version>-win-x64.zip`) y qué metadata adicional se registra
  (commit SHA, fecha de build, versión de Octave, arquitectura);
- disparo manual del workflow de GitHub Actions (`workflow_dispatch`) —
  sin publicación automática de releases oficiales hasta que los tests de
  packaging estén maduros;
- prerequisito pendiente: el repo todavía no tiene un remote de GitHub
  configurado; se resuelve cuando se llegue a esta fase.

Se redacta con contenido real cuando exista el workflow correspondiente.
