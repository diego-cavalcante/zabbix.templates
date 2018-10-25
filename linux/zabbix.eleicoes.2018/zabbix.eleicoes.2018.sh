#!/bin/bash
#####################################################################################################
# Script Title:   ZAE2018                                                                           #
# Script Descr:   ZABBIX ELEICOES 2018 MONITOR                                                      #
# Script Name:    zabbix.eleicoes.2018.sh                                                           #
# Author:         Diego Cavalcante                                                                  #
# E-Mail:         diego@suportecavalcante.com.br                                                    #
# Telegram:       @diego_cavalcante                                                                 #
# Description BR: Coleta metricas da apuracao das eleicoes 2018 dos presidenciaveis.                #
#                 Coleta metricas em ambito nacional e por estado.                                  #
# Description EN: Collect metrics for the 2018 presidential elections.                              #
#                 Collect metrics nationwide and by state.                                          #
# Help:           Execute /bin/bash zabbix.eleicoes.2018.sh para informacoes de uso.                #
#                 Run /bin/bash zabbix.eleicoes.2018.sh for usage information.                      #
# Create v1.0.0:  Wed Oct 24 10:17:17 BRT 2018                                                      #
#####################################################################################################

# REQUIREMENTS ######################################################################################
# curl, jq.                                                                                         #
# END ###############################################################################################

# GLOBAL VARIABLES ##################################################################################
VERS="1.0.0"                                                                                        #
VERCREATE="24/10/2018"                                                                              #
VERUPDATE="24/10/2018"                                                                              #
VERSCRIPTAUTHOR="Diego Cavalcante"                                                                  #
NUMBSTATE=$2                                                                                        #
CANDIDATE=$3                                                                                        #
URL="http://interessados.divulgacao.tse.jus.br/2018/divulgacao/oficial"                             #
URLBR="$URL/296/dadosdivweb/br/br-c0001-e000296-w.js"                                               #
URLUF="$URL/296/dadosdivweb/$NUMBSTATE/$NUMBSTATE-c0001-e000296-w.js"                               #
# END ###############################################################################################

# Function JSON #####################################################################################
# BR - Monta JSON com os nomes e numero dos candidatos.                                             #
# EN - Mount JSON with names and number of candidates.                                              #
#####################################################################################################

