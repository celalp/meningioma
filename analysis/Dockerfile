ARG BIOCONDUCTOR_VERSION=latest
FROM bioconductor/bioconductor_docker:${BIOCONDUCTOR_VERSION}

RUN apt update -y && \
    apt install -y libpq-dev pandoc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app
COPY install.R .
RUN Rscript install.R
COPY . .

VOLUME ["analysis_logs", "files"]
CMD ["Rscript", "analysis_pipeline.R",  "-y", "config.yaml"]

