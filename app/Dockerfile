ARG R_VERSION=latest
FROM rocker/r-ver:${R_VERSION}
RUN apt update -y && \
    apt install -y libpq-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/app
COPY install.R .
RUN Rscript install.R
COPY . .
# VOLUME ["files"]
EXPOSE 3838
CMD ["R", "-q", "-e", "shiny::runApp(host='0.0.0.0', port=3838)"]
