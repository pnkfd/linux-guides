#!/usr/bin/env bash
#================================================================
#                                                                |
#      Administrar os usuários do linux (criar, editar, listar)  |
#                                                                |
#================================================================

ERR=''  #colocar erros aqui
CHOOSE_OPT='' #escolha das opções de um user
GET_UID_MIN=`egrep '^UID_MIN' /etc/login.defs | tr -d [:blank:]` #get uid min in /etc/login.defs
UID_MIN=${GET_UID_MIN:7}                                         #remove UID_MIN until 100*

#####################
#     funções       #
#####################

getent_user(){ # Retorna apenas o nome de usuário

    echo `getent passwd $1 | cut -d":" -f 1 --output-delimiter=' '`

}

user_options(){ #exibe as opções para o usuário selecionado
echo "---------------------------------------"
read -p "Choose an user by ID or Name: " CHOOSE_USER   
echo ""

KKK="\
\033[32m User: `getent_user $CHOOSE_USER`\033[m\n\
 1 - Lock account      |   6 - Set new passwd\n
2 - Unlock account    |   7 - Disable Login\n
3 - Define Shell      |   8 - Exit\n
4 - Force pass swap   |   9 - Select another user\n
5 - Delete account (-r)  |  "

echo -e $KKK | column -t -s "|" # Printa e coloca em colunas 
echo "" #nova linha
read -ep "Choose an option: " CHOOSE_OPT   #SALVA A ESCOLHA das ações
echo "" #nova linha

fores $CHOOSE_OPT #passa a funcão "fores" e como args o opção escolhida para o usuário
}

menu_principal() { #exibe o menu principal, o primeiro a ser exibido
echo -e  "\
===================  powUser  ====================\n \
        1 - List ALL users \n \
        2 - List BLOCKED users \n \
        9 - quit  \n\
==================================================\n"
read -p "Choose an option: " CHOOSE_INIT    #lê a primeira escolha
echo ""  #pula uma linha
}

#após o usuário escolher a opção no $CHOOSE_INIT, inicia as tarefas

fores(){  #função das opções escolhidas para o usuário


NAME=$( getent_user $CHOOSE_USER ) #Salva só o nome de usuário em $NAME para rodar o #passwd


if [[ "$1" = 1 ||  "$1" = 2 ||  "$1" = 9  ||  #checa se a escolha tem no menu (1-9)
     "$1" = 5 ||  "$1" = 6 ||  "$1" = 7   ||  #checa se a escolha tem no menu  (1-9)
    "$1" = 8 ||  "$1" = 9 ]];then  #checa se a escolhe tem no menu (1-9)
#1º case
case $1 in  #caso sim, roda o case
    1) # o primeiro é travar (lock) a conta
        RESULT=$( passwd -l $NAME 2>&1 ) #salva a saída de passwd -l 
        if [ $? = 0 ]; then #se não teve erro, exibe msg de success
        echo -e "\033[32mUser $CHOOSE_USER locked! \033[m "
        user_options  #Volta ao menu das opções do usuário
        else #Se teve erro, exibe e sai
            echo "Something wrong: $RESULT"
            exit
        fi
    ;;
    2) # o segundo destrava (unlock) a conta
        RESULT=$( passwd -u $NAME 2>&1 ) #Salva em $RESULT
        if [ $? = 0 ]; then #se não teve erro, exibe msg de success
        echo -e "User $CHOOSE_USER \033[32munlocked\033[m ! "
        user_options #Volta ao menu das opções do usuário
        else #Se teve erro, exibe e sai
            echo "Something wrong: $RESULT"
            exit
        fi
    ;;
        3)  # o segundo define o shell do usuário 
        cat /etc/shells  #exibe a lista de shells do sistema
        echo ""  # pula uma linha 
        read -p "Escolha o shell (digite o caminho completo): " SHELL  #o usuário digita o shell
        RESULT=$( usermod -s "$SHELL" $NAME 2>&1 ) #seta o shell e guarda em $RESULT
        if [ $? = 0 ]; then #Se não teve erro, exibe msg de success
        echo "" # pula linha
        echo -e "Shell \033[32m$SHELL\033[m definido para $NAME"
        user_options #Volta ao menu das opções do usuário
        else #Se teve erro, exibe e sai
            echo "Something wrong: $RESULT"
            exit
        fi
    ;;
        6) # o sexto altera a senha 
        RESULT=$( passwd $NAME 1>&2 ) #roda o passwd USER
        if [ $? = 0 ]; then
        user_options #Volta ao menu das opções do usuário
        else
            echo "Something wrong: $RESULT"
            exit
        fi
    ;;
         8) #caso 8, sai do programa
            sleep 3
            echo "Bye"
            exit
        
    ;;
    *)
