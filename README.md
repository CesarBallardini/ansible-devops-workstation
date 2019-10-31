# Ansible playbooks to install a devops workstation

A partir de una instalación base de Ubuntu 18.04 se pueden agregar las herramientas
populares para trabajar en las siguientes áreas:

* escritorio gráfico para navegar en Internet
* devops
* programación SWI-Prolog, Scheme y Pharo Smalltalk

Se consideran algunas optimizaciones de performance para aquellos que trabajan con
computadoras de bajos recursos (4 GB RAM, Intel(R) Core(TM) i3-4130 CPU @ 3.40GHz, 
almacenamiento magnético rotativo, etc.)

# 1. Cómo usar este repositorio

## 1.1. Instale desde DVD o mediante PXE un escritorio Ubuntu 18.04

1. `sudo` configurado para correr sin pedir contraseña con la cuenta que corre este script
2. APT configurado (mirrors, acceso al mirror y acceso a fuentes de paquetes por internet)
3. Proxy configurado en `/etc/environment` (para curl, wget, etc.)


## 1.2. Instale y configure Git

```bash
sudo apt install git
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


