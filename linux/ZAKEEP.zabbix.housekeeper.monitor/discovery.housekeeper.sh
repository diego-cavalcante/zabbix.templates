#!/bin/bash
#####################################################################################################
# Script Title:   ZAKEEP                                                                            #
# Script Descr:   ZABBIX HOUSEKEEPER MONITOR                                                        #
# Script Name:    discovery.housekeeper.sh                                                          #
# Author:         Diego Cavalcante                                                                  #
# E-Mail:         diego@suportecavalcante.com.br                                                    #
# Telegram:       @diego_cavalcante                                                                 #
# Description BR: Coleta metricas sobre a execucao do Housekeeper.                                  #
#                 Fornece relatorio sobre as ultimas execucoes (dados deletados, data e tempo).     #
# Description EN: Collect Metrics on Housekeeper Execution.                                         #
#                 Provides report on the last executions (data deleted, date and time).             #
# Help:           Execute /bin/bash discovery.housekeeper.sh para informacoes de uso.               #
#                 Run /bin/bash discovery.housekeeper.sh for usage information.                     #
# Create v1.0.0:  Sun Jan 07 17:55:32 BRT 2018                                                      #
# Update v1.1.0:  Wed Jul 04 22:14:49 BRT 2018 (ADD function report)                                #
#####################################################################################################

# REQUIREMENTS ######################################################################################
# none.                                                                                             #
# END ###############################################################################################

# GLOBAL VARIABLES ##################################################################################
VERS="1.1.0"                                                                                        #
VERCREATE="07/01/2018"                                                                              #
VERUPDATE="04/07/2018"                                                                              #
VERSCRIPTAUTHOR="Diego Cavalcante"                                                                  #
TABLE=$2                                                                                            #
LOG="/var/log/zabbix/zabbix_server.log"                                                             #
FILTER="housekeeper [deleted"                                                                       #
COLNAME="= DATE TIME HIST/TRENDS ITEMS/TRIGGERS EVENTS PROBLEMS SESSIONS ALARMS AUDIT DURATION ="   #
# END ###############################################################################################

# Function JSON #####################################################################################
# BR - Monta JSON com os nomes das tabelas que são afetadas pelo housekeeper.                       #
# EN - Mounts JSON with names of tables that are affected by housekeeper.                           #
#####################################################################################################

