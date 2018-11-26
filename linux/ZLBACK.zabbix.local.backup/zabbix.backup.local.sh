#!/bin/bash
#####################################################################################################
# Script Title:   ZLBACK                                                                            #
# Script Descr:   ZABBIX LOCAL BACKUP DATABASE/FRONT                                                #
# Script Name:    zabbix.backup.local.sh                                                            #
# Author:         Diego Cavalcante                                                                  #
# E-Mail:         diego@suportecavalcante.com.br                                                    #
# Telegram:       @diego_cavalcante                                                                 #
# Description BR: Realiza backup da database, frontend e arquivos de configuração do S.O.           #
#                 Fornece relatorio sobre as ultimas execucoes dos backups.                         #
# Description EN: Backs up the database, frontend, and S.O configuration files.                     #
#                 Provides report on the latest backup executions.                                  #
# Help:           Execute /bin/bash zabbix.backup.local.sh para informacoes de uso.                 #
#                 Run /bin/bash zabbix.backup.local.sh for usage information.                       #
# Create v1.0.0:  Sun Mai 01 17:30:32 BRT 2016                                                      #
# Update v1.1.0:  Sat Mai 21 10:43:30 BRT 2016 (ADD backup functions MYSQL and FRONT)               #
# Update v1.2.0:  Fri Fev 03 12:30:38 BRT 2018 (ADD validations and log rotations)                  #
# Update v1.3.0:  Wed Fev 07 00:42:59 BRT 2018 (ADD validations of backups FRONT)                   #
# Update v1.3.1:  Tue Ago 30 09:11:05 BRT 2018 (ADD simplified front backup)                        #
# Update v1.4.0:  Fri Ago 31 11:03:12 BRT 2018 (ADD function REPORT)                                #
#####################################################################################################

# REQUIREMENTS ######################################################################################
# crontab, bzip2, tar, zabbix_sender.                                                               #
# END ###############################################################################################

# GLOBAL VARIABLES ##################################################################################
VERS="1.4.0"                                                                                        #
VERCREATE="01/05/2016"                                                                              #
VERUPDATE="31/08/2018"                                                                              #
VERSCRIPTAUTHOR="Diego Cavalcante"                                                                  #
IP=$2                                                                                               # 
HOSTNAME=$3                                                                                         #
LOGDATE=`date +%d%m%Y.%H%M%S`                                                                       #
DIRLOGS="/var/log/zabbix/backup/local"                                                              #
DIRBKMYSQL="/var/backup/zabbix/mysql"                                                               #
DIRBKFRONT="/var/backup/zabbix/front"                                                               #
DATA=`date +%d%m%Y.%H%M%S`                                                                          #
EXECTIMEINI=`date +%s`                                                                              #
ROTATEDAYS="7"                                                                                      #
ROTATEEXEC="7d"                                                                                     #
ROTATELOGS="14d"                                                                                    #
ZSENDER='zabbix_sender -z'                                                                          #
# END ###############################################################################################

# MYSQL GLOBAL VARIABLES ############################################################################
MYIP="127.0.0.1"                                                                                    #
MYUSER="mysqluser"                                                                                  #
MYPASS="mysqlpassword"                                                                              #
MYDB="zabbixdb"                                                                                     #
MYERRO=".mysqldump.err"                                                                             #
# END ###############################################################################################

# FRONT GLOBAL VARIABLES ############################################################################
Z01="/etc/zabbix/"                                                                                  #
Z02="/etc/apache2/"                                                                                 #
Z03="/usr/share/zabbix/"                                                                            #
Z04="/etc/crontab"                                                                                  #
Z05="/etc/mysql/"                                                                                   #
Z06="/etc/odbc.ini"                                                                                 #
Z07="/etc/odbcinst.ini"                                                                             #
ZBKFILES=`echo "$Z01|$Z02|$Z03|$Z04|$Z05|$Z06|$Z07" |tr "|" "\n"`                                   #
# END ###############################################################################################

# ZABBIX SENDER KEY AND VALUES MYSQL ################################################################
MYKEYSTAT="zabbix.backup.mysql.local.stat"                                                          #
MYKEYSIZEBY="zabbix.backup.mysql.local.size"                                                        #
MYKEYNAME="zabbix.backup.mysql.local.name"                                                          #
MYKEYTIME="zabbix.backup.mysql.local.time"                                                          #
MYKEYNUMB="zabbix.backup.mysql.local.number"                                                        #
MYSUCESSO="0"                                                                                       #
MYERROPO1="1"                                                                                       #
MYERROPO2="2"                                                                                       #
MYERROPO3="3"                                                                                       #
MYERROPO4="4"                                                                                       #
MYERROPO5="5"                                                                                       #
# END ###############################################################################################

