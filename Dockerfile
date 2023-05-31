FROM debian:bullseye-slim AS builder

ARG QGIS_VERSION=final-3_28_1
ARG QGIS_VERSION_SHORT=3_28
ARG QGIS_DEBIAN_REPOSITORY=

WORKDIR /src
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
  wget \
  software-properties-common
RUN wget https://github.com/qgis/QGIS/archive/refs/tags/${QGIS_VERSION}.tar.gz
ADD qgis-archive-keyring.gpg /etc/apt/keyrings/qgis-archive-keyring.gpg
ADD ${QGIS_DEBIAN_REPOSITORY}.sources /etc/apt/sources.list.d/qgis.sources
ADD debian/rules QGIS-${QGIS_VERSION}/debian/rules
RUN apt-get update
RUN apt-get build-dep -y qgis
RUN tar -xvf ${QGIS_VERSION}.tar.gz
RUN cd QGIS-${QGIS_VERSION} && DIST=bullseye dpkg-buildpackage -uc -us -b 




ENV QT_QPA_PLATFORM offscreen
