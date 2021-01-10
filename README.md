# Gerbera
Docker installation of [gerbera](https://github.com/gerbera/gerbera), a upnp media server

# Usage
Either | Or
-------|---
git clone https://github.com/nbxtruong/gerbera.git | docker pull gpbenton/gerbera
cd gerbera                                         | mkdir gerbera
docker-compose build                               | cd gerbera

- edit volume lines in docker-compose.yaml to point to your media
- docker-compose up -d