# ZABBIX SENDER KEY AND VALUES FRONT ################################################################
FRONTBKTEMP="temporary"                                                                             #
FRONTBKNAME="front"                                                                                 #
FRONTKEYSTAT="zabbix.backup.front.local.stat"                                                       #
FRONTKEYTIME="zabbix.backup.front.local.time"                                                       #
FRONTKEYSIZEBY="zabbix.backup.front.local.size"                                                     #
FRONTKEYNAME="zabbix.backup.front.local.name"                                                       #
FRONTKEYNUMB="zabbix.backup.front.local.number"                                                     #
FRONTSUCESSO="0"                                                                                    #
FRONTERROPO1="1"                                                                                    #
FRONTERROPO2="2"                                                                                    #
FRONTERROPO3="3"                                                                                    #
FRONTERROPO4="4"                                                                                    #
# END ###############################################################################################

# Function MYSQL ####################################################################################
# BR - Faz backup do banco de dados e executa algumas validações.                                   #
# EN - Backs up the database and performs some validations.                                         #
#####################################################################################################

function mysql
{
# BR - Cria diretório de logs e cria log no final.
# EN - Creates logs directory and create log at the end.
if [ -d $DIRLOGS ]; then
   LOG="$DIRLOGS/$MYDB.$LOGDATE.log"
   exec 1> >(tee -a $LOG)
   exec 2>&1
   ls -td1 $DIRLOGS/* |sed -e "1,$ROTATELOGS" |xargs -d '\n' rm -rif
else
   mkdir -p $DIRLOGS
   LOG="$DIRLOGS/$MYDB.$LOGDATE.log"
   exec 1> >(tee -a $LOG)
   exec 2>&1
fi

# BR - STEP 01 VALIDANDO LOGIN.
# EN - STEP 01 VALIDATING LOGIN.
   echo ""
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 01                                     ="
   echo "=                                               VALIDATING LOGIN                                                ="
   echo "================================================================================================================="
   PASSO01INI=`date +%s`
   TESTCONNECTION=`MYSQL_PWD=$MYPASS mysqlshow --user=$MYUSER -h $MYIP $MYDB |grep -v "Windcard" |grep -o "$MYDB"`
if [ "$TESTCONNECTION" == "$MYDB" ]; then
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Testing connection, please wait."
   sleep 1
   echo "INFO: Connection successfully completed in ($MYDB), continuing."
   PASSO01END=`date +%s`
   PASSO01CAL=`expr $PASSO01END \- $PASSO01INI`
   DURATION=`date -d@$PASSO01CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Testing connection, please wait."
   sleep 1
   PASSO01END=`date +%s`
   PASSO01CAL=`expr $PASSO01END \- $PASSO01INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP01=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOERROP01=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYERROPO1 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   ENVIOTIMEP01=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYTIME -o $EXECTIMEP01 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Failed to connect to ($MYDB)."
   echo "ERRO: Check that the USER:$MYUSER PASS:$MYPASS, MYDB:$MYDB are correct."
   if [ $ENVIOERROP01 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO01CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 02 VALIDANDO DIRETÓRIO DE BACKUP MYSQL.
# EN - STEP 02 VALIDATING MYSQL BACKUP DIRECTORY.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 02                                     ="
   echo "=                                       VALIDATING MYSQL BACKUP DIRECTORY                                       ="
   echo "================================================================================================================="
   PASSO02INI=`date +%s`
if [ -d $DIRBKMYSQL ]; then
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Checking the Backups storage directory for existence, please wait."
   sleep 1
   echo "INFO: Directory $DIRBKMYSQL already exists, continuing."
   PASSO02END=`date +%s`
   PASSO02CAL=`expr $PASSO02END \- $PASSO02INI`
   DURATION=`date -d@$PASSO02CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Checking the Backups storage directory for existence, please wait."
   sleep 1
   ENVIOERROP02=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYERROPO2 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "INFO: Directory $DIRBKMYSQL does not exist."
   echo "INFO: Creating directory, please wait."
   mkdir -p $DIRBKMYSQL
   echo "INFO: Directory $DIRBKMYSQL successfully created, continuing."
   PASSO02END=`date +%s`
   PASSO02CAL=`expr $PASSO02END \- $PASSO02INI`
   if [ $ENVIOERROP02 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO02CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
fi

# BR - STEP 03 VALIDANDO DUMP DO BANCO DE DADOS.
# EN - STEP 03 VALIDATING THE DATABASE DUMP.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 03                                     ="
   echo "=                                         VALIDATING THE DATABASE DUMP                                          ="
   echo "================================================================================================================="
   PASSO03INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Starting Backup From ($MYDB) in $DIRBKMYSQL, please wait."
   mysqldump -u"$MYUSER" --password="$MYPASS" -h $MYIP --single-transaction --routines $MYDB > $DIRBKMYSQL/$MYDB.$DATA.sql 2>$DIRBKMYSQL/$MYERRO
if [ "$?" -eq 0 ]; then
   echo "INFO: Backup ($MYDB.$DATA.sql) successfully created, continuing."
   PASSO03END=`date +%s`
   PASSO03CAL=`expr $PASSO03END \- $PASSO03INI`
   SIZEMB=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk 'NR==1 {print $5}'`
   DURATION=`date -d@$PASSO03CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Size ($SIZEMB)."
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   ENVIOERROP03=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYERROPO3 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO03END=`date +%s`
   PASSO03CAL=`expr $PASSO03END \- $PASSO03INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP03=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP03=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYTIME -o $EXECTIMEP03 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Failed to create backup ($MYDB.$DATA.sql)."
   echo "ERRO: Check the file $DIRBKMYSQL/$MYERRO for more details."
   if [ $ENVIOERROP03 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO03CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 04 VALIDANDO COMPRESSÃO.
# EN - STEP 04 VALIDATING COMPRESSION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 04                                     ="
   echo "=                                            VALIDATING COMPRESSION                                             ="
   echo "================================================================================================================="
   PASSO04INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Compacting ($MYDB.$DATA.sql) in $DIRBKMYSQL, please wait."
   bzip2 $DIRBKMYSQL/$MYDB.$DATA.sql 2> /dev/null
if [ "$?" -eq 0 ]; then
   echo "INFO: Backup ($MYDB.$DATA.sql.bz2) compressed successfully, continuing."
   PASSO04END=`date +%s`
   PASSO04CAL=`expr $PASSO04END \- $PASSO04INI`
   SIZEMB=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk 'NR==1 {print $5}'`
   SIZEBY=`ls -lt $DIRBKMYSQL |grep "$MYDB" |awk 'NR==1 {print $5}'`
   ENVIOSIZEP04=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSIZEBY -o $SIZEBY |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "INFO: Size ($SIZEMB)."
   if [ $ENVIOSIZEP04 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO04CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   ENVIOERROP04=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYERROPO4 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO04END=`date +%s`
   PASSO04CAL=`expr $PASSO04END \- $PASSO04INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP04=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP04=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYTIME -o $EXECTIMEP04 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Failed to compact backup ($MYDB.$DATA.sql.bz2)"
   if [ $ENVIOERROP04 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO04CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 05 VALIDANDO ROTAÇÃO DOS BACKUPS.
# EN - STEP 05 VALIDATING BACKUP ROTATION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 05                                     ="
   echo "=                                          VALIDATING BACKUP ROTATION                                           ="
   echo "================================================================================================================="
   PASSO05INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: The rule is to keep ($ROTATEDAYS) backup(s)."
   echo "INFO: Rotating backup(s), please wait."
   sleep 1
   ls -td1 $DIRBKMYSQL/* |sed -e "1,$ROTATEEXEC" |xargs -d '\n' rm -rif
   COUNTBK=`ls $DIRBKMYSQL |wc -w`
if [ $COUNTBK -eq $ROTATEDAYS ]; then
   echo "INFO: Backup(s) rotated successfully, continuing."
   NAME=`ls -lt $DIRBKMYSQL |grep "$MYDB" |awk 'NR==1 {print $9}'`
   ENVIONAMEP05=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYNAME -o $NAME |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   ENVIONUMBP05=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYNUMB -o $COUNTBK |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO05END=`date +%s`
   PASSO05CAL=`expr $PASSO05END \- $PASSO05INI`
   echo "INFO: Total of ($COUNTBK) backup(s) stored in $DIRBKMYSQL."
   if [ $ENVIONAMEP05 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO05CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   ENVIOERROP05=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYERROPO5 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   NAME=`ls -lt $DIRBKMYSQL |grep "$MYDB" |awk 'NR==1 {print $9}'`
   ENVIONAMEP05=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYNAME -o $NAME |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO05END=`date +%s`
   PASSO05CAL=`expr $PASSO05END \- $PASSO05INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP05=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP05=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYTIME -o $EXECTIMEP05 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Backup rotation failed."
   echo "ERRO: Rotation found only ($COUNTBK) backup(s)."
   if [ $ENVIOERROP05 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO05CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 06 VALIDANDO NOTIFICAÇÃO FINAL.
# EN - STEP 06 VALIDATING FINAL NOTIFICATION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP DATABASE - STEP 06                                     ="
   echo "=                                         VALIDATING FINAL NOTIFICATION                                         ="
   echo "================================================================================================================="
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   ENVIOSUCESSO=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYSTAT -o $MYSUCESSO |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   EXECTIMEEND=`date +%s`
   EXECTIMEP06=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP06=`$ZSENDER $IP -s "$HOSTNAME" -k $MYKEYTIME -o $EXECTIMEP06 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   DURATION=`date -d@$EXECTIMEP06 -u +%H:%M:%S`
   echo "INFO: Backup completed successfully."
   if [ $ENVIOSUCESSO -eq 0 ]; then
      DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      echo "INFO: Log create in $DIRLOGS/$MYDB.$LOGDATE.log"
      echo "INFO: Duration $DURATION"
      echo "INFO: $DATEEND"
      echo "================================================================================================================="
      echo ""
   else
      DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      echo "INFO: Log create in $DIRLOGS/$MYDB.$LOGDATE.log"
      echo "INFO: Duration $DURATION"
      echo "INFO: $DATEEND"
      echo "================================================================================================================="
      echo ""
   fi

# BR - STEP 07 RESUMO DA TAREFA DE BACKUP.
# EN - STEP 07 BACKUP TASK SUMMARY.
RESULTMYSQLDATE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $7"/"$6"_"$8}'`
RESULTMYSQLSIZE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $5}'`
RESULTMYSQLNAME=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $9}'`
RESULTMYSQLLINE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $9}' |wc -l`
RESULTMYSQLSEQ1=`seq 1 $RESULTMYSQLLINE |sed 's/[0-9]*/=/g'`
RESULTMYSQL=`paste <(echo "$RESULTMYSQLSEQ1") <(echo "$RESULTMYSQLDATE") <(echo "$RESULTMYSQLSIZE") <(echo "$RESULTMYSQLNAME") <(echo "$RESULTMYSQLSEQ1")`
echo "================================================================================================================="
echo "= ______   ___ ________ _______ _______________ __                                                              ="
echo "= ___  /__/  / ___  __ )___    |__  ____/___  //_/                                                              ="
echo "= __  / _/  /  __  __  |__  /| |_  /     __  ,<                      REPORT ZLBACK (SUMMARY)                    ="
echo "= _  /___  /____  /_/ / _  ___ |/ /___   _  /| |               ZABBIX LOCAL BACKUP DATABASE/FRONT               ="
echo "= /____//_____//_____/  /_/  |_|\____/   /_/ |_|                                                                ="
echo "=                                                                                                               ="
echo "================================================================================================================="
echo "= TOTAL: $RESULTMYSQLLINE =" |awk -F" " '{printf "%-1s %-5s %-102s %-1s\n", $1,$2,$3,$4}'
echo "= DIRECTORY: $DIRBKMYSQL =" |awk -F" " '{printf "%-1s %-10s %-98s %-1s\n", $1,$2,$3,$4}'
echo "================================================================================================================="
echo "= DATE SIZE NAME =" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "$RESULTMYSQL" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "================================================================================================================="
echo ""
}
# END ###############################################################################################

