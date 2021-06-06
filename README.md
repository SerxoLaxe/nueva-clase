# NUEVA-CLASE

Nueva Clase es un script escrito en Bash que automatiza algunos aspectos de las clases en remoto cursadas en Hack a Boss. Crea un repositorio local en el que almacena ordenadamente los archivos usados cada día, también se conecta a los meetings de Zoom y, al finalizar la clase, sube a un repositorio remoto todo lo creado.

![imagen](imagen.png)

## Instalación

Clona este repositorio para instalar nueva-clase.

```bash
git clone url
cd nueva-clase
chmod +x nueva-clase.sh
./nueva-clase.sh  configurar

```

## Uso

```bash

./nueva-clase.sh comenzar    # Comienza la sesión de clase.
./nueva-clase.sh finalizar   # Finaliza la sesión de clase
./nueva-clase.sh configurar  # Configura el script.
./nueva-clase.sh ayuda       # Muestra un menú con estos argumentos.
```

## TODO
* Automatizar completamente el acceso a los meetings de Zoom.
* Al finalizar, cerrar VS Code y Zoom.
* Opción de añadir y eliminar tareas a crontab dentro del propio script.


## License
[MIT](https://choosealicense.com/licenses/mit/)