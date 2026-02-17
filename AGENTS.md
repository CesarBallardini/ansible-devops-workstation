# AGENTS.md - Ansible DevOps Workstation

## Supported Distributions

**Currently supported:** Ubuntu 22.04 (Jammy), 24.04 (Noble), 26.04 (Resolute), Debian 13 (Trixie), and Debian 14 (Forky).

Ubuntu versions are tested in CI (`.github/workflows/ci.yml` matrix). Debian is supported but not yet in CI (GitHub Actions has no Debian runners; container-based testing would require additional work due to systemd limitations).

## Process for New Ubuntu Releases

When a new Ubuntu version arrives (e.g., 28.04):

1. **Add the new runner to CI matrix** in `.github/workflows/ci.yml`
2. **Fix failures**: missing packages, renamed packages, changed repos, unavailable PPAs
3. **Drop the oldest supported version** if desired (keep at most two LTS releases)
4. **Remove dead conditionals** for dropped versions (`when:` clauses, version checks)
5. **Add Vagrantfile and host_vars**: create `Vagrantfile.<distro>` with unique hostname/IP, and `vagrant-inventory/host_vars/<hostname>` with the correct repo URLs
6. **Update inventory**: add the new host to `vagrant-inventory/hosts` in the appropriate groups (`devops_group`, `devops_group_ubuntu`)
7. **Update documentation**: `README.md`, `site.yml` comment, `CLAUDE.md`, `LLM.txt`, and this file

## Process for New Debian Releases

When a new Debian version arrives:

1. **Test manually** on a Debian machine or container (no GitHub Actions Debian runners exist)
2. **Fix failures**: same pattern as Ubuntu -- missing packages, renamed packages, changed repos
3. **Update variable templates**: `hosts-vars-debian.yml` and `tests/hosts-vars-debian.yml` if repo structure changes
4. **Add Vagrantfile and host_vars**: create `Vagrantfile.debian<N>` with unique hostname/IP (use `bento/debian-<N>` box, official `debian/*` boxes only provide libvirt), and `vagrant-inventory/host_vars/<hostname>` with Debian repo URLs
5. **Update inventory**: add the new host to `vagrant-inventory/hosts` in the appropriate groups (`devops_group`, `devops_group_debian`)
6. **Update documentation**: `README.md`, `site.yml` comment, `CLAUDE.md`, `LLM.txt`, and this file

## Multi-Distribution Design Patterns

The codebase supports both Ubuntu and Debian using these patterns:

- **Distribution detection**: Use `ansible_facts['distribution']` (returns `'Ubuntu'` or `'Debian'`), NOT the deprecated `ansible_distribution`
- **Variable templates**: `hosts-vars.yml` for Ubuntu, `hosts-vars-debian.yml` for Debian (different repo URLs and components)
- **Ubuntu-only PPAs**: Wrap with `when: ansible_facts['distribution'] == 'Ubuntu'` -- Debian packages come from standard repos
- **Ubuntu-only packages**: Add conditionals (e.g., `ubuntu-restricted-extras`, `indicator-cpufreq`, `linux-headers-lowlatency`)
- **Package alternatives**: Use Jinja2 conditionals for packages with different names (e.g., `zram-config` on Ubuntu vs `zram-tools` on Debian)
- **Distribution-aware URLs**: Use `{{ ansible_facts['distribution'] | lower }}` in repo URLs (e.g., Docker: `download.docker.com/linux/ubuntu` vs `download.docker.com/linux/debian`)
- **Optional packages**: Use `tasks/package_available.yml` for packages that may not exist on all distributions (e.g., `libreoffice-style-elementary`)
- **Repo components**: Ubuntu uses `main restricted universe multiverse`; Debian uses `main contrib non-free non-free-firmware`
- **Security repos**: Ubuntu uses `security.ubuntu.com/ubuntu/` with suffix `-security`; Debian uses `security.debian.org/debian-security/` with suffix `-security`

### Self-healing package patterns

The codebase uses several techniques to handle package changes across Ubuntu versions without version conditionals:

