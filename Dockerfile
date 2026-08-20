ARG OS_VERSION=debian:trixie-slim
#ARG OS_VERSION=ubuntu:26.04
FROM ${OS_VERSION} AS builder

ARG QGIS_VERSION=final-4_2_0
ARG QGIS_VERSION_SHORT=4_2

WORKDIR /build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        dh-python \
        doxygen \
        expect \
        flex \
        flip \
        gdal-bin \
        git \
        graphviz \
        grass-dev \
        libdraco-dev \
        libexiv2-dev \
        libexpat1-dev \
        libgdal-dev \
        libgeos-dev \
        libgsl-dev \
        libpq-dev \
        libproj-dev \
        libprotobuf-dev \
        libqca-qt6-dev \
        libqscintilla2-qt6-dev \
        libqt6opengl6-dev \
        libqt6svg6-dev \
        libspatialindex-dev \
        libspatialite-dev \
        libsqlite3-dev \
        libsqlite3-mod-spatialite \
        libyaml-tiny-perl \
        libzip-dev \
        libzstd-dev \
        lighttpd \
        locales \
        ninja-build \
        ocl-icd-opencl-dev \
        opencl-headers \
        pandoc \
        pkg-config \
        poppler-utils \
        protobuf-compiler \
        pyqt6-dev-tools \
        pyqt6.qsci-dev \
        python3-all-dev \
        python3-autopep8 \
        python3-dev \
        python3-gdal \
        python3-jinja2 \
        python3-lxml \
        python3-mock \
        python3-nose2 \
        python3-owslib \
        python3-plotly \
        python3-psycopg2 \
        python3-pygments \
        python3-pyproj \
        python3-pyqt6.sip \
        python3-pyqtbuild \
        python3-termcolor \
        python3-yaml \
        qmake6 \
        qt6-5compat-dev \
        qt6-base-dev \
        qt6-base-private-dev \
        qt6-multimedia-dev \
        qt6-pdf-dev \
        qt6-positioning-dev \
        qt6-serialport-dev \
        qt6-tools-dev \
        qt6-tools-dev-tools \
        qt6-webengine-dev \
        qtkeychain-qt6-dev \
        sip-tools \
        xauth \
        xfonts-100dpi \
        xfonts-75dpi \
        xfonts-base \
        xfonts-scalable \
        xvfb

RUN git clone --depth 1 https://github.com/qgis/QGIS.git --single-branch --branch=${QGIS_VERSION} && \
    mkdir build && \
    mkdir /build/dist

RUN cmake -B build \
        -S QGIS \
        -G Ninja \
        -D CMAKE_INSTALL_PREFIX="" \
        -D WITH_ANALYSIS=TRUE \
        -D WITH_DESKTOP=FALSE \
        -D WITH_GRASS7=FALSE \
        -D WITH_GUI=FALSE \
        -D WITH_INTERNAL_SPATIALINDEX=true \
        -D WITH_QGIS_PROCESS=TRUE \
        -D WITH_QTSERIALPORT=FALSE \
        -D WITH_STAGED_PLUGINS=FALSE \
        -D WITH_SERVER=FALSE \
        -D WITH_3D=FALSE \
        -D WITH_PDAL=FALSE \
        -D ENABLE_TESTS=FALSE && \
    cmake --build build && \
    DESTDIR=/build/dist cmake --install build

RUN rm -rf /build/dist/share/qgis/resources/server

# -----------------------------------------------------------------------------

FROM ${OS_VERSION}
ENV QGIS_AUTH_DB_DIR_PATH=/auth

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        fontconfig \
        xvfb \
        tzdata \
        bash

COPY --from=builder /build/dist/ /usr

COPY uid_entrypoint.sh /usr/local/bin/
COPY run.sh /usr/local/bin/
ADD fonts/admin_ch_symbols /usr/share/fonts/truetype/
ADD fonts/fontawesome /usr/share/fonts/truetype/

RUN fc-cache -f -v && \
    useradd \
      --system \
      --uid 1001 \
      --gid 0 \
      --shell /bin/bash \
      --no-create-home \
      --no-user-group \
      --password '*' \
      qgis && \
    mkdir -p /data && \
    chown 1001:0 /data && \
    chmod g=u /data && \
    mkdir -p /auth && \
    chown 1001:0 /auth && \
    chmod g=u /auth && \
    chgrp 0 /etc/passwd && \
    chmod g=u /etc/passwd

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libdraco8 \
        libexiv2-28 \
        libexpat1 \
        libgeos-c1v5 \
        libgsl28 \
        libpq5 \
        libproj25 \
        libprotobuf-lite32t64 \
        libpython3.13 \
        libqca-qt6-2 \
        libqscintilla2-qt6-15 \
        libqt6core6 \
        libqt6concurrent6 \
        libqt6gui6 \
        libqt6keychain1 \
        libqt6network6 \
        libqt6multimedia6 \
        libqt6opengl6 \
        libqt6positioning6 \
        libqt6printsupport6 \
        libqt6serialport6 \
        libqt6sql6 \
        libqt6svg6 \
        libqt6webenginecore6 \
        libqt6xml6 \
        libzip5 \
        python3-autopep8 \
        python3-gdal \
        python3-jinja2 \
        python3-lxml \
        python3-mock \
        python3-nose2 \
        python3-owslib \
        python3-plotly \
        python3-psycopg2 \
        python3-pygments \
        python3-pyproj \
        python3-pyqt6 \
        python3-pyqt6.qsci \
        python3-pyqt6.qtpositioning \
        python3-pyqt6.qtserialport \
        python3-pyqt6.qtsvg \
        python3-pyqtbuild \
        python3-termcolor \
        python3-yaml \
        ocl-icd-libopencl1

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

WORKDIR /data

ENTRYPOINT [ "/tini", "--", "/usr/local/bin/uid_entrypoint.sh" ]

ENV PYTHONPATH="/usr/share/qgis/python/"
ENV QT_QPA_PLATFORM=offscreen

EXPOSE 5000

CMD [ "/usr/local/bin/run.sh" ]

USER 1001
