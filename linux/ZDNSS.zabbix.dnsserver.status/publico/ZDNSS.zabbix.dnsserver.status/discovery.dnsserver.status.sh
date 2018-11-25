#!/bin/bash
#####################################################################################################
# Script Title:   ZDNSS                                                                             #
# Script Descr:   ZABBIX DNS SERVER STATUS MONITOR                                                  #
# Script Name:    discovery.dnsserver.status.sh                                                     #
# Author:         Diego Cavalcante                                                                  #
# E-Mail:         diego@suportecavalcante.com.br                                                    #
# Telegram:       @diego_cavalcante                                                                 #
# Description BR: Descoberta de DNS Servers do dominio especificado e tempo de resposta.            #
# Description EN: DNS Servers Discovery of Specified Domain is Response Time.                       #
# Help:           Execute /bin/bash discovery.dnsserver.status.sh para informacoes de uso.          #
#                 Run /bin/bash discovery.dnsserver.status.sh for usage information.                #
# Create v1.0.0:  Fri Nov 24 21:30:05 BRT 2017                                                      #
#####################################################################################################

# REQUIREMENTS ######################################################################################
# dig.                                                                                              #
# END ###############################################################################################

# GLOBAL VARIABLES ##################################################################################
VERS="1.0.0"                                                                                        #
VERCREATE="24/11/2017"                                                                              #
VERUPDATE="24/07/2018"                                                                              #
VERSCRIPTAUTHOR="Diego Cavalcante"                                                                  #
DNS=$2                                                                                              #
DOMAIN=$3                                                                                           #
TYPE=$4                                                                                             #
# END ###############################################################################################

# Function JSON #####################################################################################
# BR - Monta JSON com o dominio, nameserver e IP da zona consultada.                                #
# EN - JSON mount with the domain, nameserver and IP of the zone consulted.                         #
#####################################################################################################

function json
{
LLDZN=(`dig @$DNS $DOMAIN -t $TYPE +short |sort |rev |cut -c 2- |rev`)
LLDNS=`dig @$DNS $DOMAIN -t $TYPE +short |sort |rev |cut -c 2- |rev`
LLDIP=(`dig $LLDNS -t A +short`)
length=${#LLDZN[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#DNSZONE}\":\"$DOMAIN\", \"{#DNSSERVER}\":\"${LLDZN[$i]}\", \"{#DNSIP}\":\"${LLDIP[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
# END ###############################################################################################

# Function RESPONSE #################################################################################
# BR - Verifica tempo de resposta do servidor DNS consultado.                                       #
# EN - Check DNS server response time queried.                                                      #
#####################################################################################################

function response
{
CHECKDNS=`dig @$DNS $DOMAIN -t $TYPE |grep ">>HEADER<<" |awk '{print $6}' |sed 's/,//g'`
CHECKDNSTIME=`dig @$DNS $DOMAIN -t $TYPE |grep 'Query time' |awk '{print $4}'`

# Handles output in text and converts to number.
function consult_status() {
	[[ $CHECKDNS == "NOERROR"  ]] && echo "0" # DNS query completed successfully.
	[[ $CHECKDNS == "FORMERR"  ]] && echo "1" # DNS query format error.
	[[ $CHECKDNS == "SERVFAIL" ]] && echo "2" # The server failed to complete the DNS request.
        [[ $CHECKDNS == "NXDOMAIN" ]] && echo "3" # Domain name does not exist.
        [[ $CHECKDNS == "NOTIMP"   ]] && echo "4" # Function not implemented.
        [[ $CHECKDNS == "REFUSED"  ]] && echo "5" # Server refused to respond by query.
        [[ $CHECKDNS == "YXDOMAIN" ]] && echo "6" # The name that should not exist exists.
        [[ $CHECKDNS == "XRRSET"   ]] && echo "7" # Record that should not exist, there is.
        [[ $CHECKDNS == "NOTAUTH"  ]] && echo "8" # Unauthorized server for the zone.
        [[ $CHECKDNS == "NOTZONE"  ]] && echo "9" # Name not found in zone.
}
OUTPUT=`consult_status "$CHECKDNS"` # Query Status Response converted to number.
if [ $OUTPUT == 0 ]; then           # 1º check if the response status is 0 = NOERROR
	echo "$CHECKDNSTIME"        # If Yes = Shows the response time in msec
else                                #
	echo "0"                    # If No = Returns "0" and will be used as trigger on zabbix
fi
}
# END ###############################################################################################

#################################
#     PARAMETER OPTION $1       #
#################################
case $1 in                      #
        JSON) json;             #
        ;;                      #
        RESPONSE) response;     #
        ;;                      #
        *)                      #
# END ###########################
echo ""
echo "================================================================================================================="
echo "= ______________ _____   __________________ NAME: ZDNSS ========================================================="
echo "= ___  /___  __ \___  | / /__  ___/__  ___/ DESCRIPTION: ZABBIX DNS SERVER STATUS MONITOR ======================="
echo "= __  / __  / / /__   |/ / _____ \ _____ \  VERSION: $VERS ======================================================"
echo "= _  /___  /_/ / _  /|  /  ____/ / ____/ /  CREATE: $VERCREATE =================================================="
echo "= /____//_____/  /_/ |_/   /____/  /____/   UPDATE: $VERUPDATE =================================================="
echo "=                                           AUTHOR: $VERSCRIPTAUTHOR ============================================"
echo "================================================================================================================="
echo "= USAGE: JSON|RESPONSE                                                                                          ="
echo "=                                                                                                               ="
echo "= Ex: /bin/bash discovery.dnsserver.status.sh JSON 8.8.8.8 ZONE NS                                              ="
echo "= Ex: /bin/bash discovery.dnsserver.status.sh RESPONSE IP/NS ZONE NS                                            ="
echo "================================================================================================================="
echo "= ZONE: Domain name consulted. (ex: google.com, facebook.com, yourdomain.com.br)                                ="
echo "= IP/NS: IP or DNS server name queried. (ex: ns1.google.com, 216.239.32.10, ns2.google.com, 216.239.34.10)      ="
echo "================================================================================================================="
echo ""
exit ;;
esac
# END SCRIPT ###########################################################################################################
