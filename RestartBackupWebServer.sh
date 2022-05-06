#!/bin/bash
#RestartBackupWebServer.sh
#########################################################################################
##  Скрипт позволяет перезапускать WEB сервера SAS и cделать бэкап                     ##
##  папок temp, logs, work.                                                            ##
##  Порядок использования:                                                             ##
##  RestartBackupWebServer.sh <option> <Имя SAS WEB server>                            ##
##                                                                                     ##
##  options:                                                                           ##
##  -b скрипт делает бэкап temp, logs, work и удаляет старые файлы в этих папках.      ##
##  Бэкап производится в дерикторию SERVICEDIR/<Имя SAS WEB server>/backup             ##
##                                                                                     ##
##  Перед использованием необходимо указать SERVICEDIR и LOGFILE                       ##
##                                                                                     ##
#########################################################################################

SERVICEDIR="/opt/sas/SASConfigMid/Lev1/Web/WebAppServer/" # путь к папке с веб серверам SAS
LOGFILE="/opt/sas/SASHome/cron/logs/RestartBackupWebServer.log" # путь к логу, куда сохранять действия скрипта

# Функция записи в лог
# $1 сообщение для лога
function filelogger (){
    echo `date --rfc-3339=seconds`' PID' $$ $USER ':' $1 >> $LOGFILE
    echo $1
}

# Проверка кода ошибки последней выполненной команды
# $1 код ошибки, $2 сообщение
e_exit(){
    if [[ $1 -ne 0 ]]
    then
        filelogger " ${2} - ERROR! "
        exit 1
    else
        filelogger " ${2} - Successful! "
    fi
}

#получение списка web служб
cd $SERVICEDIR
declare -a listOfServices
for file in * ; do
    listOfServices+=( "$file" )
done

#проверка верно ли передано имя службы
if [[ ! " ${listOfServices[*]} " =~ " ${1} " ]]; then
    if [[ ! " ${listOfServices[*]} " =~ " ${2} " ]]; then
        filelogger "Assigned service ${1} dosen't exist!"
        echo 'Allowed services:' "${listOfServices[*]}"
        exit 1
    fi
fi

if [ ! "${1}" = "-b" ]; then
echo "You may use key -b for backup"
fi


if [ "${1}" = "-b" ]; then
    shift
    #Остановка службы
    STOPSSTARTSH="${SERVICEDIR}/${1}/bin/tcruntime-ctl.sh"
    filelogger "Start restarting ${1}"
    echo "*==========================STOP============================*" >> $LOGFILE
    echo "*                                                          *" >> $LOGFILE
    $STOPSSTARTSH stop 1>> $LOGFILE 2>> $LOGFILE
    ex=$?
    echo "*                                                          *" >> $LOGFILE
    echo "*=========================/STOP============================*" >> $LOGFILE
    e_exit $ex "Stopping ${1}" 
    sleep 10 

   #Создание папки backup с текущей датой
    BACKUPPATH=$SERVICEDIR/${1}/backup
    mkdir $BACKUPPATH 2>/dev/null 
    NAME_ARCHIVE="`date +"%Y-%m-%d-%T"`"
    mkdir $BACKUPPATH/$NAME_ARCHIVE
    e_exit $? "Backup folder created: $BACKUPPATH/$NAME_ARCHIVE"

    #перенос файлов 
    cp -r ${SERVICEDIR}/${1}/logs $BACKUPPATH/$NAME_ARCHIVE 2>>$LOGFILE
    e_exit $? "Logs folder was copied"
    cp -r ${SERVICEDIR}/${1}/temp $BACKUPPATH/$NAME_ARCHIVE 2>>$LOGFILE
    e_exit $? "Temp folder was copied"
    cp -r ${SERVICEDIR}/${1}/work $BACKUPPATH/$NAME_ARCHIVE 2>>$LOGFILE
    e_exit $? "Work folder was copied"

    #удаление старых файлов
    rm -rf ${SERVICEDIR}/${1}/logs/* 2>>$LOGFILE
    e_exit $? "Old logs folder was deleted"
    rm -rf ${SERVICEDIR}/${1}/temp/* 2>>$LOGFILE
    e_exit $? "Old temp folder was deleted"
    rm -rf ${SERVICEDIR}/${1}/work/* 2>>$LOGFILE
    e_exit $? "Old work folder was deleted"

    #Создание пустых файлов для лога SAS
    touch  ${SERVICEDIR}/${1}/logs/catalina.out 2>>$LOGFILE
    touch  ${SERVICEDIR}/${1}/logs/server.logs 2>>$LOGFILE
    
elif [[ " ${listOfServices[*]} " =~ " ${1} " ]]; then
    #Остановка службы
    STOPSSTARTSH="${SERVICEDIR}/${1}/bin/tcruntime-ctl.sh"
    filelogger "Start restarting ${1}"
    echo "*==========================STOP============================*" >> $LOGFILE
    echo "*                                                          *" >> $LOGFILE
    $STOPSSTARTSH stop 1>> $LOGFILE 2>> $LOGFILE
    ex=$?
    echo "*                                                          *" >> $LOGFILE
    echo "*=========================/STOP============================*" >> $LOGFILE
    e_exit $ex "Stopping ${1}" 
    sleep 10 
else
    filelogger "ERROR: Somethink went wrong =(("
fi

#Запуск службы
echo "*========================START=============================*" >> $LOGFILE
echo "*                                                          *" >> $LOGFILE
$STOPSSTARTSH start 1>> $LOGFILE 2>> $LOGFILE
ex=$?
echo "*                                                          *" >> $LOGFILE
echo "*=======================/START=============================*" >> $LOGFILE
e_exit $ex "Restarting ${1}"  

exit 0






