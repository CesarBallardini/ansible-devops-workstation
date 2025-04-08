# Inicio de una pc / notebook

# A. Usando acceso físico a la nueva pc

1. Instalamos con el medio de instalación que hayamos escogido

2. El paquete `openssh-server` está instalado en la pc, para así tener acceso remoto para la instalación.

Entonces tengo la dirección IP de la nueva pc en la variable `NODO_IP_ADDRESS`, ej:

```bash
export NODO_IP_ADDRESS=192.168.99.104
```

3. Activamos que `root` pueda acceder por SSH:

En `/etc/ssh/sshd_config` aseguramos que existe la línea:

```text
PermitRootLogin yes
```

Reiniciamos el daemon SSH:

```bash
sudo service ssh restart
```

Imponemos una contraseña a la cuenta `root`:

```bash
echo root:perico | sudo chpasswd
```


# B. Asegurar el acceso en forma remota a la pc

Verificamos que podemos ingresar con las credenciales de `root` mediante ssh:

```bash
ssh-keyscan -H "${NODO_IP_ADDRESS}" >> ~/.ssh/known_hosts
ssh root@"${NODO_IP_ADDRESS}"
```

Agregamos nuestras claves de SSH a la pc:

```bash
ssh-copy-id root@"${NODO_IP_ADDRESS}"
```


Creamos una función de utilidad en Bash:

```bash

NODO_IP_ADDRESS=192.168.99.104
NODO_USERNAME=root
NODO_PASSWORD=perico

cmd(){

  #sshssh-keygen -f "~/.ssh/known_hosts" -R "${NODO_IP_ADDRESS}"
  #ssh-copy-id -i ~/.ssh/id_rsa "${NODO_USERNAME}@${NODO_IP_ADDRESS}"

  sshpass -p "${NODO_PASSWORD}" ssh \
    -o StrictHostKeyChecking=no \
    -i ~/.ssh/id_rsa \
    "${NODO_USERNAME}@${NODO_IP_ADDRESS}" \
    "$*"
}


apt_cmd(){

  mandato=$1
  shift

  cmd "
    export DEBIAN_FRONTEND=noninteractive ;
    export DEBCONF_NONINTERACTIVE_SEEN=true ;
    export UCF_FORCE_CONFOLD=1 ;
    export APT_LISTCHANGES_FRONTEND=none ;
          echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
    apt-get -q --option \"Dpkg::Options::=--force-confold\" $mandato $* -y"
}



```

# C. Configuramos la hora y timezone correctos

## Ponemos en hora la pc con NTP:

```bash
cmd date

cmd sudo timedatectl set-timezone America/Argentina/Buenos_Aires
cmd sudo timedatectl set-ntp no
cmd sudo timedatectl set-local-rtc 0
cmd timedatectl  status

cmd sudo apt-get update
cmd sudo apt-get install ntp -y

# TODO: hacer un script de sed para que edite el /etc/ntp.conf y le imponga el NTP server de la organizacion
# o sino está definido, que deje los que vienen predeterminados

# pool 0.ubuntu.pool.ntp.org iburst borrar
# pool 1.ubuntu.pool.ntp.org iburst cambiar <NTP1.MIDOMINIO.COM>
# pool 2.ubuntu.pool.ntp.org iburst
# pool 3.ubuntu.pool.ntp.org iburst

cmd sudo service ntp restart
sleep 30
cmd sudo hwclock --systohc
cmd ntpq -p
```


Fecha con Chrony:

```bash

configuracion_fecha() {

  cmd timedatectl
  #cmd timedatectl list-timezones
  cmd timedatectl set-timezone America/Argentina/Buenos_Aires
  cmd timedatectl set-local-rtc 0
  cmd timedatectl set-ntp on
  cmd apt install chrony -y

#  cmd sed -i -e \'s/pool ntp.ubuntu.com[ ]*iburst maxsources.*//\'  /etc/chrony/chrony.conf
#  cmd sed -i -e \'s/pool 0.ubuntu.pool.ntp.org[ ]*iburst maxsources.*/server ntp1.MIDOMINIO.COM iburst maxsources 4/\' /etc/chrony/chrony.conf
#  cmd sed -i -e \'s/pool 1.ubuntu.pool.ntp.org[ ]*iburst maxsources.*/server ntp2.MIDOMINIO.COM iburst maxsources 1/\' /etc/chrony/chrony.conf
#  cmd sed -i -e \'s/pool 2.ubuntu.pool.ntp.org[ ]*iburst maxsources.*/server ntp3.MIDOMINIO.COM iburst maxsources 2/\' /etc/chrony/chrony.conf

  cmd systemctl restart chrony.service
  cmd systemctl restart systemd-timesyncd
  cmd systemctl status systemd-timesyncd
  cmd sudo hwclock --systohc
  #cmd sudo chronyd -q
  cmd timedatectl
}

```


