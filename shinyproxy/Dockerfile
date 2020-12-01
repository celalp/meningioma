ARG JDK_VERSION=11-jre
FROM openjdk:${JDK_VERSION}

ARG SHINYPROXY_VERSION=2.3.1
WORKDIR /opt/shinyproxy
RUN curl -o shinyproxy.jar https://www.shinyproxy.io/downloads/shinyproxy-${SHINYPROXY_VERSION}.jar

COPY application.yml .
# VOLUME ["logs"]
CMD ["java", "-jar", "shinyproxy.jar"]
