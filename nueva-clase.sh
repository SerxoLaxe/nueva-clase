#!/bin/bash

#TODO
#Almacenar en la configuración el estado del programa, para solo permitir la finalización despues de la inicialización ni permitir la configuración en mitad de una sesión
#Añadir el argumento de Verbose y definir que mensajes son debug y cuales necesita el usuario.

#VARIABLES DATOS ALFANUMÉRICOS
Fecha=$(date +"%d-%b")
Argumento=$1
declare -a Dependencias=("zoom" "code" "git")
defaultDir="./archivos-clase"
defaultConfig="./.nueva-clase.conf"
Commit="Nada que comentar"
EnSesion=false

#VARIABLES GRÁFICAS
Verde="32"
Rojo="91"
Cian="\e[96m"
Magenta="\e[95m"
Amarillo="\e[93m"

VerdeBold="\e[1;${Verde}m"
RojoBold="\e[1;${Rojo}m"
FinColor="\e[0m"
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

checkDependecias() { #Comprueba si Git, Zoom y VS Code están instalados

    local Apto=true

    command_exists() {
        # check if command exists and fail otherwise
        command -v "$1" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "$1 no está instalado. $Error."
            Apto=false
        else
            echo -e "$1 está instalado. $Correcto"
        fi

    }

    for COMMAND in "${Dependencias[@]}"; do
        command_exists "${COMMAND}"
    done

    echo ""

    if $Apto; then
        echo -e "Las dependencias están satisfechas. $Correcto "
        echo ""
    else
        echo -e "Las dependencias no están satisfechas. Instala las aplicaciones pertinentes  $Error"
        echo ""
        exit
    fi
}

checkExisteConfig() { #Función que comprueba si existe el archivo nueva-clase.conf.

    if [ -f "$defaultConfig" ]; then #Si ya existe el archivo de configuración, lo más común es que sea innecesario configurarlo.
        echo -e "Encontrado archivo de configuración en el directorio actual. $Correcto"
        source $defaultConfig #Leemos el archivo de configuración que contiene las variables

    else

        echo -e "No se ha encontrado archivo de configuración en el directorio local. $Error"
        echo "Deseas crearlo ahora?"
        read -p 'Escribe S para confirmar, escribe cualquier otra cosa para cancelar: ' respuesta
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
            echo -e "no existe un directorio para los archivos de clase registrado en el archivo de configuración. $Error"
            echo "Para configurar/crear un directorio de clases nuevo, accede a la ayuda."
            exit
        #Si el directorio está registrado y existe, el script continua su función
        elif [ -d "$directorioClases" ]; then
            echo -e "El directorio $directorioClases está configurado como archivo de clases. $Correcto "
        #Si nada de lo anterior se cumple, entonces pasa que el directorio registrado en la configuración ya no existe en la ruta especificada.
        else
            echo -e "El directorio guardado en la configuración de este script ($directorioClases) ya no existe o ha sido modificado $Error"
            echo "Para configurar/crear un directorio de clases nuevo, utiliza la ayuda"
            exit
        fi
    }

    checkIdZoom() {

        if [ -z "$idZoom" ]; then
            echo -e "no existe un id de Zoom registrado en el archivo de configuración.$Error"
            echo "Para configurarlo accede a la ayuda."
            exit
        else
            echo -e "El id de Zoom $idZoom está configurado como archivo de clases. $Correcto"
        fi
    }

    checkDatosGit() {

        if [ -z "$urlRemote" ]; then
            echo -e "no existe una url de repositorio remoto registrada en el archivo de configuración. $Error"
            echo "Para configurar una nueva url, accede a la ayuda."
            echo ""
            exit

        else
            echo -e "La url "$urlRemote" está registrada en el archivo de configuración. $Correcto"
            echo ""
        fi
    }

    source $defaultConfig #Leemos el archivo de configuración que contiene las variables.
    checkDirectorioClase
    checkIdZoom
    checkDatosGit

}

