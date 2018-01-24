#!/bin/bash
# Script: discovery.housekeeper.sh
# Versão: 1.0
# Autor: Diego Cavalcante
# Data: Sun Jan 07 17:55:32 BRT 2018
# Email: <diego@suportecavalcante.com.br>
# Telegram: @diego_cavalcante
# Descrição: Coleta metricas sobre a execucao do Housekeeper.
# Ajuda: Execute /bin/bash discovery.housekeeper.sh para informacoes de uso.
# Parametro $1 = Opção JSON|TABELA|TEMPO
# Parametro $2 = Nome da Tabela

# Parametros e Variaveis #
TABLE=$2
LOG="/var/log/zabbix/zabbix_server.log"

# Funcao 01 = JSON #########################################################################################################
# Monta JSON com os nomes das tabelas que o housekeeper limpou dados.
function json
{
comando=(`cat $LOG | grep -F "housekeeper [deleted" | awk 'END{print $5, $7, $9, $11, $13, $15, $17}' | sed 's/,//g' | tr ' ' '\n'`)
length=${#comando[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#HOUSEKEEPER}\":\"${comando[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
############################################################################################################################

# Funcao 02 = TABELA #######################################################################################################
# Verifica no Log do zabbix_server.log o ultimo housekeeper executado, coleta quantos registros foram apagados da tabela.
function tabela
{
cat $LOG | grep -F "housekeeper [deleted" | awk 'END{print}' | awk -F $TABLE '{print $1}' | awk '{print $NF}'
}
############################################################################################################################

# Funcao 03 = TEMPO ########################################################################################################
# Verifica no Log do zabbix_server.log o ultimo housekeeper executado, coleta tempo gasto ate o final do ultimo housekeeper.
function tempo
{
cat $LOG | grep -F "housekeeper [deleted" | awk 'END{print $20}'
}
############################################################################################################################

# Opcoes do Parametro $1 ###################################################################################################
case $1 in
          JSON)
json ;;
          TABELA)
tabela ;;
          TEMPO)
tempo ;;
          *)
echo "##################################################### AJUDA #####################################################"
echo "#                                                                                                               #"
echo "# Opcoes Disponiveis no 1º Parametro JSON|TABELA|TEMPO                                                          #"
echo "#                                                                                                               #"
echo "# Ex: /bin/bash discovery.housekeeper.sh JSON                                                                   #"
echo "# Ex: /bin/bash discovery.housekeeper.sh TEMPO                                                                  #"
echo "# Ex: /bin/bash discovery.housekeeper.sh TABELA hist/trends                                                     #"
echo "# Ex: /bin/bash discovery.housekeeper.sh TABELA items/triggers                                                  #"
echo "#                                                                                                               #"
echo "#################################################################################################################"
exit ;;
esac
############################################################################################################################
