
# Ansible Playbooks for DevOps Workstation

[![CI](https://github.com/CesarBallardini/ansible-devops-workstation/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/CesarBallardini/ansible-devops-workstation/actions/workflows/ci.yml)

From a base installation of Ubuntu 22.04 (Jammy), 24.04 (Noble), 26.04 (Resolute) or Debian 13 (Trixie), Debian 14 (Forky) you can add the popular tools for working in the following areas:

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

## Repository Structure

```text
.
├── site.yml                        # Main entry point (imports all playbooks in order)
├── all.yml                         # Base system: APT repos, locales, apt-fast, system upgrade
├── escritorio.yml                  # Desktop apps: Chrome, LibreOffice, VS Code, Snap, IDEs
├── utn.yml                         # Educational tools: SWI-Prolog, Racket, Pharo Smalltalk
├── devops.yml                      # DevOps toolchain: Docker, Terraform, VirtualBox, Vagrant, etc.
├── ocsinventory-agent.yml          # OCS Inventory agent
├── vars/
│   └── tool_profiles.yml           # Profile definitions for selective tool installation
├── tasks/
│   ├── actualiza_sistema.yml       # System upgrade
│   ├── agrego_repositorio.yml      # APT repository management
│   ├── apt.yml                     # APT configuration
│   ├── dev_eclipse.yml             # Eclipse IDE
│   ├── devops_ansible.yml          # Ansible installation
│   ├── devops_aws.yml              # AWS CLI
│   ├── devops_docker.yml           # Docker
│   ├── devops_git_credential_manager.yml
│   ├── devops_goss.yml             # Goss / DGoss
│   ├── devops_govc.yml             # GOVC (VMware vCenter)
│   ├── devops_packer.yml           # Packer
│   ├── devops_terraform.yml        # Terraform
│   ├── devops_terraform_docs.yml   # terraform-docs
│   ├── devops_terragrunt.yml       # Terragrunt
│   ├── devops_vagrant.yml          # Vagrant
│   ├── devops_virtualbox.yml       # VirtualBox
│   ├── instala_apt_fast.yml        # apt-fast
│   ├── instala_microsoft_visualstudio_code.yml
│   ├── instala_openshot.yml        # OpenShot video editor
│   ├── instala_rambox.yml          # Rambox
│   ├── instala_snap.yml            # Snap packages
│   ├── instala_zoom.yml            # Zoom
│   ├── mejora_performance.yml      # Performance tuning
│   ├── package_available.yml       # Package availability check helper
│   ├── paquetes_de_escritorio.yml  # Desktop package group
│   ├── sshfs-fuse.yml              # SSHFS / FUSE
│   ├── utn_pharo.yml              # Pharo Smalltalk
│   ├── utn_prolog.yml             # SWI-Prolog / GProlog
│   └── utn_racket.yml             # Racket Scheme
├── templates/
│   ├── environment.j2              # /etc/environment
│   ├── fuse.conf.j2                # /etc/fuse.conf
│   ├── http-proxy.conf.j2          # Docker HTTP proxy
│   └── msteams-preference.j2       # MS Teams preferences
├── local-roles/
│   ├── ffmpeg/                     # FFmpeg role
│   ├── git/                        # Git role
│   ├── mise-en-place/              # mise-en-place role
│   ├── netbeans/                   # NetBeans role
│   ├── pup/                        # pup HTML parser role
│   └── tinyproxy/                  # TinyProxy local HTTP proxy role
├── tests/
│   ├── test.yml                    # Test playbook
│   ├── inventory                   # Test inventory
│   ├── hosts-vars.yml              # Test variables (Ubuntu)
│   └── hosts-vars-debian.yml       # Test variables (Debian)
├── vagrant-inventory/
│   ├── ansible.cfg                 # gathering = smart
│   ├── hosts                       # All 5 VMs, group definitions
│   ├── group_vars/
│   │   └── devops_group            # Shared variables (proxy, OCS, pharo, goss, etc.)
│   └── host_vars/
│       ├── devopsws-jammy          # Ubuntu 22.04 repo URLs
│       ├── devopsws-noble          # Ubuntu 24.04 repo URLs
│       ├── devopsws-resolute       # Ubuntu 26.04 repo URLs
│       ├── devopsws-trixie         # Debian 13 repo URLs
│       └── devopsws-forky          # Debian 14 repo URLs
├── Vagrantfile                     # Symlink to default Vagrantfile
├── Vagrantfile.ubuntu22.04         # Vagrant VM for Ubuntu 22.04
├── Vagrantfile.ubuntu24.04         # Vagrant VM for Ubuntu 24.04
├── Vagrantfile.ubuntu26.04         # Vagrant VM for Ubuntu 26.04
├── Vagrantfile.debian13            # Vagrant VM for Debian 13 (Trixie)
├── Vagrantfile.debian14            # Vagrant VM for Debian 14 (Forky)
├── hosts                           # Inventory template
├── hosts-vars.yml                  # Variable template with placeholders (Ubuntu)
├── hosts-vars-debian.yml           # Variable template with placeholders (Debian)
├── inventario/                     # Production inventory (separate git repo)
├── first-time-install-ansible.sh   # Bootstrap: uv, venv, Ansible, Galaxy deps
├── requirements.yml                # Ansible Galaxy roles and collections
├── ansible.cfg                     # Ansible configuration
├── .ansible-lint                   # ansible-lint configuration
├── .github/workflows/ci.yml        # GitHub Actions CI pipeline
├── CLAUDE.md                       # AI agent instructions (Claude Code)
├── AGENTS.md                       # AI agent reference documentation
├── LLM.txt                         # AI agent context file
└── README.md                       # This file
```

## Playbook Chain

`site.yml` imports all playbooks in order, each targeting a different host group:

| Order | Playbook | Target group | Description |
|-------|----------|-------------|-------------|
| 1 | `all.yml` | `all` | Base system: APT repos, locales, apt-fast, system upgrade, performance tuning, profile computation |
| 2 | `escritorio.yml` | `escritorio` | Desktop apps: Chrome, LibreOffice, VS Code, Snap/Flatpak, IDEs, messaging |
| 3 | `utn.yml` | `utn` | Educational tools: SWI-Prolog, Racket, Pharo Smalltalk |
| 4 | `devops.yml` | `devops` | DevOps toolchain: Docker, Terraform, VirtualBox, Vagrant, Packer, AWS CLI, etc. |
| 5 | `site.yml` (tinyproxy) | `tinyproxy` | Local HTTP proxy via `local-roles/tinyproxy` |
| 6 | `ocsinventory-agent.yml` | `ocsinventoryagent` | OCS Inventory agent (only when `ocs_server` is set) |

# 1. How to set up a new host

## 1.1. Prerequisites

Install Ubuntu 22.04 (Jammy), 24.04 (Noble), 26.04 (Resolute) or Debian 13 (Trixie), 14 (Forky) with a graphical desktop. Then ensure:

1. `sudo` configured to run without asking for password with the account running this script
2. APT configured (mirrors, mirror access and access to package sources over the internet)
3. Proxy configured in `/etc/environment` (for curl, wget, etc.) if needed

## 1.2. Install Git and clone the repository

```bash
sudo apt install git -y
git clone https://github.com/CesarBallardini/ansible-devops-workstation.git
cd ansible-devops-workstation/
```

From this point on, the rest of the activities will be performed from that directory.

## 1.3. Install Ansible and dependencies

A single script handles all setup (uv, Python venv, Ansible, ansible-lint, Galaxy roles/collections):

```bash
./first-time-install-ansible.sh
```

The venv is created at `~/.ansible-venv` by default. Use `--venv /path` for a custom location.

## 1.4. Create an inventory for your machine

### 1.4.1. Create the directory structure

```bash
mkdir -p inventario/{group_vars,host_vars}
```

### 1.4.2. Create the hosts file

```bash
cat - > inventario/hosts  <<EOF
localhost ansible_connection=local

[tinyproxy]
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

Remove any group line for playbooks you don't need (e.g., remove `[utn]` and its `localhost` line if you don't need educational tools).

### 1.4.3. Create host variables

Copy the variable template and customize it. Use `hosts-vars.yml` for Ubuntu or `hosts-vars-debian.yml` for Debian:

```bash
# Ubuntu:
cp hosts-vars.yml inventario/host_vars/localhost

# Debian:
cp hosts-vars-debian.yml inventario/host_vars/localhost
```

Edit `inventario/host_vars/localhost` and replace placeholder values. The key variables to customize:

| Variable | Description |
|----------|-------------|
| `devops_user_name` | Username of the account used by the devops user |
| `devops_user_uid` | UID of that user |
| `tinyproxy_listen_ip` | IP address where TinyProxy listens for requests |
| `tinyproxy_listen_port` | Port for TinyProxy (default: `8888`) |
| `tinyproxy_no_upstream` | Domains/CIDRs that TinyProxy accesses directly (no upstream proxy) |
| `tinyproxy_upstream` | Upstream corporate proxy (`''` for none) |
| `tinyproxy_allow` | CIDRs authorized to use TinyProxy |
| `organizacion` | Organization name (noted in `/etc/environment`) |
| `all_proxy` | Proxy URL for outbound Internet access (leave empty if no proxy needed) |
| `no_proxy` | Addresses that bypass the proxy |
| `ocs_server` | OCS Inventory server URL (`''` to skip installation) |

Proxy configuration -- assign `all_proxy` and `no_proxy` when there is a single proxy for all protocols:

```yaml
all_proxy: 'http://<NETWORK_INTERFACE_IP>:8888'
http_proxy: '{{ all_proxy }}'
https_proxy: '{{ all_proxy }}'
ftp_proxy: '{{ all_proxy }}'
no_proxy: '10.,192.168.,wpad,127.0.0.1,localhost,.dominio.local.tld'
soap_use_proxy: 'on'
```

### 1.4.4. Configure tool profiles (optional)

By default, **all tools are installed** (backward compatible behavior). To install only the tools you need, uncomment and set the profile variables in `inventario/host_vars/localhost`:

```yaml
# Available profiles: full, developer, sysadmin, academic, minimal, communication, video
# See vars/tool_profiles.yml for details.
active_profiles:
  - developer
  - communication
extra_tools: []
skip_tools: []
```

**Available profiles:**

| Profile | Description | Tools included |
|---------|-------------|----------------|
| `full` | Everything (default when `active_profiles` is undefined) | All tools |
| `developer` | Software developer desktop | escritorio, snap, VS Code, mise-en-place, sshfs-fuse, bitwarden, git, git-credential-manager, docker, terraform, terraform-docs, terragrunt |
| `sysadmin` | Infrastructure/ops | escritorio, snap, sshfs-fuse, bitwarden, aws, ansible, git, git-credential-manager, terraform, terraform-docs, terragrunt, virtualbox, vagrant, packer, goss, govc, docker, tinyproxy |
| `academic` | UTN courses | escritorio, snap, VS Code, sshfs-fuse, prolog, racket, pharo |
| `minimal` | Just base desktop | escritorio, snap, sshfs-fuse, bitwarden |
| `communication` | Messaging apps | telegram_desktop, slack, rambox, zoom |
| `video` | Media production | ffmpeg, openshot, zoom |

Profiles can be combined. The final tool list is: `union(all selected profiles) + extra_tools - skip_tools`.

**Snap/Flatpak packages** are driven by profiles via lookup maps in `vars/tool_profiles.yml`. When a tool identifier is active, its associated snap/flatpak packages are automatically installed by the snap and flatpak roles. For example, activating the `communication` profile installs `telegram-desktop`, `slack`, and other messaging snaps. You can also override the computed lists directly:

```yaml
# Override computed snap packages for this host
snap_install:
  - bw
  - bitwarden
  - slack
snap_remove: []

# Override computed flatpak packages for this host
flatpak_install:
  - com.calibre_ebook.calibre
  - com.dropbox.Client
flatpak_remove: []
```

**Examples:**

```yaml
# Developer who also needs messaging and Docker
active_profiles:
  - developer
  - communication

# Minimal desktop with Docker added, but no bitwarden
active_profiles:
  - minimal
extra_tools:
  - docker
skip_tools:
  - bitwarden

# Academic workstation plus Terraform
active_profiles:
  - academic
extra_tools:
  - terraform
  - terraform-docs
```

You can also set profiles via `--extra-vars` on the command line:

```bash
ansible-playbook -i inventario site.yml --limit localhost \
  --extra-vars '{"active_profiles": ["developer", "communication"]}'
```

## 1.5. Run the playbook

```bash
# Ubuntu:
time ansible-playbook -vv -i inventario site.yml --limit localhost

# Or using the template variables directly (without a custom inventory):
time ansible-playbook -vv -i hosts site.yml --extra-vars "@hosts-vars.yml"

# Debian:
time ansible-playbook -vv -i hosts site.yml --extra-vars "@hosts-vars-debian.yml"
```

### Run specific tags only

```bash
ansible-playbook -i inventario site.yml --tags apt,docker
ansible-playbook -i inventario site.yml --skip-tags eclipse,netbeans,telegram-desktop
```

### Dry run (check mode)

```bash
ansible-playbook -i inventario site.yml --check
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

| File | Distribution | Hostname | IP |
|---------|--------------|----------|-----|
| `Vagrantfile.ubuntu22.04` | Ubuntu 22.04 (Jammy) | `devopsws-jammy` | `192.168.56.11` |
| `Vagrantfile.ubuntu24.04` | Ubuntu 24.04 (Noble) | `devopsws-noble` | `192.168.56.12` |
| `Vagrantfile.ubuntu26.04` | Ubuntu 26.04 (Resolute) | `devopsws-resolute` | `192.168.56.13` |
| `Vagrantfile.debian13` | Debian 13 (Trixie) | `devopsws-trixie` | `192.168.56.14` |
| `Vagrantfile.debian14` | Debian 14 (Forky) | `devopsws-forky` | `192.168.56.15` |

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

### vagrant-inventory layout

```text
vagrant-inventory/
├── ansible.cfg                 # gathering = smart
├── hosts                       # All 5 VMs, group definitions
├── group_vars/
│   └── devops_group            # Shared variables (proxy, OCS, pharo, goss, etc.)
└── host_vars/
    ├── devopsws-jammy          # Ubuntu 22.04 repo URLs
    ├── devopsws-noble          # Ubuntu 24.04 repo URLs
    ├── devopsws-resolute       # Ubuntu 26.04 repo URLs
    ├── devopsws-trixie         # Debian 13 repo URLs
    └── devopsws-forky          # Debian 14 repo URLs
```

### Verify vagrant-inventory

```bash
ansible-inventory -i vagrant-inventory/ --list
ansible-playbook -vv --syntax-check -i vagrant-inventory/ site.yml
```

# 3. Syntax check and linting

```bash
# Syntax check
ansible-playbook -vv -i tests/inventory tests/test.yml --syntax-check

# Lint
ansible-lint site.yml

# Run tests locally (Ubuntu)
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars.yml

# Run tests locally (Debian)
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars-debian.yml
```
