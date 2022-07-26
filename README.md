
# Playbooks Ansible que instalan una estación de trabajo para personal DevOps

[![Build Status](https://travis-ci.com/CesarBallardini/ansible-devops-workstation.svg?branch=master)](https://app.travis-ci.com/github/CesarBallardini/ansible-devops-workstation)

A partir de una instalación base de Ubuntu 18.04, 20.04, 22.04 se pueden agregar las herramientas
populares para trabajar en las siguientes áreas:


* Escritorio gráfico para navegar en Internet (el escritorio se instala previamente al trabajo de los playbooks)
  * Google Chrome
  * LibreOffice
  * Herramientas para crear screencasts
  * Emulador 3270 (está comentado el código para que no se instale)
  * Flatpak
  * Snap
  * Skype (para hablar con los clientes :)  

* Editores / IDEs
  * Atom
  * IntelliJ IDEA Community
  * MS VisualStudio Code
  * Netbeans
  * Sublime 3
  * WebStorm

* DevOps
  * Ansible
  * Docker
  * Git
  * Goss / DGoss
  * GOVC: gestión de VMware vCenter
  * Packer
  * Terraform / Terraform Docs / Terragrunt
  * Vagrant + plugins
  * VirtualBox
  * vmWare Workstation (queda deshabilitado para que no corra al inicio del sistema)
  
* Útiles en la asignatura Paradigmas de Programación
  * SWI-Prolog
  * Racket (Scheme)
  * Pharo Smalltalk

Se consideran algunas optimizaciones de performance para aquellos que trabajan con
computadoras de bajos recursos (4 GB RAM, Intel(R) Core(TM) i3-4130 CPU @ 3.40GHz, 
almacenamiento magnético rotativo, etc.)

# 1. Cómo usar este repositorio sobre un nodo físico

Cómo instalar una notebook o pc con estas herramientas.

## 1.1. Instale desde DVD o mediante PXE un escritorio Ubuntu 18.04, 20.04, 22.04

1. `sudo` configurado para correr sin pedir contraseña con la cuenta que corre este script
2. APT configurado (mirrors, acceso al mirror y acceso a fuentes de paquetes por internet)
3. Proxy configurado en `/etc/environment` (para curl, wget, etc.)


## 1.2. Instale y configure Git

```bash
sudo apt install git -y 
```

## 1.3. Clone este repositorio

```bash
git clone https://github.com/CesarBallardini/ansible-devops-workstation.git
cd ansible-devops-workstation/
```
A partir de este momento, el resto de las actividades las realizaremos desde
ese directorio.


## 1.4. Instale los requisitos para que funcione ansible

```bash
sudo apt-get install -y python3-pip
sudo -H python3 -m pip install --upgrade pip setuptools wheel
sudo -H python3 -m pip install --upgrade ansible
```

Verificado con Ansible versión 2.8.6, python version 3.6.8

## 1.5. Instalar con Ansible el resto del software

```bash
mkdir roles/
ansible-galaxy install -r requirements.yml --roles-path=roles/
```


* Ejecutamos Ansible sobre localhost, con las variables de `host-vars.yml` para la configuración:

```bash
time ansible-playbook -vv -i hosts site.yml --extra-vars "@hosts-vars.yml"
```

Si escribimos un inventario en su directorio, podemos correrlo con:

```bash
time ansible-playbook -vv -i inventario site.yml --limit localhost

```

## 1.6. Crear un inventario para su local

* el directorio para el inventario:

```bash
mkdir -p inventario/{group_vars,host_vars}
```


* la lista de hosts, localhost en el caso más simple:

```bash
cat - > inventario/hosts  <<EOF
localhost ansible_connection=local

[ejemplo]
localhost

[tinyproxy]
localhost

[servidor]
localhost

[escritorio]
localhost

[devops]
localhost

[utn]
localhost

[python3]
localhost

[python3:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

* las variables de host: copiar la plantilla de variables `hosts-vars.yml` y reemplazar las que corresponda.

```bash
cp hosts-vars.yml inventario/host_vars/localhost
```

Las variables a modificar según su ambiente local son las siguientes:


`security_repo_base_url`:
URL base del repositorio de seguridad para Ubuntu (no es necesario modificarla)

`standard_repo_base_url`:
URL base del repositorio base para Ubuntu (no es necesario modificarla)

`oracle_java_repository`:
Repositorio para Java de Oracle, deprecado pues Oracle no distribuye más sin pago sus binarios

`devops_user`:
El username de la cuenta que usa el usuario devops

`tinyproxy_listen_ip` y `tinyproxy_listen_port`:
Dirección IP donde debe escuchar peticiones el servidor TinyProxy

`tinyproxy_no_upstream`:
lista de dominios y CIDR que el TinyProxy debe acceder directamente, sin pasar por el proxy de aguas arriba

`tinyproxy_default_upstream`:
'DIRECCION_IP_PROXY_CORPORATIVO:PUERTO_PROXY_CORPORATIVO' info del proxy aguas arriba, o sea, el proxy 
corporativo que nos permite salir a Internet desde la oficina.

`tinyproxy_allow`: lista de CIDR autorizados a usar el TinyProxy, no olvidar localhost y mi dirección de IP en la red local

`organizacion`: String con el nombre de la organización, sólo a efectos de anotarla en `/etc/environment`

Y la configuración de proxy para salir a Internet.  Basta con asignar `all_proxy` y `no_proxy` cuando hay un solo proxy para todos los protocolos:

```text
all_proxy: 'http://<DIRECCION_IP_INTERFAZ_DE_RED>:8888'
http_proxy: '{{ all_proxy }}'
https_proxy: '{{ all_proxy }}'
ftp_proxy: '{{ all_proxy }}'
no_proxy: '10.,192.168.,wpad,127.0.0.1,localhost,.dominio.local.tld'
soap_use_proxy: 'on'
```

# 2. Cómo comprobar los playbooks mediante Vagrant y VirtualBox

## 2.1. Configure su estación de trabajo como en el punto 1. anterior

Si lo hace manualmente, debe tener instalados:

* Oracle Virtualbox y Oracle VM VirtualBox Extension Pack
* Vagrant
* Plugins de Vagrant:
  * vagrant-proxyconf y su configuracion si requiere de un Proxy para salir a Internet
  * vagrant-cachier
  * vagrant-disksize
  * vagrant-hostmanager
  * vagrant-share
  * vagrant-vbguest

Hace falta unos 26 GB de espacio en disco para crear la VM

## 2.2. Ejecute Vagrant

```bash
time vagrant up
```


Se usarán las configuraciones de Proxy de la estación de trabajo y el inventario (con sus variables) disponible
en `vagrant-inventory`.

`vagrant-inventory` tiene los archivos:

```text
vagrant-inventory/
├── ansible.cfg
├── hosts
└── host_vars
    └── devopsws
```
