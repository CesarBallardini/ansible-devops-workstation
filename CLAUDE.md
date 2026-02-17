# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Ansible playbook repository that provisions DevOps workstations on Ubuntu 22.04/24.04/26.04 and Debian 13 (Trixie)/14 (Forky). Installs desktop apps, DevOps tools (Docker, Terraform, Vagrant, VirtualBox, etc.), UTN educational tools (Prolog, Racket, Pharo), and configures a TinyProxy instance.

## Commands

```bash
# Bootstrap: install uv, create venv, install Ansible + lint, install Galaxy roles/collections
# (single entry point for both local and CI use)
./first-time-install-ansible.sh                  # venv at ~/.ansible-venv
./first-time-install-ansible.sh --venv /path     # custom venv path

# Syntax check
ansible-playbook -vv -i tests/inventory tests/test.yml --syntax-check

# Run tests locally (Ubuntu)
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars.yml

# Run tests locally (Debian)
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars-debian.yml

# Dry run (check mode)
ansible-playbook -i hosts site.yml --check

# Run against localhost with variables (Ubuntu)
time ansible-playbook -vv -i hosts site.yml --limit localhost --extra-vars "@hosts-vars.yml"

# Run against localhost with variables (Debian)
time ansible-playbook -vv -i hosts site.yml --limit localhost --extra-vars "@hosts-vars-debian.yml"

# Run with custom inventory (production pattern)
PYTHON_LOCAL_VENV=/usr/local/venv
time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario site.yml --limit localhost

# Run specific tags only
ansible-playbook site.yml --tags apt,docker
ansible-playbook site.yml --skip-tags eclipse,netbeans,telegram-desktop

# Lint
/usr/local/venv/bin/ansible-lint site.yml
/usr/local/venv/bin/ansible-lint tasks/*.yml

# Vagrant VM testing (one Vagrantfile per distro)
time vagrant up                                               # default symlink (ubuntu 22.04)
VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu24.04 vagrant up        # specific distro
VAGRANT_VAGRANTFILE=Vagrantfile.debian13 vagrant up           # Debian 13 (Trixie)
VAGRANT_VAGRANTFILE=Vagrantfile.debian14 vagrant up           # Debian 14 (Forky)

# Verify vagrant-inventory variables
ansible-inventory -i vagrant-inventory/ --list
ansible-playbook -vv --syntax-check -i vagrant-inventory/ site.yml
```

## Architecture

**Playbook chain** (`site.yml` imports all in order):
1. `all.yml` -- Base system: APT repos, locales, apt-fast, system upgrade, performance tuning. Targets `hosts: all`.
2. `escritorio.yml` -- Desktop apps: Chrome, LibreOffice, VS Code, Snap/Flatpak packages, IDEs (Eclipse, NetBeans), messaging (Telegram, Slack, MS Teams), mise-en-place. Targets `hosts: escritorio`.
3. `utn.yml` -- Educational tools: SWI-Prolog, Racket, Pharo Smalltalk. Targets `hosts: utn`.
4. `devops.yml` -- DevOps toolchain: VMware Workstation, AWS CLI, Ansible, Git, Terraform/Terragrunt/terraform-docs, VirtualBox, Vagrant, Packer, Goss, GOVC, Docker. Targets `hosts: devops`.
5. `local-roles/tinyproxy` -- Local HTTP proxy (role). Targets `hosts: tinyproxy`.
6. `ocsinventory-agent.yml` -- OCS Inventory agent (conditionally installed when `ocs_server` is set). Targets `hosts: ocsinventoryagent`.

**Inventory model**: Each playbook targets a different host group. Three inventory sources exist:

- `hosts` + `hosts-vars.yml` / `hosts-vars-debian.yml` -- Basic template for quick runs with `--extra-vars @hosts-vars.yml`. The canonical variable templates with placeholder values.
- `inventario/` -- Separate git repo for production (machine-specific). Contains `host_vars/localhost` with real values for the user's machine.
- `vagrant-inventory/` -- Structured inventory for Vagrant multi-distro testing (see below).

