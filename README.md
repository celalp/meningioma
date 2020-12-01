# Methylation webapp

Copy `sample.env` to `.env` and change the credentials.
Create `nginx/certs` and add your `public.crt` and `private.key`.

```bash
cd app
docker-compose build
cd ..
docker-compose up
```
The application is now available at localhost.


## TODO
R side:
Shiny: read Postgres variables from environment variables
Shiny: prune unused contents from `config.yaml`
Pipeline: read Postgres variables from environment variables
Pipeline: clean up configuration

Shinyproxy: investigate logging issue with 2.4.x
Postgres: log bind mount not doing anything
Shiny: independent Docker Compose mounts
