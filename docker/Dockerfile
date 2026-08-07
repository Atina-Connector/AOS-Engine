FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        octave \
        octave-common \
        gnuplot-nox \
        ghostscript \
        python3 \
        ca-certificates \
        locales \
        util-linux \
        fontconfig \
        fonts-freefont-otf \
        fonts-dejavu-core \
        fonts-liberation \
    && fc-cache -f -v \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen es_AR.UTF-8

ENV LANG=es_AR.UTF-8
ENV LC_ALL=es_AR.UTF-8
ENV HOME=/home/aos
ENV AOS_ROOT=/opt/aos
ENV GNUTERM=dumb

RUN useradd \
        --create-home \
        --home-dir /home/aos \
        --shell /bin/bash \
        --uid 10001 \
        aos

WORKDIR /opt/aos

COPY app/ /opt/aos/
COPY docker/aos-internal /usr/local/bin/aos-internal

RUN chmod +x /usr/local/bin/aos-internal \
    && mkdir -p \
        /opt/aos/datos_usuario \
        /opt/aos/intercambio \
        /opt/aos/salida \
        /opt/aos/logs \
    && chmod -R a+rX /opt/aos \
    && chown -R aos:aos \
        /home/aos \
        /opt/aos/datos_usuario \
        /opt/aos/intercambio \
        /opt/aos/salida \
        /opt/aos/logs

USER aos

CMD ["sleep", "infinity"]