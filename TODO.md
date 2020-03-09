# TODO

# Ubuntu 18.04 Bionic

* ttf-mscorefonts-installer fallo al descargar archivos extras durante la instalacion FIXME

# Ubuntu 20.04 Focal Fossa

* no hay paquete `key-mon`
* no hay repo para `apt-fast` (usamos bionic)
* no hay repo para Docker, Virtualbox (usamos eoan)
* youtube-dl busca `/usr/bin/env python` y eso no existe en Focal y no trae Python2 de fábrica
* ttf-mscorefonts-installer fallo al descargar archivos extras durante la instalacion


# Todas las distros


## Configurar NTP como servidor de hora

En las versiones basadas en Systemd ya no se usa NTP. CUIDADO!

```bash

cmd() {
  ssh root@<direccion_ip_nuevo_nodo> $*
}

cmd date

cmd sudo timedatectl set-timezone America/Argentina/Buenos_Aires
cmd sudo timedatectl set-ntp no
cmd sudo timedatectl set-local-rtc 0
cmd timedatectl  status

cmd sudo apt-get update
cmd sudo apt-get install ntp -y

# pool 0.ubuntu.pool.ntp.org iburst borrar
# pool 1.ubuntu.pool.ntp.org iburst cambiar <servidor nombres interno de organizacion>
# pool 2.ubuntu.pool.ntp.org iburst
# pool 3.ubuntu.pool.ntp.org iburst

cmd sudo service ntp restart
sleep 30
cmd sudo hwclock --systohc
cmd ntpq -p


cmd useradd --create-home --user-group --uid <devops_user_uid> <devops_user_name>

```


