# qgis-slim

A containerized version of qgis without any bells and whistles.

Optimized for headless, containerized environments

- Builds on `debian:slim`
- Does not have any gui or server components included

## Releases

There are two streams, `stable` and `ltr`. These tags are moving targets and
new versions will be added as they appear.

Each QGIS release version will also have a moving tag, e.g. `3.28` which is
updated as releases appear.

In parallel there are also patch versions e.g. `3.28.2` which will only be
published once and then left stable.
