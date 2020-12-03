# Methylation webapp

Copy `sample.env` to `.env` and change the credentials.
Create `nginx/certs` and add your `public.crt` and `private.key`.

```bash
docker-compose up
```
This will take quite a bit of time on first run to pull gigabytes of dependencies to build the
container images, after which the application will be available at localhost.

## Architecture
This deploys as several containers as described by Docker Compose. They are networked in the `methylation-main` Docker network and `.idat` files are persisted in the `methylation-main` Docker volume.

A PostgreSQL container initializes from `./db/init` and its data is backed by a bind mount to `./db/data`. By default, you can communicate with it on the host on port 5432.

A very heavy pipeline executor image is built from `./analysis` based on a Bioconductor image. It mounts `./analysis/logs` and `methylation-main`.

`shiny-build` is only used to make Docker Compose build the `methylation-shiny` image with the rest of the containers. The Shiny app proper is not orchestrated by Docker Compose.

A Shinyproxy 2.3.1 image is built from `./shinyproxy` and OpenJDK 11. It is responsible for starting Shiny containers on demand within the `methylation-main` network and mounting the `methylation-uploads` volume. Shinyproxy itself mounts `./shinyproxy/logs`, the host Docker socket, and the host Docker volumes directory. By default you can access it on the host on port 8080.

Finally, an nginx container acts as a reverse proxy to Shinyproxy and takes care of HTTPS. It mounts TLS certificates from `./nginx/certs`.

## TODO
R side:
- Shiny: read Postgres variables from environment variables
- Shiny: prune unused contents from `config.yaml`
- Pipeline: read Postgres variables from environment variables
- Pipeline: clean up configuration
- Shiny: fix upload_sample:132 tryCatch to not die if directory creation fails (it doesn't for login)

Docker:
- Shinyproxy: investigate logging issue with 2.4.x
- Postgres: log bind mount not doing anything
- If using rocker/verse, use R_VERSION in .env and docker-compose