# D. Creamos la cuenta de usuario nominada para trabajar en la pc


1. Aseguramos que existe la cuenta `cesarballardini` con `uid` 1001.

Por simplificar voy a usar mi nombre de cuenta; y la contraseña para
este tutorial será `perico`.


* existe con `uid` 1001
* pertenece al grupo `sudo`
* y a los grupos:

```text
adm:x:4:syslog,cesarballardini,administrador
lp:x:7:cesarballardini,administrador
cdrom:x:24:cesarballardini,administrador
sudo:x:27:cesarballardini,administrador
dip:x:30:cesarballardini,administrador
plugdev:x:46:cesarballardini,administrador
lpadmin:x:116:cesarballardini,administrador
sambashare:x:122:cesarballardini,administrador
rvm:x:1002:cesarballardini,administrador
docker:x:999:cesarballardini,administrador
fuse:x:998:cesarballardini
cesarballardini:x:1001:
```

Con esos datos, la creación ese hace con:

```bash
cmd  groupadd --gid 1001 cesarballardini
cmd  useradd --create-home --groups sudo,adm,lp,dip,lpadmin,sambashare,fuse,dialout,cdrom,floppy,audio,video,plugdev,users --shell /bin/bash --gid 1001 --uid 1001 cesarballardini
cmd "echo cesarballardini:perico | chpasswd"
```


2. Los miembros del grupo `sudo` no necesitan poner contraseña para correr mandatos de `root`

```bash
cmd "sed -e 's/%sudo[[:space:]]*ALL=(ALL:ALL)[[:space:]]ALL/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/' < /etc/sudoers > /tmp/sudoers.new"
cmd "visudo --check --file=/tmp/sudoers.new && cp /tmp/sudoers.new /etc/sudoers"
```


# E. Instalaciones y configuraciones iniciales para un nodo de tipo escritorio de trabajo

```bash
apt_cmd update
apt_cmd upgrade
apt_cmd dist-upgrade
apt_cmd autoremove

apt_cmd install screen vim git
apt_cmd install lubuntu-gtk-desktop

cmd reboot

cmd apt-get install ubuntu-mate-desktop^ -y 



```

# F. Acceso a LUKS devices

Para leer el viejo disco cifrado con LUKS, y desde ese disco copiar hacia el nuevo.

## Instalo soporte para crypto LUKS

```bash
apt_cmd install cryptsetup-bin lvm2

```


```bash

# Encuentro cuál es el dispositivo cifrado con LUKS
blkid --match-token TYPE=crypto_LUKS  --output device

# Estado de un dispositivo LUKS
sudo cryptsetup status $( sudo cryptsetup luksUUID /dev/sdc5 )


# Abrir la partición cifrada (pide la passphrase, alguna de todas las almacenadas en los slots)
sudo cryptsetup -v luksOpen /dev/sdc5 sdc5_crypt

Enter passphrase for /dev/sda5: 
Key slot 1 unlocked.
Command successful.

# ver rutas de las unidades
sudo lvdisplay | grep "LV Path"
  LV Path                /dev/dskvg/root
  LV Path                /dev/dskvg/altroot
  LV Path                /dev/dskvg/swap
  LV Path                /dev/dskvg/home


# crear puntos de montaje para el viejo disco y montarlo
sudo mkdir -p /home/respaldos/kirk-disco-viejo/{root,altroot,home}

sudo mount -o ro,noload /dev/dskvg/root    /home/respaldos/kirk-disco-viejo/root
sudo mount -o ro,noload /dev/dskvg/altroot /home/respaldos/kirk-disco-viejo/altroot
sudo mount -o ro,noload /dev/dskvg/home    /home/respaldos/kirk-disco-viejo/home

# copia los respaldos del viejo disco al nuevo
time sudo rsync -Pav /home/respaldos/kirk-disco-viejo/altroot /home/respaldos/kirk/
time sudo rsync -Pav /home/respaldos/kirk-disco-viejo/home    /home/respaldos/kirk/
time sudo rsync -Pav /home/respaldos/kirk-disco-viejo/root    /home/respaldos/kirk/


# Cerrar la partición cifrada

sudo vgchange -a n dskvg                         
#  0 logical volume(s) in volume group "dskvg" now active

sudo cryptsetup luksClose /dev/mapper/sda5_crypt
```