**vagrant-inventory structure**: Split into group_vars (shared) and per-distro host_vars:
```
vagrant-inventory/
  ansible.cfg                    # gathering = smart
  hosts                          # all 5 VMs, group definitions
  group_vars/
    devops_group                 # shared variables (proxy, OCS, pharo, goss, etc.)
  host_vars/
    devopsws-jammy               # Ubuntu 22.04 repo URLs
    devopsws-noble               # Ubuntu 24.04 repo URLs
    devopsws-resolute            # Ubuntu 26.04 repo URLs
    devopsws-trixie              # Debian 13 repo URLs
    devopsws-forky               # Debian 14 repo URLs
```

The `hosts` file defines groups: `devops_group` (all 5 VMs), `devops_group_ubuntu`, `devops_group_debian`, and playbook target groups (`escritorio`, `devops`, `utn`, `tinyproxy`, `ocsinventoryagent`) as `:children` of `devops_group`.

**Vagrantfiles**: One per distribution, each with a unique hostname and IP:
| File | Hostname | IP |
|---|---|---|
| `Vagrantfile.ubuntu22.04` | `devopsws-jammy` | `192.168.56.11` |
| `Vagrantfile.ubuntu24.04` | `devopsws-noble` | `192.168.56.12` |
| `Vagrantfile.ubuntu26.04` | `devopsws-resolute` | `192.168.56.13` |
| `Vagrantfile.debian13` | `devopsws-trixie` | `192.168.56.14` |
| `Vagrantfile.debian14` | `devopsws-forky` | `192.168.56.15` |

`Vagrantfile` is a symlink to `Vagrantfile.ubuntu22.04`. Use `VAGRANT_VAGRANTFILE=Vagrantfile.debian13 vagrant up` for a specific distro. Ubuntu boxes use `bento/ubuntu-*`; Debian boxes use `bento/debian-*` (official `debian/*` boxes only provide libvirt).

**Task files** (`tasks/`): Each tool has its own task file (e.g., `devops_docker.yml`, `devops_terraform.yml`, `instala_zoom.yml`). Naming convention: `devops_*.yml` for DevOps tools, `instala_*.yml` for desktop/general apps, `paquetes_*.yml` for package groups, `utn_*.yml` for UTN educational tools, `dev_*.yml` for IDEs.

**External roles** (via `requirements.yml`): `vmware-workstation`, `locales`, `ocsinventory-agent`. Installed into `roles/`.

**Templates** (`templates/`): Jinja2 templates for `/etc/environment`, Docker HTTP proxy, fuse.conf, MS Teams preferences. TinyProxy templates live in `local-roles/tinyproxy/templates/`.

## Code Style

- YAML with 2-space indent, files start with `---`
- Booleans: lowercase `yes`/`no` (legacy) or `true`/`false`
- Every task must have a `name:` field, prefixed with the component (e.g., `devops | git clone...`, `all | configura APT`)
- Use Ansible modules (`apt:`, `copy:`, `template:`, `service:`) over `shell:`/`command:` whenever possible
- Variable references always quoted: `"{{ variable_name }}"`
- Variable names in snake_case
- Tags on every included task file for selective execution
- Distribution conditionals use `ansible_facts['distribution']` (not the deprecated `ansible_distribution`): `when: ansible_facts['distribution'] == 'Ubuntu'`
- Version conditionals use: `ansible_distribution_version is version('22.04', operator='ge', strict=True)`
- Distribution-aware URLs use: `{{ ansible_facts['distribution'] | lower }}` (e.g., Docker repo URL)
- Codename detection uses: `{{ ansible_facts['distribution_release'] }}` (works for both Ubuntu and Debian)
- Use `ansible.builtin.package` for packages with stable names across Ubuntu versions
- Use `ansible.builtin.apt` only when apt-specific features are needed (update_cache, cache_valid_time, dpkg_options)
- Use `block/rescue` for packages that get renamed between releases (try new name, fall back to old)
- Use `failed_when: false` for package removal lists (packages may not exist in all releases)
- Use package availability checks (`tasks/package_available.yml`) for optional packages that may disappear in future releases or not exist on Debian (e.g., `libreoffice-style-elementary`, `libreoffice-style-tango`)
- Ubuntu-only PPAs (Launchpad) must be wrapped with `when: ansible_facts['distribution'] == 'Ubuntu'`; on Debian, packages are typically available from standard repos
- Ubuntu-only packages (e.g., `ubuntu-restricted-extras`, `indicator-cpufreq`, `zram-config`, `linux-headers-lowlatency`) must have Ubuntu-only conditionals; use Debian equivalents where they exist (e.g., `zram-tools`)
- Snap tasks use `ignore_errors: "{{ lookup('env', 'CI') | default(false) | bool }}"` because the `community.general.snap` module crashes on GitHub Actions runners where snapd cannot query the snap store
- Linting: `.ansible-lint` configured with `profile: basic`, several rules skipped (see file for details)

