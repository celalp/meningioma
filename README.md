# Methylation webapp

## Setup

1. Copy `sample.env` to `.env` and change the database credentials and admin contact email. If using external proxy, remove `127.0.0.1:` from `SHINYPROXY_HOST_PORT`.
1. If using internal nginx, create `nginx/certs` and add your `public.crt` and `private.key`.
1. Add proprietary models in `analysis/externaldata` and `analysis/extrasample` directories.

```bash
docker-compose up
```
This will take quite a bit of time on first run to pull gigabytes of dependencies to build the
container images, after which the application will be available at localhost.

The images are also already on [GitHub Container Registry](https://docs.github.com/en/packages/guides/about-github-container-registry).
To make use of these instead, you will need to enable "Improved container support" in the "Feature preview"
menu item, accessible by clicking on your profile picture in the top-right of GitHub. Then, in your
[Developer settings](https://github.com/settings/tokens), create a personal access token with access
to `read:packages`.

Login to registry on your command-line and paste in the generated token when prompted.

```bash
docker login -u GITHUB_USERNAME --password-stdin
```

After you get access to the three private images, you no longer need to build the images locally.

```bash
docker-compose pull
docker-compose up
```

If not using internal nginx, you do `docker-compose up -d executor shinyproxy` and forward requests to port 8080.

## Architecture
This deploys as several containers as described by Docker Compose. They are networked in the `methylation-main` Docker network and `.idat` files are persisted in the `./files` bind mount.

A PostgreSQL container initializes from `./db/init` and its data is backed by a bind mount to `./db/data`. By default, you can communicate with it on the host on port 5432.

A very heavy pipeline executor image is built from `./analysis` based on a Bioconductor image. It mounts `./analysis/logs`, the proprietary models, and `./files`.

`shiny-build` is only used to make Docker Compose build the `methylation-shiny` image with the rest of the containers. The Shiny app proper is not orchestrated by Docker Compose.

A Shinyproxy 2.3.1 image is built from `./shinyproxy` and OpenJDK 11. It is responsible for starting Shiny containers on demand within the `methylation-main` network and binding the `./files` mount. Shinyproxy itself mounts `./shinyproxy/logs`, the host Docker socket, and the host Docker volumes directory. By default you can access it on the host on port 8080.

Finally, an nginx container acts as a reverse proxy to Shinyproxy and takes care of HTTPS. It mounts TLS certificates from `./nginx/certs`.

