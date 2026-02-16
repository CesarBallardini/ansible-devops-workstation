
# Ansible Playbooks for DevOps Workstation

[![CI](https://github.com/CesarBallardini/ansible-devops-workstation/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/CesarBallardini/ansible-devops-workstation/actions/workflows/ci.yml)

From a base installation of Ubuntu 22.04, 24.04, 26.04 or Debian 13 (Trixie), Debian 14 (Forky) you can add the popular tools for working in the following areas:

* Graphical desktop for Internet browsing (the desktop is installed before running the playbooks)
  * Google Chrome
  * LibreOffice
  * Screencast tools
  * 3270 emulator (code is commented out to prevent installation)
  * Flatpak
  * Snap

* Editors / IDEs
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
  * GOVC: VMware vCenter management
  * Packer
  * Terraform / Terraform Docs / Terragrunt
  * Vagrant + plugins
  * VirtualBox
  * vmWare Workstation (disabled so it doesn't run at system startup)
  
* Useful for Programming Paradigms course
  * SWI-Prolog
  * Racket (Scheme)
  * Pharo Smalltalk

Some performance optimizations are considered for those working with low-end computers (4 GB RAM, Intel(R) Core(TM) i3-4130 CPU @ 3.40GHz, magnetic storage, etc.)

# 1. How to use this repository on a physical node

How to install a notebook or PC with these tools.

## 1.1. Install from DVD or via PXE Ubuntu 22.04, 24.04, 26.04 or Debian 13, 14

1. `sudo` configured to run without asking for password with the account running this script
2. APT configured (mirrors, mirror access and access to package sources over the internet)
3. Proxy configured in `/etc/environment` (for curl, wget, etc.)

## 1.2. Install and configure Git

```bash
sudo apt install git -y 
```

## 1.3. Clone this repository

```bash
git clone https://github.com/CesarBallardini/ansible-devops-workstation.git
cd ansible-devops-workstation/
```

From this point on, the rest of the activities will be performed from that directory.

## 1.4. Install Ansible and dependencies

```bash
./first-time-install-ansible.sh
```

* Run Ansible on localhost, with the variables from `hosts-vars.yml` for configuration:

```bash
# Ubuntu:
time ansible-playbook -vv -i hosts site.yml --extra-vars "@hosts-vars.yml"

# Debian:
time ansible-playbook -vv -i hosts site.yml --extra-vars "@hosts-vars-debian.yml"
```

If we write an inventory in your directory, we can run it with:

```bash
time ansible-playbook -vv -i inventario site.yml --limit localhost

```

## 1.5. Create an inventory for your local machine

* the directory for the inventory:

```bash
mkdir -p inventario/{group_vars,host_vars}
```

* the host list, localhost in the simplest case:

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

[ocsinventoryagent]
localhost

[python3]
localhost

[python3:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

* host variables: copy the variable template and replace the ones that correspond. Use `hosts-vars.yml` for Ubuntu or `hosts-vars-debian.yml` for Debian.

```bash
# Ubuntu:
cp hosts-vars.yml inventario/host_vars/localhost

# Debian:
cp hosts-vars-debian.yml inventario/host_vars/localhost
```

The variables to modify according to your local environment are as follows:

`security_repo_base_url`:
Base URL of the security repository for Ubuntu (no need to modify)

`standard_repo_base_url`:
Base URL of the base repository for Ubuntu (no need to modify)

`oracle_java_repository`:
Oracle Java repository, deprecated since Oracle no longer distributes binaries for free

`devops_user`:
The username of the account used by the devops user

`tinyproxy_listen_ip` and `tinyproxy_listen_port`:
IP address where the TinyProxy server should listen for requests

`tinyproxy_no_upstream`:
List of domains and CIDR that TinyProxy should access directly, without going through the upstream proxy

`tinyproxy_default_upstream`:
'CORPORATE_PROXY_IP_ADDRESS:PORT' upstream proxy info, i.e., the corporate proxy that allows us to exit to the Internet from the office.

`tinyproxy_allow`: list of CIDR authorized to use TinyProxy, don't forget localhost and my IP address on the local network

`organization`: String with the name of the organization, only for the purpose of noting it in `/etc/environment`

And the proxy configuration to exit to the internet. Just assign `all_proxy` and `no_proxy` when there is a single proxy for all protocols:

```text
all_proxy: 'http://<NETWORK_INTERFACE_IP>:8888'
http_proxy: '{{ all_proxy }}'
https_proxy: '{{ all_proxy }}'
ftp_proxy: '{{ all_proxy }}'
no_proxy: '10.,192.168.,wpad,127.0.0.1,localhost,.dominio.local.tld'
soap_use_proxy: 'on'
```

# 2. How to test the playbooks with Vagrant and VirtualBox

## 2.1. Configure your workstation as in the previous point 1.

If you do it manually, you must have installed:

* Oracle Virtualbox and Oracle VM VirtualBox Extension Pack
* Vagrant
* Vagrant Plugins:
  * vagrant-proxyconf and its configuration if you need a Proxy to access the Internet
  * vagrant-cachier
  * vagrant-disksize
  * vagrant-hostmanager
  * vagrant-share
  * vagrant-vbguest

You need about 26 GB of disk space to create the VM

## 2.2. Run Vagrant

This repository contains specific Vagrantfiles for each supported distribution:

| File | Distribution |
|---------|--------------|
| `Vagrantfile.ubuntu22.04` | Ubuntu 22.04 (Jammy) |
| `Vagrantfile.ubuntu24.04` | Ubuntu 24.04 (Noble) |
| `Vagrantfile.ubuntu26.04` | Ubuntu 26.04 (Resolute Raccoon) |
| `Vagrantfile.debian13` | Debian 13 (Trixie) |
| `Vagrantfile.debian14` | Debian 14 (Forky) |

### Usage

```bash
# Ubuntu 22.04
time VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu22.04 vagrant up

# Ubuntu 24.04
time VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu24.04 vagrant up

# Ubuntu 26.04
time VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu26.04 vagrant up

# Debian 13
time VAGRANT_VAGRANTFILE=Vagrantfile.debian13 vagrant up

# Debian 14
time VAGRANT_VAGRANTFILE=Vagrantfile.debian14 vagrant up
```

The Proxy configuration from your workstation and the inventory (with its variables) available in `vagrant-inventory` will be used.

`vagrant-inventory` has the files:

```text
vagrant-inventory/
├── ansible.cfg
├── hosts
└── host_vars
    └── devopsws
```