- **`block/rescue`** for renamed packages (e.g., `tasks/sshfs-fuse.yml` tries `fuse3`, falls back to `fuse`)
- **`failed_when: false`** on package removal lists (packages that no longer exist don't cause failures)
- **`ansible.builtin.package`** for stable packages (jq, git, curl, vim, etc.) instead of `ansible.builtin.apt`
- **`tasks/package_available.yml`** for optional packages that may disappear or not exist on Debian (checks `apt-cache pkgnames` before install)
- **CI-conditional `ignore_errors`** on snap tasks: `ignore_errors: "{{ lookup('env', 'CI') | default(false) | bool }}"` because the `community.general.snap` module crashes on GitHub Actions runners where snapd cannot query the snap store. Errors are still fatal on real desktop machines.

When adding new packages:
- If the package name is stable across releases, use `ansible.builtin.package`
- If the package has been renamed, use `block/rescue` with the new name first
- If the package might not exist in future releases, add it to the optional packages list with availability check
- Keep `ansible.builtin.apt` only for tasks needing apt-specific features (`update_cache`, `cache_valid_time`, `dpkg_options`)
- If a package is Ubuntu-only (PPAs, `ubuntu-*` packages), add `when: ansible_facts['distribution'] == 'Ubuntu'`
- If a package has a different name on Debian, use a Jinja2 conditional: `"{{ 'ubuntu-pkg' if ansible_facts['distribution'] == 'Ubuntu' else 'debian-pkg' }}"`
- If a package might not exist on Debian, use the `tasks/package_available.yml` pattern

Common package issues to check:
- Packages removed from repos (e.g., `libssl1.1` in 22.04+, `key-mon` in 20.04+)
- Packages renamed (e.g., `exfat-utils` -> `exfatprogs`)
- PPAs that lack builds for the new release (e.g., Racket PPA, Unetbootin PPA)
- Library conflicts (e.g., fuse vs fuse3)

## Profile-Based Tool Selection

Hosts can select which tools to install via named profiles instead of getting everything.

**Architecture**:
- Profile definitions live in `vars/tool_profiles.yml` (single source of truth)
- `all.yml` loads profiles and computes `active_tools` via `set_fact` (persists across all plays)
- `all.yml` also computes `snap_install` and `flatpak_install` lists from `active_tools` using the `snap_packages`/`flatpak_packages` lookup maps in `vars/tool_profiles.yml`
- Each `include_tasks`/`include_role` in `escritorio.yml`, `devops.yml`, `utn.yml`, and `site.yml` (tinyproxy) has a `when: "'tool' in active_tools"` guard
- The snap and flatpak roles install/remove packages from the computed `snap_install`/`flatpak_install` lists
- If `active_profiles` is undefined, all tools install (backward compatible)

**Host variables**:
- `active_profiles`: list of profile names (e.g., `[developer, communication]`)
- `extra_tools`: additional tool identifiers beyond selected profiles (default: `[]`)
- `skip_tools`: tool identifiers to exclude (default: `[]`)
- `snap_install`/`flatpak_install`: computed from `active_tools`; can be overridden directly in host_vars to bypass profile computation
- `snap_remove`/`flatpak_remove`: explicit package removal lists (default: `[]`)

**Snap/Flatpak package maps** (in `vars/tool_profiles.yml`):
- `snap_packages`: maps tool identifiers to snap package names (e.g., `bitwarden` -> `[bw, bitwarden]`, `slack` -> `[slack]`, `telegram_desktop` -> `[telegram-desktop]`)
- `flatpak_packages`: maps tool identifiers to flatpak package names (e.g., `flatpak` -> `[com.calibre_ebook.calibre, ...]`)
- `telegram_desktop`, `slack`, and `bitwarden` no longer have dedicated roles; their snap packages are installed via the snap role using these maps

**Available profiles**: `full`, `developer`, `sysadmin`, `academic`, `minimal`, `communication`, `video`

**Adding a new tool**:
1. Add the tool identifier to appropriate profiles in `vars/tool_profiles.yml`
2. Add `when: "'tool_id' in active_tools"` to its `include_tasks`/`include_role`
3. If the tool installs via snap/flatpak, add entries to `snap_packages`/`flatpak_packages` maps in `vars/tool_profiles.yml` (no dedicated role needed)
4. Document in `CLAUDE.md`, `AGENTS.md`, `LLM.txt`

**Adding a new profile**:
1. Add the profile definition to `vars/tool_profiles.yml`
2. Update the "Available profiles" comments in all inventory files
3. Document in `CLAUDE.md`, `AGENTS.md`, `LLM.txt`

## Overview

This is an Ansible playbook repository for provisioning a DevOps workstation on Ubuntu 22.04/24.04/26.04 and Debian 13 (Trixie)/14 (Forky). It includes playbooks for desktop applications, DevOps tools, UTN educational tools, and proxy configuration.

**Repository Structure:**
```
.
├── site.yml                      # Main entry point (imports all playbooks)
├── all.yml                       # Base system configuration (APT, locales)
├── escritorio.yml                # Desktop applications
├── devops.yml                    # DevOps tools (Docker, Terraform, etc.)
├── utn.yml                       # UTN educational tools
├── local-roles/tinyproxy/        # Proxy configuration (local role)
├── ocsinventory-agent.yml        # OCS Inventory agent
├── first-time-install-ansible.sh # Bootstrap: uv, venv, ansible, Galaxy deps
├── hosts                         # Inventory file
├── hosts-vars.yml                # Host variables template (Ubuntu)
├── hosts-vars-debian.yml         # Host variables template (Debian)
├── requirements.yml              # Ansible Galaxy roles/collections
├── tasks/                        # Individual task files
├── templates/                    # Jinja2 templates for config files
├── tests/                        # Test playbooks and inventory
├── .github/workflows/ci.yml      # GitHub Actions CI pipeline
├── Vagrantfile                   # Symlink to Vagrantfile.ubuntu22.04
├── Vagrantfile.ubuntu22.04       # Vagrant VM for Ubuntu 22.04
├── Vagrantfile.ubuntu24.04       # Vagrant VM for Ubuntu 24.04
├── Vagrantfile.ubuntu26.04       # Vagrant VM for Ubuntu 26.04
├── Vagrantfile.debian13          # Vagrant VM for Debian 13 (Trixie)
├── Vagrantfile.debian14          # Vagrant VM for Debian 14 (Forky)
├── inventario/                   # Production inventory (separate git repo)
│   ├── hosts
│   ├── group_vars/all
│   └── host_vars/localhost
└── vagrant-inventory/            # Vagrant multi-distro testing inventory
    ├── ansible.cfg
    ├── hosts
    ├── group_vars/devops_group
    └── host_vars/
        ├── devopsws-jammy
        ├── devopsws-noble
        ├── devopsws-resolute
        ├── devopsws-trixie
        └── devopsws-forky
```

**CI/CD:** GitHub Actions (`.github/workflows/ci.yml`) runs on push/PR to master. The pipeline uses `first-time-install-ansible.sh` for bootstrapping (same script and `~/.ansible-venv` path as local setup), then runs ansible-lint, syntax check, a full playbook run, and an idempotency check. The `astral-sh/setup-uv@v5` action pre-installs uv before the script runs (the script detects uv is present and skips its own installation). The CI passes `GITHUB_TOKEN` to avoid GitHub API rate limits.

## Vagrant Testing Infrastructure

Each supported distribution has its own Vagrantfile with a unique hostname and IP address:

| Vagrantfile | Hostname | IP | Box |
|---|---|---|---|
| `Vagrantfile.ubuntu22.04` | `devopsws-jammy` | `192.168.56.11` | `bento/ubuntu-22.04` |
| `Vagrantfile.ubuntu24.04` | `devopsws-noble` | `192.168.56.12` | `bento/ubuntu-24.04` |
| `Vagrantfile.ubuntu26.04` | `devopsws-resolute` | `192.168.56.13` | `bento/ubuntu-26.04` |
| `Vagrantfile.debian13` | `devopsws-trixie` | `192.168.56.14` | `bento/debian-13` |
| `Vagrantfile.debian14` | `devopsws-forky` | `192.168.56.15` | `bento/debian-14` |

`Vagrantfile` is a symlink to `Vagrantfile.ubuntu22.04`. To test a specific distro:
```bash
VAGRANT_VAGRANTFILE=Vagrantfile.debian13 vagrant up
```

Each Vagrantfile provisions in this order:
1. `fix-no-tty` -- fixes mesg/tty issue
2. `actualiza` -- full apt upgrade
3. `ssh_pub_key` -- injects host SSH key
4. `instala-ansible` -- runs `first-time-install-ansible.sh`
5. `link-ansible` -- symlinks venv binaries to `/usr/local/bin/`
6. `ansible-provision` -- runs `site.yml` via `ansible_local` provisioner using `vagrant-inventory/`

### vagrant-inventory layout

The inventory is split into shared group variables and per-distro host variables:

- **`group_vars/devops_group`**: Variables shared by all VMs (proxy config, OCS, pharo, goss, ansible version, etc.)
- **`host_vars/<hostname>`**: Distribution-specific variables (APT repo URLs and repository definitions)
- **`hosts`**: Defines `devops_group` (all 5 VMs), `devops_group_ubuntu`, `devops_group_debian`, and all playbook target groups as `:children` of `devops_group`

Ubuntu host_vars define `security.ubuntu.com/ubuntu/` and `mirrors.edge.kernel.org/ubuntu/` repos with components `main restricted universe multiverse`. Debian host_vars define `security.debian.org/debian-security/` and `deb.debian.org/debian/` repos with components `main contrib non-free non-free-firmware`.

## Inventory Variable Conventions

When working with inventory variables across the three sources (`hosts-vars*.yml`, `inventario/`, `vagrant-inventory/`):

- **`devops_user_uid`** (not `devops_uid`): all tasks reference this name
- **Repo URL trailing slashes**: `security_repo_base_url` and `standard_repo_base_url` values must end with `/` (e.g., `"security.ubuntu.com/ubuntu/"`, `"deb.debian.org/debian/"`)
- **`ansible_version_deseada: ''`**: empty string means "install latest via uv, don't pin"
- **`goss_version_actual: ''`**: empty string means "fetch latest from GitHub API"
- **`ocs_server: ''`**: empty string means "don't install OCS Inventory agent"
- **Pharo variables** (`pharo_version_family`, `pharo_version`, `pharo_main_version`, `pharo_home_directory`): required for the UTN playbook

## GITHUB_TOKEN Support

Seven task files call the GitHub API to fetch latest release versions. They all support `GITHUB_TOKEN` to avoid rate limits:

```bash
curl --silent --fail \
  ${GITHUB_TOKEN:+-H "Authorization: token ${GITHUB_TOKEN}"} \
  https://api.github.com/repositories/.../releases/latest
```

Affected tasks: `devops_aws.yml`, `devops_git_credential_manager.yml`, `devops_goss.yml`, `devops_govc.yml`, `devops_terraform_docs.yml`, `devops_terragrunt.yml`, `instala_rambox.yml`.

When adding new tasks that call the GitHub API, use this same pattern. The CI workflow passes `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` as an environment variable.

## Build/Lint/Test Commands

### Syntax Check (Required Before Running)
```bash
ansible-playbook -vv -i tests/inventory tests/test.yml --syntax-check
```

### Run Full Test Suite
```bash
# Ubuntu:
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars.yml

# Debian:
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars-debian.yml
```

### Run Single Test Task by Tag
```bash
ansible-playbook -i tests/inventory tests/test.yml --tags apt --check
```

### Idempotency Check (Run Twice)
```bash
# First run
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars.yml
# Second run - should show no changes
ansible-playbook -i tests/inventory tests/test.yml --connection=local --extra-vars @tests/hosts-vars.yml
```

### Linting
```bash
# Using custom venv
/usr/local/venv/bin/ansible-lint site.yml
/usr/local/venv/bin/ansible-lint tasks/*.yml
```

### Dry Run (Check Mode)
```bash
ansible-playbook -i hosts site.yml --check
```

### Run Against Localhost
```bash
# Ubuntu:
time ansible-playbook -vv -i hosts site.yml --limit localhost --extra-vars "@hosts-vars.yml"

# Debian:
time ansible-playbook -vv -i hosts site.yml --limit localhost --extra-vars "@hosts-vars-debian.yml"
```

### Vagrant Testing
```bash
# Default (Ubuntu 22.04):
time vagrant up

# Specific distribution:
VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu24.04 vagrant up
VAGRANT_VAGRANTFILE=Vagrantfile.debian13 vagrant up

# Verify inventory:
ansible-inventory -i vagrant-inventory/ --list
```

### Bootstrap (Install Dependencies)
```bash
# Single script handles everything: uv, venv, ansible, ansible-lint, Galaxy roles/collections
./first-time-install-ansible.sh                  # venv at ~/.ansible-venv
./first-time-install-ansible.sh --venv /path     # custom venv path
```

## Code Style Guidelines

### YAML Structure
- **Indentation**: 2 spaces (no tabs)
- **Document separator**: Start files with `---`
- **Key-value**: Use `key: value` (not `key:value`)
- **Booleans**: Use lowercase `yes`/`no`

### File Naming
- Playbooks: `*.yml`
- Tasks: `tasks/*.yml`
- Variables: `*-vars.yml` (Ubuntu), `*-vars-debian.yml` (Debian), `group_vars/`, `host_vars/`
- Inventory: `hosts`, `inventory/`
- Vagrantfiles: `Vagrantfile.<distro>` (e.g., `Vagrantfile.ubuntu24.04`, `Vagrantfile.debian13`)

### Playbook Structure
```yaml
---
- name: Playbook description
  hosts: target_hosts
  become: true
  vars:
    var_name: value
  tasks:
    - name: Task description
      module:
        option: value
```

### Task Conventions
- Always include `name:` for tasks (required for debugging)
- Use `tags:` for task organization
- Prefer idempotent modules
- Use `changed_when: false` for read-only operations

### Variable Naming
- Use snake_case: `my_variable`, `http_proxy`
- Role variables: Prefix with role name (e.g., `nginx_port`)
- Always quote variable references: `"{{ variable_name }}"`

### Error Handling
- Use `failed_when:` for conditional failure
- Use `ignore_errors: yes` sparingly, with comment explaining why
- For snap tasks in CI, use `ignore_errors: "{{ lookup('env', 'CI') | default(false) | bool }}"` to tolerate snap store failures on GitHub Actions while still catching errors on real desktops
- Use `register:` with `failed_when:` for error handling
- Always use `become: true` for privileged operations

### Imports and Includes
```yaml
- import_playbook: other_playbook.yml  # Static import (evaluated at parse time)
- include_tasks: tasks/some_task.yml   # Dynamic include (evaluated at runtime)
- import_tasks: tasks/static_task.yml  # Static include
```

### Conditional Execution
```yaml
# Distribution check (use ansible_facts form, not the deprecated ansible_distribution):
when: ansible_facts['distribution'] == "Ubuntu"
when: ansible_facts['distribution'] == "Debian"
# Version check:
when: ansible_distribution_version is version('22.04', operator='ge', strict=True)
```

### Loops
```yaml
- name: Loop example
  module:
    name: "{{ item.name }}"
  loop:
    - { name: 'foo', state: 'present' }
    - { name: 'bar', state: 'absent' }

- include_tasks: task.yml
  loop: "{{ my_list }}"
```

### Module Usage (Best Practices)
- **DO**: Use `apt:` module instead of `shell: apt-get install`
- **DO**: Use `copy:` module instead of `shell: echo ... > file`
- **DO**: Use `lineinfile:` for single line modifications
- **DO**: Use `template:` for configuration files with variables
- **DO**: Use `service:` for service management
- **AVOID**: Shell/command unless no module exists

### Become/Privilege Escalation
```yaml
- name: Task requiring root
  apt:
    name: nginx
    state: present
  become: true
```

### Handlers
```yaml
handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted

tasks:
  - name: Config changed
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx
```

### Inventory
```ini
# hosts file
localhost ansible_connection=local

[group_name]
localhost ansible_python_interpreter=/usr/bin/python3

[group_name:vars]
ansible_python_interpreter=/usr/bin/python3
```

## Best Practices

1. **Always use `--syntax-check`** before running playbooks
2. **Test on Vagrant VM** before production (use the appropriate `Vagrantfile.<distro>` for each distribution)
3. **Use tags** to run subsets of playbooks
4. **Keep variables in `host_vars/`** for machine-specific settings, `group_vars/` for shared settings
5. **Use descriptive names** for plays and tasks
6. **Comment complex conditionals**
7. **Use `changed_when: false`** for read-only operations
8. **Install dependencies first**: `./first-time-install-ansible.sh` (handles venv, ansible, and Galaxy deps)
9. **Keep inventory sources in sync**: when changing variables, update `hosts-vars*.yml`, `inventario/`, and `vagrant-inventory/`
10. **Use GITHUB_TOKEN pattern** in new tasks that call the GitHub API

## Common Tags

- `apt`: Package management tasks
- `docker`: Docker installation
- `terraform`: Terraform tools
- `vagrant`: Vagrant tools
- `virtualbox`: VirtualBox installation

## Running Specific Tags
```bash
ansible-playbook site.yml --tags apt,docker
ansible-playbook site.yml --skip-tags docker
```

## Daily Update Commands

### Standard Daily Update (Production)
Uses custom inventory with skip tags for problematic/slow tools:
```bash
PYTHON_LOCAL_VENV=/usr/local/venv
time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario site.yml --limit localhost \
  --skip-tags eclipse,netbeans,telegram-desktop,codium,virtualbox,vmware-workstation,ansible
```

### Run Twice for Idempotency
```bash
time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario site.yml --limit localhost \
  --skip-tags eclipse,netbeans,telegram-desktop,codium,zoom,virtualbox,vmware-workstation,ansible
```

### Common Skip Tags
- `eclipse`: Eclipse IDE (slow/heavy)
- `netbeans`: NetBeans IDE
- `telegram-desktop`: Telegram desktop app
- `codium`: VSCodium editor
- `zoom`: Zoom client
- `virtualbox`: VirtualBox (requires vboxconfig)
- `vmware-workstation`: VMware Workstation
- `ansible`: Ansible itself

### Using Custom Virtual Environment
The project uses a local Python venv at `/usr/local/venv`:
```bash
PYTHON_LOCAL_VENV=/usr/local/venv
"${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario site.yml --limit localhost
```
