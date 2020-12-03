ARG R_VERSION=latest
FROM rocker/verse:${R_VERSION}

RUN apt update -y && \
    apt install -y libpq-dev pandoc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app
COPY install.R .
RUN Rscript install.R
COPY . .

# VOLUME ["externaldata", "extrasample", "files", "logs"]
CMD ["Rscript", "analysis_pipeline.R",  "-y", "config.yaml"]

