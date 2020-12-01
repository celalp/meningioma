FROM rocker/shiny:latest
RUN apt update -y && \
    apt install -y libpq-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /srv/shiny-server
COPY install.R .
RUN Rscript install.R
COPY . .
VOLUME ["files"]
# The latest Shiny server images require this to avoid
# starting the s6 supervisor as non-root
CMD ["/usr/bin/shiny-server"]
