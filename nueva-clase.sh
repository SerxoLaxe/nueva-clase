#!/bin/bash

#                                                NUEVA-CLASE
#Nueva Clase es un script escrito en Bash que automatiza algunos aspectos de las clases en remoto cursadas en Hack a Boss.
#Crea un repositorio local en el que almacena ordenadamente los archivos usados cada día, también se conecta a los meetings de Zoom
#y, al finalizar la clase, sube a un repositorio remoto todo lo creado.

#TODO
#Guardar los archivos en un esquema de directorios dividido por meses.
#Añadir el argumento de Verbose y definir que mensajes son debug y cuales necesita el usuario.
#Automatizar totalmente el acceso a Zoom.
#Cierre de VScode y Zoom al finalizar la sesión.
#Aádir y eliminar tareas a Crontab desde el propio script.
#Simplificar el método comenzar()

#VARIABLES DATOS ALFANUMÉRICOS
Version="0.1.0" #Versión del script.
Fecha=$(date +"%d-%b")
Argumento=$1
declare -a Dependencias=("zoom" "code" "git" "python3") #Dependencias.
defaultDir="./archivos-clase"                 #Directorio donde se guardarán los archivos generados por defecto.
defaultConfig="./.nueva-clase.conf"           #Archivo de configuración por defecto.
Commit="Nada que comentar"                    #Commit por defecto.
EnSesion=false

#VARIABLES GRÁFICAS
Verde="32"
Rojo="91"
Cian="\e[36m"
Magenta="\e[35m"
Amarillo="\e[33m"

VerdeBold="\e[1;${Verde}m"
RojoBold="\e[1;${Rojo}m"
FinColor="\e[0m"

#mensajes
Correcto="$VerdeBold Correcto :) $FinColor" #Mensaje de debug correcto bold y en color verde.
Error="$RojoBold Error :( $FinColor"        #Mensaje de debug error bold y en color rojo.

checkArgumentos() {

    if [ "$Argumento" = "comenzar" ]; then
        comenzar
    elif [ "$Argumento" = "finalizar" ]; then
        finalizar
    elif [ "$Argumento" = "ayuda" ]; then
        ayuda
    elif [ "$Argumento" = "configurar" ]; then
        configurar
    else
        echo "Escribe #./nueva-clase.sh ayuda  para ver una lista detallada de las herramientas del script."
        echo ""
    fi
}

checkDependecias() { #Comprueba si las dependencias están instaladas

    local Apto=true

    command_exists() {
        # check if command exists and fail otherwise
        command -v "$1" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "$Error $1 no está instalado."
            Apto=false
        else
            echo -e " $Correcto $1 está instalado."
        fi

    }

    for COMMAND in "${Dependencias[@]}"; do
        command_exists "${COMMAND}"
    done

    echo ""

    if $Apto; then
        echo -e "$Correcto Las dependencias están satisfechas."
    else
        echo -e "$Error Las dependencias no están satisfechas. Instala las aplicaciones pertinentes."
        echo ""
        exit
    fi
}

checkExisteConfig() { #Función que comprueba si existe el archivo nueva-clase.conf.

    if [ -f "$defaultConfig" ]; then #Si ya existe el archivo de configuración, lo más común es que sea innecesario configurarlo.
        echo -e "$Correcto Encontrado archivo de configuración en el directorio actual. "
        source $defaultConfig #Leemos el archivo de configuración que contiene las variables

    else

        echo -e "$Error No se ha encontrado archivo de configuración en el directorio local."
        echo "Deseas crearlo ahora?"
        read -p 'Escribe S para confirmar, Introduce cualquier otra cosa para cancelar: ' respuesta
        echo ""
        if [ "$respuesta" == "S" ]; then
            modificarConfig
        else
            exit
        fi
    fi

}

checkVarConfig() { #Esta función comprueba si las variables del archivo de configuración son válidas,

    checkDirectorioClase() {

        if [ -z "$directorioClases" ]; then

            echo -e "$Error No existe un directorio para los archivos de clase registrado en el archivo de configuración."
            echo ""
            #Usamos el método siguiente para que el ususario configure su archivo de clase.
            escribirDirectorioClase

        #Si el directorio está registrado y existe, el script continua su función
        elif [ -d "$directorioClases" ]; then

            echo -e "$Correcto El directorio $directorioClases está configurado como archivo de clases. "

        #Si nada de lo anterior se cumple, entonces pasa que el directorio registrado en la configuración ya no existe en la ruta especificada.
        else
            echo -e "$Error El directorio guardado en la configuración de este script ($directorioClases) ya no existe o ha sido modificado "
            echo ""
            #Usamos el método siguiente para que el ususario configure su archivo de clase.
            escribirDirectorioClase
        fi
    }

    checkIdZoom() {

        if [ -z "$idZoom" ]; then
            echo -e "$Error no existe un id de Zoom registrado en el archivo de configuración."
            escribirIdZoom
        else
            echo -e "$Correcto El id de Zoom $idZoom está configurado como meeting en el archivo de clases."
        fi
    }

    checkDatosGit() {

        if [ -z "$urlRemote" ]; then
            echo -e "$Error No hay ningún repositorio remoto configurado."
            echo ""
            escribirDatosGit

        else
            echo -e "$Correcto La url "$urlRemote" está registrada como repositorio remoto. "
            echo ""
        fi
    }

    source $defaultConfig #Leemos el archivo de configuración que contiene las variables.
    checkDirectorioClase
    checkIdZoom
    checkDatosGit

}

