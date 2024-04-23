#!/usr/bin/env bash

set -e

/usr/bin/xvfb-run --server-num=1 /usr/bin/spawn-fcgi -p 5000 -n -d /data -- /opt/qgis/bin/qgis_mapserv.fcgi
