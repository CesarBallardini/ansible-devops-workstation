#!/usr/bin/env bash

PYTHON_LOCAL_VENV=~/.ansible-venv

sudo apt-get install python3-full -y
if command -v vboxconfig &>/dev/null; then
  sudo /sbin/vboxconfig
fi


espera_apt_libre() {
  # ver https://saveriomiroddi.github.io/Handling-the-apt-lock-on-ubuntu-server-installations/
  DPKG_LOCK_DIR="$(apt-config shell StateDir Dir::State/d | perl -ne "print /'(.*)\/'/")"

  sudo systemd-run '--property=After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true
  ret=1
  while [ "${ret}" != "0" ]
  do
    #~/bin/autentica-proxy.sh || exit 1
    flock "$DPKG_LOCK_DIR"/daily_lock sudo apt-get -qq update ; ret_daily=$?

    if [ -f "$DPKG_LOCK_DIR"/lock-frontend ]
    then
      flock "$DPKG_LOCK_DIR"/lock-frontend sudo apt-get -qq update ; ret_frontend=$?
    else
      ret_frontend=0
    fi

    ret=$(( ret_daily + ret_frontend ))
    sleep 2
  done

}


# ver https://saveriomiroddi.github.io/Handling-the-apt-lock-on-ubuntu-server-installations/                                                                                                                   
ret=1

# Create venv with uv if it doesn't exist
if [ ! -d "${PYTHON_LOCAL_VENV}" ]; then
    uv venv "${PYTHON_LOCAL_VENV}"
fi

# Install ansible using uv pip
uv pip install --python "${PYTHON_LOCAL_VENV}/bin/python" ansible ansible-lint

pushd ~/cesar/github/CesarBallardini/ansible-devops-workstation/
git pull

# Update Galaxy collections and roles to match requirements.yml
"${PYTHON_LOCAL_VENV}"/bin/ansible-galaxy install -r requirements.yml --force
"${PYTHON_LOCAL_VENV}"/bin/ansible-galaxy collection install -r requirements.yml --upgrade
popd

rm -f /tmp/hashicorp_index.json

while [ "$ret" -ne 0 ]
do

 # vagrant en ls lista de skip por un problema en ruby: https://github.com/hashicorp/vagrant/issues/13527 
 # VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant plugin update / install
 # resuelto en 2.4.3
 #
  espera_apt_libre
  pushd ~/cesar/github/CesarBallardini/ansible-devops-workstation/
  time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags ansible
  [ $? -eq 0 ] && time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags zoom,ansible
  # virtualbox.org esta caido 2023-09-05

  #time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags zoom
  #time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --skip-tags codium
  #time "${PYTHON_LOCAL_VENV}"/bin/ansible-playbook -i inventario  site.yml --tags msteams
  ret=$?
  popd

  sleep 5m
done

sync
#notify-send "termino la actualizacion: sin snaps [eclipse,netbeans,telegram-desktop]"
notify-send "termino la actualizacion"

