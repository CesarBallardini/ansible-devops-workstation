# TODO - FIXME

# Eliminar problemas de idempotencia

Quedan tres elementos que impiden la idempotencia:


* `./roles/locales/tasks/main.yml:75` crea `/etc/default/locale` y lo regenera
* `./tasks/apt.yml:29` pone en blanco a `/etc/apt/sources.list`
* `all.yml:6` escribe mediante un template a `/etc/environment`

Una vez resuelto, modificar el `.travis.yml` para que muestre 0 en lugar de 3.

# Instalar Skypeforlinux

```bash
sudo apt install software-properties-common apt-transport-https wget ca-certificates gnupg2 -y

wget -O- https://repo.skype.com/data/SKYPE-GPG-KEY | sudo gpg --dearmor | sudo tee /usr/share/keyrings/skype.gpg > /dev/null


#echo deb [arch=amd64 signed-by=/usr/share/keyrings/skype.gpg] https://repo.skype.com/deb unstable main | sudo tee /etc/apt/sources.list.d/skype-stable.list

echo deb [arch=amd64 signed-by=/usr/share/keyrings/skype.gpg] https://repo.skype.com/deb stable main | sudo tee /etc/apt/sources.list.d/skype-stable.list
sudo apt-get update
sudo apt install skypeforlinux -y

```

* https://es.linuxcapable.com/how-to-install-skype-on-ubuntu-22-04-lts/