function json
{
command=(`cat $LOG |grep -F "housekeeper [deleted" |awk 'END{print $5, $7, $9, $11, $13, $15, $17}' |sed 's/,//g' |tr ' ' '\n'`)
length=${#command[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#HOUSEKEEPER}\":\"${command[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
# END ###############################################################################################

# Function DURATION #################################################################################
# BR - Verifica o ultimo housekeeper executado, coleta tempo gasto do ultimo housekeeper.           #
# EN - Check the last housekeeper run, collect time end of the last housekeeper.                    #
#####################################################################################################

function duration
{
RESULT=`cat $LOG |grep -F "housekeeper [deleted" |awk 'END{print $20}'`
echo "$RESULT"
}
# END ###############################################################################################

# Function DELETED ##################################################################################
# BR - Verifica o ultimo housekeeper executado e coleta quantos registros foram excluidos.          #
# EN - Checks the last executed housekeeper and collects how many records were deleted.             #
#####################################################################################################

function deleted
{
RESULT=`cat $LOG |grep -F "housekeeper [deleted" |awk 'END{print}' |awk -F $TABLE '{print $1}' |awk '{print $NF}'`
echo "$RESULT"
}
# END ###############################################################################################

# Function REPORT ###################################################################################
# BR - Fornece relatorio detalhado sobre das ultimas execucoes do housekeeper.                      #
# EN - Provides detailed report on the latest housekeeper.                                          #
#####################################################################################################

function report
{
EXECHK=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |awk '{print $2"_"$3}' |head -n 24`
echo ""
echo "================================================================================================================="
echo "= _____________ ______ ______________________________                                                           ="
echo "= ___  /___    |___  //_/___  ____/___  ____/___  __ \                                                          ="
echo "= __  / __  /| |__  ,<   __  __/   __  __/   __  /_/ /                       REPORT ZAKEEP                      ="
echo "= _  /___  ___ |_  /| |  _  /___   _  /___   _  ____/                 ZABBIX HOUSEKEEPER MONITOR                ="
echo "= /____//_/  |_|/_/ |_|  /_____/   /_____/   /_/                                                                ="
echo "=                                                                                                               ="
echo "================================================================================================================="
echo "$COLNAME" |awk -F" " '{printf "%-1s %-11s %-9s %-12s %-15s %-7s %-9s %-9s %-7s %-6s %-15s %-1s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'

# BR - Listar e organizar dados.
# EN - List and organize data.
for listexec in $EXECHK
do

RZLIMI=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $5}' |sed 's/housekeeper/=/g'`
RZDATE=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $2}' |sed 's/./ &/5' |sed 's/./ &/8' |awk '{print $3"/"$2"/"$1}'`
RZTIME=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $3}' |sed 's/./ &/3' |sed 's/./ &/6' |awk '{print $1":"$2":"$3}'`
RZHIST=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $7}'`
RZITEM=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $9}'`
RZEVEN=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $11}'`
RZPROB=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $13}'`
RZSESS=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $15}'`
RZALAR=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $17}'`
RZAUDI=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $19}'`
RZDURA=`cat $LOG |grep -F "$FILTER" |sort -rg |tr ":." " " |tr " " "_" |grep -iE "$listexec" |tr "_" " " |awk '{print $23"."$24}'`
RZCONV=`date -d@$RZDURA -u +%H:%M:%S`
OUTPUT="$RZLIMI $RZDATE $RZTIME $RZHIST $RZITEM $RZEVEN $RZPROB $RZSESS $RZALAR $RZAUDI $RZCONV $RZLIMI"

# BR - Montar saída formatada.
# EN - Mount output formated.
echo "$OUTPUT" |awk -F" " '{printf "%-1s %-11s %-9s %-12s %-15s %-7s %-9s %-9s %-7s %-6s %-15s %-1s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}'
done
echo "================================================================================================================="
echo ""
}
# END ###############################################################################################

#################################
#     PARAMETER OPTION $1       #
#################################
case $1 in                      #
        JSON) json;             #
        ;;                      #
        DURATION) duration;     #
        ;;                      #
        DELETED) deleted;       #
        ;;                      #
        REPORT) report;         #
        ;;                      #
        *)                      #
# END ###########################
echo ""
echo "================================================================================================================="
echo "= _____________ ______ ______________________________  NAME: ZAKEEP ============================================="
echo "= ___  /___    |___  //_/___  ____/___  ____/___  __ \ DESCRIPTION: ZABBIX HOUSEKEEPER MONITOR =================="
echo "= __  / __  /| |__  ,<   __  __/   __  __/   __  /_/ / VERSION: $VERS ==========================================="
echo "= _  /___  ___ |_  /| |  _  /___   _  /___   _  ____/  CREATE: $VERCREATE ======================================="
echo "= /____//_/  |_|/_/ |_|  /_____/   /_____/   /_/       UPDATE: $VERUPDATE ======================================="
echo "=                                                      AUTHOR: $VERSCRIPTAUTHOR ================================="
echo "================================================================================================================="
echo "= USAGE: JSON|DURATION|DELETED                                                                                  ="
echo "=                                                                                                               ="
echo "= Ex: /bin/bash discovery.housekeeper.sh JSON                                                                   ="
echo "= Ex: /bin/bash discovery.housekeeper.sh DURATION                                                               ="
echo "= Ex: /bin/bash discovery.housekeeper.sh DELETED TABLE                                                          ="
echo "= Ex: /bin/bash discovery.housekeeper.sh REPORT                                                                 ="
echo "================================================================================================================="
echo "= TABLE: Table name. (ex: alarms, audit, events, hist/trends, items/triggers, problems or sessions)             ="
echo "================================================================================================================="
echo ""
exit ;;
esac
# END SCRIPT ###########################################################################################################
