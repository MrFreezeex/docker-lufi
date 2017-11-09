# docker-lufi

## Projet Lufi

https://framagit.org/luc/lufi#tab-readme

## Compose

### `docker-compose.yml`

	services:
	  app:
	    image: s7b4/lufi
	    init: true
	    network_mode: bridge
	    ports:
	    - 8080:8080/tcp
	    restart: always
	version: '2.2'
