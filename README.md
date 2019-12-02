Nginx (Alpine-based) with many 3rd-party modules and [S6 overlay](https://github.com/just-containers/s6-overlay).

## Usage

To get started.

### docker

```
docker create \
  --name=docker-nginx \
  -e TZ=UTC \
  -e PUID=33 \
  -e PGID=33 \
  --restart unless-stopped \
  qedadmin/alpine-nginx
```

## Parameters


| Parameter | Function |
| :---- | --- |
| `-e TZ=UTC` | Set timezone |
| `-e PUID=33` | Set www-data uid |
| `-e PGID=33` | Set www-data gid |
