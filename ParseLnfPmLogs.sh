#!/bin/bash
#ParseLsfPmLogs.sh
# Скрипт позволяет спарсить лог планировщика задач process manager LSF
# Определяет выполненные кампании, статус выполнения, нозвание джоба, время начала и конца и пользователя 
#
# Порядок использования:
# ParseLsfPmLogs.sh <название лога>
#
# Перед использованием необходимо указать LOGSDIR - путь к папке с логами
#

LOGSDIR="/glowbyte/sas/pm/work/history/" # путь к pm/work/history/


RED='\033[0;31m'
GREEN='\033[0;32m'
YEL='\033[1;33m'
NC='\033[0m'

#получение списка ЛОГОВ
cd $LOGSDIR
declare -a listOfLogs
for file in * ; do
    listOfLogs+=( "$file" )
done

#проверка верно ли передано имя лога
if [[ ! " ${listOfLogs[*]} " =~ " ${1} " ]]; then
    filelogger "Assigned LOG ${1} dosen't exist!"
    echo 'Allowed LOGS:'
    ls -rtl
    exit 1
fi

# находим все id процессов
declare -a listIDs
touch temp_file
awk '{print $4}' ${1} | grep -o '\"[[:digit:]]*\:' | grep -o '[[:digit:]]*' > temp_file
while read -r id ; do
    if [[ ! " ${listIDs[*]} " =~ " ${id} " ]]; then
        listIDs+=( "$id" )
    fi
done < temp_file
# echo "${listIDs[*]}"

for id in ${listIDs[*]} ; do
    # получаем строки с одним id процесса 
    declare -a listDate
    grep -e "\"$id\:" ${1} > temp_file
    while read -r str ; do
        # echo $str
        date=`echo $str | awk '{print $3}' | grep -o '[[:digit:]]*'`
        dateNorm=`date -d @$date`
        nameJob=`echo $str | awk '{print $4}' | grep -o '\:.*\"' `
        listDate+=( "$dateNorm" )
    done < temp_file


    statuses=`grep -o 'Status=[[:digit:]]*' temp_file | grep -o "[[:digit:]]*"`
    check=$?
    if [ ${check} -eq 1 ]; then
        status="${YEL}See next log${NC}"
    else
        for status in ${statuses}; do
            if [[ " 0 " = " ${status} " ]]; then
                status="${GREEN}OK${NC} (${statuses})"
            else
                status="ERROR (${statuses})"
                break
            fi
        done
    fi

    campagin=`grep -o "\-v \-\-.*'" temp_file | grep -o "[A-Z0-9]*"`
    declare -a listCampagin
    for Camp in $campagin ; do
        if [[ ! " ${listCampagin[*]} " =~ " ${Camp} " ]]; then
            listCampagin+=( "$Camp" )
        fi
    done
    # echo ${listCampagin[*]}

    users=`grep -o " quotequote[[:graph:]]*@[[:graph:]]*quotequote " temp_file`
    declare -a listUser
    for usr in $users ; do
        usr=${usr/quotequote/}
        usr=${usr/quotequote/}
        if [[ ! " ${listUser[*]} " =~ " ${usr} " ]]; then
            listUser+=( "$usr" )
        fi
    done
    # echo ${listUser[*]}


    nameJob=${nameJob#:*:}
    nameJob=${nameJob/[\"]/}
    start="${listDate[0]}"
    stop="${listDate[-1]}"


    echo -e campaign=${YEL}${listCampagin[*]}${NC} Job=$nameJob status=$status user=${listUser[*]} start=$start stop=$stop log_id=$id
    echo
    unset listCampagin nameJob listStatus listUser start stop id
done
rm temp_file
exit 0