## Inventory Variable Conventions

- **`devops_user_uid`** (not `devops_uid`): all tasks reference `devops_user_uid`
- **Repo URL trailing slashes**: `security_repo_base_url` and `standard_repo_base_url` values must end with `/` (e.g., `"security.ubuntu.com/ubuntu/"`, `"deb.debian.org/debian/"`)
- **`ansible_version_deseada: ''`**: empty string means "install latest via uv, don't pin a version"
- **`goss_version_actual: ''`**: empty string means "fetch latest from GitHub API"
- **`ocs_server: ''`**: empty string means "don't install OCS Inventory agent"
- **Pharo variables**: `pharo_version_family`, `pharo_version`, `pharo_main_version`, `pharo_home_directory` must be defined for the UTN playbook

When adding or modifying inventory variables, keep all three sources in sync:
1. `hosts-vars.yml` / `hosts-vars-debian.yml` (canonical templates with placeholders)
2. `inventario/host_vars/localhost` (production values)
3. `vagrant-inventory/group_vars/devops_group` + `host_vars/<hostname>` (Vagrant testing)

## Profile-Based Tool Selection

Hosts can select which tools to install via profiles instead of getting everything. Defined in `vars/tool_profiles.yml`.

**Variables** (set in host_vars or extra-vars):
- **`active_profiles`**: List of profile names (e.g., `[developer, communication]`). When undefined, ALL tools install (backward compatible).
- **`extra_tools`**: Additional tool identifiers to add beyond the selected profiles. Default: `[]`
- **`skip_tools`**: Tool identifiers to exclude even if selected by profiles. Default: `[]`

**Available profiles**: `full`, `developer`, `sysadmin`, `academic`, `minimal`, `communication`, `video`

**How it works**:
1. `all.yml` loads `vars/tool_profiles.yml` and computes `active_tools` via `set_fact` (persists across all plays)
2. Each `include_tasks`/`include_role` in `escritorio.yml`, `devops.yml`, `utn.yml`, and `site.yml` (tinyproxy) has a `when: "'tool' in active_tools"` guard
3. If `active_profiles` is not defined, `active_tools` defaults to the `full` profile (all tools)

**Tool identifiers** match existing Ansible tags: `escritorio`, `zoom`, `ffmpeg`, `openshot`, `snap`, `eclipse`, `netbeans`, `telegram_desktop`, `slack`, `bitwarden`, `microsoft_visualstudio_code`, `mise-en-place`, `sshfs-fuse`, `rambox`, `aws`, `ansible`, `git`, `git-credential-manager`, `terraform`, `terraform-docs`, `terragrunt`, `virtualbox`, `vagrant`, `packer`, `goss`, `govc`, `docker`, `prolog`, `racket`, `pharo`, `tinyproxy`

**Example usage**:
```bash
# Install only developer + communication tools
ansible-playbook -i hosts site.yml --extra-vars '{"active_profiles": ["developer", "communication"]}'

# Minimal install plus docker, but skip bitwarden
ansible-playbook -i hosts site.yml --extra-vars '{"active_profiles": ["minimal"], "extra_tools": ["docker"], "skip_tools": ["bitwarden"]}'
```

When adding or modifying profiles, keep `vars/tool_profiles.yml` as the single source of truth. When adding new tools, add the tool identifier to the appropriate profiles and add a `when:` guard to the include.

## GITHUB_TOKEN Support

Tasks that call the GitHub API support `GITHUB_TOKEN` to avoid rate limits. The pattern used in shell tasks:
```bash
curl --silent --fail \
  ${GITHUB_TOKEN:+-H "Authorization: token ${GITHUB_TOKEN}"} \
  https://api.github.com/repositories/.../releases/latest
```

Affected tasks: `devops_aws.yml`, `devops_git_credential_manager.yml`, `devops_goss.yml`, `devops_govc.yml`, `devops_terraform_docs.yml`, `devops_terragrunt.yml`, `instala_rambox.yml`.

The CI workflow passes `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` as an environment variable.