# Function FRONT ####################################################################################
# BR - Faz backup de arquivos importantes do frontend, personalizações do S.O com validações.       #
# EN - Backs up important frontend files, S.O customizations with validations.                      #
#####################################################################################################

function front
{
# BR - Cria diretório de logs e cria log no final.
# EN - Creates logs directory and create log at the end.
if [ -d $DIRLOGS ]; then
   LOG="$DIRLOGS/$FRONTBKNAME.$LOGDATE.log"
   exec 1> >(tee -a $LOG)
   exec 2>&1
   ls -td1 $DIRLOGS/* |sed -e "1,$ROTATELOGS" |xargs -d '\n' rm -rif
else
   mkdir -p $DIRLOGS
   LOG="$DIRLOGS/$FRONTBKNAME.$LOGDATE.log"
   exec 1> >(tee -a $LOG)
   exec 2>&1
fi

# BR - STEP 01 VALIDANDO DIRETÓRIO DE BACKUP FRONT.
# EN - STEP 01 VALIDATING FRONT BACKUP DIRECTORY.
   echo ""
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP FRONTEND - STEP 01                                     ="
   echo "=                                       VALIDATING FRONT BACKUP DIRECTORY                                       ="
   echo "================================================================================================================="
PASSO01INI=`date +%s`
if [ -d $DIRBKFRONT ]; then
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Checking the Backups storage directory for existence, please wait."
   sleep 1
   echo "INFO: Directory $DIRBKFRONT already exists, continuing."
else
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Checking the Backups storage directory for existence, please wait."
   sleep 1
   echo "INFO: Directory $DIRBKFRONT does not exist."
   echo "INFO: Creating directory, please wait."
   mkdir -p $DIRBKFRONT
   echo "INFO: Directory $DIRBKFRONT successfully created, continuing.."
   ENVIOERROP01=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTERROPO1 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   if [ $ENVIOERROP01 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
fi
   sleep 1
   mkdir -p $DIRBKFRONT/$FRONTBKTEMP
   if [ -d $DIRBKFRONT/$FRONTBKTEMP ]; then
      echo "INFO: Creating temporary storage directory, please wait."
      echo "INFO: Temporary directory $DIRBKFRONT/$FRONTBKTEMP created successfully, continuing."
      PASSO01END=`date +%s`
      PASSO01CAL=`expr $PASSO01END \- $PASSO01INI`
      DURATION=`date -d@$PASSO01CAL -u +%H:%M:%S`
      DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
      echo "INFO: Duration $DURATION"
      echo "INFO: $DATEEND"
      echo "================================================================================================================="
      echo ""
fi

# BR - STEP 02 VALIDANDO BACKUP DOS ARQUIVOS.
# EN - STEP 02 VALIDATING BACKUP OF FILES.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP FRONTEND - STEP 02                                     ="
   echo "=                                          VALIDATING BACKUP OF FILES                                           ="
   echo "================================================================================================================="
   PASSO02INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Starting backup, please wait."
for files in $ZBKFILES
do
if [ -e $files ]; then
   echo "================================================================================================================="
   echo "INFO: Verifying existence of origin $files"
   echo "INFO: Verifying existence of destination $DIRBKFRONT/$FRONTBKTEMP"$files""
   mkdir -p $DIRBKFRONT/$FRONTBKTEMP"$files"
   echo "INFO: Saving backup at destination, please wait."
   cp -R $files* $DIRBKFRONT/$FRONTBKTEMP"$files"
   ORIG=`ls -Rl $files |egrep -c "^\-"`
   DEST=`ls -Rl $DIRBKFRONT/$FRONTBKTEMP"$files" |egrep -c "^\-"`
   echo "INFO: Validating backup, please wait."
   sleep 1
      if [ $ORIG -eq $DEST ]; then
         DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
         echo "INFO: Origin: ($ORIG files)."
         echo "INFO: Destination: ($DEST files)."
         echo "INFO: Backup succssesfully done."
         echo "INFO: $DATEEND"
         echo "================================================================================================================="
         echo ""
      else
         sleep 1
         PASSO02END=`date +%s`
         PASSO02CAL=`expr $PASSO02END \- $PASSO02INI`
         ENVIOERROP02=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTERROPO2 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
         EXECTIMEEND=`date +%s`
         EXECTIMEP02=`expr $EXECTIMEEND \- $EXECTIMEINI`
         ENVIOTIMEP02=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYTIME -o $EXECTIMEP02 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
            if [ $ENVIOERROP02 -eq 0 ]; then
               echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
               echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
            else
               echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
               echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
            fi
         echo "ERRO: Origin: ($ORIG files)."
         echo "ERRO: Destination: ($DEST files)."
         echo "ERRO: Backup $files finalized with errors."
         DURATION=`date -d@$PASSO02CAL -u +%H:%M:%S`
         DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
         echo "INFO: Duration $DURATION"
         echo "INFO: $DATEEND"
         echo "================================================================================================================="
         echo ""
         exit 0
      fi
else
   sleep 1
   PASSO02END=`date +%s`
   PASSO02CAL=`expr $PASSO02END \- $PASSO02INI`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Verifying existence of origin $files"
   ENVIOERROP02=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTERROPO2 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   EXECTIMEEND=`date +%s`
   EXECTIMEP02=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP02=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYTIME -o $EXECTIMEP02 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
      if [ $ENVIOERROP02 -eq 0 ]; then
         echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
         echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      else
         echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
         echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      fi
   DURATION=`date -d@$PASSO02CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "ERRO: Backup source $files, not exist."
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi
done

# BR - STEP 03 VALIDANDO COMPRESSÃO.
# EN - STEP 03 VALIDATING COMPRESSION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP FRONTEND - STEP 03                                     ="
   echo "=                                            VALIDATING COMPRESSION                                             ="
   echo "================================================================================================================="
   PASSO03INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: Compressing backup, please wait."
   sleep 1
   cd $DIRBKFRONT/$FRONTBKTEMP
   tar czf $FRONTBKNAME.$DATA.tar.gz *
if [ -e $DIRBKFRONT/$FRONTBKTEMP/$FRONTBKNAME.$DATA.tar.gz ]; then
   echo "INFO: Backup ($FRONTBKNAME.$DATA.tar.gz) successfully compacted."
   cp $FRONTBKNAME.$DATA.tar.gz $DIRBKFRONT
   echo "INFO: Backup saved in $DIRBKFRONT."
   cd $DIRBKFRONT
   rm -R $DIRBKFRONT/$FRONTBKTEMP
   echo "INFO: Temporary directory $DIRBKFRONT/$FRONTBKTEMP successfully removed."
   PASSO03END=`date +%s`
   PASSO03CAL=`expr $PASSO03END \- $PASSO03INI`
   SIZEMB=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk 'NR==1 {print $5}'`
   SIZEBY=`ls -lt $DIRBKFRONT |grep "$FRONTBKNAME" |awk 'NR==1 {print $5}'`
   ENVIOSIZEP03=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSIZEBY -o $SIZEBY |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "INFO: Size ($SIZEMB)."
   if [ $ENVIOSIZEP03 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO03CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   ENVIOERROP03=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTERRO03 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO03END=`date +%s`
   PASSO03CAL=`expr $PASSO03END \- $PASSO03INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP03=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP03=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYTIME -o $EXECTIMEP03 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Failed to compact backup ($FRONTBKNAME.$DATA.tar.gz)."
   if [ $ENVIOERROP03 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO03CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 04 VALIDANDO ROTAÇÃO DOS BACKUPS.
# EN - STEP 04 VALIDATING BACKUP ROTATION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP FRONTEND - STEP 04                                     ="
   echo "=                                          VALIDATING BACKUP ROTATION                                           ="
   echo "================================================================================================================="
   PASSO04INI=`date +%s`
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   echo "INFO: The rule is to keep ($ROTATEDAYS) backup(s)."
   echo "INFO: Rotating backup(s), please wait."
   sleep 1
   ls -td1 $DIRBKFRONT/* |sed -e "1,$ROTATEEXEC" |xargs -d '\n' rm -rif
   COUNTBK=`ls $DIRBKFRONT |wc -w`
if [ $COUNTBK -eq $ROTATEDAYS ]; then
   echo "INFO: Backup(s) rotated successfully, continuing."
   NAME=`ls -lt $DIRBKFRONT |grep "$FRONTBKNAME" |awk 'NR==1 {print $9}'`
   ENVIONAMEP04=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYNAME -o $NAME |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   ENVIONUMBP04=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYNUMB -o $COUNTBK |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO04END=`date +%s`
   PASSO04CAL=`expr $PASSO04END \- $PASSO04INI`
   echo "INFO: Total of ($COUNTBK) backup(s) stored in $DIRBKFRONT."
   if [ $ENVIONAMEP04 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO04CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
else
   ENVIOERROP04=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTERROPO4 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   NAME=`ls -lt $DIRBKFRONT |grep "$FRONTBKNAME" |awk 'NR==1 {print $9}'`
   ENVIONAMEP04=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYNAME -o $NAME |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   PASSO04END=`date +%s`
   PASSO04CAL=`expr $PASSO04END \- $PASSO04INI`
   EXECTIMEEND=`date +%s`
   EXECTIMEP04=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP04=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYTIME -o $EXECTIMEP04 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "ERRO: Backup rotation failed."
   echo "ERRO: Rotation found only ($COUNTBK) backup(s)."
   if [ $ENVIOERROP04 -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
   fi
   DURATION=`date -d@$PASSO04CAL -u +%H:%M:%S`
   DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: Duration $DURATION"
   echo "INFO: $DATEEND"
   echo "================================================================================================================="
   echo ""
   exit 0
fi

# BR - STEP 05 VALIDANDO NOTIFICAÇÃO FINAL.
# EN - STEP 05 VALIDATING FINAL NOTIFICATION.
   echo "================================================================================================================="
   echo "=                                    ZABBIX LOCAL BACKUP FRONTEND - STEP 05                                     ="
   echo "=                                         VALIDATING FINAL NOTIFICATION                                         ="
   echo "================================================================================================================="
   DATEINI=`date "+%d/%m/%Y %H:%M:%S"`
   echo "INFO: $DATEINI"
   ENVIOSUCESSO=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYSTAT -o $FRONTSUCESSO |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   EXECTIMEEND=`date +%s`
   EXECTIMEP05=`expr $EXECTIMEEND \- $EXECTIMEINI`
   ENVIOTIMEP05=`$ZSENDER $IP -s "$HOSTNAME" -k $FRONTKEYTIME -o $EXECTIMEP05 |grep -E "info from server:" |cut -d ";" -f2 |awk '{print $2}'`
   echo "INFO: Backup completed successfully."
   if [ $ENVIOSUCESSO -eq 0 ]; then
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "INFO: Notification successfully sent to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      echo "INFO: Log create in $DIRLOGS/$FRONTBKNAME.$LOGDATE.log"
      DURATION=`date -d@$EXECTIMEP05 -u +%H:%M:%S`
      DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
      echo "INFO: Duration $DURATION"
      echo "INFO: $DATEEND"
      echo "================================================================================================================="
      echo ""
   else
      echo "INFO: Notifying Zabbix Server ($IP), Hostame ($HOSTNAME), please wait."
      echo "ERRO: Failed to send notification to Zabbix Server ($IP), Hostname ($HOSTNAME)."
      echo "INFO: Log create in $DIRLOGS/$FRONTBKNAME.$LOGDATE.log"
      DURATION=`date -d@$EXECTIMEP05 -u +%H:%M:%S`
      DATEEND=`date "+%d/%m/%Y %H:%M:%S"`
      echo "INFO: Duration $DURATION"
      echo "INFO: $DATEEND"
      echo "================================================================================================================="
      echo ""
   fi

# BR - STEP 07 RESUMO DA TAREFA DE BACKUP.
# EN - STEP 07 BACKUP TASK SUMMARY.
RESULTFRONTDATE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $7"/"$6"_"$8}'`
RESULTFRONTSIZE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $5}'`
RESULTFRONTNAME=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $9}'`
RESULTFRONTLINE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $9}' |wc -l`
RESULTFRONTSEQ1=`seq 1 $RESULTFRONTLINE |sed 's/[0-9]*/=/g'`
RESULTFRONT=`paste <(echo "$RESULTFRONTSEQ1") <(echo "$RESULTFRONTDATE") <(echo "$RESULTFRONTSIZE") <(echo "$RESULTFRONTNAME") <(echo "$RESULTFRONTSEQ1")`
echo "================================================================================================================="
echo "= ______   ___ ________ _______ _______________ __                                                              ="
echo "= ___  /__/  / ___  __ )___    |__  ____/___  //_/                                                              ="
echo "= __  / _/  /  __  __  |__  /| |_  /     __  ,<                      REPORT ZLBACK (SUMMARY)                    ="
echo "= _  /___  /____  /_/ / _  ___ |/ /___   _  /| |               ZABBIX LOCAL BACKUP DATABASE/FRONT               ="
echo "= /____//_____//_____/  /_/  |_|\____/   /_/ |_|                                                                ="
echo "=                                                                                                               ="
echo "================================================================================================================="
echo "= TOTAL: $RESULTFRONTLINE =" |awk -F" " '{printf "%-1s %-5s %-102s %-1s\n", $1,$2,$3,$4}'
echo "= DIRECTORY: $DIRBKFRONT =" |awk -F" " '{printf "%-1s %-10s %-98s %-1s\n", $1,$2,$3,$4}'
echo "================================================================================================================="
echo "= DATE SIZE NAME =" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "$RESULTFRONT" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "================================================================================================================="
echo ""
}
# END ###############################################################################################

