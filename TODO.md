# TODO - FIXME

# Eliminar problemas de idempotencia

Quedan tres elementos que impiden la idempotencia:


* `./roles/locales/tasks/main.yml:75` crea `/etc/default/locale` y lo regenera
* `./tasks/apt.yml:29` pone en blanco a `/etc/apt/sources.list`
* `all.yml:6` escribe mediante un template a `/etc/environment`

Una vez resuelto, modificar el `.travis.yml` para que muestre 0 en lugar de 3.
