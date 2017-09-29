### PostgreSQL with [BDR](https://2ndquadrant.com/en/resources/bdr/) B-Directional Replication in a docker.

[![GitHub Open Issues](https://img.shields.io/github/issues/gaelrottier/docker-postgres-bdr.svg)](https://github.com/gaelrottier/docker-postgres-bdr/issues)
[![GitHub Stars](https://img.shields.io/github/stars/gaelrottier/docker-postgres-bdr.svg)](https://github.com/gaelrottier/docker-postgres-bdr)
[![GitHub Forks](https://img.shields.io/github/forks/gaelrottier/docker-postgres-bdr.svg)](https://github.com/gaelrottier/docker-postgres-bdr)  
[![Stars on Docker Hub](https://img.shields.io/docker/stars/gaelrottier/postgres-bdr.svg)](https://hub.docker.com/r/gaelrottier/postgres-bdr)
[![](https://images.microbadger.com/badges/version/gaelrottier/docker-postgres-bdr.svg)](https://microbadger.com/images/gaelrottier/docker-postgres-bdr)
[![](https://images.microbadger.com/badges/license/gaelrottier/docker-postgres-bdr.svg)](https://microbadger.com/images/gaelrottier/docker-postgres-bdr)
[![](https://images.microbadger.com/badges/image/gaelrottier/docker-postgres-bdr.svg)](https://microbadger.com/images/gaelrottier/docker-postgres-bdr)

[Docker Image](https://registry.hub.docker.com/u/gaelrottier/postgres-bdr/) with PostgreSQL server with [BDR](https://2ndquadrant.com/en/resources/bdr/) support for database **Bi-Directional** replication. Based on [CentOS with Supervisor](https://hub.docker.com/r/million12/centos-supervisor/).

### Environmental Variables

| Variable     | Meaning     |
| :-----------:| :---------- |
|`POSTGRES_PASSWORD`|Self explanatory|
|`POSTGRES_USER`|Self explanatory|
|`POSTGRES_DB`|Self explanatory|

### Usage

   docker run \
     -d \
     --name postgres \
     -p 5432:5432 \
     polinux/postgres-bdr

### Master + 2 slaves

se `docker-compose.yml` exmple.

### Deploy all at once from `docker-compose-yml` file.

   docker compose up

[All](https://raw.githubusercontent.com/pozgo/docker-postgres-bdr/master/images/all.gif)

### Deploy master only

   docker compose up master

[Master](https://raw.githubusercontent.com/pozgo/docker-postgres-bdr/master/images/master.gif)

### Deploy slave1 only

   docker compose up slave1

[Master](https://raw.githubusercontent.com/pozgo/docker-postgres-bdr/master/images/slave1.gif)

### Deploy slave2 only

   docker compose up slave2

![Master](https://raw.githubusercontent.com/pozgo/docker-postgres-bdr/master/images/slave2.gif)

### Build

    docker build -t polinux/postgres-bdr .

Docker troubleshooting
======================

Use docker command to see if all required containers are up and running:
```
$ docker ps
```

Check logs of postgres-bdr server container:
```
$ docker logs postgres-bdr
```

Sometimes you might just want to review how things are deployed inside a running
 container, you can do this by executing a _bash shell_ through _docker's
 exec_ command:
```
docker exec -ti postgres-bdr /bin/bash
```

History of an image and size of layers:
```
docker history --no-trunc=true polinux/postgres-bdr | tr -s ' ' | tail -n+2 | awk -F " ago " '{print $2}'
```

## Author

Przemyslaw Ozgo (<linux@ozgo.info>)  
This work is also inspired by [agios](https://github.com/agios)'s work on their [docker images](https://github.com/agios/docker-postgres-bdr). Many thanks!