modificarConfig() { #Versión más modular y limpia

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
            read -p 'Escribe S para confirmar o no escribas nada para cancelar: ' respuesta
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
        echo ""
        read -p 'id: ' idZoom
        if [ ${#idZoom} -ne 11 ]; then
            echo "id no válido."
            escribirIdZoom
        else
            echo -e "idZoom="$idZoom"\n" >>$defaultConfig
        fi
    }

    escribirDatosGit() { #Inicia git en el directorio de las clases y pregunta por los datos de acceso al remote.

        #Inicia git en el directorio de las clases.
        git init "$directorioClases"

        #Pregunta por los datos de acceso al remote.
        echo "introduce el enlace al repositorio remoto en donde desees almacenar tus archivos de clase"
        echo ""
        read -p 'url del repositorio: ' urlRemote
        echo ""

        git -C "$directorioClases" remote add origin "$urlRemote"

        echo -e "urlRemote="$urlRemote"\n" >>$defaultConfig #Escribimos variables en archivo de configuración.
    }

    if [ -d "$defaultConfig" ]; then
        echo "Ya existe un archivo de configuración, si se modifica será primero eliminado"
        rm $defaultConfig
    fi
    touch "$defaultConfig"
    escribirDirectorioClase
    escribirIdZoom
    escribirDatosGit

}

configurar() { #falta esto
    echo "Configurar"
    checkDependecias
    checkExisteConfig
    checkVarConfig
}

comenzar() { #Falta simplificar esta función

    #Comprueba dependencias y la configuración, para luego crear un directorio nombrado con la fecha actual y generar dentro de el un log y archivo de notas.
    #También abre esa carpeta en VS Code y se conecta al meeting de Zoom.

    echo "Seleccionado comenzar."

    checkDependecias
    checkExisteConfig

    #Comprobación de si el programa se encuentra en mitad de una sesión.
    if [ $EnSesion == true]; then
        echo " $Error Ya hay una sesión en curso, antes de comenzar otra usa el argumento finalizar para terminar la actual"
        exit
    fi
    EnSesion=true
    echo "EnSesion=true" >>$defaultConfig

    checkVarConfig

    if [ ! -d "$directorioClases/Clase.$Fecha" ]; then #Si en el directorio de clases no existe una carpeta para la fecha actual

        echo "Creada sesión 1 del $Fecha"
        echo ""

        mkdir "$directorioClases/Clase.$Fecha"
        touch "$directorioClases/Clase.$Fecha/apuntes.txt"
        touch "$directorioClases/Clase.$Fecha/log.txt"
        echo -e "La sesión "$clasesHoy" comenzó a las $(date +"%H:%M") del $(date +"%d-%b").\n" >"$directorioClases/Clase.$Fecha/log.txt"

        #!!!!!!        #S code "$directorioClases/Clase.$Fecha"

        #!!!!!!        # xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom

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

            #!!!!!!            # code "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy"

            #!!!!!!            # xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom
        fi
    fi

}

finalizar() {

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

    if [ $clasesHoy -gt 0 ]; then #Escribe en el log la hora de finalización de la clase

        echo "-La sesión $clasesHoy del $(date +"%d-%b") finalizó a las $(date +"%H:%M")." >>"$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"

    else

        echo -e "-La sesión $clasesHoy del $(date +"%d-%b") finalizó a las $(date +"%H:%M")\n" >>"$directorioClases/Clase.$Fecha/log.txt"
    fi

    git -C "$directorioClases" add .
    git -C "$directorioClases" commit -m "$Commit"
    git -C "$directorioClases" push --set-upstream origin master
    git -C "$directorioClases" push origin master
    exit

}

ayuda() {
    echo "Herramienta de automatización de sesiones de enseñanza en remoto"
    echo ""
    echo "comenzar      -       Comienza la sesión crea una carpeta fechada, genera un archivo para tomar apuntes dentro de esta y un log."
    echo "                      Luego la abre en VS code, inicializa GIT y abre la sesión de Zoom"
    echo "finalizar     -       Termina la sesión. Guarda los archivos y los sube al repositorio remoto."
    echo "configurar    -       Configura el script para su correcto funcionamiento."
    echo "ayuda         -       Muestra este menú."
    echo ""
}

banner() {

    echo -e "$Cian███╗   ██╗██╗   ██╗███████╗██╗   ██╗ █████╗      ██████╗██╗      █████╗ ███████╗███████╗$FinColor"
    echo -e "$Magenta████╗  ██║██║   ██║██╔════╝██║   ██║██╔══██╗    ██╔════╝██║     ██╔══██╗██╔════╝██╔════╝$FinColor"
    echo -e "$Amarillo██╔██╗ ██║██║   ██║█████╗  ██║   ██║███████║    ██║     ██║     ███████║███████╗█████╗$FinColor"
    echo -e "$Magenta██║╚██╗██║██║   ██║██╔══╝  ╚██╗ ██╔╝██╔══██║    ██║     ██║     ██╔══██║╚════██║██╔══╝ $FinColor"
    echo -e "$Cian██║ ╚████║╚██████╔╝███████╗ ╚████╔╝ ██║  ██║    ╚██████╗███████╗██║  ██║███████║███████╗$FinColor"
    echo -e "$Amarillo╚═╝  ╚═══╝ ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝  ╚═╝     ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝$FinColor"
}

#-------------------------------------
echo ""
banner
checkArgumentos
exit
#-------------------------------------
