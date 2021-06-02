#!/bin/bash

Fecha=$(date +"%d-%b")
Argumento=$1
declare -a Dependencias=("zoom" "code" "git")
defaultDir="./archivos-clase"
Commit="Nada que comentar"

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
            echo "$1 no está instalado. Fallo."
            Apto=false
        else
            echo "$1 está instalado. correcto"
        fi

    }

    for COMMAND in "${Dependencias[@]}"; do
        command_exists "${COMMAND}"
    done

    echo ""

    if $Apto; then
        echo "Las dependencias están satisfechas. Correcto :)"
        echo ""
    else
        echo "Las dependencias no están satisfechas. Instala las aplicaciones pertinentes :("
        echo ""
        exit
    fi
}

checkExisteConfig() { #Función que comprueba si existe el archivo nueva-clase.conf.

    if [ -f "./nueva-clase.conf" ]; then #Si ya existe el archivo de configuración, lo más común es que sea innecesario configurarlo.
        echo "Encontrado archivo de configuración en el directorio actual :)"
        echo ""

    else

        echo "No se ha encontrado archivo de configuración en el directorio local. Para que el script funcione es necesario crearlo y almacenar en él la ruta donde serán guardados los archivos de clase"
        echo ""
        modificarConfig
    fi

}

checkVarConfig() { #Esta función comprueba si las variables del archivo de configuración son válidas,

    checkDirectorioClase() {

        if [ -z "$directorioClases" ]; then
            echo "no existe un directorio para los archivos de clase registrado en el archivo de configuración. :("
            echo "Para configurar/crear un directorio de clases nuevo, accede a la ayuda."
            echo ""
            exit
        #Si el directorio está registrado y existe, el script continua su función
        elif [ -d "$directorioClases" ]; then
            echo "El directorio $directorioClases está configurado como archivo de clases. Correcto :)"
            echo ""
        #Si nada de lo anterior se cumple, entonces pasa que el directorio registrado en la configuración ya no existe en la ruta especificada.
        else
            echo "El directorio guardado en la configuración de este script ($directorioClases) ya no existe o ha sido modificado. :("
            echo ""
            echo "Para configurar/crear un directorio de clases nuevo, utiliza la ayuda"
            exit
        fi
    }

    checkIdZoom() {

        if [ -z "$idZoom" ]; then
            echo "no existe un id de Zoom registrado en el archivo de configuración. :("
            echo "Para configurarlo accede a la ayuda."
            echo ""
            exit
        else
            echo "El id de Zoom $idZoom está configurado como archivo de clases. Correcto :)"
            echo ""
        fi
    }

    checkDatosGit() {

        if [ -z "$urlRemote" ]; then
            echo "no existe una url de repositorio remoto registrada en el archivo de configuración. :("
            echo "Para configurar una nueva url, accede a la ayuda."
            echo ""
            exit

        else
            echo "La url "$urlRemote" está registrada en el archivo de configuración. correcto :)"
            echo ""
        fi

        if [ -z "$usuarioRemote" ]; then
            echo "no existe un usuario de repositorio remoto registrado en el archivo de configuración. :("
            echo "Para configurar un nuevo usuario, accede a la ayuda."
            echo ""
            exit

        else
            echo "El usuario "$usuarioRemote" está registrado en el archivo de configuración. correcto :)"
            echo ""
        fi
    }

    source ./nueva-clase.conf #Leemos el archivo de configuración que contiene las variables.
    checkDirectorioClase
    checkIdZoom
    checkDatosGit

}

