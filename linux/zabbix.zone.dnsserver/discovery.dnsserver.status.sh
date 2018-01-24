#!/bin/bash
# Script: discovery.dnsserver.status.sh
# Versão: 1.0
# Autor: Diego Cavalcante
# Data: Fri Nov 24 21:30:0 BRT 2017
# Email: diego@suportecavalcante.com.br
# Telegram: @diego_cavalcante
# Descrição: LLD Monitoramento Zona DNS Status, DNS Servers Status e Tempo de Resposta
# Ajuda: Execute /bin/bash discovery.dnsserver.status.sh para informacoes de uso.
# Parametro $1 = Funcao a ser chamada.
# Parametro $2 = IP ou Dominio do servidor DNS a ser consultado.
# Parametro $3 = Zona DNS a ser consultado.
# Parametro $4 = Tipo de Consulta DNS a ser realizada.

# Parametros #
DNS=$2
DOMINIO=$3
TIPO=$4

# Funcao 01 = JSON #########################################################################################################
# Funcao que monta o JSON com as informacoes de Zona, DNS Server e DNS IP.
function json
{
lld1=(`dig @$DNS $DOMINIO -t $TIPO +short | sort | rev | cut -c 2- | rev`) # Lista DNS Servers da Zona na Macro {#DNSSERVER}
lld2=`dig @$DNS $DOMINIO -t $TIPO +short | sort | rev | cut -c 2- | rev`   # Lista DNS Servers da Zona em Ordem Crescente
lldip=(`dig $lld2 -t A +short`)                                            # Lista IPs dos DNS Servers na Macro {#DNSIP}
length=${#lld1[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#DNSZONA}\":\"$DOMINIO\", \"{#DNSSERVER}\":\"${lld1[$i]}\", \"{#DNSIP}\":\"${lldip[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
}
############################################################################################################################

# Funcao 02 = TEMPO ########################################################################################################
# Funcao que consulta o tempo de resposta do servidor DNS.
function tempo
{
CHECKDNS=`dig @$DNS $DOMINIO -t $TIPO | grep ">>HEADER<<" | awk '{print $6}' | sed 's/,//g'` # Status da Consulta DNS
CHECKDNSTIME=`dig @$DNS $DOMINIO -t $TIPO | grep 'Query time' | awk '{print $4}'`            # Tempo de Resposta da Consulta

# Trata a saida em texto e converte em numero.
function consultar_status() {
	[[ $CHECKDNS == "NOERROR"  ]] && echo "0" # Consulta de DNS concluída com sucesso.
	[[ $CHECKDNS == "FORMERR"  ]] && echo "1" # Erro de formato de consulta DNS.
	[[ $CHECKDNS == "SERVFAIL" ]] && echo "2" # O servidor falhou ao completar o pedido de DNS.
        [[ $CHECKDNS == "NXDOMAIN" ]] && echo "3" # O nome de domínio não existe.
        [[ $CHECKDNS == "NOTIMP"   ]] && echo "4" # Função não implementada.
        [[ $CHECKDNS == "REFUSED"  ]] && echo "5" # O servidor recusou responder pela consulta.
        [[ $CHECKDNS == "YXDOMAIN" ]] && echo "6" # O nome que não deveria existir, existe.
        [[ $CHECKDNS == "XRRSET"   ]] && echo "7" # Conjunto de RR que não deveria existir, existe.
        [[ $CHECKDNS == "NOTAUTH"  ]] && echo "8" # Servidor não autorizado para a zona.
        [[ $CHECKDNS == "NOTZONE"  ]] && echo "9" # Nome não encontrado na zona.
}
RESPOSTA=`consultar_status "$CHECKDNS"` # Resposta do Status da Consulta convertido em numero
if [ $RESPOSTA == 0 ]; then             # 1ª verifica se o status da resposta é 0 = NOERROR
	echo "$CHECKDNSTIME"            # Caso Sim = Mostra o tempo de Resposta em msec
else
	echo "0"                        # Caso Nao = Retorna "0" e será usado como trigger no zabbix
fi
}
############################################################################################################################

# Opcoes do Parametro $1 ###################################################################################################
case $1 in
            JSON)
json ;;
            TEMPO)
tempo ;;
            *)
echo ""
echo "##################################################### AJUDA #####################################################"
echo "#                                                                                                               #"
echo "# Opcoes Disponiveis no 1º Parametro JSON|TEMPO                                                                 #"
echo "#                                                                                                               #"
echo "# Ex: /bin/bash discovery.dnsserver.status.sh Param1 Param2 Param3 Param4                                       #"
echo "# Ex: /bin/bash discovery.dnsserver.status.sh JSON 8.8.8.8 dominio.com.br NS                                    #"
echo "# Ex: /bin/bash discovery.dnsserver.status.sh TEMPO IP/DNS dominio.com.br NS                                    #"
echo "#                                                                                                               #"
echo "#################################################################################################################"
echo ""
exit ;;
esac
############################################################################################################################