# G. Copiar elementos del HOME de mi cuenta

Las claves de SSH, `.gitconfig`,  `.stg-intranet-password` y las configuraciones de los programas de escritorio en `.config`, y parte del entorno 
de trabajo de Virtualbox y Vagrant, las cachés de Chrome y Firefox, etc.

Activo mi espacio de trabajo y ya puedo continuar con mis obligaciones, mientras se restauran las cuentas de los demás.


```
.config
.docker
.dropbox
.dropbox-dist
.gnupg
.hplip
.mozilla
.ssh
.vagrant.d (ver less_insecure_private_key dueño y grupo usuario, permisos ---x-wx--T -> g+w o+t
Descargas
Desktop
Documentos
Dropbox
Escritorio
Imágenes
VirtualBox VMs
atico
bin
cesar
stg
.docker_password.txt
.gitconfig
.stg-intranet-password
```

# H. Instalar software de escritorio y devops

La instalación está automatizada por medio de Ansible

```bash
# instalar Ansible
sudo apt-get install -y python3-pip
sudo -H python3 -m pip install --upgrade pip setuptools wheel
sudo -H python3 -m pip install --upgrade ansible

# clonar repo de código genérico y de inventario para kirk
cp /home/respaldos/kirk/home/cesarballardini/.gitconfig ~
mkdir -p ~/cesar/github/
cd ~/cesar/github/
git clone https://github.com/CesarBallardini/ansible-devops-workstation.git
cd ansible-devops-workstation/
git clone https://github.com/CesarBallardini/kirk_inventario_workstations.git inventario

mkdir roles/
ansible-galaxy install -r requirements.yml --roles-path=roles/

# crear la instalacion de kirk para escritorio devops
ret=1 ; pushd ~/cesar/github/ansible-devops-workstation/ ; git pull ;  popd ; while [ "$ret" -ne 0 ] ; do  sudo apt-get update ; [ $? -ne 0 ] && break ; pushd ~/cesar/github/ansible-devops-workstation/ ; time ansible-playbook -i inventario  site.yml  ; ret=$? ; popd ; sleep 5m ; done ; sync ; notify-send "termino la actualizacion" # actualiza

```


# I. Crear cuentas de la familia

```bash
alta_usuario() {
  USERID=$1
  USERNAME=$2

  sudo groupadd --gid ${USERID} ${USERNAME}
  sudo useradd --groups cdrom,floppy,audio,video,plugdev,users --shell /bin/bash --gid ${USERID} --uid ${USERID} ${USERNAME}
}

alta_usuario 1002 flor
alta_usuario 1003 norma
alta_usuario 1004 julian
```


Copiar las lineas de /home/respaldos/kirk/root/etc/shadow viejas para tener las mismas contraseñas

# J. Restaurar HOMEs de la familia

Se puede evitar la restauración de las cachés de Chrome y Firefox, o restaurar todo como se muestra a continuación:

```bash
sudo rsync -Pav /home/respaldos/kirk/norma /home
sudo rsync -Pav /home/respaldos/kirk/flor  /home
sudo rsync -Pav /home/respaldos/kirk/julian /home

# luego de comprobar que todo está bien, eliminar la copa de respaldo en /home/respaldos/kirk/{norma,flor,julian}
```

Otra alternativa es mover con cuidado mediante `mc` los directorios de usuario desde el respaldo.


