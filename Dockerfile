ARG OS_VERSION=ubuntu:22.04
#ARG OS_VERSION=debian:bullseye-slim
FROM ${OS_VERSION} AS builder

ARG QGIS_VERSION=final-3_28_15
ARG QGIS_VERSION_SHORT=3_28

WORKDIR /build

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        cmake-curses-gui \
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
        libfcgi-dev \
        libgdal-dev \
        libgeos-dev \
        libgsl-dev \
        libpdal-dev \
        libpq-dev \
        libproj-dev \
        libprotobuf-dev \
        libqca-qt5-2-dev \
        libqca-qt5-2-plugins \
        libqscintilla2-qt5-dev \
        libqt5opengl5-dev \
        libqt5serialport5-dev \
        libqt5sql5-sqlite \
        libqt5svg5-dev \
        libqt5webkit5-dev \
        libqt5xmlpatterns5-dev \
        libqwt-qt5-dev \
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
        pdal \
        pkg-config \
        poppler-utils \
        protobuf-compiler \
        pyqt5-dev \
        pyqt5-dev-tools \
        pyqt5.qsci-dev \
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
        python3-pyqt5 \
        python3-pyqt5.qsci \
        python3-pyqt5.qtmultimedia \
        python3-pyqt5.qtpositioning \
        python3-pyqt5.qtserialport \
        python3-pyqt5.qtsql \
        python3-pyqt5.qtsvg \
        python3-pyqt5.qtwebkit \
        python3-pyqtbuild \
        python3-sip \
        python3-termcolor \
        python3-yaml \
        qt3d-assimpsceneimport-plugin \
        qt3d-defaultgeometryloader-plugin \
        qt3d-gltfsceneio-plugin \
        qt3d-scene2d-plugin \
        qt3d5-dev \
        qtbase5-dev \
        qtbase5-private-dev \
        qtkeychain-qt5-dev \
        qtmultimedia5-dev \
        qtpositioning5-dev \
        qttools5-dev \
        qttools5-dev-tools \
        sip-tools \
        spawn-fcgi \
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
        -D WITH_ANALYSIS=FALSE \
        -D WITH_DESKTOP=FALSE \
        -D WITH_GRASS7=FALSE \
        -D WITH_GUI=FALSE \
        -D WITH_QGIS_PROCESS=FALSE \
        -D WITH_QT5SERIALPORT=FALSE \
        -D WITH_QTWEBKIT=FALSE \
        -D WITH_STAGED_PLUGINS=FALSE \
        -D WITH_SERVER=TRUE \
        -D WITH_3D=FALSE && \
    cmake --build build && \
    DESTDIR=/build/dist --install build

# -----------------------------------------------------------------------------

FROM ${OS_VERSION}
ENV QGIS_AUTH_DB_DIR_PATH=/auth

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        fontconfig \
        spawn-fcgi \
        xvfb \
        tzdata \
        bash && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=builder /build/dist/ /usr

COPY uid_entrypoint.sh /usr/local/bin/
COPY run.sh /usr/local/bin/
ADD fonts/admin_ch_symbols /usr/share/fonts/truetype/
ADD fonts/fontawesome /usr/share/fonts/truetype/

RUN fc-cache -f -v && \
    adduser \
        --system \
        --uid 1001 \
        --gid 0 \
        --shell /bin/bash \
        --no-create-home \
        --disabled-password \
        --disabled-login \
        qgis && \
    mkdir -p /data && \
    chown 1001:0 /data && \
    chmod g=u /data && \
    mkdir -p /auth && \
    chown 1001:0 /auth && \
    chmod g=u /auth && \
    chgrp 0 /etc/passwd && \
    chmod g=u /etc/passwd

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libexiv2-27 \
        libexpat1 \
        libfcgi-bin \
        libgdal30 \
        libgeos3.10.2 \
        libgeos-c1v5 \
        libgsl27 \
        libpdal-base13 \
        libpq5 \
        libproj22 \
        libprotobuf-lite23 \
        libqca-qt5-2 \
        libqt5concurrent5 \
        libqt5core5a \
        libqt5gui5 \
        libqt5keychain1 \
        libqt5positioning5 \
        libqt5printsupport5 \
        libqt5serialport5 \
        libqt5sql5 \
        libqt5xml5 \
        libspatialindex6 \
        libzip4 \
        ocl-icd-libopencl1 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

WORKDIR /data

ENTRYPOINT [ "/tini", "--", "/usr/local/bin/uid_entrypoint.sh" ]

EXPOSE 5000

CMD [ "/usr/local/bin/run.sh" ]

USER 1001
