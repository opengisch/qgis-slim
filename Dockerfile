FROM debian:bullseye-slim AS builder

ARG QGIS_VERSION=final-3_28_1

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  wget \
  devscripts \
  equivs \
  grass-dev \
  python3-dev
WORKDIR /src
RUN wget https://github.com/qgis/QGIS/archive/refs/tags/${QGIS_VERSION}.tar.gz
RUN tar -xvf ${QGIS_VERSION}.tar.gz
RUN rm QGIS-${QGIS_VERSION}/debian/control
COPY debian/* QGIS-${QGIS_VERSION}/debian/
RUN cd QGIS-${QGIS_VERSION} && touch debian/*.in && make -f debian/rules
RUN (export DEBIAN_FRONTEND=noninteractive; cd QGIS-${QGIS_VERSION} && yes | mk-build-deps --install --remove debian/control)
RUN cd QGIS-${QGIS_VERSION} && dpkg-buildpackage -us -uc
RUN mkdir /src/release && mkdir /src/debug && mv /src/*dbg*.deb /src/debug && mv /src/*.deb /src/release

FROM debian:bullseye-slim AS release
COPY --from=builder /src/release/*.deb /src/
RUN ls /src/*.deb
RUN (export DEBIAN_FRONTEND=noninteractive; apt-get update && apt install -y /src/*.deb && rm -rf /var/lib/apt/lists/*)

FROM debian:bullseye-slim AS debug
COPY --from=builder /src/release/*.deb /src/
COPY --from=builder /src/debug/*.deb /src/
RUN ls /src/*.deb
RUN (export DEBIAN_FRONTEND=noninteractive; apt-get update && apt install -y /src/*.deb && rm -rf /var/lib/apt/lists/*)
