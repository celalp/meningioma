FROM ubuntu:bionic

RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install curl --yes && \
    apt-get install libxml2 --yes && \
    apt-get install libcurl4-openssl-dev --yes && \
    apt-get install libssl-dev --yes && \
    apt-get install libxml2-dev --yes 


RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install software-properties-common --yes

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/'

RUN apt-get update --yes

RUN apt-get install libpq-dev --yes

RUN apt install r-base --yes

COPY ./install_apppacks.R app/install_apppacks.R

RUN Rscript app/install_apppacks.R

RUN useradd -ms /bin/bash application

USER application

RUN mkdir /home/application/app

WORKDIR /home/application/app



