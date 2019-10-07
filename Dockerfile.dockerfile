FROM r-base:latest

LABEL authors="Jakub Wąsik <jakub.wasik@analyx.com>" \
      
RUN apt-get update && apt-get install -y \
  libpq-dev \
  libssl-dev \
  libssh2-1-dev \
  libgit2-dev \
  libcurl4-openssl-dev \
  libxml2-dev \
  libpoppler-cpp-dev \
  libapparmor-dev \
  pandoc \
  openjdk-8-jdk

COPY RocheETL /tmp/RocheETL

ENV JSON_DIRECTORY="/opt/data"
ENV ROCHE_ETL_DIRECTORY="/tmp/RocheETL"

# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN R -e "install.packages(c('devtools', 'roxygen2'))"
# installing dependencies earlies allows us to document package here
RUN R -e "devtools::document('/tmp/RocheETL')" && \
    R -e "devtools::install('/tmp/RocheETL', dependencies = F, args = c('--no-test-load'), keep_source = T)"

ENTRYPOINT ["R", "-e"]