function json
{
LLDNUMB=(`curl -s $URLBR |jq '.cand[].n' |sed s/'"'/""/g`)
LLDNAME=(`curl -s $URLBR |jq '.cand[].nm' |sed s/'"'/""/g |tr " " "_"`)
length=${#LLDNUMB[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#NUMBER}\":\"${LLDNUMB[$i]}\", \"{#NAME}\":\"${LLDNAME[$i]}\"}" |tr "_" " "
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
# END ###############################################################################################

# Function BRVOTOS ##################################################################################
# BR - Total de votos Brasil para o candidato selecionado.                                          #
# EN - Total votes Brazil for the selected candidate.                                               #
#####################################################################################################

function brvotos
{
RESULT=`curl -s $URLBR |jq '.cand |map({nm, n, v})' |sed s/'"'/""/g |grep -iE "n: $NUMBSTATE" -A 1 |awk 'END{print $2}'`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRSESSOES ################################################################################
# BR - Total de sessões no Brasil.                                                                  #
# EN - Total sessions in Brazil.                                                                    #
#####################################################################################################

function brsessoes
{
RESULT=`curl -s $URLBR |jq '.s' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRSESSOEST ###############################################################################
# BR - Total de sessões apuradas no Brasil.                                                         #
# EN - Total number of sections cleared in Brazil.                                                  #
#####################################################################################################

function brsessoest
{
RESULT=`curl -s $URLBR |jq '.st' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEIT ##################################################################################
# BR - Total de eleitores aptos para votar no Brasil.                                               #
# EN - Total voters eligible to vote in Brazil.                                                     #
#####################################################################################################

function breleit
{
RESULT=`curl -s $URLBR |jq '.e' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEITC #################################################################################
# BR - Total de eleitores que compareceram na votação no Brasil.                                    #
# EN - Total voters who attended the voting in Brazil.                                              #
#####################################################################################################

function breleitc
{
RESULT=`curl -s $URLBR |jq '.c' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEITA #################################################################################
# BR - Total de abstenções no Brasil.                                                               #
# EN - Total abstentions in Brazil.                                                                 #
#####################################################################################################

function breleita
{
RESULT=`curl -s $URLBR |jq '.a' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEITB #################################################################################
# BR - Total de votos brancos no Brasil.                                                            #
# EN - Total white votes in Brazil.                                                                 #
#####################################################################################################

function breleitb
{
RESULT=`curl -s $URLBR |jq '.vb' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEITN #################################################################################
# BR - Total de votos nulos no Brasil.                                                              #
# EN - Total null votes in Brazil.                                                                  #
#####################################################################################################

function breleitn
{
RESULT=`curl -s $URLBR |jq '.vn' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function BRELEITVV ################################################################################
# BR - Total de votos validos no Brasil.                                                            #
# EN - Total valid votes in Brazil.                                                                 #
#####################################################################################################

function breleitvv
{
RESULT=`curl -s $URLBR |jq '.vv' |sed s/'"'/""/g`
if [ $RESULT -eq 0 ]; then
   echo "1"
else
   echo "$RESULT"
fi
}
# END ###############################################################################################

# Function BRUPDATE #################################################################################
# BR - Ultima atualização dos webservices, data e hora.                                             #
# EN - Last update of webservices, date and time.                                                   #
#####################################################################################################

function brupdate
{
RESULTD=`curl -s $URLBR |jq '.dt' |sed s/'"'/""/g`
RESULTH=`curl -s $URLBR |jq '.ht' |sed s/'"'/""/g`
echo "$RESULTD $RESULTH"
}
# END ###############################################################################################

# Function UFVOTOS ##################################################################################
# BR - Total de votos por unidade federativa no candidato selecionado.                              #
# EN - Total votes per federative unit in the selected candidate.                                   #
#####################################################################################################

function ufvotos
{
RESULT=`curl -s $URLUF |jq '.cand |map({nm, n, v})' |sed s/'"'/""/g |grep -iE "n: $CANDIDATE" -A 1 |awk 'END{print $2}'`
echo "$RESULT"
}
# END ###############################################################################################

# Function UFSESSOES ################################################################################
# BR - Total de sessões da unidade federativa.                                                      #
# EN - Total sessions of the federative unit.                                                       #
#####################################################################################################

function ufsessoes
{
RESULT=`curl -s $URLUF |jq '.s' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function UFSESSOEST ###############################################################################
# BR - Total de sessões apuradas na unidade federativa.                                             #
# EN - Total sections cleared in the federative unit.                                               #
#####################################################################################################

function ufsessoest
{
RESULT=`curl -s $URLUF |jq '.st' |sed s/'"'/""/g`
echo "$RESULT"
}
# END ###############################################################################################

# Function UFELEITVV ################################################################################
# BR - Total de votos validos na unidade federativa.                                                #
# EN - Total valid votes in the federative unit.                                                    #
#####################################################################################################

function ufeleitvv
{
RESULT=`curl -s $URLUF |jq '.vv' |sed s/'"'/""/g`
if [ $RESULT -eq 0 ]; then
   echo "1"
else
   echo "$RESULT"
fi
}
# END ###############################################################################################

# Function UFUPDATE #################################################################################
# BR - Ultima atualização dos webservices, data e hora.                                             #
# EN - Last update of webservices, date and time.                                                   #
#####################################################################################################

function ufupdate
{
RESULTD=`curl -s $URLUF |jq '.dt' |sed s/'"'/""/g`
RESULTH=`curl -s $URLUF |jq '.ht' |sed s/'"'/""/g`
echo "$RESULTD $RESULTH"
}
# END ###############################################################################################

###################################
#      PARAMETER OPTION $1        #
###################################
case $1 in                        #
        JSON) json;               #
        ;;                        #
        BRVOTOS) brvotos;         #
        ;;                        #
        BRSESSOES) brsessoes;     #
        ;;                        #
        BRSESSOEST) brsessoest;   #
        ;;                        #
        BRELEIT) breleit;         #
        ;;                        #
        BRELEITC) breleitc;       #
        ;;                        #
        BRELEITA) breleita;       #
        ;;                        #
        BRELEITB) breleitb;       #
        ;;                        #
        BRELEITN) breleitn;       #
        ;;                        #
        BRELEITVV) breleitvv;     #
        ;;                        #
        BRUPDATE) brupdate;       #
        ;;                        #
        UFVOTOS) ufvotos;         #
        ;;                        #
        UFSESSOES) ufsessoes;     #
        ;;                        #
        UFSESSOEST) ufsessoest;   #
        ;;                        #
        UFELEITVV) ufeleitvv;     #
        ;;                        #
        UFUPDATE) ufupdate;       #
        ;;                        #
        *)                        #
# END #############################
echo ""
echo "================================================================================================================="
echo "= _____________ ________________ _______ _____________  NAME: ZAE2018 ==========================================="
echo "= ___  /___    |___  ____/__|__ \__  __ \__<  /__( __ ) DESCRIPTION: ZABBIX ELEICOES 2018 MONITOR ==============="
echo "= __  / __  /| |__  __/   ____/ /_  / / /__  / _  __  | VERSION: $VERS =========================================="
echo "= _  /___  ___ |_  /___   _  __/ / /_/ / _  /  / /_/ /  CREATE: $VERCREATE ======================================"
echo "= /____//_/  |_|/_____/   /____/ \____/  /_/   \____/   UPDATE: $VERUPDATE ======================================"
echo "=                                                       AUTHOR: $VERSCRIPTAUTHOR ================================"
echo "================================================================================================================="
echo "= USAGE: JSON|BRVOTOS|BRSESSOES|BRSESSOEST|BRELEIT|BRELEITC|BRELEITA|BRELEITB|BRELEITN|BRELEITVV|BRUPDATE       ="
echo "= USAGE: UFVOTOS|UFSESSOES|UFSESSOEST|UFELEITVV|UFUPDATE                                                        ="
echo "=                                                                                                               ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh JSON                                                                    ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRVOTOS NUMERO                                                          ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRSESSOES                                                               ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRSESSOEST                                                              ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEIT                                                                 ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEITC                                                                ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEITA                                                                ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEITB                                                                ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEITN                                                                ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRELEITVV                                                               ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh BRUPDATE                                                                ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh UFVOTOS UF NUMERO                                                       ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh UFSESSOES UF                                                            ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh UFSESSOEST UF                                                           ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh UFELEITVV UF                                                            ="
echo "= Ex: /bin/bash zabbix.eleicoes.2018.sh UFUPDATE UF                                                             ="
echo "================================================================================================================="
echo "= NUMERO: Numero do candidato. (ex: 17, 13, 12, 45, 30, 51, 15 ou outros)                                       ="
echo "= UF: Sigla do estado (Unidade Federativa). (ex: pb, pe, sp, df, go, ac, ou outros)                             ="
echo "================================================================================================================="
echo ""
exit ;;
esac
# END SCRIPT ###########################################################################################################