#encerra o case
esac

#Caso não tenha sido escolhido nenhuma das opções acima (1,2,3,6) sai.
else 
echo "INVALID NUMBER"
exit
#fim do if
fi
}

###############
# aqui começa #
###############


menu_principal   #Exibe o menu principal


#  Verifica se uma das 3 opções foi escolhida (1,2,9)

#1º for
if [ $CHOOSE_INIT == 1 ]; then              #Se for 1 vai listar todos os usuário do /etc/passwd
  
USER_UID=$(cut -d: -f 1,3 /etc/passwd --output-delimiter='>' )     #traz o nome e UID, seta o delimitador ">" para usar no column
ALL=''                                     #Será o resultado final no formato : user id status lastlogin
LASTLOG=''                                 #ultimo login ssh do usuário
PASS_STATUS=''                             # Guarda  L | P | NP retirados do #passwd -S

#2º FOR
for passo in $USER_UID #ITERA SOBRE AS LINHAS DO /ETC/PASSWD 1,3
do
USER_NAME=$(echo $passo | sed 's/>.*$//') #REMOVE O ID DO USUARIO, DEIXANDO O NOME
PASS_STATUS=$(passwd -S $USER_NAME 2> /dev/null | cut -d " " -f 2   ) # PEGA o $USER_NAME e passa como parametro para o passwd e Retorna L | P | NP
LASTLOG=$(lastlog -u $USER_NAME | tail -1 | tr -s " " | cut -d " " -f 2- ) # $LASLOG guarda o último \
# login via SSH do usuário, pega o ultimo campo do retorno (o que traz a o horário)

#echo $PASS_STATUS  #para debug


if [[ "$PASS_STATUS" != "L" &&  "$PASS_STATUS" != "P" &&  "$PASS_STATUS" != "NP" ]] ;then  #checa se não contém um desses
PASS_STATUS="\033[31mSem permissão\033[m"  #caso não tenha L | P | NP , $PASS_STATUS guarda o erro "sem permissão"
elif [ "$PASS_STATUS" = "L" ] ; then    #caso seja L (locket) fica vermelho
PASS_STATUS="\033[31mLOCKED\033[m"         
elif [ "$PASS_STATUS" = "P" ] ; then    #caso seja P (pass ok) fica verde
PASS_STATUS="\033[32mPASSOK\033[m"         
elif [ "$PASS_STATUS" = "NP" ] ; then   #caso seja NP (no pass) fica azul
PASS_STATUS="\033[34mNO PASS\033[m"        
fi


#JUNTA TUDO NA STRING ALL
ALL="\
| $passo>$PASS_STATUS>$LASTLOG |\n\
$ALL\n" #ADICIONA O VALOR NO FINAL para somar a string
#Fim do 2º for
done 


#IMPRIME NA TELA TODOS OS USUÁRIOS
echo -e "$ALL" | column -t -s '>'  

#Com a saída na tela, agora é hora de escolher um usuário da lista, por nome ou UID
user_options  #exibe as opções para o usuário selecionado

#Se no início o usuário escolheu 9 (sair), encerra o programa
elif [ $CHOOSE_INIT == 5 ]; then
echo "Bye"
exit
#Fim do 1º for
fi