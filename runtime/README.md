# runtime/

Datos mutables de desarrollo/testing local con Docker. `docker/docker-compose.yml`
bind-mountea estas subcarpetas sobre las del contenedor:

- `datos_usuario/`
- `intercambio/`
- `salida/`
- `logs/`

Docker las crea automáticamente si no existen al hacer
`docker compose -f docker/docker-compose.yml up -d`. Su contenido no se
versiona (ver `.gitignore`) — es el equivalente de desarrollo a lo que en la
distribución Windows viven en `%USERPROFILE%\Documents\AOS\`.
