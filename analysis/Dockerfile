ARG R_VERSION=latest
FROM rocker/verse:${R_VERSION}

RUN apt update -y && \
    apt install -y \
      libpq-dev \
      pandoc \
#      texlive-base \
#      texlive-binaries \
#      texlive-full \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app
COPY install.R .
RUN Rscript install.R

COPY  analysis_pipeline.R config.yaml header.png header.tex sample_report.Rmd ./

ADD ./extrasample ./extrasample
ADD ./externaldata ./externaldata

# VOLUME ["externaldata", "extrasample", "files", "logs"]
CMD ["Rscript", "analysis_pipeline.R",  "-y", "config.yaml"]

