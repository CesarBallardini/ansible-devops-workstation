# Instala Python virtual environment

Instalamos un _Python viertual environment_ para independizar la versión de los
paquetes Python requeridos por Ansible de los paquetes Python existentes a nivel de tu
sistema operativo.

```bash
PYTHON_LOCAL_VENV=/usr/local/venv

[ -d "${PYTHON_LOCAL_VENV}" ] || sudo python3 -m venv "${PYTHON_LOCAL_VENV}"
sudo chown -R "${USER}" "${PYTHON_LOCAL_VENV}"

"${PYTHON_LOCAL_VENV}"/bin/python -m pip install --upgrade pip
"${PYTHON_LOCAL_VENV}"/bin/python -m pip install ansible==9.6.1
```

Luego puedes correr Ansible desde ese entorno virtual, haciendo:

```bash
time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags eclipse,netbeans,telegram-desktop,codium,virtualbox,vmware-workstation,ansible
```

En mi caso hay ciertos playbooks que no quiero instalar, y por eso el `--skip-tags`.

Si necesitas una versión de Python diferente de la que está instalada en tu sistema operativo, puedes usar `pyenv`:
* https://github.com/pyenv/pyenv Simple Python Version Management: pyenv
* https://www.programaenpython.com/avanzado/python-con-pyenv/ Cómo instalar diferentes versiones de Python en tu computadora con pyenv


Importante: las fechas de caducidad de los paquetes:
* https://endoflife.date/ansible-core Se listan las versiones de `ansible-core` y las versiones de Python tanto en el nodo de control, como en el nodo gestionado.
* https://endoflife.date/ansible Ídem para `ansible` con la referencia de las versiones de `ansible-core` necesarias para correr Ansible.
