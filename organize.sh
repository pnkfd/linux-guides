#! /usr/bin/env bash
#================================================================
#                                                                |
#     Organizar os arquivos da pasta de $USER/Downloasd
#                                                                |
#================================================================
#move os arquivos para sua respectiva pasta de acordo com a extensão
#Se a pasta não existir, cria
USER=$1 #recebe o username por parametro

find "/home/$USER/Downloads/" -maxdepth 1 -type f | while read n ; do #itera sobre a lista
   
IFS=$'\n'       

FORMATO=$(echo $n | egrep -o "\.{1}.[^.]*$" | tr -d "." ) #retira o ponto "." do formato = .pdf -> pdf

case $FORMATO in
    $FORMATO) 

        if [ ! -d "/home/$USER/Downloads/$FORMATO" ]; then #se a pasta com o formato não existir cria
            mkdir "/home/$USER/Downloads/$FORMATO"   #cria
        fi
        mv $n "/home/$USER/Downloads/$FORMATO" 
        #Move o arquivo que está no download para sua respectiva pasta de acordo com a extensão
        
    ;;

esac #fim do case

done #fim do while

echo 
 



