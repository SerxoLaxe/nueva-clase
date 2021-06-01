#!/bin/bash

Fecha=$(date +"%d-%b")

echo "Clase.$Fecha"
echo ""
Comando=$1
declare -a Dependencias=("zoom" "code" "git" "papapa")

checkArgumentos() {

    if [ "$Comando" = "reset" ]; then
        Comando=""
        checkConfig
        checkDirectorioClase
        reset
    elif [ "$Comando" = "comenzar" ]; then
        Comando=""
        checkConfig
        checkDirectorioClase
        comenzar
    elif [ "$Comando" = "finalizar" ]; then
        Comando=""
        checkConfig
        checkDirectorioClase
        finalizar
    elif [ "$Comando" = "ayuda" ]; then
        ayuda
    elif [ "$Comando" = "instalar" ]; then
        Comando=""
        checkDependecias
        checkConfig
        checkDirectorioClase
    else
        echo "Escribe     #./nueva-clase.sh ayuda        para ver una lista detallada de las herramientas del script."
        echo ""
    fi
}

checkConfig() {
    #Función que compruebe si existe el archivo nueva-clase.conf en la misma carpeta donde se encuentra este script. en caso de no existir crea uno con los parámetros seleccionados por el usuario o por defecto.
    #En caso de que sí exista o una vez terminada la configuración, la función lee este archivo como source.
    if [ -f "./nueva-clase.conf" ]; then
        echo "Encontrado archivo de configuración en el directorio actual :)"
        echo ""
        source ./nueva-clase.conf
    else

        echo "No se ha encontrado archivo de configuración en el directorio local. Para que el script funcione es necesario crearlo y almacenar en él la ruta donde serán guardados los archivos de clase"
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
                touch nueva-clase.conf
                echo "directorioClases="$directorioClases"" >./nueva-clase.conf
                echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
                echo ""
            else
                checkConfig
            fi

        elif
            [ -z "$directorioClases" ]
        then

            mkdir ./archivos-clase
            touch nueva-clase.conf
            echo "directorioClases='./archivos-clase'" >./nueva-clase.conf
            echo "directorio por defecto y archivo de configuración creados"
            echo ""
        else

            mkdir "$directorioClases"
            touch nueva-clase.conf
            echo "directorioClases="$directorioClases"" >./nueva-clase.conf
            echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
            echo ""
        fi
        source ./nueva-clase.conf
    fi
}

checkDirectorioClase() {

    #Esta función comprueba si la variable directorioClases está vacia en el archivo de configuración ,
    #en ese caso animando al usuario a configurar un directorio nuevo
    #y almacenar su ruta en el archivo de configuración de este script.

    #Si el directorio registrado en la configuración es null, anima al usuario a reconfigurar el script
    if [ -z "$directorioClases" ]; then
        echo "no existe un directorio para los archivos de clase registrado en el archivo de configuración. :("
        echo "Para configurar/crear un directorio de clases nuevo, accede a la ayuda."
        echo ""
    #Si el directorio está registrado y existe, el script continua su función
    elif [ -d "$directorioClases" ]; then
        echo "El directorio $directorioClases está configurado como archivo de clases. Todo correcto :)"
        echo ""
    #Si nada de lo anterior se cumple, entonces pasa que el directorio registrado en la configuración ya no existe en la ruta especificada.
    else
        echo "El directorio guardado en la configuración de este script ($directorioClases) ya no existe o ha sido modificado. :("
        echo ""
        echo "Para configurar/crear un directorio de clases nuevo, utiliza la ayuda"
    fi
}

checkDependecias() {
    command_exists() {
        # check if command exists and fail otherwise
        command -v "$1" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo "$1 no está instalado. Fallo."
        else
            echo "$1 está instalado. correcto"    
        fi

    }
    for COMMAND in "${Dependencias[@]}"; do
        command_exists "${COMMAND}"
    done
    echo ""
}

reset() {
    echo "reset"

    read -p 'directorio:  ' directorioClases
    if [ -d "$directorioClases" ]; then
        echo "El directorio introducido ya existe, estás seguro que deseas usarlo? su contenido podría ser borrado o modificado"
        echo ""
        read -p 'Escribe S para confirmar o no escribas nada para cancelar: ' respuesta
        echo ""
        if [ "$respuesta" == "S" ]; then
            echo "directorioClases="$directorioClases"" >./nueva-clase.conf
            echo "Guardando ruta del directorio ya existente en el archivo de configuración."
            echo ""
        else
            checkConfig
        fi

    elif
        [ -z "$directorioClases" ]
    then

        mkdir ./archivos-clase
        echo "directorioClases='./archivos-clase'" >./nueva-clase.conf
        echo "directorio por defecto y archivo de configuración creados"
        echo ""
    else

        mkdir "$directorioClases"
        echo "directorioClases="$directorioClases"" >./nueva-clase.conf
        echo "creando directorio especificado y guardando su ruta en el archivo de configuración."
        echo ""
    fi
}

comenzar() {
    echo "Comenzar"
}

finalizar() {
    echo "comenzar"
}

ayuda() {
    echo "--------------------------------HERRAMIENTAS--------------------------------"
    echo ""
    echo "comenzar - Crea una carpeta fechada y genera un archivo para tomar apuntes dentro de esta. Luego la abre en VS code, inicializa GIT y abre la sesión de Zoom"
    echo ""
}

checkArgumentos
#checkConfig
#checkDirectorioClase
exit
