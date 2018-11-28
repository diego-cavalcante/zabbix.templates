#!/bin/bash
#####################################################################################################
# Script Title:   ZACUP                                                                             #
# Script Descr:   ZABBIX CHECK UPDATE MONITOR                                                       #
# Script Name:    discovery.zabbix.update.sh                                                        #
# Author:         Diego Cavalcante                                                                  #
# E-Mail:         diego@suportecavalcante.com.br                                                    #
# Telegram:       @diego_cavalcante                                                                 #
# Description BR: Verifica repositorio do zabbix e procura atualizacoes disponiveis.                #
# Description EN: Check zabbix repository for available updates.                                    #
# Help:           Execute /bin/bash discovery.zabbix.update.sh para informacoes de uso.             #
#                 Run /bin/bash discovery.zabbix.update.sh for usage information.                   #
# Create v1.0.0:  Fri Dec 08 10:54:22 BRT 2017                                                      #
# Update v1.0.1:  Wed Jul 25 15:09:08 BRT 2018 (ADD check version of O.S).                          #
# Update v1.1.0:  Wed Oct 10 13:32:22 BRT 2018 (ADD function JSON).                                 #
# Update v1.2.0:  Tue Nov 27 16:12:57 BRT 2018 (ADD function JSONDEV and DEV).                      #
#####################################################################################################

# REQUIREMENTS ######################################################################################
# lynx.                                                                                             #
# END ###############################################################################################

# GLOBAL VARIABLES ##################################################################################
VERS="1.2.0"                                                                                        #
VERCREATE="08/12/2017"                                                                              #
VERUPDATE="27/11/2018"                                                                              #
VERSCRIPTAUTHOR="Diego Cavalcante"                                                                  #
ZBVERSION=$2                                                                                        #
LYNX='lynx -dump'                                                                                   #
DEVLURL='https://www.zabbix.com/developers'                                                         #
REPOURL='http://repo.zabbix.com/zabbix'                                                             #
RELDEB='pool/main/z/zabbix-release/'                                                                #
RELUBU='pool/main/z/zabbix-release/'                                                                #
REPOMAIN='pool/main/z/zabbix/'                                                                      #
U='ubuntu'                                                                                          #
D='debian'                                                                                          #
C='rhel'                                                                                            #
# END ###############################################################################################

# Function JSON #####################################################################################
# BR - Monta JSON com todas as versões disponíveis do Zabbix.                                       #
# EN - Mounts JSON with all available versions of Zabbix.                                           #
#####################################################################################################