# Function REPORT ###################################################################################
# BR - Fornece relatório detalhado sobre os backups armazenados.                                    #
# EN - Provides detailed report on stored backups.                                                  #
#####################################################################################################

function report
{
RESULTMYSQLDATE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $7"/"$6"_"$8}'`
RESULTMYSQLSIZE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $5}'`
RESULTMYSQLNAME=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $9}'`
RESULTMYSQLLINE=`ls -lht $DIRBKMYSQL |grep "$MYDB" |awk '{print $9}' |wc -l`
RESULTMYSQLSEQ1=`seq 1 $RESULTMYSQLLINE |sed 's/[0-9]*/=/g'`
RESULTFRONTDATE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $7"/"$6"_"$8}'`
RESULTFRONTSIZE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $5}'`
RESULTFRONTNAME=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $9}'`
RESULTFRONTLINE=`ls -lht $DIRBKFRONT |grep "$FRONTBKNAME" |awk '{print $9}' |wc -l`
RESULTFRONTSEQ1=`seq 1 $RESULTFRONTLINE |sed 's/[0-9]*/=/g'`
RESULTMYSQL=`paste <(echo "$RESULTMYSQLSEQ1") <(echo "$RESULTMYSQLDATE") <(echo "$RESULTMYSQLSIZE") <(echo "$RESULTMYSQLNAME") <(echo "$RESULTMYSQLSEQ1")`
RESULTFRONT=`paste <(echo "$RESULTFRONTSEQ1") <(echo "$RESULTFRONTDATE") <(echo "$RESULTFRONTSIZE") <(echo "$RESULTFRONTNAME") <(echo "$RESULTFRONTSEQ1")`
echo ""
echo "================================================================================================================="
echo "= ______   ___ ________ _______ _______________ __                                                              ="
echo "= ___  /__/  / ___  __ )___    |__  ____/___  //_/                                                              ="
echo "= __  / _/  /  __  __  |__  /| |_  /     __  ,<                      REPORT ZLBACK (BACKUPS)                    ="
echo "= _  /___  /____  /_/ / _  ___ |/ /___   _  /| |               ZABBIX LOCAL BACKUP DATABASE/FRONT               ="
echo "= /____//_____//_____/  /_/  |_|\____/   /_/ |_|                                                                ="
echo "=                                                                                                               ="
echo "================================================================================================================="
echo "= TOTAL: $RESULTMYSQLLINE =" |awk -F" " '{printf "%-1s %-5s %-102s %-1s\n", $1,$2,$3,$4}'
echo "= DIRECTORY: $DIRBKMYSQL =" |awk -F" " '{printf "%-1s %-10s %-98s %-1s\n", $1,$2,$3,$4}'
echo "================================================================================================================="
echo "= DATE SIZE NAME =" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "$RESULTMYSQL" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "================================================================================================================="
echo "= TOTAL: $RESULTFRONTLINE =" |awk -F" " '{printf "%-1s %-5s %-102s %-1s\n", $1,$2,$3,$4}'
echo "= DIRECTORY: $DIRBKFRONT =" |awk -F" " '{printf "%-1s %-10s %-98s %-1s\n", $1,$2,$3,$4}'
echo "================================================================================================================="
echo "= DATE SIZE NAME =" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "$RESULTFRONT" |awk -F" " '{printf "%-1s %-14s %-6s %-87s %-1s\n", $1,$2,$3,$4,$5}'
echo "================================================================================================================="
echo ""
}
# END ###############################################################################################

