# Script to run all this

I have a script on my `~/bin/` directory that helps me run the Ansible playbook, it's content follows:


```bash
#!/usr/bin/env bash

ANSIBLE_VENV=~/.ansible-venv
ANSIBLE_LOCAL_REPO=~/cesar/github/CesarBallardini/ansible-devops-workstation/

# things that I do not want on my system
SKIP_TAGS=eclipse,netbeans,telegram-desktop,codium,virtualbox,vmware-workstation

# just in case...
sudo apt-get install python3-full -y
sudo apt-get install libnotify-bin -y # for notify-send at the bottom of this script

wait_for_apt() {
  # ver https://saveriomiroddi.github.io/Handling-the-apt-lock-on-ubuntu-server-installations/
  DPKG_LOCK_DIR="$(apt-config shell StateDir Dir::State/d | perl -ne "print /'(.*)\/'/")"

  sudo systemd-run '--property=After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true
  ret=1
  while [ "${ret}" != "0" ]
  do
    flock "$DPKG_LOCK_DIR"/daily_lock sudo apt-get -qq update ; ret_daily=$?

    if [ -f "$DPKG_LOCK_DIR"/lock-frontend ]
    then
      flock "$DPKG_LOCK_DIR"/lock-frontend sudo apt-get -qq update ; ret_frontend=$?
    else
      ret_frontend=0
    fi

    ret=$[ $ret_daily + $ret_frontend ]
    sleep 2
  done

}


# Bootstrap (first time only)
if [ ! -x "${ANSIBLE_VENV}"/bin/ansible-playbook ]; then
  "${ANSIBLE_LOCAL_REPO}"/first-time-install-ansible.sh
fi


# get the latest version of the code in the repo:
pushd "${ANSIBLE_LOCAL_REPO}"
git pull
popd


# remove the cache for Hashicorp package list
rm -f /tmp/hashicorp_index.json

##
#
# Now the real deal: use Ansible to upgrade and converge the system installation
# The playbook's ansible task keeps the venv updated on each run
#

# retry until it succeeds
ret=1
while [ "$ret" -ne 0 ]
do
  wait_for_apt
  pushd "${ANSIBLE_LOCAL_REPO}"
    time "${ANSIBLE_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags "${SKIP_TAGS}"
    # yeah, I don't know how to avoid re-installing zoom because there are no version info available on the download site, arrgghhh
    [ $? -eq 0 ] && time "${ANSIBLE_VENV}"/bin/ansible-playbook -i inventario  site.yml --limit localhost --skip-tags "${SKIP_TAGS},zoom"
    ret=$?
  popd

  sleep 5m
done

sync

notify-send "system upgrade just finished"
```

Hope you can adapt it as you wish/need.