function json
{
command=(`$LYNX $REPOURL |grep "]" |awk '{print $1}' |grep "/" |grep -iE "1.8" -A 254 |cut -d "]" -f2 |cut -d "/" -f1`)
length=${#command[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#ZABBIXVERSION}\":\"${command[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
# END ###############################################################################################

# Function UBUNTU ###################################################################################
# BR - Verifica atualizacao disponivel do Zabbix para Ubuntu.                                       #
# EN - Checks available Zabbix update for Ubuntu.                                                   #
#####################################################################################################

function ubuntu
{
CHECKOSV=`lsb_release -c |awk '{print $2}'`
CHECKOSN=`lsb_release -d |awk '{print $2, $3}'`
CHECKZB=`$LYNX $REPOURL/$ZBVERSION/$U/$RELUBU |grep -w "$CHECKOSV" |grep "http" |awk '{print $2}' |wc -l |sed '/^$/d'`
if [ $CHECKZB -eq 0 ]; then
   echo "Zabbix $ZBVERSION for $CHECKOSN ($CHECKOSV) not found."
else
   OUTPUT=`$LYNX $REPOURL/$ZBVERSION/$U/$REPOMAIN |grep "$CHECKOSV" |grep ".tar." |sed 's/_/ /g' |sed 's/-/ /g' |grep "repo." |awk '{print $3}' |sort -n |awk 'END{print}'`
   echo "$OUTPUT"
fi
}
# END ###############################################################################################

# Function DEBIAN ###################################################################################
# BR - Verifica atualizacao disponivel do Zabbix para Debian.                                       #
# EN - Checks available Zabbix update for Debian.                                                   #
#####################################################################################################

function debian
{
CHECKOSV=`lsb_release -c |awk '{print $2}'`
CHECKOSN=`lsb_release -d |awk '{print $2, $4}'`
CHECKZB=`$LYNX $REPOURL/$ZBVERSION/$D/$RELDEB |grep -w "$CHECKOSV" |grep "http" |awk '{print $2}' |wc -l |sed '/^$/d'`
if [ $CHECKZB -eq 0 ]; then
   echo "Zabbix $ZBVERSION for $CHECKOSN ($CHECKOSV) not found."
else
   OUTPUT=`$LYNX $REPOURL/$ZBVERSION/$D/$REPOMAIN |grep "$CHECKOSV" |grep ".tar." |sed 's/_/ /g' |sed 's/-/ /g' |grep "repo." |awk '{print $3}' |sort -n |awk 'END{print}'`
   echo "$OUTPUT"
fi
}
# END ###############################################################################################

# Function CENTOS ###################################################################################
# BR - Verifica atualizacao disponivel do Zabbix para CentOS.                                       #
# EN - Checks available Zabbix update for CentOS.                                                   #
#####################################################################################################

function centos
{
CHECKOSV=`cat /etc/redhat-release |tr -d [:alpha:] |awk '{print $1}' |tr "." " " |awk '{print $1}'`
CHECKOSN=`cat /etc/redhat-release |tr -d [:alpha:] |awk '{print $1}'`
CHECKZB=`$LYNX $REPOURL/$ZBVERSION/$C/ |grep "$C" |grep "http" |tr "/" " " |awk '{print $NF}' |grep -w "$CHECKOSV" |wc -l`
if [ $CHECKZB -eq 0 ]; then
   echo "Zabbix $ZBVERSION for CentOS $CHECKOSN not found."
else
   OUTPUT=`$LYNX $REPOURL/$ZBVERSION/$C/$CHECKOSV/x86_64/ |grep "agent" |grep "$H" |sed 's/-/ /g' |awk '{print $4}' |sort -n |awk 'END{print}'`
   echo "$OUTPUT"
fi
}
# END ###############################################################################################

# Function JSONDEV ##################################################################################
# BR - Monta JSON com todas as versões de desenvolvimento disponíveis do Zabbix.                    #
# EN - Mounts JSON with all available development versions of Zabbix.                               #
#####################################################################################################

function jsondev
{
command=(`$LYNX $DEVLURL |grep "Zabbix Sources" |awk '{print $3}' |sed 's/Pre-//g' |tr "." " " |awk '{print $1,$2}' |tr " " "."`)
length=${#command[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#ZABBIXVERSIONDEV}\":\"${command[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
# END ###############################################################################################

# Function DEV ######################################################################################
# BR - Verifica atualizacao de versoes em desenvolvimento.                                          #
# EN - Check for updated versions of development.                                                   #
#####################################################################################################

function dev
{
CHECKZB=`$LYNX $DEVLURL |grep "Zabbix Sources" |grep -w "$ZBVERSION" |awk '{print $3}' |sed 's/Pre-//g' |wc -l |sed '/^$/d'`
if [ $CHECKZB -eq 0 ]; then
   echo "Zabbix Development $ZBVERSION not found."
else
   OUTPUT=`$LYNX $DEVLURL |grep "Zabbix Sources" |grep -w "$ZBVERSION" |awk '{print $3}' |sed 's/Pre-//g'`
   echo "$OUTPUT"
fi
}
# END ###############################################################################################

#################################
#     PARAMETER OPTION $1       #
#################################
case $1 in                      #
        JSON) json;             #
        ;;                      #
        UBUNTU) ubuntu;         #
        ;;                      #
        DEBIAN) debian;         #
        ;;                      #
        CENTOS) centos;         #
        ;;                      #
        JSONDEV) jsondev;       #
        ;;                      #
        DEV) dev;               #
        ;;                      #
        *)                      #
# END ###########################
echo ""
echo "================================================================================================================="
echo "= _____________ ______________  __________  NAME: ZACUP ========================================================="
echo "= ___  /___    |__  ____/__  / / /___  __ \ DESCRIPTION: ZABBIX CHECK UPDATE MONITOR ============================"
echo "= __  / __  /| |_  /     _  / / / __  /_/ / VERSION: $VERS ======================================================"
echo "= _  /___  ___ |/ /___   / /_/ /  _  ____/  CREATE: $VERCREATE =================================================="
echo "= /____//_/  |_|\____/   \____/   /_/       UPDATE: $VERUPDATE =================================================="
echo "=                                           AUTHOR: $VERSCRIPTAUTHOR ============================================"
echo "================================================================================================================="
echo "= USAGE: JSON|UBUNTU|DEBIAN|CENTOS|JSONDEV|DEV                                                                  ="
echo "=                                                                                                               ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh JSON                                                                 ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh UBUNTU ZABBIXVERSION                                                 ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh DEBIAN ZABBIXVERSION                                                 ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh CENTOS ZABBIXVERSION                                                 ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh JSONDEV                                                              ="
echo "= Ex: /bin/bash discovery.zabbix.update.sh DEV ZABBIXVERSION                                                    ="
echo "================================================================================================================="
echo "= ZABBIXVERSION: Check version of Zabbix available. (ex: 3.0, 3.2, 3.4, 4.0)                                    ="
echo "================================================================================================================="
echo ""
exit ;;
esac
# END SCRIPT ###########################################################################################################
