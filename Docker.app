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

RUN apt-get install software-properties-common --yes && \
	add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/' && \
	apt-get update --yes && \
    apt-get install libpq-dev --yes && \
	apt install r-base --yes

COPY ./install_apppacks.R /opt/app/install_apppacks.R

RUN Rscript /opt/app/install_apppacks.R

COPY ./launch_app.R /opt/app/launch_app.R

EXPOSE 3838

WORKDIR /opt/app

CMD Rscript /opt/app/launch_app.R