#################################
#     PARAMETER OPTION $1       #
#################################
case $1 in                      #
        MYSQL) mysql;           #
        ;;                      #
        FRONT) front;           #
        ;;                      #
        REPORT) report;         #
        ;;                      #
        *)                      #
# END ###########################
echo ""
echo "================================================================================================================="
echo "= ______   ___ ________ _______ _______________ __ NAME: ZLBACK ================================================="
echo "= ___  /__/  / ___  __ )___    |__  ____/___  //_/ DESCRIPTION: ZABBIX LOCAL BACKUP DATABASE/FRONT =============="
echo "= __  / _/  /  __  __  |__  /| |_  /     __  ,<    VERSION: $VERS ==============================================="
echo "= _  /___  /____  /_/ / _  ___ |/ /___   _  /| |   CREATE: $VERCREATE ==========================================="
echo "= /____//_____//_____/  /_/  |_|\____/   /_/ |_|   UPDATE: $VERUPDATE ==========================================="
echo "=                                                  AUTHOR: $VERSCRIPTAUTHOR ====================================="
echo "================================================================================================================="
echo "= USAGE: MYSQL|FRONT|REPORT                                                                                     ="
echo "=                                                                                                               ="
echo "= Ex: /bin/bash backup.zabbix.local.sh MYSQL IP HOSTNAME                                                        ="
echo "= Ex: /bin/bash backup.zabbix.local.sh FRONT IP HOSTNAME                                                        ="
echo "= Ex: /bin/bash backup.zabbix.local.sh REPORT                                                                   ="
echo "================================================================================================================="
echo "= IP: Zabbix Server IP address (ex: 127.0.0.1, 182.168.0.222)                                                   ="
echo "= HOSTNAME: Name of the host to which the template is associated (ex: BACKUP, SERVER.BACKUP)                    ="
echo "================================================================================================================="
echo ""
exit ;;
esac
# END SCRIPT ###########################################################################################################