modificarConfig() { #Versión más modular y limpia

    #Parámetros a introducir:

    # - directorio para las clases.
    # - id del meeting Zoom.
    # - url del repositorio remoto
    # - usuario del repositorio remoto

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
                echo -e "directorioClases="$directorioClases"\n" >./nueva-clase.conf
                echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
                echo ""
            else
                escribirDirectorioClase
            fi

        elif [ -z "$directorioClases" ]; then

            directorioClases="$defaultDir"
            mkdir "$directorioClases"
            echo -e "directorioClases="$directorioClases"\n" >./nueva-clase.conf
            echo "directorio por defecto creado ( "$directorioClases")."
            echo ""
        else

            mkdir "$directorioClases"
            echo -e "directorioClases="$directorioClases"\n" >./nueva-clase.conf
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
            echo -e "idZoom="$idZoom"\n" >>./nueva-clase.conf
        fi
    }

    escribirDatosGit() { #Inicia git en el directorio de las clases y pregunta por los datos de acceso al remote.

        #Inicia git en el directorio de las clases.
        git init "$directorioClases"

        #Pregunta por los datos de acceso al remote.
        echo "introduce el enlace al repositorio remoto en donde desees almacenar tus archivos de clase"
        echo ""
        read -p 'url del repositorio: ' urlRemote
        echo "Introduce el nombre de usuario del repositorio remoto."
        echo ""
        read -p 'Usuario: ' usuarioRemote
        echo ""

        git -C "$directorioClases" remote add origin "$urlRemote"

        echo -e "urlRemote="$urlRemote"\n" >>./nueva-clase.conf #Escribimos variables en archivo de configuración.
        echo -e "usuarioRemote="$usuarioRemote"\n" >>./nueva-clase.conf
    }

    if [ -d "./nueva-clase.conf" ]; then
        echo "Ya existe un archivo de configuración, si se modifica será primero eliminado"
        rm ./nueva-clase.conf
    fi
    touch nueva-clase.conf
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

comenzar() {

    #Comprueba dependencias y la configuración, para luego crear un directorio nombrado con la fecha actual y generar dentro de el un log y archivo de notas.
    #También abre esa carpeta en VS Code y se conecta al meeting de Zoom.

    echo "Seleccionado comenzar."

    checkDependecias
    checkExisteConfig
    checkVarConfig

    if [ ! -d "$directorioClases/Clase.$Fecha" ]; then #Si en el directorio de clases no existe una carpeta para la fecha actual

        echo "Creada sesión 1 del $Fecha"
        echo ""

        mkdir "$directorioClases/Clase.$Fecha"
        touch "$directorioClases/Clase.$Fecha/apuntes.txt"
        touch "$directorioClases/Clase.$Fecha/log.txt"
        echo -e "La sesión "$clasesHoy" comenzó a las $(date +"%H:%M") del $(date +"%d-%b").\n" >"$directorioClases/Clase.$Fecha/log.txt"
       #S code "$directorioClases/Clase.$Fecha"

       # xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom
    else
        echo "Ya existe un archivo para hoy, estas seguro de que quieres realizar otra sesión?"
        echo ""
        read -p 'Escribe S para confirmar:  ' respuesta
        if [ "$respuesta" == "S" ]; then
            clasesHoy=$((clasesHoy + 1))
            sed -i '/clasesHoy/d' ./nueva-clase.conf #borra la variable de config
            echo -e "clasesHoy=$clasesHoy\n" >>./nueva-clase.conf
            mkdir "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy"
            touch "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/apuntes.txt"
            touch "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"
            echo "-La sesión "$clasesHoy" del $(date +"%d-%b") comenzó a las $(date +"%H:%M")." >>"$directorioClases/Clase.$Fecha.Sesion.$clasesHoy/log.txt"
           # code "$directorioClases/Clase.$Fecha.Sesion.$clasesHoy"

           # xdg-open "https://zoom.us/j/"$idZoom"" #Abre Zoom
        fi
    fi

}

finalizar() {

    echo "Finalizar"
    checkDependecias
    checkExisteConfig
    checkVarConfig

    if [ $clasesHoy > 0 ]; then #Escribe en el log la hora de finalización de la clase

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
    echo ""
    echo "--------------------------------//NUEVA-CLASE.sh\\\--------------------------------"
    echo "comenzar      -       Crea una carpeta fechada, genera un archivo para tomar apuntes dentro de esta y un log. Luego la abre en VS code, inicializa GIT y abre la sesión de Zoom"
    echo "finalizar     -       Termina la sesión. Guarda los archivos y los sube al repositorio remoto."
    echo "configurar    -       Configura el script para su correcto funcionamiento."
    echo "ayuda         -       Muestra este menú."
    echo ""
}

#-------------------------------------
checkArgumentos
exit
#-------------------------------------