modificarConfig() { #Función que modifica los contenidos del archivo de configuración.

    #Parámetros a introducir:

    # - directorio para las clases.
    # - id del meeting Zoom.
    # - url del repositorio remoto
    # - usuario del repositorio remoto----eliminado por ser innecesario

    escribirDirectorioClase() {

        echo "Introduce el directorio en el que deseas guardar tus archivos de clase o pulsa Ctrl-Z para cancelar"
        echo "por defecto este directorio será ./archivos-clase"
        echo ""

        read -p 'directorio:  ' directorioClases
        echo ""

        if [ -d "$directorioClases" ]; then
            echo "El directorio introducido ya existe, estás seguro que deseas usarlo? su contenido podría ser borrado o modificado"
            echo ""
            read -p 'Escribe S para confirmar o introduce cualquier otra cosa para cancelar: ' respuesta
            echo ""
            if [ "$respuesta" == "S" ]; then
                echo -e "directorioClases="$directorioClases"\n" >$defaultConfig
                echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
                echo ""
            else
                escribirDirectorioClase
            fi

        elif [ -z "$directorioClases" ]; then

            directorioClases="$defaultDir"
            mkdir "$directorioClases"
            echo -e "directorioClases="$directorioClases"\n" >$defaultConfig
            echo "directorio por defecto creado ( "$directorioClases")."
            echo ""
        else

            mkdir "$directorioClases"
            echo -e "directorioClases="$directorioClases"\n" >$defaultConfig
            echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
            echo ""
        fi
    }

    escribirIdZoom() { #Pregunta por id para el meeting de Zoom.

        echo "Introduce el id del meeting de Zoom al que te deseas conectar al comenzar la sesión."
        echo "O introduce N para cancelar"
        read -p 'id: ' idZoom
        if [ ${#idZoom} -ne 11 ]; then
            echo "id no válido."
            escribirIdZoom
        elif [ $idZoom -eq "N"]; then
            exit
        else
            echo -e "idZoom="$idZoom"\n" >>$defaultConfig
        fi
    }

    escribirDatosGit() { #Inicia git en el directorio de las clases y pregunta por los datos de acceso al remote.

        #Inicia git en el directorio de las clases.
        git init "$directorioClases"

        #Pregunta por los datos de acceso al remote.
        echo "introduce el enlace al repositorio remoto en donde desees almacenar tus archivos de clase"
        echo "O introduce N para cancelar"
        read -p 'url del repositorio: ' urlRemote
        if [ $urlRemote -eq "N" ]; then
            exit
        fi
        echo ""

        git -C "$directorioClases" remote add origin "$urlRemote"

        echo -e "urlRemote="$urlRemote"\n" >>$defaultConfig #Escribimos variables en archivo de configuración.
    }

    if [ ! -d "$defaultConfig" ]; then
        echo "Archivo de configuración creado"
        touch "$defaultConfig"
    fi

    escribirDirectorioClase
    escribirIdZoom
    escribirDatosGit

}

configurar() { #Configura el script sin comenzar la sesión al terminar.

    checkDependecias
    checkExisteConfig
    checkVarConfig
}

comenzar() { #Falta simplificar esta función

    #Comprueba dependencias y la configuración, para luego crear un directorio nombrado con la fecha actual y generar dentro de el un log y archivo de notas.
    #También abre esa carpeta en VS Code y se conecta al meeting de Zoom.

    checkDependecias
    checkExisteConfig

    #Comprobación de si el script se intenta ejecutar en mitad de una sesión.
    if [ $EnSesion == true ]; then
        echo -e "$Error Ya hay una sesión en curso, antes de comenzar otra usa el argumento finalizar para terminar la actual"
        echo ""
        exit
    fi
    EnSesion=true
    sed -i '/EnSesion/d' $defaultConfig   #borra la variable de config
    echo "EnSesion=true" >>$defaultConfig #Introduce el nuevo valor

    checkVarConfig

    if [ ! -d "$directorioClases/Clase.$Fecha" ]; then #Si en el directorio de clases no existe una carpeta para la fecha actual

        echo "Creada sesión 1 del $Fecha"
        echo ""

        mkdir "$directorioClases/Clase.$Fecha"
        touch "$directorioClases/Clase.$Fecha/apuntes.txt"
        touch "$directorioClases/Clase.$Fecha/log.txt"
        echo -e "La sesión "$clasesHoy" comenzó a las $(date +"%H:%M") del $(date +"%d-%b").\n" >"$directorioClases/Clase.$Fecha/log.txt"

        code "$directorioClases/Clase.$Fecha" #Abre VS Code

        #xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom

        #Nuevo método totalmente automático con python
        cd botZoom
        source .venv/bin/activate
        python3 main.py

    else
        echo "Ya existe un archivo para hoy, estas seguro de que quieres realizar otra sesión?"
        echo ""
        read -p 'Escribe S para confirmar:  ' respuesta
        if [ "$respuesta" == "S" ]; then
            clasesHoy=$((clasesHoy + 1))
            sed -i '/clasesHoy/d' $defaultConfig #borra la variable de config
            echo -e "clasesHoy=$clasesHoy\n" >>$defaultConfig
            mkdir "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy"
            touch "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/apuntes.txt"
            touch "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"
            echo "-La sesión "$clasesHoy" del $(date +"%d-%b") comenzó a las $(date +"%H:%M")." >>"$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"

            code "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy" #Abre VS Code

            #xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom

            #Nuevo método totalmente automático con python
            cd botZoom
            source .venv/bin/activate
            python3 main.py
        fi
    fi

}

finalizar() { #Finaliza la sesión guardando los archivos y subiéndolos al repositorio remoto.

    echo "Finalizar"
    checkDependecias
    checkExisteConfig
    checkVarConfig

    #Comprobación de si existe una sesión que finalizar.
    if [ $EnSesion == false ]; then
        echo -e " $Error No hay ninguna sesión que finalizar, Inicia una usando el argumento comenzar."
        echo ""
        exit
    fi
    sed -i '/EnSesion/d' $defaultConfig #borra la variable de config
    echo "EnSesion=false" >>$defaultConfig

    if [ $clasesHoy -gt 0 ]; then #Escribe en el log la hora de finalización de la clase

        echo "-La sesión $clasesHoy del $(date +"%d-%b") finalizó a las $(date +"%H:%M")." >>"$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"

    else

        echo "-La sesión $clasesHoy del $(date +"%d-%b") finalizó a las $(date +"%H:%M")" >>"$directorioClases/Clase.$Fecha/log.txt"
    fi

    #git add, commit y push automaticos.
    git -C "$directorioClases" add .
    git -C "$directorioClases" commit -m "$Commit"
    git -C "$directorioClases" push --set-upstream origin master
    git -C "$directorioClases" push origin master
    exit

}

ayuda() { #Muestra el nenú de ayuda
    echo "Herramienta de automatización de sesiones de enseñanza en remoto"
    echo ""
    echo "comenzar      -       Comienza la sesión crea una carpeta fechada, genera un archivo para tomar apuntes dentro de esta y un log."
    echo "                      Luego la abre en VS code, inicializa GIT y abre la sesión de Zoom"
    echo "finalizar     -       Termina la sesión. Guarda los archivos y los sube al repositorio remoto."
    echo "configurar    -       Configura el script para su correcto funcionamiento."
    echo "ayuda         -       Muestra este menú."
    echo ""
}

banner() { #Banner ASCII

    echo -e "    $Amarillo███╗   ██╗██╗   ██╗███████╗██╗   ██╗ █████╗      ██████╗██╗      █████╗ ███████╗███████╗$FinColor"
    echo -e "    $Amarillo████╗  ██║██║   ██║██╔════╝██║   ██║██╔══██╗    ██╔════╝██║     ██╔══██╗██╔════╝██╔════╝$FinColor"
    echo -e "    $Amarillo██╔██╗ ██║██║   ██║█████╗  ██║   ██║███████║    ██║     ██║     ███████║███████╗█████╗$FinColor"
    echo -e "    $Amarillo██║╚██╗██║██║   ██║██╔══╝  ╚██╗ ██╔╝██╔══██║    ██║     ██║     ██╔══██║╚════██║██╔══╝ $FinColor"
    echo -e "    $Amarillo██║ ╚████║╚██████╔╝███████╗ ╚████╔╝ ██║  ██║    ╚██████╗███████╗██║  ██║███████║███████╗$FinColor"
    echo -e "    $Cian ═╝  ╚═══╝ ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝  ╚═╝     ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝$FinColor $VerdeBold V $Version $FinColor"
    echo "              Herramienta de automatización de sesiones de enseñanza HAB en remoto"
    echo ""
}

#-------------------------------------
echo ""
banner
checkArgumentos
echo ""
exit
#-------------------------------------
