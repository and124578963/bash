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


cd $LOGSDIR
lastLog=`ls -t1 | sed "1q;d"`

# находим все id процессов
declare -a listIDs
touch /tmp/temp_file_q
awk '{print $4}' ${lastLog} | grep -o '\"[[:digit:]]*\:' | grep -o '[[:digit:]]*' > /tmp/temp_file_q
while read -r id ; do
    if [[ ! " ${listIDs[*]} " =~ " ${id} " ]]; then
        listIDs+=( "$id" )
    fi
done < /tmp/temp_file_q
# echo "${listIDs[*]}"

for id in ${listIDs[*]} ; do
    # получаем строки с одним id процесса 
    declare -a listDate
    declare -a listTimestamp
    grep -e "\"$id\:" ${lastLog} > /tmp/temp_file_q
    while read -r str ; do
        # echo $str
        date=`echo $str | awk '{print $3}' | grep -o '[[:digit:]]*'`
        dateNorm=`date -d @$date`
        nameJob=`echo $str | awk '{print $4}' | grep -o '\:.*\"' `
        listDate+=( "$dateNorm" )
	listTimestamp+=( "$date" )
    done < /tmp/temp_file_q


    statuses=`grep -o 'Status=[[:digit:]]*' /tmp/temp_file_q | grep -o "[[:digit:]]*"`
    check=$?
    if [ ${check} -eq 1 ]; then
        status="None"
    else
        for status in ${statuses}; do
            if [[ " 0 " = " ${status} " ]]; then
                status="OK (${statuses})"
            else
                status="ERROR (${statuses})"
                break
            fi
        done
    fi

    campagin=`grep -o "\-v \-\-.*'" /tmp/temp_file_q | grep -o "[A-Z0-9]*"`
    check_camp=$?
    declare -a listCampagin
    for Camp in $campagin ; do
        if [[ ! " ${listCampagin[*]} " =~ " ${Camp} " ]]; then
            listCampagin+=( "$Camp" )
        fi
    done
    # echo ${listCampagin[*]}

    users=`grep -o " quotequote[[:graph:]]*@[[:graph:]]*quotequote " /tmp/temp_file_q`
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
    let duration=(${listTimestamp[-1]} - ${listTimestamp[0]}) 
   # 
    if [ ${check_camp} -eq 1 ] && [ "${status}" != "None" ]; then
        listCampagin=( "Stored process" )
    fi
    
    echo -e "${listCampagin[*]} ;; $nameJob ;; $statuses ;; ${listUser[*]} ;; $start ;; $stop ;; $duration ;/; "
    unset listCampagin nameJob listStatus listUser start stop id listDate listTimestamp
done
rm /tmp/temp_file_q
exit 0






